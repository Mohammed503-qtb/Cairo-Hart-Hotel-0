// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/room-types — أنواع الغرف
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { parseJsonArray, asString, asInt, asBool, isUniqueViolation } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const types = await db.roomType.findMany({
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    include: { _count: { select: { rooms: true, reservations: true, rates: true } } },
  })

  return ok({
    roomTypes: types.map((t) => ({
      id: t.id,
      name: t.name,
      nameEn: t.nameEn,
      description: t.description,
      capacityAdults: t.capacityAdults,
      capacityChildren: t.capacityChildren,
      bedConfig: t.bedConfig,
      sizeSqm: t.sizeSqm,
      basePriceCents: t.basePriceCents,
      amenities: parseJsonArray(t.amenities),
      images: parseJsonArray(t.images),
      active: t.active,
      sortOrder: t.sortOrder,
      roomsCount: t._count.rooms,
      reservationsCount: t._count.reservations,
      ratesCount: t._count.rates,
      createdAt: t.createdAt,
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const name = asString(body.name)?.trim()
  if (!name) return fail('اسم النوع مطلوب')

  const capacityAdults = asInt(body.capacityAdults) ?? 2
  if (capacityAdults < 1 || capacityAdults > 8) return fail('عدد البالغين يجب أن يكون بين 1 و 8')
  const capacityChildren = asInt(body.capacityChildren) ?? 0
  if (capacityChildren < 0 || capacityChildren > 6) return fail('عدد الأطفال يجب أن يكون بين 0 و 6')
  const sizeSqm = asInt(body.sizeSqm) ?? 0
  if (sizeSqm < 0 || sizeSqm > 500) return fail('المساحة يجب أن تكون بين 0 و 500 م²')
  const basePriceCents = asInt(body.basePriceCents) ?? 0
  if (basePriceCents <= 0) return fail('السعر الأساسي يجب أن يكون أكبر من صفر')

  const amenities = Array.isArray(body.amenities) ? body.amenities.filter((a): a is string => typeof a === 'string') : []
  const images = Array.isArray(body.images) ? body.images.filter((a): a is string => typeof a === 'string') : []

  const hotel = await db.hotel.findFirst({ select: { id: true } })
  if (!hotel) return fail('لم يتم العثور على بيانات الفندق', 404)

  try {
    const created = await db.roomType.create({
      data: {
        hotelId: hotel.id,
        name,
        nameEn: asString(body.nameEn) ?? '',
        description: asString(body.description) ?? '',
        capacityAdults,
        capacityChildren,
        bedConfig: asString(body.bedConfig) ?? '',
        sizeSqm,
        basePriceCents,
        amenities: JSON.stringify(amenities),
        images: JSON.stringify(images),
        sortOrder: asInt(body.sortOrder) ?? 0,
        active: asBool(body.active) ?? true,
      },
    })

    await audit(db, {
      action: 'ROOM_TYPE_CHANGED',
      entityType: 'RoomType',
      entityId: created.id,
      actor: staffName,
      actorRole: 'ADMIN',
      details: { op: 'CREATE', name, basePriceCents },
    })

    return ok({ roomType: { ...created, amenities, images } }, 201)
  } catch (e) {
    if (isUniqueViolation(e)) return fail('يوجد نوع غرف بهذا الاسم بالفعل')
    throw e
  }
}

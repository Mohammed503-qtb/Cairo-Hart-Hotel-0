// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/rooms — الغرف الفعلية
// GET: مع اسم النوع + الضيف الحالي إن وُجدت إقامة نشطة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt, isUniqueViolation } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const rooms = await db.room.findMany({
    orderBy: [{ floor: 'asc' }, { number: 'asc' }],
    include: {
      roomType: { select: { id: true, name: true } },
      stays: {
        where: { status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] } },
        include: { guest: { select: { fullName: true } } },
        orderBy: { checkInAt: 'desc' },
        take: 1,
      },
    },
  })

  return ok({
    rooms: rooms.map((r) => {
      const activeStay = r.stays[0]
      return {
        id: r.id,
        number: r.number,
        floor: r.floor,
        status: r.status,
        notes: r.notes,
        roomTypeId: r.roomType.id,
        roomTypeName: r.roomType.name,
        guestName: r.status === 'OCCUPIED' && activeStay ? activeStay.guest.fullName : null,
        expectedCheckOut: r.status === 'OCCUPIED' && activeStay ? activeStay.expectedCheckOutAt : null,
        createdAt: r.createdAt,
      }
    }),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const number = asString(body.number)?.trim()
  if (!number) return fail('رقم الغرفة مطلوب')

  const floor = asInt(body.floor) ?? 1
  if (floor < 1 || floor > 30) return fail('الطابق يجب أن يكون بين 1 و 30')

  const roomTypeId = asString(body.roomTypeId)?.trim()
  if (!roomTypeId) return fail('نوع الغرفة مطلوب')
  const type = await db.roomType.findUnique({ where: { id: roomTypeId } })
  if (!type) return fail('نوع الغرفة غير موجود', 404)

  const duplicate = await db.room.findUnique({ where: { number } })
  if (duplicate) return fail(`يوجد غرفة بالرقم ${number} بالفعل — رقم الغرفة يجب أن يكون فريدًا`)

  const created = await db.room.create({
    data: { number, floor, roomTypeId, status: 'AVAILABLE', notes: asString(body.notes) ?? null },
  })

  await audit(db, {
    action: 'ROOM_CHANGED',
    entityType: 'Room',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'CREATE', room: number, floor, roomTypeName: type.name },
  })

  return ok({
    room: {
      id: created.id,
      number: created.number,
      floor: created.floor,
      status: created.status,
      notes: created.notes,
      roomTypeId: type.id,
      roomTypeName: type.name,
      guestName: null,
      expectedCheckOut: null,
      createdAt: created.createdAt,
    },
  }, 201)
}

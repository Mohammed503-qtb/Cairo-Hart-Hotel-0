// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/rates — المعدلات الموسمية
// POST: تحذير تداخل (يسمح بالإنشاء) + audit RATE_CHANGED
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const rates = await db.rate.findMany({
    orderBy: [{ roomTypeId: 'asc' }, { startDate: 'asc' }],
    include: { roomType: { select: { id: true, name: true, basePriceCents: true } } },
  })

  return ok({
    rates: rates.map((r) => ({
      id: r.id,
      name: r.name,
      roomTypeId: r.roomTypeId,
      roomTypeName: r.roomType.name,
      roomTypeBasePriceCents: r.roomType.basePriceCents,
      startDate: r.startDate,
      endDate: r.endDate,
      priceCents: r.priceCents,
      active: r.active,
      createdAt: r.createdAt,
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const roomTypeId = asString(body.roomTypeId)?.trim()
  if (!roomTypeId) return fail('نوع الغرفة مطلوب')
  const type = await db.roomType.findUnique({ where: { id: roomTypeId } })
  if (!type) return fail('نوع الغرفة غير موجود', 404)

  const name = asString(body.name)?.trim()
  if (!name) return fail('اسم المعدل مطلوب')

  const startDateRaw = asString(body.startDate)
  const endDateRaw = asString(body.endDate)
  if (!startDateRaw || !endDateRaw) return fail('نطاق التاريخين مطلوب')
  const startDate = new Date(startDateRaw)
  const endDate = new Date(endDateRaw)
  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) return fail('تواريخ غير صالحة')
  if (endDate < startDate) return fail('تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو مساويًا له')

  const priceCents = asInt(body.priceCents) ?? 0
  if (priceCents <= 0) return fail('سعر المعدل يجب أن يكون أكبر من صفر')

  // تحذير التداخل — يسمح بالإنشاء
  const overlapping = await db.rate.findFirst({
    where: {
      roomTypeId,
      id: { not: undefined },
      startDate: { lte: endDate },
      endDate: { gte: startDate },
    },
    orderBy: { startDate: 'asc' },
  })
  let warning: string | undefined
  if (overlapping) {
    warning = `يتداخل مع معدل «${overlapping.name}» — المعدل الأحدث بدايةً يسود لكل ليلة`
  }

  const created = await db.rate.create({
    data: { roomTypeId, name, startDate, endDate, priceCents, active: true },
  })

  await audit(db, {
    action: 'RATE_CHANGED',
    entityType: 'Rate',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'CREATE', name, roomTypeName: type.name, startDate: startDate.toISOString().slice(0, 10), endDate: endDate.toISOString().slice(0, 10), priceCents, warning },
  })

  return ok({
    rate: {
      id: created.id,
      name: created.name,
      roomTypeId: type.id,
      roomTypeName: type.name,
      roomTypeBasePriceCents: type.basePriceCents,
      startDate: created.startDate,
      endDate: created.endDate,
      priceCents: created.priceCents,
      active: created.active,
      createdAt: created.createdAt,
    },
    warning,
  }, 201)
}

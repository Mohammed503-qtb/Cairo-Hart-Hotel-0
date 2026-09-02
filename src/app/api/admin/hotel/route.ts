// ─────────────────────────────────────────────────────────────
// GET/PATCH /api/admin/hotel — إعدادات الفندق
// PATCH: تحقق من الحقول ثم audit SETTINGS_UPDATED بالحقول المتغيرة فقط
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt } from '../_shared'

export const dynamic = 'force-dynamic'

const STRING_FIELDS = [
  'name', 'tagline', 'description', 'phone', 'whatsapp', 'email', 'address', 'city', 'currency',
  'cancellationPolicy', 'paymentPolicy', 'childrenPolicy', 'petsPolicy', 'smokingPolicy',
] as const

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const hotel = await db.hotel.findFirst()
  if (!hotel) return fail('لم يتم العثور على بيانات الفندق', 404)
  return ok({ hotel })
}

export async function PATCH(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const hotel = await db.hotel.findFirst()
  if (!hotel) return fail('لم يتم العثور على بيانات الفندق', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | number> = {}
  const changed: Record<string, string | number> = {}

  // الحقول النصية
  for (const f of STRING_FIELDS) {
    const v = asString(body[f])
    if (v === undefined) continue
    if (f === 'name' && v.trim() === '') return fail('اسم الفندق لا يمكن أن يكون فارغًا')
    if (f === 'currency' && v.trim() === '') return fail('العملة لا يمكن أن تكون فارغة')
    if (v !== (hotel as Record<string, unknown>)[f]) {
      data[f] = v
      changed[f] = v
    }
  }

  // الأوقات HH:MM
  for (const f of ['checkInTime', 'checkOutTime'] as const) {
    const v = asString(body[f])
    if (v === undefined) continue
    if (!/^\d{2}:\d{2}$/.test(v)) return fail('صيغة الوقت يجب أن تكون HH:MM (مثال: 14:00)')
    if (v !== hotel[f]) {
      data[f] = v
      changed[f] = v
    }
  }

  // النسب 0-100
  for (const f of ['taxPercent', 'weekendSurchargePercent'] as const) {
    const v = asInt(body[f])
    if (v === undefined) continue
    if (v < 0 || v > 100) return fail('النسبة يجب أن تكون بين 0 و 100')
    if (v !== hotel[f]) {
      data[f] = v
      changed[f] = v
    }
  }

  // حدود الإقامة والحجز
  const minStay = asInt(body.minStayNights)
  if (minStay !== undefined && (minStay < 1 || minStay > 30)) return fail('أقل عدد ليالٍ يجب أن يكون بين 1 و 30')
  const maxStay = asInt(body.maxStayNights)
  if (maxStay !== undefined && (maxStay < 1 || maxStay > 60)) return fail('أقصى عدد ليالٍ يجب أن يكون بين 1 و 60')
  const horizon = asInt(body.bookingHorizonDays)
  if (horizon !== undefined && (horizon < 1 || horizon > 730)) return fail('أفق الحجز يجب أن يكون بين 1 و 730 يومًا')

  const finalMin = minStay ?? hotel.minStayNights
  const finalMax = maxStay ?? hotel.maxStayNights
  if (finalMax < finalMin) return fail('أقصى عدد ليالٍ يجب أن يكون أكبر من أو يساوي أقل عدد ليالٍ')

  for (const [f, v] of [['minStayNights', minStay], ['maxStayNights', maxStay], ['bookingHorizonDays', horizon]] as const) {
    if (v === undefined) continue
    if (v !== hotel[f]) {
      data[f] = v
      changed[f] = v
    }
  }

  if (Object.keys(data).length === 0) {
    return ok({ hotel, changedFields: [], note: 'لا توجد تغييرات — تغيير الضريبة والأسعار يؤثر على الحجوزات الجديدة فقط، والحجوزات القديمة تحتفظ بلقطة سعرها' })
  }

  const updated = await db.hotel.update({ where: { id: hotel.id }, data })

  await audit(db, {
    action: 'SETTINGS_UPDATED',
    entityType: 'Hotel',
    entityId: hotel.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { changed },
  })

  return ok({
    hotel: updated,
    changedFields: Object.keys(changed),
    note: 'تم الحفظ — تغيير الضريبة والأسعار يؤثر على الحجوزات الجديدة فقط، والحجوزات القديمة تحتفظ بلقطة سعرها وقت الحجز',
  })
}

// POST /api/public/lookup — إدارة الحجز (مرجع + هاتف)
// لا يكشف وجود الحجز عند فشل التحقق (نفس رسالة الفشل دائمًا)
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { audit } from '@/lib/audit'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import {
  digitsOnly,
  lastNDigits,
  toReservationPublic,
  snapshotBreakdown,
  cancellationInfo,
} from '../_lib'

export const dynamic = 'force-dynamic'

const NOT_FOUND_MSG = 'لم نتمكن من التحقق من هذا الحجز. تأكد من رقم الحجز ورقم الهاتف'

interface LookupBody {
  reference?: unknown
  phone?: unknown
}

export async function POST(req: Request) {
  // حماية: 5 محاولات/دقيقة لكل IP
  const ip = clientIp(req)
  const rl = rateLimit(`lookup:${ip}`, 5, 60_000)
  if (!rl.allowed) {
    return fail(`محاولات كثيرة جدًا — يرجى المحاولة مجددًا بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  const body = await readBody<LookupBody>(req)
  if (!body) return fail('طلب غير صالح', 400)

  const reference = String(body.reference ?? '').trim().toUpperCase()
  const phone = String(body.phone ?? '').trim()

  if (!reference || digitsOnly(phone).length < 9) {
    return fail(NOT_FOUND_MSG, 404)
  }

  try {
    const reservation = await db.reservation.findUnique({
      where: { bookingReference: reference },
      include: { guest: true, roomType: true },
    })

    // التحقق: آخر 9 أرقام من هاتف الحجز === آخر 9 أرقام من الهاتف المدخل
    if (!reservation || lastNDigits(reservation.guest.phone) !== lastNDigits(phone)) {
      return fail(NOT_FOUND_MSG, 404)
    }

    await audit(db, {
      action: 'RESERVATION_LOOKED_UP',
      entityType: 'Reservation',
      entityId: reservation.id,
      actor: reservation.guest.fullName,
      actorRole: 'GUEST',
      details: { reference, via: 'website' },
    })

    return ok({
      reservation: toReservationPublic(reservation),
      snapshot: snapshotBreakdown(reservation),
      cancellation: cancellationInfo(reservation),
    })
  } catch {
    return fail('حدث خطأ أثناء جلب تفاصيل الحجز — يرجى المحاولة مرة أخرى', 500)
  }
}

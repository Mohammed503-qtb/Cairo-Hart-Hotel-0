// POST /api/public/cancel — إلغاء حجز عبر الموقع
// مجاني حتى (الوصول − 24 ساعة)، وإلا رسوم ليلة واحدة (نظام تجريبي بلا استرداد فعلي)
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { audit } from '@/lib/audit'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import { formatDateAr } from '@/lib/format'
import {
  digitsOnly,
  lastNDigits,
  toReservationPublic,
  cancellationInfo,
  type ReservationWithRelations,
} from '../_lib'

export const dynamic = 'force-dynamic'

const NOT_FOUND_MSG = 'لم نتمكن من التحقق من هذا الحجز. تأكد من رقم الحجز ورقم الهاتف'

interface CancelBody {
  reference?: unknown
  phone?: unknown
}

export async function POST(req: Request) {
  // حماية: 5 محاولات/دقيقة لكل IP
  const ip = clientIp(req)
  const rl = rateLimit(`cancel:${ip}`, 5, 60_000)
  if (!rl.allowed) {
    return fail(`محاولات كثيرة جدًا — يرجى المحاولة مجددًا بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  const body = await readBody<CancelBody>(req)
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

    // نفس تحقق lookup — لا يُكشف الوجود
    if (!reservation || lastNDigits(reservation.guest.phone) !== lastNDigits(phone)) {
      return fail(NOT_FOUND_MSG, 404)
    }

    if (reservation.status !== 'CONFIRMED' && reservation.status !== 'PENDING') {
      return fail('لا يمكن إلغاء هذا الحجز في حالته الحالية', 400)
    }

    // سياسة الإلغاء (تُحسب لحظة الطلب)
    const info = cancellationInfo(reservation)
    const now = new Date()

    const updated: ReservationWithRelations = await db.$transaction(async (tx) => {
      const row = await tx.reservation.update({
        where: { id: reservation.id },
        data: { status: 'CANCELLED', cancelledAt: now },
        include: { guest: true, roomType: true },
      })

      await audit(tx, {
        action: 'RESERVATION_CANCELLED',
        entityType: 'Reservation',
        entityId: row.id,
        actor: 'الموقع',
        actorRole: 'WEBSITE',
        details: {
          reference: row.bookingReference,
          guest: row.guest.fullName,
          refundable: info.refundable,
          penaltyCents: info.penaltyCents,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          type: 'RESERVATION',
          title: `إلغاء حجز ${row.bookingReference}`,
          body: `${row.guest.fullName} — ${row.roomType.name}، ${formatDateAr(row.checkIn)}`,
        },
      })

      return row
    })

    return ok({
      reservation: toReservationPublic(updated),
      refundable: info.refundable,
      penaltyCents: info.penaltyCents,
    })
  } catch {
    return fail('حدث خطأ أثناء إلغاء الحجز — يرجى المحاولة مرة أخرى', 500)
  }
}

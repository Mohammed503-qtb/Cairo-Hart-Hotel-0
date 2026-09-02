// ─────────────────────────────────────────────────────────────
// POST /api/guest/extension — طلب تمديد الإقامة
// تحقق (نشطة + تواريخ + حد الإقامة + الأفق + توفر الخادم)
// + تسعير computeQuote + ExtensionRequest PENDING + إشعار وتدقيق وبث
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { computeQuote } from '@/lib/pricing'
import { formatMoney, formatDateAr } from '@/lib/format'
import {
  loadStay,
  loadHotel,
  parseDateInput,
  startOfDayLocal,
  endOfDayLocal,
  nightsBetweenDays,
  GuestApiError,
} from '../_lib'

export const dynamic = 'force-dynamic'

const BLOCKING_STATUSES = ['PENDING', 'CONFIRMED', 'CHECKED_IN']

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const body = await readBody<{ newCheckOut?: string; note?: string }>(req)
  const newCheckOut = parseDateInput(body?.newCheckOut)
  const note = typeof body?.note === 'string' ? body.note.trim().slice(0, 300) : ''

  if (!newCheckOut) return fail('أدخل تاريخ خروج جديدًا صالحًا (YYYY-MM-DD)')

  try {
    const stay = await loadStay(stayId)
    if (!stay) return fail('الإقامة غير موجودة', 404)
    if (stay.status !== 'ACTIVE') {
      return fail('لا يمكن طلب تمديد — إقامتك غير نشطة', 403)
    }

    const hotel = await loadHotel()
    const expected = startOfDayLocal(stay.expectedCheckOutAt)

    // 1) التاريخ الجديد بعد الخروج المتوقع (مقارنة يومية)
    if (nightsBetweenDays(expected, newCheckOut) < 1) {
      return fail('تاريخ الخروج الجديد يجب أن يكون بعد تاريخ الخروج الحالي')
    }

    // 2) ضمن الحد الأقصى للإقامة من الوصول
    const maxStayNights = hotel?.maxStayNights ?? 30
    const totalNights = nightsBetweenDays(stay.checkInAt, newCheckOut)
    if (totalNights > maxStayNights) {
      return fail(`الحد الأقصى لمدة الإقامة ${maxStayNights} ليلة`)
    }

    // 3) ضمن أفق الحجز
    const horizonDays = hotel?.bookingHorizonDays ?? 365
    const horizon = startOfDayLocal(new Date())
    horizon.setDate(horizon.getDate() + horizonDays)
    if (newCheckOut > horizon) {
      return fail(`التمديد متاح حتى ${horizonDays} يومًا من اليوم فقط`)
    }

    // 4) فحص توفر الخادم — المحجوز لنوع غرفته بين الخروج الحالي والجديد مستثنيًا حجزه
    const roomTypeId = stay.reservation.roomTypeId
    const [roomsCount, overlapping] = await Promise.all([
      db.room.count({
        where: { roomTypeId, status: { not: 'OUT_OF_ORDER' } },
      }),
      db.reservation.count({
        where: {
          roomTypeId,
          status: { in: BLOCKING_STATUSES },
          checkIn: { lt: endOfDayLocal(newCheckOut) },
          checkOut: { gt: endOfDayLocal(expected) },
          id: { not: stay.reservationId },
        },
      }),
    ])
    if (overlapping >= roomsCount) {
      return fail('الغرفة غير متاحة للتمديد في هذه التواريخ')
    }

    // 5) التسعير من الخروج المتوقع إلى التاريخ الجديد
    const rates = await db.rate.findMany({
      where: { roomTypeId, active: true },
      select: { name: true, startDate: true, endDate: true, priceCents: true },
    })
    const quote = computeQuote({
      checkIn: expected,
      checkOut: newCheckOut,
      basePriceCents: stay.room.roomType.basePriceCents,
      rates,
      weekendSurchargePercent: hotel?.weekendSurchargePercent ?? 0,
      taxPercent: hotel?.taxPercent ?? 0,
      currency: stay.reservation.currency,
      roomsCount: stay.reservation.roomsCount,
    })

    // 6) إنشاء الطلب
    const created = await db.$transaction(async (tx) => {
      const request = await tx.extensionRequest.create({
        data: {
          stayId,
          newCheckOut: endOfDayLocal(newCheckOut),
          nights: quote.nights,
          priceCents: quote.grandTotalCents,
          note: note || null,
          status: 'PENDING',
        },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'EXTENSION',
          title: 'طلب تمديد إقامة',
          body: `${guestName} (الغرفة ${stay.room.number}) يطلب تمديد إقامته حتى ${formatDateAr(newCheckOut)} — التكلفة التقديرية ${formatMoney(quote.grandTotalCents, quote.currency)} (${quote.nights} ليلة).`,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId,
          type: 'EXTENSION',
          title: 'تم إرسال طلب التمديد',
          body: `طلبك بتمديد الإقامة حتى ${formatDateAr(newCheckOut)} قيد المراجعة — التكلفة التقديرية ${formatMoney(quote.grandTotalCents, quote.currency)}.`,
        },
      })

      await audit(tx, {
        action: 'EXTENSION_REQUESTED',
        entityType: 'ExtensionRequest',
        entityId: request.id,
        actor: guestName,
        actorRole: 'GUEST',
        details: {
          stayId,
          reference: stay.reference,
          newCheckOut: endOfDayLocal(newCheckOut).toISOString(),
          nights: quote.nights,
          priceCents: quote.grandTotalCents,
        },
      })

      return request
    })

    // بث للاستقبال
    await emitEvent(wsRooms.reception, WS_EVENTS.NOTIFICATION_NEW, {
      title: 'طلب تمديد إقامة',
      stayId,
    })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.NOTIFICATION_NEW, {
      title: 'تم إرسال طلب التمديد',
    })

    return ok(
      {
        request: {
          id: created.id,
          newCheckOut: created.newCheckOut.toISOString(),
          nights: created.nights,
          priceCents: created.priceCents,
          note: created.note,
          status: created.status,
          createdAt: created.createdAt.toISOString(),
        },
        quote: {
          nights: quote.nights,
          currency: quote.currency,
          taxPercent: quote.taxPercent,
          nightly: quote.nightly,
          subtotalCents: quote.subtotalCents,
          taxCents: quote.taxCents,
          grandTotalCents: quote.grandTotalCents,
        },
      },
      201
    )
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest extension failed', e)
    return fail('حدث خطأ أثناء إرسال طلب التمديد — أعد المحاولة', 500)
  }
}

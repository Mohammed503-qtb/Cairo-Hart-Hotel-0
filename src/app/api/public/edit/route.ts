// POST /api/public/edit — تعديل الحجز المؤهل من الموقع (المسار C · REQ-01)
//
// «المؤهل» = حجز CONFIRMED لم يبدأ إقامته وتاريخه لم يدخل نافذة الـ24 ساعة
// الأخيرة قبل الوصول (نفس نافذة الإلغاء المجاني).
//
// القواعد الصارمة (متطابقة مع بوابة الحجز الأصلية):
//   · التحقق: مرجع الحجز + آخر 9 أرقام من الهاتف (لا يُكشف الوجود عند الفشل)
//   · الخادم وحده يقرر السعر والتوفر — إعادة تسعير كاملة + لقطة سعر جديدة
//   · التوفر يُفحص داخل المعاملة مع استثناء الحجز نفسه (غرفه تُحرَّر لأنها
//     ستُستبدل ذريًا) — يمنع التعديل فوق المخزون ولا يُغلق على نفسه (I1/I7)
//   · المدفوع يُنقل كما هو (لا دفع/استرداد فعلي من الموقع — تسوية الفرق
//     عند الفندق) — paidCents تبقى مرآة لمدفوعات COMPLETED المسجلة
//   · التدقيق RESERVATION_MODIFIED (قبل/بعد) + إشعار استقبال + بث فوري
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { availableRoomCount, validateStayDates } from '@/lib/availability'
import { computeQuote, buildSnapshot } from '@/lib/pricing'
import { audit } from '@/lib/audit'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatDateAr } from '@/lib/format'
import {
  digitsOnly,
  lastNDigits,
  inputToDate,
  toReservationPublic,
  snapshotBreakdown,
  cancellationInfo,
  type ReservationWithRelations,
} from '../_lib'

export const dynamic = 'force-dynamic'

const NOT_FOUND_MSG = 'لم نتمكن من التحقق من هذا الحجز. تأكد من رقم الحجز ورقم الهاتف'
const WINDOW_MS = 24 * 3_600_000

class AvailabilityError extends Error {
  status = 409
}

interface EditBody {
  reference?: unknown
  phone?: unknown
  checkIn?: unknown
  checkOut?: unknown
  roomTypeId?: unknown
  adults?: unknown
  children?: unknown
  roomsCount?: unknown
  specialRequests?: unknown
}

/** هل الحجز «مؤهل» للتعديل الآن؟ (CONFIRMED + خارج نافذة الـ24 ساعة) */
function editWindowInfo(r: { status: string; checkIn: Date }): {
  eligible: boolean
  freeUntil: Date
} {
  const freeUntil = new Date(new Date(r.checkIn).getTime() - WINDOW_MS)
  const eligible = r.status === 'CONFIRMED' && new Date() < freeUntil
  return { eligible, freeUntil }
}

export async function POST(req: Request) {
  // حماية: 5 محاولات/دقيقة لكل IP (مثل الإلغاء)
  const ip = clientIp(req)
  const rl = rateLimit(`edit:${ip}`, 5, 60_000)
  if (!rl.allowed) {
    return fail(`محاولات كثيرة جدًا — يرجى المحاولة مجددًا بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  const body = await readBody<EditBody>(req)
  if (!body) return fail('طلب غير صالح', 400)

  const reference = String(body.reference ?? '').trim().toUpperCase()
  const phone = String(body.phone ?? '').trim()
  if (!reference || digitsOnly(phone).length < 9) {
    return fail(NOT_FOUND_MSG, 404)
  }

  const checkIn = inputToDate(body.checkIn)
  const checkOut = inputToDate(body.checkOut)
  if (!checkIn || !checkOut) {
    return fail('يرجى إدخال تاريخي الوصول والمغادرة بشكل صحيح', 400)
  }

  const adults = Number(body.adults ?? 1)
  const children = Number(body.children ?? 0)
  const roomsCount = Number(body.roomsCount ?? 1)
  if (!Number.isInteger(adults) || adults < 1 || adults > 10) return fail('عدد البالغين غير صالح', 400)
  if (!Number.isInteger(children) || children < 0 || children > 10) return fail('عدد الأطفال غير صالح', 400)
  if (!Number.isInteger(roomsCount) || roomsCount < 1 || roomsCount > 3) {
    return fail('عدد الغرف يجب أن يكون بين 1 و 3', 400)
  }

  const roomTypeId = String(body.roomTypeId ?? '').trim()
  if (!roomTypeId) return fail('يرجى اختيار نوع الغرفة', 400)

  const specialRequests = String(body.specialRequests ?? '').trim()

  try {
    const reservation = await db.reservation.findUnique({
      where: { bookingReference: reference },
      include: { guest: true, roomType: true },
    })

    // نفس تحقق lookup/cancel — لا يُكشف الوجود
    if (!reservation || lastNDigits(reservation.guest.phone) !== lastNDigits(phone)) {
      return fail(NOT_FOUND_MSG, 404)
    }

    // ── أهلية التعديل ──
    if (reservation.status !== 'CONFIRMED') {
      return fail('لا يمكن تعديل هذا الحجز في حالته الحالية', 400)
    }
    const { freeUntil } = editWindowInfo(reservation)
    if (new Date() >= freeUntil) {
      return fail(
        'تجاوزت مهلة التعديل المجاني (24 ساعة قبل الوصول) — يرجى التواصل مع الفندق مباشرة لتغيير حجزك',
        400
      )
    }

    // ── كشف «لا تغييرات» (نفس القيم الحالية) ──
    const sameDates =
      reservation.checkIn.getTime() === checkIn.getTime() &&
      reservation.checkOut.getTime() === checkOut.getTime()
    const sameValues =
      sameDates &&
      reservation.roomTypeId === roomTypeId &&
      reservation.adults === adults &&
      reservation.children === children &&
      reservation.roomsCount === roomsCount &&
      (reservation.specialRequests ?? '') === specialRequests
    if (sameValues) {
      return fail('لم تقم بأي تعديل — القيم المدخلة مطابقة للحجز الحالي', 400)
    }

    // ── المعاملة: تحقق + إعادة تسعير + استبدال ذري ──
    const updated: ReservationWithRelations = await db.$transaction(async (tx) => {
      const hotel = await tx.hotel.findFirst()
      if (!hotel) return Promise.reject(new Error('معلومات الفندق غير متاحة حاليًا'))

      const roomType = await tx.roomType.findFirst({
        where: { id: roomTypeId, hotelId: hotel.id, active: true },
      })
      if (!roomType) {
        return Promise.reject(Object.assign(new Error('نوع الغرفة المحدد غير متاح'), { status: 400 }))
      }

      const v = validateStayDates(checkIn, checkOut, {
        minStayNights: hotel.minStayNights,
        maxStayNights: hotel.maxStayNights,
        bookingHorizonDays: hotel.bookingHorizonDays,
      })
      if (!v.valid) return Promise.reject(Object.assign(new Error(v.error ?? 'المواعيد غير صالحة'), { status: 400 }))

      if (adults > roomType.capacityAdults * roomsCount || children > roomType.capacityChildren * roomsCount) {
        return Promise.reject(Object.assign(new Error('عدد الضيوف يتجاوز سعة هذا النوع من الغرف'), { status: 400 }))
      }

      // التوفر داخل المعاملة مع استثناء الحجز نفسه — غرفه المحجوزة تحررت
      // للنطاق الجديد لأن الحجز القديم يُستبدل ذريًا ضمن نفس المعاملة (I1/I7)
      const avail = await availableRoomCount(tx, roomType.id, checkIn, checkOut, {
        excludeReservationId: reservation.id,
      })
      if (avail < roomsCount) {
        throw new AvailabilityError('الغرفة لم تعد متاحة لهذه التواريخ. يرجى اختيار خيار آخر أو تغيير المواعيد')
      }

      // إعادة التسعير من الخادم فقط + لقطة سعر جديدة
      const rates = await tx.rate.findMany({
        where: { roomTypeId: roomType.id, active: true },
        select: { name: true, startDate: true, endDate: true, priceCents: true },
      })
      const now = new Date()
      const quote = computeQuote({
        checkIn,
        checkOut,
        basePriceCents: roomType.basePriceCents,
        rates,
        weekendSurchargePercent: hotel.weekendSurchargePercent,
        taxPercent: hotel.taxPercent,
        currency: hotel.currency,
        roomsCount,
      })
      const snapshot = buildSnapshot({
        quote,
        roomTypeName: roomType.name,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: now.toISOString(),
      })

      // المدفوع يُنقل كما هو (لا حركة مالية من الموقع — تسوية الفرق عند الفندق)
      const paidBefore = reservation.paidCents
      const paymentStatus =
        paidBefore >= quote.grandTotalCents && quote.grandTotalCents > 0
          ? 'PAID'
          : paidBefore > 0
            ? 'PARTIALLY_PAID'
            : 'UNPAID'

      const row = await tx.reservation.update({
        where: { id: reservation.id },
        data: {
          roomTypeId: roomType.id,
          checkIn,
          checkOut,
          adults,
          children,
          roomsCount,
          currency: quote.currency,
          subtotalCents: quote.subtotalCents,
          discountCents: quote.discountCents,
          taxCents: quote.taxCents,
          grandTotalCents: quote.grandTotalCents,
          paymentStatus,
          specialRequests: specialRequests || null,
          priceSnapshot: snapshot,
        },
        include: { guest: true, roomType: true },
      })

      // التدقيق: قبل/بعد كاملة (I10)
      await audit(tx, {
        action: 'RESERVATION_MODIFIED',
        entityType: 'Reservation',
        entityId: row.id,
        actor: row.guest.fullName,
        actorRole: 'WEBSITE',
        details: {
          reference: row.bookingReference,
          before: {
            roomTypeId: reservation.roomTypeId,
            roomTypeName: reservation.roomType.name,
            checkIn: reservation.checkIn.toISOString(),
            checkOut: reservation.checkOut.toISOString(),
            adults: reservation.adults,
            children: reservation.children,
            roomsCount: reservation.roomsCount,
            grandTotalCents: reservation.grandTotalCents,
            paymentStatus: reservation.paymentStatus,
          },
          after: {
            roomTypeId: roomType.id,
            roomTypeName: roomType.name,
            checkIn: checkIn.toISOString(),
            checkOut: checkOut.toISOString(),
            adults,
            children,
            roomsCount,
            grandTotalCents: quote.grandTotalCents,
            paymentStatus,
          },
          paidCents: paidBefore,
          specialRequests: specialRequests || null,
        },
      })

      // إشعار الاستقبال
      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          type: 'RESERVATION',
          title: `تعديل حجز ${row.bookingReference}`,
          body: `${row.guest.fullName} — ${roomType.name}، ${formatDateAr(checkIn)}`,
        },
      })

      return row
    })

    // بعد نجاح المعاملة: بث فوري (best-effort)
    void emitEvent(wsRooms.reception, WS_EVENTS.RESERVATION_MODIFIED, {
      bookingReference: updated.bookingReference,
      guestName: updated.guest.fullName,
      roomTypeName: updated.roomType.name,
      checkIn: updated.checkIn.toISOString(),
    })

    return ok({
      reservation: toReservationPublic(updated),
      snapshot: snapshotBreakdown(updated),
      cancellation: cancellationInfo(updated),
    })
  } catch (e) {
    if (e instanceof AvailabilityError) {
      return fail(e.message, 409)
    }
    const err = e as Error & { status?: number }
    if (typeof err.status === 'number') {
      return fail(err.message, err.status)
    }
    return fail('حدث خطأ أثناء تعديل الحجز — يرجى المحاولة مرة أخرى', 500)
  }
}

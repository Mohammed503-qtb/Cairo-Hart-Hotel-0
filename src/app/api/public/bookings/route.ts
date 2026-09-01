// POST /api/public/bookings — إنشاء حجز مؤكد من الموقع
// الخادم وحده يقرر السعر والتوفر (المعاملة تمنع الحجز المزدوج)
// Idempotency: مفتاح لكل محاولة دفع مع TTL 10 دقائق (in-memory)
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { availableRoomCount, validateStayDates } from '@/lib/availability'
import { computeQuote, buildSnapshot } from '@/lib/pricing'
import { nextBookingReference } from '@/lib/refs'
import { audit } from '@/lib/audit'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatDateAr } from '@/lib/format'
import {
  digitsOnly,
  lastNDigits,
  inputToDate,
  toReservationPublic,
  type ReservationWithRelations,
} from '../_lib'

export const dynamic = 'force-dynamic'

// ── Idempotency cache (module-level, TTL 10 دقائق) ──
const IDEM_TTL = 10 * 60_000
const idempotencyCache = new Map<string, { reservationId: string; at: number }>()

interface BookingBody {
  checkIn?: unknown
  checkOut?: unknown
  adults?: unknown
  children?: unknown
  roomsCount?: unknown
  roomTypeId?: unknown
  guest?: {
    fullName?: unknown
    phone?: unknown
    whatsapp?: unknown
    email?: unknown
  }
  specialRequests?: unknown
  paymentMethod?: unknown
  idempotencyKey?: unknown
}

class AvailabilityError extends Error {
  status = 409
}

export async function POST(req: Request) {
  // حماية: 10 حجوزات/ساعة لكل IP
  const ip = clientIp(req)
  const rl = rateLimit(`book:${ip}`, 10, 3_600_000)
  if (!rl.allowed) {
    return fail(`تم تجاوز عدد محاولات الحجز المسموح — يرجى المحاولة مجددًا بعد ${Math.ceil(rl.retryAfterSec / 60)} دقيقة`, 429)
  }

  const body = await readBody<BookingBody>(req)
  if (!body) return fail('طلب غير صالح', 400)

  // ── Idempotency: أعد نفس الحجز السابق إن وُجد ──
  const idemKey = typeof body.idempotencyKey === 'string' ? body.idempotencyKey.slice(0, 100).trim() : ''
  if (idemKey) {
    // تنظيف الإدخالات المنتهية (تنظيف خفيف مع كل نداء)
    const now = Date.now()
    for (const [k, v] of idempotencyCache) {
      if (now - v.at > IDEM_TTL) idempotencyCache.delete(k)
    }
    const hit = idempotencyCache.get(idemKey)
    if (hit && now - hit.at < IDEM_TTL) {
      const existing = await db.reservation.findUnique({
        where: { id: hit.reservationId },
        include: { guest: true, roomType: true },
      })
      if (existing) {
        return ok({ reservation: toReservationPublic(existing), replayed: true })
      }
    }
  }

  // ── التحقق من المدخلات ──
  const guest = body.guest ?? {}
  const fullName = String(guest.fullName ?? '').trim()
  if (fullName.length < 3) {
    return fail('يرجى إدخال الاسم الكامل (3 أحرف على الأقل)', 400)
  }
  const phone = String(guest.phone ?? '').trim()
  if (digitsOnly(phone).length < 9) {
    return fail('يرجى إدخال رقم هاتف صحيح (9 أرقام على الأقل)', 400)
  }
  const whatsappRaw = String(guest.whatsapp ?? '').trim()
  if (whatsappRaw && digitsOnly(whatsappRaw).length < 9) {
    return fail('رقم الواتساب غير صحيح (9 أرقام على الأقل)', 400)
  }
  const emailRaw = String(guest.email ?? '').trim()
  if (emailRaw && !/^\S+@\S+\.\S+$/.test(emailRaw)) {
    return fail('يرجى إدخال بريد إلكتروني صحيح أو تركه فارغًا', 400)
  }
  const paymentMethod = String(body.paymentMethod ?? '')
  if (paymentMethod !== 'PAY_AT_HOTEL' && paymentMethod !== 'CARD') {
    return fail('طريقة الدفع غير صالحة', 400)
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

  const specialRequests = String(body.specialRequests ?? '').trim()

  try {
    const hotel = await db.hotel.findFirst()
    if (!hotel) return fail('معلومات الفندق غير متاحة حاليًا', 503)

    const roomTypeId = String(body.roomTypeId ?? '')
    const roomType = await db.roomType.findFirst({
      where: { id: roomTypeId, hotelId: hotel.id, active: true },
    })
    if (!roomType) {
      return fail('نوع الغرفة المحدد غير متاح', 400)
    }

    const v = validateStayDates(checkIn, checkOut, {
      minStayNights: hotel.minStayNights,
      maxStayNights: hotel.maxStayNights,
      bookingHorizonDays: hotel.bookingHorizonDays,
    })
    if (!v.valid) return fail(v.error ?? 'المواعيد غير صالحة', 400)

    if (adults > roomType.capacityAdults * roomsCount || children > roomType.capacityChildren * roomsCount) {
      return fail('عدد الضيوف يتجاوز سعة هذا النوع من الغرف', 400)
    }

    const rates = await db.rate.findMany({
      where: { roomTypeId: roomType.id, active: true },
      select: { name: true, startDate: true, endDate: true, priceCents: true },
    })

    const now = new Date()

    // ── المعاملة: منع الحجز المزدوج (التحقق من التوفر داخلها) ──
    const created: ReservationWithRelations = await db.$transaction(async (tx) => {
      // 1) التوفر داخل المعاملة — الفشل هنا يمنع الكتابة
      const avail = await availableRoomCount(tx, roomType.id, checkIn, checkOut)
      if (avail < roomsCount) {
        throw new AvailabilityError('الغرفة لم تعد متاحة لهذه التواريخ. يرجى اختيار خيار آخر أو تغيير المواعيد')
      }

      // 2) السعر يُحسب من جديد في الخادم فقط
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

      // 3) الضيف: upsert عبر آخر 9 أرقام من الهاتف (الحقل فريد)
      const last9 = lastNDigits(phone, 9)
      const existingGuest =
        last9.length === 9
          ? await tx.guest.findFirst({ where: { phone: { endsWith: last9 } } })
          : await tx.guest.findFirst({ where: { phone } })

      const guestData = {
        fullName,
        ...(whatsappRaw ? { whatsapp: whatsappRaw } : {}),
        ...(emailRaw ? { email: emailRaw } : {}),
      }

      const guestRow = existingGuest
        ? await tx.guest.update({
            where: { id: existingGuest.id },
            data: guestData,
          })
        : await tx.guest.create({
            data: { fullName, phone, ...(whatsappRaw ? { whatsapp: whatsappRaw } : {}), ...(emailRaw ? { email: emailRaw } : {}) },
          })

      // 4) مرجع الحجز
      const reference = await nextBookingReference(tx)

      // 5) إنشاء الحجز (مؤكد مباشرة — المصدر الموقع)
      const snapshot = buildSnapshot({
        quote,
        roomTypeName: roomType.name,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: now.toISOString(),
      })

      const reservation = await tx.reservation.create({
        data: {
          bookingReference: reference,
          guestId: guestRow.id,
          roomTypeId: roomType.id,
          status: 'CONFIRMED',
          source: 'WEBSITE',
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
          paidCents: 0,
          paymentStatus: 'UNPAID',
          paymentMethod,
          specialRequests: specialRequests || null,
          priceSnapshot: snapshot,
          confirmedAt: now,
        },
        include: { guest: true, roomType: true },
      })

      // 6) الدفع — الخادم وحده يقرر نتيجة "بوابة الدفع" (محاكاة)
      if (paymentMethod === 'CARD') {
        const deposit = Math.round(quote.grandTotalCents / 2)
        await tx.payment.create({
          data: {
            reservationId: reservation.id,
            method: 'ONLINE',
            amountCents: deposit,
            status: 'COMPLETED',
            reference: `DEP-${reference}`,
            recordedBy: 'ONLINE',
            note: 'عربون إلكتروني 50% عند الحجز',
          },
        })
        await tx.reservation.update({
          where: { id: reservation.id },
          data: { paidCents: deposit, paymentStatus: 'PARTIALLY_PAID' },
        })
      }

      // 7) التدقيق ×2
      await audit(tx, {
        action: 'RESERVATION_CREATED',
        entityType: 'Reservation',
        entityId: reservation.id,
        actor: 'الموقع',
        actorRole: 'WEBSITE',
        details: {
          reference,
          source: 'WEBSITE',
          roomTypeId: roomType.id,
          roomTypeName: roomType.name,
          nights: quote.nights,
          roomsCount,
          grandTotalCents: quote.grandTotalCents,
          paymentMethod,
        },
      })
      await audit(tx, {
        action: 'RESERVATION_CONFIRMED',
        entityType: 'Reservation',
        entityId: reservation.id,
        actor: 'الموقع',
        actorRole: 'WEBSITE',
        details: {
          reference,
          paymentMethod,
          paymentStatus: paymentMethod === 'CARD' ? 'PARTIALLY_PAID' : 'UNPAID',
          depositCents: paymentMethod === 'CARD' ? Math.round(quote.grandTotalCents / 2) : 0,
        },
      })

      // 8) إشعار الاستقبال
      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          type: 'RESERVATION',
          title: 'حجز جديد من الموقع',
          body: `${guestRow.fullName} — ${roomType.name}، ${formatDateAr(checkIn)}`,
        },
      })

      const finalRow = await tx.reservation.findUnique({
        where: { id: reservation.id },
        include: { guest: true, roomType: true },
      })
      return finalRow ?? reservation
    })

    // بعد نجاح المعاملة: سجّل المفتاح + بث الحدث الفوري (best-effort)
    if (idemKey) {
      idempotencyCache.set(idemKey, { reservationId: created.id, at: Date.now() })
    }
    void emitEvent(wsRooms.reception, WS_EVENTS.RESERVATION_NEW, {
      reference: created.bookingReference,
      guestName: created.guest.fullName,
      roomTypeName: created.roomType.name,
      checkIn: created.checkIn.toISOString(),
    })

    return ok({ reservation: toReservationPublic(created) }, 201)
  } catch (e) {
    if (e instanceof AvailabilityError) {
      return fail(e.message, 409)
    }
    return fail('حدث خطأ أثناء إنشاء الحجز — يرجى المحاولة مرة أخرى', 500)
  }
}

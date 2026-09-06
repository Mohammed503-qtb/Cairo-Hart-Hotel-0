// POST /api/public/availability — بحث التوفر للجمهور
// الخادم هو مصدر الحقيقة للتوفر والسعر دائمًا
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { availableRoomCount, validateStayDates, BLOCKING_RESERVATION_STATUSES } from '@/lib/availability'
import { computeQuote } from '@/lib/pricing'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import { inputToDate, toRoomTypePublic, digitsOnly, lastNDigits } from '../_lib'
import type { AvailabilityItem } from '@/types'

export const dynamic = 'force-dynamic'

interface AvailabilityBody {
  checkIn?: unknown
  checkOut?: unknown
  adults?: unknown
  children?: unknown
  roomsCount?: unknown
  // اختياري (امتداد المسار C): مرجع + هاتف حجز قائم — يستثني حجزه من
  // عدّ المحجوز لمعاينة دقيقة أثناء «تعديل الحجز». فشل التحقق يُتجاهل
  // بصمت (بلا كشف وجود) وتُرجَع النتائج العامة كالمعتاد.
  reference?: unknown
  phone?: unknown
}

export async function POST(req: Request) {
  // حماية: 20 طلب/دقيقة لكل IP
  const ip = clientIp(req)
  const rl = rateLimit(`avail:${ip}`, 20, 60_000)
  if (!rl.allowed) {
    return fail(`طلبات كثيرة جدًا — يرجى المحاولة مجددًا بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  const body = await readBody<AvailabilityBody>(req)
  if (!body) return fail('طلب غير صالح', 400)

  const checkIn = inputToDate(body.checkIn)
  const checkOut = inputToDate(body.checkOut)
  if (!checkIn || !checkOut) {
    return fail('يرجى إدخال تاريخي الوصول والمغادرة بشكل صحيح', 400)
  }

  const adults = Number(body.adults ?? 1)
  const children = Number(body.children ?? 0)
  const roomsCount = Number(body.roomsCount ?? 1)
  if (!Number.isInteger(adults) || adults < 1 || adults > 10) {
    return fail('عدد البالغين غير صالح', 400)
  }
  if (!Number.isInteger(children) || children < 0 || children > 10) {
    return fail('عدد الأطفال غير صالح', 400)
  }
  if (!Number.isInteger(roomsCount) || roomsCount < 1 || roomsCount > 3) {
    return fail('عدد الغرف يجب أن يكون بين 1 و 3', 400)
  }

  try {
    const hotel = await db.hotel.findFirst()
    if (!hotel) return fail('معلومات الفندق غير متاحة حاليًا', 503)

    // استثناء ذاتي اختياري: حجز مؤكد قيد التعديل (غرفه تُحرّر للمعاينة)
    let excludeReservationId: string | undefined
    const refRaw = String(body.reference ?? '').trim().toUpperCase()
    const phoneRaw = String(body.phone ?? '').trim()
    if (refRaw && digitsOnly(phoneRaw).length >= 9) {
      const own = await db.reservation.findUnique({
        where: { bookingReference: refRaw },
        select: { id: true, status: true, guest: { select: { phone: true } } },
      })
      if (
        own &&
        BLOCKING_RESERVATION_STATUSES.includes(own.status) &&
        lastNDigits(own.guest.phone) === lastNDigits(phoneRaw)
      ) {
        excludeReservationId = own.id
      }
    }

    const v = validateStayDates(checkIn, checkOut, {
      minStayNights: hotel.minStayNights,
      maxStayNights: hotel.maxStayNights,
      bookingHorizonDays: hotel.bookingHorizonDays,
    })
    if (!v.valid) return fail(v.error ?? 'المواعيد غير صالحة', 400)

    const types = await db.roomType.findMany({
      where: { hotelId: hotel.id, active: true },
      orderBy: { sortOrder: 'asc' },
    })

    const items: AvailabilityItem[] = []
    for (const t of types) {
      // تجاهل الأنواع التي لا تتسع للضيوف
      if (adults > t.capacityAdults * roomsCount) continue
      if (children > t.capacityChildren * roomsCount) continue

      const avail = await availableRoomCount(db, t.id, checkIn, checkOut, { excludeReservationId })
      if (avail < roomsCount) continue

      const rates = await db.rate.findMany({
        where: { roomTypeId: t.id, active: true },
        select: { name: true, startDate: true, endDate: true, priceCents: true },
      })

      const quote = computeQuote({
        checkIn,
        checkOut,
        basePriceCents: t.basePriceCents,
        rates,
        weekendSurchargePercent: hotel.weekendSurchargePercent,
        taxPercent: hotel.taxPercent,
        currency: hotel.currency,
        roomsCount,
      })

      items.push({ roomType: toRoomTypePublic(t), availableCount: avail, quote })
    }

    // ترتيب تصاعدي بالسعر الأساسي
    items.sort((a, b) => a.roomType.basePriceCents - b.roomType.basePriceCents)

    return ok({ items })
  } catch {
    return fail('حدث خطأ أثناء البحث عن الغرف المتاحة — يرجى المحاولة مرة أخرى', 500)
  }
}

// POST /api/public/availability — بحث التوفر للجمهور
// الخادم هو مصدر الحقيقة للتوفر والسعر دائمًا
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { availableRoomCount, validateStayDates } from '@/lib/availability'
import { computeQuote } from '@/lib/pricing'
import { rateLimit, clientIp } from '@/lib/rate-limit'
import { inputToDate, toRoomTypePublic } from '../_lib'
import type { AvailabilityItem } from '@/types'

export const dynamic = 'force-dynamic'

interface AvailabilityBody {
  checkIn?: unknown
  checkOut?: unknown
  adults?: unknown
  children?: unknown
  roomsCount?: unknown
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

      const avail = await availableRoomCount(db, t.id, checkIn, checkOut)
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

// ─────────────────────────────────────────────────────────────
// GET /api/guest/stay — تفاصيل الإقامة الكاملة
// بيانات الحجز + لقطة السعر + سياسات الفندق كاملة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'
import { loadStay, serializeStay, loadHotel, hotelBrief, nightsBetweenDays, parseSnapshot } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const stay = await loadStay(stayId)
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const hotel = await loadHotel()

    const snapshot = parseSnapshot(stay.reservation.priceSnapshot)
    const today = new Date()

    return ok({
      stay: serializeStay(stay),
      snapshot: snapshot
        ? {
            roomTypeName: snapshot.roomTypeName ?? stay.room.roomType.name,
            nightly: snapshot.nightly,
            subtotalCents: snapshot.subtotalCents,
            taxCents: snapshot.taxCents,
            grandTotalCents: snapshot.grandTotalCents,
            currency: snapshot.currency,
            taxPercent: snapshot.taxPercent,
            roomsCount: snapshot.roomsCount,
            cancellationPolicy: snapshot.cancellationPolicy ?? '',
            checkInTime: snapshot.checkInTime ?? hotel?.checkInTime ?? '14:00',
            checkOutTime: snapshot.checkOutTime ?? hotel?.checkOutTime ?? '12:00',
            bookedAt: snapshot.bookedAt ?? null,
          }
        : null,
      nights: nightsBetweenDays(stay.reservation.checkIn, stay.reservation.checkOut),
      remainingNights: Math.max(0, nightsBetweenDays(today, stay.expectedCheckOutAt)),
      hotel: hotel
        ? {
            ...hotelBrief(hotel),
            address: hotel.address,
            city: hotel.city,
            email: hotel.email,
            cancellationPolicy: hotel.cancellationPolicy,
            paymentPolicy: hotel.paymentPolicy,
            childrenPolicy: hotel.childrenPolicy,
            petsPolicy: hotel.petsPolicy,
            smokingPolicy: hotel.smokingPolicy,
          }
        : null,
    })
  } catch (e) {
    console.error('guest stay failed', e)
    return fail('حدث خطأ أثناء تحميل تفاصيل الإقامة — أعد المحاولة', 500)
  }
}

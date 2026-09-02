// ─────────────────────────────────────────────────────────────
// AVAILABILITY ENGINE — محرك التوفر (يعاد فحصه داخل معاملة)
// المخزون = غرف النوع الفعالة − الحجوزات المحجوزة المتداخلة
// ─────────────────────────────────────────────────────────────
import { Prisma, PrismaClient } from '@prisma/client'

type Tx = Prisma.TransactionClient | PrismaClient

/** الحالات التي تحجز مخزونًا */
export const BLOCKING_RESERVATION_STATUSES = ['PENDING', 'CONFIRMED', 'CHECKED_IN']

export function staysOverlap(aStart: Date, aEnd: Date, bStart: Date, bEnd: Date): boolean {
  return new Date(aStart) < new Date(bEnd) && new Date(aEnd) > new Date(bStart)
}

/** عدد الغرف المتاحة لنوع غرفة في نطاق تاريخي — يُستدعى دائمًا من الخادم */
export async function availableRoomCount(
  tx: Tx,
  roomTypeId: string,
  checkIn: Date,
  checkOut: Date
): Promise<number> {
  const total = await tx.room.count({
    where: { roomTypeId, status: { not: 'OUT_OF_ORDER' } },
  })
  const agg = await tx.reservation.aggregate({
    _sum: { roomsCount: true },
    where: {
      roomTypeId,
      status: { in: BLOCKING_RESERVATION_STATUSES },
      checkIn: { lt: new Date(checkOut) },
      checkOut: { gt: new Date(checkIn) },
    },
  })
  const booked = agg._sum.roomsCount ?? 0
  return Math.max(0, total - booked)
}

/** التحقق من صلاحية التواريخ وفق إعدادات الفندق */
export function validateStayDates(
  checkIn: Date,
  checkOut: Date,
  opts: { minStayNights: number; maxStayNights: number; bookingHorizonDays: number }
): { valid: boolean; error?: string } {
  const ci = new Date(checkIn); ci.setHours(0, 0, 0, 0)
  const co = new Date(checkOut); co.setHours(0, 0, 0, 0)
  const today = new Date(); today.setHours(0, 0, 0, 0)
  if (co <= ci) return { valid: false, error: 'تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول' }
  if (ci < today) return { valid: false, error: 'لا يمكن الحجز لتاريخٍ في الماضي' }
  const nights = Math.round((co.getTime() - ci.getTime()) / 86_400_000)
  if (nights < opts.minStayNights) return { valid: false, error: `الحد الأدنى للإقامة ${opts.minStayNights} ليلة` }
  if (nights > opts.maxStayNights) return { valid: false, error: `الحد الأقصى للإقامة ${opts.maxStayNights} ليلة` }
  const horizon = new Date(today); horizon.setDate(horizon.getDate() + opts.bookingHorizonDays)
  if (ci > horizon) return { valid: false, error: `الحجز متاح حتى ${opts.bookingHorizonDays} يومًا من اليوم فقط` }
  return { valid: true }
}

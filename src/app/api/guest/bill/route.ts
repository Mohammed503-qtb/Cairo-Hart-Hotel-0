// ─────────────────────────────────────────────────────────────
// GET /api/guest/bill — فاتورة إقامة الضيف (BillPublic)
// إقامة الغرفة من الحجز + البنود الإضافية + المدفوعات + الرصيد
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'
import { nightsBetweenDays } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const stay = await db.stay.findUnique({
      where: { id: stayId },
      include: {
        reservation: true,
        room: { select: { number: true } },
        charges: { orderBy: { createdAt: 'asc' } },
      },
    })
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const payments = await db.payment.findMany({
      where: { reservationId: stay.reservationId },
      orderBy: { createdAt: 'asc' },
    })

    const extraTotalCents = stay.charges.reduce((a, c) => a + c.amountCents, 0)
    const roomTotalCents = stay.reservation.grandTotalCents
    const totalChargesCents = roomTotalCents + extraTotalCents
    const totalPaidCents = stay.reservation.paidCents
    const nights = nightsBetweenDays(stay.reservation.checkIn, stay.reservation.checkOut)

    return ok({
      bill: {
        stayId: stay.id,
        stayReference: stay.reference,
        roomNumber: stay.room.number,
        roomNights: nights,
        roomTotalCents,
        roomSubtotalCents: stay.reservation.subtotalCents,
        roomTaxCents: stay.reservation.taxCents,
        extraCharges: stay.charges.map((c) => ({
          id: c.id,
          description: c.description,
          amountCents: c.amountCents,
          category: c.category,
          date: c.createdAt.toISOString(),
        })),
        extraTotalCents,
        payments: payments.map((p) => ({
          id: p.id,
          method: p.method,
          amountCents: p.amountCents,
          createdAt: p.createdAt.toISOString(),
          recordedBy: p.recordedBy,
        })),
        totalChargesCents,
        totalPaidCents,
        balanceCents: totalChargesCents - totalPaidCents,
        currency: stay.reservation.currency,
      },
    })
  } catch (e) {
    console.error('guest bill failed', e)
    return fail('حدث خطأ أثناء تحميل الفاتورة — أعد المحاولة', 500)
  }
}

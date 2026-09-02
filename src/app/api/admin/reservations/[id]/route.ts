// ─────────────────────────────────────────────────────────────
// GET /api/admin/reservations/[id] — تفاصيل حجز كاملة
// priceSnapshot parse (الليالي/الأسعار/السياسة وقت الحجز) + المدفوعات + الإقامة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { parseJsonObject } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { id } = await ctx.params

  const r = await db.reservation.findUnique({
    where: { id },
    include: {
      guest: true,
      roomType: { select: { id: true, name: true, nameEn: true, basePriceCents: true } },
      payments: { orderBy: { createdAt: 'desc' } },
      stay: { include: { room: { select: { number: true, floor: true } } } },
    },
  })
  if (!r) return fail('الحجز غير موجود', 404)

  return ok({
    reservation: {
      id: r.id,
      reference: r.bookingReference,
      status: r.status,
      source: r.source,
      checkIn: r.checkIn,
      checkOut: r.checkOut,
      nights: Math.max(0, Math.round((r.checkOut.getTime() - r.checkIn.getTime()) / 86_400_000)),
      adults: r.adults,
      children: r.children,
      roomsCount: r.roomsCount,
      currency: r.currency,
      subtotalCents: r.subtotalCents,
      discountCents: r.discountCents,
      taxCents: r.taxCents,
      grandTotalCents: r.grandTotalCents,
      paidCents: r.paidCents,
      paymentStatus: r.paymentStatus,
      paymentMethod: r.paymentMethod,
      specialRequests: r.specialRequests,
      createdAt: r.createdAt,
      confirmedAt: r.confirmedAt,
      cancelledAt: r.cancelledAt,
      guest: {
        id: r.guest.id,
        fullName: r.guest.fullName,
        phone: r.guest.phone,
        email: r.guest.email,
        nationality: r.guest.nationality,
      },
      roomType: r.roomType,
      payments: r.payments.map((p) => ({
        id: p.id,
        method: p.method,
        amountCents: p.amountCents,
        status: p.status,
        reference: p.reference,
        note: p.note,
        recordedBy: p.recordedBy,
        createdAt: p.createdAt,
      })),
      stay: r.stay
        ? {
            id: r.stay.id,
            reference: r.stay.reference,
            status: r.stay.status,
            checkInAt: r.stay.checkInAt,
            expectedCheckOutAt: r.stay.expectedCheckOutAt,
            actualCheckOutAt: r.stay.actualCheckOutAt,
            roomNumber: r.stay.room.number,
          }
        : null,
      priceSnapshot: parseJsonObject(r.priceSnapshot),
    },
  })
}

// ─────────────────────────────────────────────────────────────
// GET /api/reception/arrivals?date=YYYY-MM-DD — وصولو اليوم (افتراضيًا اليوم)
// حجوزات CONFIRMED/PENDING بتاريخ وصول اليوم المطلوب
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { startOfDay, endOfDay, parseDateParam } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const date = parseDateParam(req.nextUrl.searchParams.get('date')) ?? startOfDay(new Date())
  const dayStart = startOfDay(date)
  const dayEnd = endOfDay(date)

  const reservations = await db.reservation.findMany({
    where: {
      checkIn: { gte: dayStart, lte: dayEnd },
      status: { in: ['CONFIRMED', 'PENDING'] },
    },
    include: {
      guest: true,
      roomType: true,
      stay: { select: { id: true } },
    },
    orderBy: { createdAt: 'asc' },
  })

  return ok({
    date: dayStart.toISOString(),
    arrivals: reservations.map((r) => ({
      id: r.id,
      bookingReference: r.bookingReference,
      status: r.status,
      source: r.source,
      checkIn: r.checkIn.toISOString(),
      checkOut: r.checkOut.toISOString(),
      nights: Math.max(1, Math.round((startOfDay(r.checkOut).getTime() - startOfDay(r.checkIn).getTime()) / 86_400_000)),
      adults: r.adults,
      children: r.children,
      roomsCount: r.roomsCount,
      currency: r.currency,
      subtotalCents: r.subtotalCents,
      taxCents: r.taxCents,
      grandTotalCents: r.grandTotalCents,
      paidCents: r.paidCents,
      paymentStatus: r.paymentStatus,
      paymentMethod: r.paymentMethod,
      specialRequests: r.specialRequests,
      createdAt: r.createdAt.toISOString(),
      hasStay: Boolean(r.stay),
      guest: {
        id: r.guest.id,
        fullName: r.guest.fullName,
        phone: r.guest.phone,
        whatsapp: r.guest.whatsapp,
        email: r.guest.email,
        idNumber: r.guest.idNumber,
        nationality: r.guest.nationality,
      },
      roomType: {
        id: r.roomType.id,
        name: r.roomType.name,
        basePriceCents: r.roomType.basePriceCents,
        capacityAdults: r.roomType.capacityAdults,
        capacityChildren: r.roomType.capacityChildren,
        bedConfig: r.roomType.bedConfig,
        sizeSqm: r.roomType.sizeSqm,
      },
    })),
  })
}

// ─────────────────────────────────────────────────────────────
// GET /api/reception/dashboard — إحصائيات اليوم + قوائم مختصرة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { startOfDay, endOfDay, chargesTotal, computeBalance } from '../_helpers'

export const dynamic = 'force-dynamic'

const ACTIVE_STAY_STATUSES = ['ACTIVE', 'CHECKOUT_REQUESTED']
const PENDING_REQUEST_STATUSES = ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING']

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const dayStart = startOfDay(new Date())
  const dayEnd = endOfDay(new Date())

  // المغادرون اليوم = مستحقة اليوم + متأخرة (لم تغلق بعد)
  const departureStayWhere = {
    status: { in: ACTIVE_STAY_STATUSES },
    OR: [{ expectedCheckOutAt: { gte: dayStart, lte: dayEnd } }, { expectedCheckOutAt: { lt: dayStart } }],
  }

  const [
    arrivalsCount,
    departures,
    inHouseCount,
    totalRooms,
    occupiedRooms,
    pendingRequests,
  ] = await Promise.all([
    db.reservation.count({
      where: { status: 'CONFIRMED', checkIn: { gte: dayStart, lte: dayEnd } },
    }),
    db.stay.findMany({
      where: departureStayWhere,
      include: {
        guest: true,
        room: true,
        reservation: true,
        charges: true,
      },
      orderBy: { expectedCheckOutAt: 'asc' },
      take: 5,
    }),
    db.stay.count({ where: { status: { in: ACTIVE_STAY_STATUSES } } }),
    db.room.count(),
    db.room.count({ where: { status: 'OCCUPIED' } }),
    db.serviceRequest.findMany({
      where: {
        status: { in: PENDING_REQUEST_STATUSES },
        stay: { status: { in: ACTIVE_STAY_STATUSES } },
      },
      include: { stay: { include: { room: true, guest: true } } },
      orderBy: { createdAt: 'desc' },
      take: 5,
    }),
  ])

  const arrivals = await db.reservation.findMany({
    where: { status: 'CONFIRMED', checkIn: { gte: dayStart, lte: dayEnd } },
    include: { guest: true, roomType: true },
    orderBy: { createdAt: 'asc' },
    take: 5,
  })

  const pendingCount = await db.serviceRequest.count({
    where: {
      status: { in: PENDING_REQUEST_STATUSES },
      stay: { status: { in: ACTIVE_STAY_STATUSES } },
    },
  })
  const urgentCount = await db.serviceRequest.count({
    where: {
      status: { in: PENDING_REQUEST_STATUSES },
      priority: 'URGENT',
      stay: { status: { in: ACTIVE_STAY_STATUSES } },
    },
  })

  const occupancyPercent = totalRooms > 0 ? Math.round((occupiedRooms / totalRooms) * 100) : 0

  return ok({
    stats: {
      arrivalsToday: arrivalsCount,
      departuresToday: departures.length,
      inHouseStays: inHouseCount,
      pendingRequests: pendingCount,
      urgentRequests: urgentCount,
      occupancyPercent,
      totalRooms,
      occupiedRooms,
    },
    arrivals: arrivals.map((r) => ({
      reservationId: r.id,
      bookingReference: r.bookingReference,
      guestName: r.guest.fullName,
      guestPhone: r.guest.phone,
      roomTypeId: r.roomTypeId,
      roomTypeName: r.roomType.name,
      nights: Math.max(1, Math.round((startOfDay(r.checkOut).getTime() - startOfDay(r.checkIn).getTime()) / 86_400_000)),
      paidCents: r.paidCents,
      grandTotalCents: r.grandTotalCents,
      paymentStatus: r.paymentStatus,
      checkIn: r.checkIn.toISOString(),
      checkOut: r.checkOut.toISOString(),
    })),
    departures: departures.map((s) => ({
      stayId: s.id,
      reference: s.reference,
      guestName: s.guest.fullName,
      roomNumber: s.room.number,
      balanceCents: computeBalance(s.reservation, chargesTotal(s.charges)),
      status: s.status,
      expectedCheckOutAt: s.expectedCheckOutAt.toISOString(),
    })),
    pendingRequests: pendingRequests.map((r) => ({
      id: r.id,
      reference: r.reference,
      roomNumber: r.stay?.room?.number ?? '—',
      guestName: r.stay?.guest?.fullName ?? '—',
      title: r.title,
      priority: r.priority,
      status: r.status,
      createdAt: r.createdAt.toISOString(),
    })),
  })
}

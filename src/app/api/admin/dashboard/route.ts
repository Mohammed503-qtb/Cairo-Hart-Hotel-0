// ─────────────────────────────────────────────────────────────
// GET /api/admin/dashboard — لوحة تحكم الإدارة (KPIs + رسوم + تنبيهات)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { dayKey, startOfDay, endOfDay, ACTIVE_REQUEST_STATUSES } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const now = new Date()
  const todayStart = startOfDay(now)
  const todayEnd = endOfDay(now)
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
  const day14Start = startOfDay(new Date(now.getTime() - 13 * 86_400_000))

  const [
    rooms,
    activeStays,
    arrivalsToday,
    pendingRequests,
    urgentRequests,
    staleRequests,
    revenueMonth,
    activeGuestCodes,
    activeStaffCodes,
    recentBookings,
    payments,
  ] = await Promise.all([
    db.room.findMany({ select: { id: true, status: true } }),
    db.stay.findMany({
      where: { status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] } },
      include: { reservation: { select: { adults: true, children: true } } },
    }),
    db.reservation.count({
      where: { checkIn: { gte: todayStart, lte: todayEnd }, status: { in: ['PENDING', 'CONFIRMED', 'CHECKED_IN'] } },
    }),
    db.serviceRequest.count({ where: { status: { in: [...ACTIVE_REQUEST_STATUSES] } } }),
    db.serviceRequest.count({ where: { status: { in: [...ACTIVE_REQUEST_STATUSES] }, priority: 'URGENT' } }),
    db.serviceRequest.count({
      where: { status: { in: [...ACTIVE_REQUEST_STATUSES] }, createdAt: { lt: new Date(now.getTime() - 30 * 60_000) } },
    }),
    db.payment.aggregate({ _sum: { amountCents: true }, where: { status: 'COMPLETED', createdAt: { gte: monthStart } } }),
    db.accessCode.count({ where: { type: 'GUEST', status: 'ACTIVE', expiresAt: { gt: now } } }),
    db.accessCode.count({ where: { type: { in: ['RECEPTION', 'ADMIN'] }, status: 'ACTIVE', expiresAt: { gt: now } } }),
    db.reservation.findMany({
      orderBy: { createdAt: 'desc' },
      take: 6,
      include: {
        guest: { select: { fullName: true } },
        roomType: { select: { name: true } },
      },
    }),
    db.payment.findMany({
      where: { status: 'COMPLETED', createdAt: { gte: day14Start } },
      select: { amountCents: true, createdAt: true },
    }),
  ])

  // حالة الغرف
  const roomsByStatus: Record<string, number> = {
    AVAILABLE: 0, OCCUPIED: 0, RESERVED: 0, CLEANING: 0, DIRTY: 0, OUT_OF_ORDER: 0,
  }
  let occupiedRooms = 0
  let outOfOrderRooms = 0
  for (const r of rooms) {
    if (r.status in roomsByStatus) roomsByStatus[r.status]++
    if (r.status === 'OCCUPIED') occupiedRooms++
    if (r.status === 'OUT_OF_ORDER') outOfOrderRooms++
  }
  const totalRooms = rooms.length
  const availableRooms = roomsByStatus.AVAILABLE

  // المقيمون
  const inHouseStays = activeStays.length
  const inHouseGuests = activeStays.reduce((a, s) => a + (s.reservation?.adults ?? 0) + (s.reservation?.children ?? 0), 0)
  const departuresToday = activeStays.filter((s) => s.expectedCheckOutAt >= todayStart && s.expectedCheckOutAt <= todayEnd).length

  // الإيراد اليومي — آخر 14 يومًا
  const byDay = new Map<string, number>()
  for (let i = 13; i >= 0; i--) {
    const d = startOfDay(new Date(now.getTime() - i * 86_400_000))
    byDay.set(dayKey(d), 0)
  }
  for (const p of payments) {
    const k = dayKey(p.createdAt)
    if (byDay.has(k)) byDay.set(k, (byDay.get(k) ?? 0) + p.amountCents)
  }
  const revenueByDay = Array.from(byDay.entries()).map(([date, totalCents]) => ({ date, totalCents }))

  return ok({
    kpis: {
      arrivalsToday,
      departuresToday,
      inHouseStays,
      inHouseGuests,
      pendingRequests,
      urgentRequests,
      occupancyPercent: totalRooms > 0 ? Math.round((occupiedRooms / totalRooms) * 100) : 0,
      totalRooms,
      occupiedRooms,
      availableRooms,
      outOfOrderRooms,
      revenueMonthCents: revenueMonth._sum.amountCents ?? 0,
      activeGuestCodes,
      activeStaffCodes,
    },
    recentBookings: recentBookings.map((b) => ({
      id: b.id,
      reference: b.bookingReference,
      guestName: b.guest.fullName,
      roomTypeName: b.roomType.name,
      grandTotalCents: b.grandTotalCents,
      status: b.status,
      createdAt: b.createdAt,
    })),
    roomsByStatus,
    alerts: { staleRequests, outOfOrderRooms },
    revenueByDay,
  })
}

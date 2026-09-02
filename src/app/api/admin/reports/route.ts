// ─────────────────────────────────────────────────────────────
// GET /api/admin/reports — تقارير الإدارة
// الإشغال 14 يومًا + الإيراد 6 أشهر + إحصاءات الطلبات + الجنسيات
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { startOfDay, dayKey } from '../_shared'

export const dynamic = 'force-dynamic'

const AR_MONTHS_SHORT = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const now = new Date()

  // ── الإشغال آخر 14 يومًا ──
  const [rooms, reservations] = await Promise.all([
    db.room.findMany({ select: { status: true } }),
    db.reservation.findMany({
      where: { status: { in: ['CONFIRMED', 'CHECKED_IN'] } },
      select: { checkIn: true, checkOut: true },
    }),
  ])
  const effectiveRooms = rooms.filter((r) => r.status !== 'OUT_OF_ORDER').length

  // احسب الحجوزات المتداخلة فقط (stay تتبع حجز CHECKED_IN — لا ازدواج)
  const resDays = reservations.map((r) => ({
    in: dayKey(r.checkIn),
    out: dayKey(r.checkOut),
  }))
  const occupancyLast14Days: Array<{ date: string; label: string; percent: number; occupied: number }> = []
  for (let i = 13; i >= 0; i--) {
    const d = startOfDay(new Date(now.getTime() - i * 86_400_000))
    const key = dayKey(d)
    const nextKey = dayKey(new Date(d.getTime() + 86_400_000))
    // الليلة محجوزة إذا checkInDay <= اليوم && اليوم < checkOutDay
    const occupied = resDays.filter((r) => r.in <= key && key < r.out).length
    occupancyLast14Days.push({
      date: key,
      label: `${d.getDate()} ${AR_MONTHS_SHORT[d.getMonth()]}`,
      occupied,
      percent: effectiveRooms > 0 ? Math.round((occupied / effectiveRooms) * 100) : 0,
    })
  }

  // ── الإيراد آخر 6 أشهر ──
  const monthStarts: Date[] = []
  for (let i = 5; i >= 0; i--) {
    monthStarts.push(new Date(now.getFullYear(), now.getMonth() - i, 1))
  }
  const payments = await db.payment.findMany({
    where: { status: 'COMPLETED', createdAt: { gte: monthStarts[0] } },
    select: { amountCents: true, createdAt: true },
  })
  const revenueByMonth = monthStarts.map((m) => {
    const next = new Date(m.getFullYear(), m.getMonth() + 1, 1)
    const totalCents = payments
      .filter((p) => p.createdAt >= m && p.createdAt < next)
      .reduce((a, p) => a + p.amountCents, 0)
    return {
      month: `${AR_MONTHS_SHORT[m.getMonth()]} ${m.getFullYear() !== now.getFullYear() ? m.getFullYear() : ''}`.trim(),
      totalCents,
      count: payments.filter((p) => p.createdAt >= m && p.createdAt < next).length,
    }
  })

  // ── إحصاءات الطلبات ──
  const [requestsTotal, byStatusRaw, completedRequests, topServicesRaw, guestsByNationalityRaw] = await Promise.all([
    db.serviceRequest.count(),
    db.serviceRequest.groupBy({ by: ['status'], _count: { _all: true } }),
    db.serviceRequest.findMany({
      where: { status: 'COMPLETED', completedAt: { not: null } },
      select: { createdAt: true, completedAt: true },
    }),
    db.serviceRequest.groupBy({
      by: ['title'],
      _count: { _all: true },
      orderBy: { _count: { title: 'desc' } },
      take: 6,
    }),
    db.guest.groupBy({
      by: ['nationality'],
      _count: { _all: true },
      orderBy: { _count: { nationality: 'desc' } },
      take: 5,
    }),
  ])

  const avgCompletionMinutes =
    completedRequests.length > 0
      ? Math.max(
          0,
          Math.round(
            completedRequests.reduce(
              (a, r) => a + Math.max(0, (r.completedAt!.getTime() - r.createdAt.getTime()) / 60_000),
              0
            ) / completedRequests.length
          )
        )
      : null

  const requestsStats = {
    total: requestsTotal,
    byStatus: byStatusRaw.map((s) => ({ status: s.status, count: s._count._all })),
    completed: byStatusRaw.find((s) => s.status === 'COMPLETED')?._count._all ?? 0,
    active: byStatusRaw
      .filter((s) => ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING'].includes(s.status))
      .reduce((a, s) => a + s._count._all, 0),
    avgCompletionMinutes,
    topServices: topServicesRaw.map((s) => ({ title: s.title, count: s._count._all })),
  }

  const guestsByNationality = guestsByNationalityRaw.map((g) => ({
    nationality: g.nationality ?? 'غير محدد',
    count: g._count._all,
  }))

  return ok({
    effectiveRooms,
    occupancyLast14Days,
    revenueByMonth,
    requestsStats,
    guestsByNationality,
  })
}

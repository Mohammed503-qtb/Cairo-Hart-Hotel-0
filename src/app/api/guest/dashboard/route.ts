// ─────────────────────────────────────────────────────────────
// GET /api/guest/dashboard — لوحة الضيف
// الإقامة + آخر 5 إشعارات + الطلبات النشطة + الرصيد + الفندق
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'
import { loadStay, serializeStay, computeStayBalance, loadHotel, hotelBrief, nightsBetweenDays } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const stay = await loadStay(stayId)
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const [notifications, activeRequests, balance, hotel] = await Promise.all([
      db.notification.findMany({
        where: { audience: 'GUEST', stayId },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
      db.serviceRequest.count({
        where: {
          stayId,
          status: { notIn: ['COMPLETED', 'CANCELLED', 'REJECTED'] },
        },
      }),
      computeStayBalance(stay),
      loadHotel(),
    ])

    const serialized = serializeStay(stay)
    const today = new Date()
    const remainingNights = Math.max(
      0,
      nightsBetweenDays(today, stay.expectedCheckOutAt)
    )

    return ok({
      stay: {
        ...serialized,
        totalNights: nightsBetweenDays(stay.checkInAt, stay.expectedCheckOutAt),
        remainingNights,
      },
      notifications: notifications.map((n) => ({
        id: n.id,
        audience: n.audience,
        type: n.type,
        title: n.title,
        body: n.body,
        read: n.read,
        createdAt: n.createdAt.toISOString(),
      })),
      unreadCount: notifications.filter((n) => !n.read).length,
      activeRequests,
      balanceCents: balance.balanceCents,
      chargesCents: balance.chargesCents,
      currency: balance.currency,
      hotel: hotelBrief(hotel),
    })
  } catch (e) {
    console.error('guest dashboard failed', e)
    return fail('حدث خطأ أثناء تحميل لوحة الضيف — أعد المحاولة', 500)
  }
}

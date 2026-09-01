// ─────────────────────────────────────────────────────────────
// GET /api/guest/notifications — إشعارات الضيف (الأحدث أولًا) + غير المقروء
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const notifications = await db.notification.findMany({
      where: { audience: 'GUEST', stayId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    })

    return ok({
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
    })
  } catch (e) {
    console.error('guest notifications failed', e)
    return fail('حدث خطأ أثناء تحميل الإشعارات — أعد المحاولة', 500)
  }
}

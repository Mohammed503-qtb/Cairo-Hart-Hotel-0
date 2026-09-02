// ─────────────────────────────────────────────────────────────
// GET /api/reception/notifications — إشعارات الاستقبال (30 الأحدث)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const [notifications, unreadCount] = await Promise.all([
    db.notification.findMany({
      where: { audience: 'RECEPTION' },
      orderBy: { createdAt: 'desc' },
      take: 30,
    }),
    db.notification.count({ where: { audience: 'RECEPTION', read: false } }),
  ])

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
    unreadCount,
  })
}

// ─────────────────────────────────────────────────────────────
// GET /api/admin/notifications — إشعارات التشغيل للجرس (للإدارة)
// آخر 30 إشعارًا بجمهور ADMIN أو RECEPTION (إشراف تشغيلي)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const notifications = await db.notification.findMany({
    where: { audience: { in: ['ADMIN', 'RECEPTION'] } },
    orderBy: { createdAt: 'desc' },
    take: 30,
  })

  return ok({
    notifications: notifications.map((n) => ({
      id: n.id,
      audience: n.audience,
      type: n.type,
      title: n.title,
      body: n.body,
      read: n.read,
      createdAt: n.createdAt,
    })),
    unreadCount: notifications.filter((n) => !n.read).length,
  })
}

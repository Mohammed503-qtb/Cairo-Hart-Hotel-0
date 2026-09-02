// ─────────────────────────────────────────────────────────────
// POST /api/reception/notifications/read — تحديد الإشعارات كمقروءة
// Body: { ids?: string[] } — بدونه تُعلَّم كلها
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const body = await readBody<{ ids?: string[] }>(req)
  const ids = Array.isArray(body?.ids) ? body!.ids.filter((x) => typeof x === 'string') : null

  const result = await db.notification.updateMany({
    where: {
      audience: 'RECEPTION',
      read: false,
      ...(ids && ids.length > 0 ? { id: { in: ids } } : {}),
    },
    data: { read: true },
  })

  return ok({ updated: result.count })
}

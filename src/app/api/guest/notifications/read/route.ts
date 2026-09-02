// ─────────────────────────────────────────────────────────────
// POST /api/guest/notifications/read — تعليم كل إشعارات الضيف كمقروءة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../../_lib'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const result = await db.notification.updateMany({
      where: { audience: 'GUEST', stayId, read: false },
      data: { read: true },
    })

    return ok({ updated: result.count })
  } catch (e) {
    console.error('guest notifications read failed', e)
    return fail('حدث خطأ أثناء تحديث الإشعارات — أعد المحاولة', 500)
  }
}

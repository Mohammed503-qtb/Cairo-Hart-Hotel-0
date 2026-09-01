// ─────────────────────────────────────────────────────────────
// DELETE /api/admin/rates/[id] — حذف معدل موسمي
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'

export const dynamic = 'force-dynamic'

export async function DELETE(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const rate = await db.rate.findUnique({ where: { id }, include: { roomType: { select: { name: true } } } })
  if (!rate) return fail('المعدل غير موجود', 404)

  await db.rate.delete({ where: { id } })
  await audit(db, {
    action: 'RATE_CHANGED',
    entityType: 'Rate',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'DELETE', name: rate.name, roomTypeName: rate.roomType.name },
  })

  return ok({ deleted: true, message: `تم حذف المعدل «${rate.name}»` })
}

// ─────────────────────────────────────────────────────────────
// GET /api/admin/audit?action=&q=&page= — سجل التدقيق (30/صفحة)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { Prisma } from '@prisma/client'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { searchParams } = new URL(req.url)
  const action = searchParams.get('action') ?? ''
  const q = (searchParams.get('q') ?? '').trim()
  const page = Math.max(1, parseInt(searchParams.get('page') ?? '1', 10) || 1)
  const limit = 30

  const where: Prisma.AuditLogWhereInput = {}
  if (action) where.action = action
  if (q) {
    where.OR = [
      { actor: { contains: q } },
      { entityType: { contains: q } },
      { entityId: { contains: q } },
    ]
  }

  const [total, logs] = await Promise.all([
    db.auditLog.count({ where }),
    db.auditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
  ])

  return ok({
    items: logs.map((l) => ({
      id: l.id,
      action: l.action,
      entityType: l.entityType,
      entityId: l.entityId,
      actor: l.actor,
      actorRole: l.actorRole,
      details: l.details,
      createdAt: l.createdAt,
    })),
    total,
    page,
    limit,
    pages: Math.max(1, Math.ceil(total / limit)),
  })
}

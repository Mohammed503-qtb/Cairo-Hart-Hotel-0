// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/service-categories — أقسام الخدمات
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt, SERVICE_CATEGORY_KEYS } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const categories = await db.serviceCategory.findMany({
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    include: { _count: { select: { services: true } } },
  })

  return ok({
    categories: categories.map((c) => ({
      id: c.id,
      name: c.name,
      nameEn: c.nameEn,
      key: c.key,
      icon: c.icon,
      sortOrder: c.sortOrder,
      servicesCount: c._count.services,
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const name = asString(body.name)?.trim()
  if (!name) return fail('اسم القسم مطلوب')

  const key = asString(body.key)?.trim() ?? 'OTHER'
  if (!(SERVICE_CATEGORY_KEYS as readonly string[]).includes(key)) {
    return fail('مفتاح القسم غير صالح — يجب أن يكون HOUSEKEEPING أو MAINTENANCE أو GUEST_SERVICES أو OTHER')
  }

  const created = await db.serviceCategory.create({
    data: {
      name,
      nameEn: asString(body.nameEn) ?? '',
      key,
      icon: asString(body.icon) ?? '',
      sortOrder: asInt(body.sortOrder) ?? 0,
    },
  })

  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'ServiceCategory',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'CREATE', name, key },
  })

  return ok({
    category: { ...created, servicesCount: 0 },
  }, 201)
}

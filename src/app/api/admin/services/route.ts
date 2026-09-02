// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/services — كتالوج الخدمات
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt, asBool } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const services = await db.service.findMany({
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    include: { category: true },
  })

  return ok({
    services: services.map((s) => ({
      id: s.id,
      name: s.name,
      nameEn: s.nameEn,
      description: s.description,
      priceCents: s.priceCents,
      active: s.active,
      sortOrder: s.sortOrder,
      categoryId: s.categoryId,
      categoryName: s.category.name,
      categoryKey: s.category.key,
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const categoryId = asString(body.categoryId)?.trim()
  if (!categoryId) return fail('القسم مطلوب')
  const category = await db.serviceCategory.findUnique({ where: { id: categoryId } })
  if (!category) return fail('القسم غير موجود', 404)

  const name = asString(body.name)?.trim()
  if (!name) return fail('اسم الخدمة مطلوب')

  const priceCents = asInt(body.priceCents) ?? 0
  if (priceCents < 0) return fail('السعر لا يمكن أن يكون سالبًا')

  const created = await db.service.create({
    data: {
      categoryId,
      name,
      nameEn: asString(body.nameEn) ?? '',
      description: asString(body.description) ?? '',
      priceCents,
      active: asBool(body.active) ?? true,
      sortOrder: asInt(body.sortOrder) ?? 0,
    },
  })

  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'Service',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'CREATE', name, priceCents, categoryName: category.name },
  })

  return ok({
    service: {
      id: created.id,
      name: created.name,
      nameEn: created.nameEn,
      description: created.description,
      priceCents: created.priceCents,
      active: created.active,
      sortOrder: created.sortOrder,
      categoryId: category.id,
      categoryName: category.name,
      categoryKey: category.key,
    },
  }, 201)
}

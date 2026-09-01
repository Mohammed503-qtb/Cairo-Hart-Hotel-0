// ─────────────────────────────────────────────────────────────
// PATCH/DELETE /api/admin/service-categories/[id]
// DELETE: يمنع إذا وُجدت خدمات نشطة أو طلبات مرتبطة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt, SERVICE_CATEGORY_KEYS } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function PATCH(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const category = await db.serviceCategory.findUnique({ where: { id } })
  if (!category) return fail('القسم غير موجود', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | number> = {}
  const changed: string[] = []

  const name = asString(body.name)
  if (name !== undefined) {
    if (name.trim() === '') return fail('اسم القسم لا يمكن أن يكون فارغًا')
    if (name !== category.name) { data.name = name.trim(); changed.push('name') }
  }
  for (const f of ['nameEn', 'icon'] as const) {
    const v = asString(body[f])
    if (v !== undefined && v !== category[f]) { data[f] = v; changed.push(f) }
  }
  const key = asString(body.key)
  if (key !== undefined) {
    if (!(SERVICE_CATEGORY_KEYS as readonly string[]).includes(key)) return fail('مفتاح القسم غير صالح')
    if (key !== category.key) { data.key = key; changed.push('key') }
  }
  const sortOrder = asInt(body.sortOrder)
  if (sortOrder !== undefined && sortOrder !== category.sortOrder) { data.sortOrder = sortOrder; changed.push('sortOrder') }

  if (Object.keys(data).length === 0) return ok({ category })

  const updated = await db.serviceCategory.update({ where: { id }, data })
  const servicesCount = await db.service.count({ where: { categoryId: id } })

  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'ServiceCategory',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'UPDATE', name: updated.name, changed },
  })

  return ok({ category: { ...updated, servicesCount } })
}

export async function DELETE(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const category = await db.serviceCategory.findUnique({ where: { id } })
  if (!category) return fail('القسم غير موجود', 404)

  const activeServices = await db.service.count({ where: { categoryId: id, active: true } })
  if (activeServices > 0) {
    return fail(`لا يمكن حذف القسم «${category.name}» — يحتوي على ${activeServices} خدمة نشطة. عطّل خدماته أولًا`)
  }

  // ServiceRequest غير مرتبط علاقيًا — نتحقق عبر معرّفات خدمات القسم
  const categoryServiceIds = await db.service.findMany({ where: { categoryId: id }, select: { id: true } })
  const servicesWithRequests = await db.serviceRequest.count({
    where: { serviceId: { in: categoryServiceIds.map((s) => s.id) } },
  })
  if (servicesWithRequests > 0) {
    return fail(`لا يمكن حذف القسم «${category.name}» نهائيًا — توجد خدمات مرتبطة بطلبات سابقة. عدّله بدلًا من حذفه`)
  }

  // حذف الخدمات غير المرتبطة (معطلة) ثم القسم
  await db.service.deleteMany({ where: { categoryId: id } })
  await db.serviceCategory.delete({ where: { id } })

  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'ServiceCategory',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'DELETE', name: category.name },
  })

  return ok({ deleted: true, message: `تم حذف القسم «${category.name}» نهائيًا` })
}

// ─────────────────────────────────────────────────────────────
// PATCH/DELETE /api/admin/services/[id]
// DELETE: تعطيل ناعم إذا وُجدت طلبات مرتبطة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asInt, asBool } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function PATCH(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const service = await db.service.findUnique({ where: { id }, include: { category: true } })
  if (!service) return fail('الخدمة غير موجودة', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | number | boolean> = {}
  const changed: string[] = []

  const name = asString(body.name)
  if (name !== undefined) {
    if (name.trim() === '') return fail('اسم الخدمة لا يمكن أن يكون فارغًا')
    if (name !== service.name) { data.name = name.trim(); changed.push('name') }
  }
  for (const f of ['nameEn', 'description'] as const) {
    const v = asString(body[f])
    if (v !== undefined && v !== service[f]) { data[f] = v; changed.push(f) }
  }
  const priceCents = asInt(body.priceCents)
  if (priceCents !== undefined) {
    if (priceCents < 0) return fail('السعر لا يمكن أن يكون سالبًا')
    if (priceCents !== service.priceCents) { data.priceCents = priceCents; changed.push('priceCents') }
  }
  const sortOrder = asInt(body.sortOrder)
  if (sortOrder !== undefined && sortOrder !== service.sortOrder) { data.sortOrder = sortOrder; changed.push('sortOrder') }
  const active = asBool(body.active)
  if (active !== undefined && active !== service.active) { data.active = active; changed.push('active') }

  const categoryId = asString(body.categoryId)
  if (categoryId !== undefined && categoryId !== service.categoryId) {
    const category = await db.serviceCategory.findUnique({ where: { id: categoryId } })
    if (!category) return fail('القسم غير موجود', 404)
    data.categoryId = categoryId
    changed.push('categoryId')
  }

  if (Object.keys(data).length === 0) return ok({ service })

  const updated = await db.service.update({ where: { id }, data })
  const category = await db.serviceCategory.findUnique({ where: { id: updated.categoryId } })

  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'Service',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'UPDATE', name: updated.name, changed },
  })

  return ok({
    service: {
      id: updated.id,
      name: updated.name,
      nameEn: updated.nameEn,
      description: updated.description,
      priceCents: updated.priceCents,
      active: updated.active,
      sortOrder: updated.sortOrder,
      categoryId: updated.categoryId,
      categoryName: category?.name ?? service.category.name,
      categoryKey: category?.key ?? service.category.key,
    },
  })
}

export async function DELETE(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const service = await db.service.findUnique({
    where: { id },
    include: { category: true },
  })
  if (!service) return fail('الخدمة غير موجودة', 404)

  // ServiceRequest لا يرتبط علاقيًا بـ Service (serviceId فقط) — نعدّ عبر الجدول
  const linkedRequests = await db.serviceRequest.count({ where: { serviceId: id } })

  if (linkedRequests > 0) {
    if (service.active) {
      await db.service.update({ where: { id }, data: { active: false } })
    }
    await audit(db, {
      action: 'SERVICE_CATALOG_CHANGED',
      entityType: 'Service',
      entityId: id,
      actor: staffName,
      actorRole: 'ADMIN',
      details: { op: 'DEACTIVATE', name: service.name, reason: 'مرتبطة بطلبات سابقة', requests: linkedRequests },
    })
    return ok({ deactivated: true, message: `تم تعطيل الخدمة «${service.name}» لوجود طلبات مرتبطة بها — يمكن تفعيلها مجددًا في أي وقت` })
  }

  await db.service.delete({ where: { id } })
  await audit(db, {
    action: 'SERVICE_CATALOG_CHANGED',
    entityType: 'Service',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'DELETE', name: service.name },
  })
  return ok({ deleted: true, message: `تم حذف الخدمة «${service.name}» نهائيًا` })
}

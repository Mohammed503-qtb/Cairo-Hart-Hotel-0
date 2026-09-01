// ─────────────────────────────────────────────────────────────
// PATCH/DELETE /api/admin/room-types/[id]
// DELETE: حذف ناعم (تعطيل) إذا وُجدت غرف/حجوزات/معدلات مرتبطة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { parseJsonArray, asString, asInt, asBool } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function PATCH(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const existing = await db.roomType.findUnique({ where: { id } })
  if (!existing) return fail('نوع الغرف غير موجود', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | number | boolean> = {}
  const changed: string[] = []

  const name = asString(body.name)
  if (name !== undefined) {
    if (name.trim() === '') return fail('اسم النوع لا يمكن أن يكون فارغًا')
    if (name !== existing.name) { data.name = name.trim(); changed.push('name') }
  }
  for (const f of ['nameEn', 'description', 'bedConfig'] as const) {
    const v = asString(body[f])
    if (v !== undefined && v !== existing[f]) { data[f] = v; changed.push(f) }
  }
  const capacityAdults = asInt(body.capacityAdults)
  if (capacityAdults !== undefined) {
    if (capacityAdults < 1 || capacityAdults > 8) return fail('عدد البالغين يجب أن يكون بين 1 و 8')
    if (capacityAdults !== existing.capacityAdults) { data.capacityAdults = capacityAdults; changed.push('capacityAdults') }
  }
  const capacityChildren = asInt(body.capacityChildren)
  if (capacityChildren !== undefined) {
    if (capacityChildren < 0 || capacityChildren > 6) return fail('عدد الأطفال يجب أن يكون بين 0 و 6')
    if (capacityChildren !== existing.capacityChildren) { data.capacityChildren = capacityChildren; changed.push('capacityChildren') }
  }
  const sizeSqm = asInt(body.sizeSqm)
  if (sizeSqm !== undefined) {
    if (sizeSqm < 0 || sizeSqm > 500) return fail('المساحة يجب أن تكون بين 0 و 500 م²')
    if (sizeSqm !== existing.sizeSqm) { data.sizeSqm = sizeSqm; changed.push('sizeSqm') }
  }
  const basePriceCents = asInt(body.basePriceCents)
  if (basePriceCents !== undefined) {
    if (basePriceCents <= 0) return fail('السعر الأساسي يجب أن يكون أكبر من صفر')
    if (basePriceCents !== existing.basePriceCents) { data.basePriceCents = basePriceCents; changed.push('basePriceCents') }
  }
  const sortOrder = asInt(body.sortOrder)
  if (sortOrder !== undefined && sortOrder !== existing.sortOrder) { data.sortOrder = sortOrder; changed.push('sortOrder') }
  const active = asBool(body.active)
  if (active !== undefined && active !== existing.active) { data.active = active; changed.push('active') }

  if (Array.isArray(body.amenities)) {
    const amenities = body.amenities.filter((a): a is string => typeof a === 'string')
    const json = JSON.stringify(amenities)
    if (json !== existing.amenities) { data.amenities = json; changed.push('amenities') }
  }
  if (Array.isArray(body.images)) {
    const images = body.images.filter((a): a is string => typeof a === 'string')
    const json = JSON.stringify(images)
    if (json !== existing.images) { data.images = json; changed.push('images') }
  }

  if (Object.keys(data).length === 0) return ok({ roomType: existing })

  const updated = await db.roomType.update({ where: { id }, data })

  await audit(db, {
    action: 'ROOM_TYPE_CHANGED',
    entityType: 'RoomType',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'UPDATE', name: updated.name, changed },
  })

  return ok({ roomType: { ...updated, amenities: parseJsonArray(updated.amenities), images: parseJsonArray(updated.images) } })
}

export async function DELETE(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const existing = await db.roomType.findUnique({
    where: { id },
    include: { _count: { select: { rooms: true, reservations: true, rates: true } } },
  })
  if (!existing) return fail('نوع الغرف غير موجود', 404)

  // حذف ناعم إذا وُجد ارتباط
  if (existing._count.rooms > 0 || existing._count.reservations > 0 || existing._count.rates > 0) {
    if (existing.active) {
      await db.roomType.update({ where: { id }, data: { active: false } })
    }
    await audit(db, {
      action: 'ROOM_TYPE_CHANGED',
      entityType: 'RoomType',
      entityId: id,
      actor: staffName,
      actorRole: 'ADMIN',
      details: { op: 'DEACTIVATE', name: existing.name, reason: 'مرتبط بغرف/حجوزات/معدلات', rooms: existing._count.rooms, reservations: existing._count.reservations },
    })
    return ok({ deactivated: true, message: `تم تعطيل النوع «${existing.name}» لوجود غرف أو حجوزات مرتبطة به` })
  }

  await db.roomType.delete({ where: { id } })
  await audit(db, {
    action: 'ROOM_TYPE_CHANGED',
    entityType: 'RoomType',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'DELETE', name: existing.name },
  })
  return ok({ deleted: true, message: `تم حذف النوع «${existing.name}» نهائيًا` })
}

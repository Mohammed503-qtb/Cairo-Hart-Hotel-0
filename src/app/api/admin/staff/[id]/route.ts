// ─────────────────────────────────────────────────────────────
// PATCH /api/admin/staff/[id]
// تعطيل الموظف يبطل كوده النشط وجلساته فورًا
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, asBool } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function PATCH(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const member = await db.staff.findUnique({ where: { id } })
  if (!member) return fail('الموظف غير موجود', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | boolean | null> = {}
  const changed: string[] = []

  const fullName = asString(body.fullName)
  if (fullName !== undefined) {
    if (fullName.trim() === '') return fail('اسم الموظف لا يمكن أن يكون فارغًا')
    if (fullName !== member.fullName) { data.fullName = fullName.trim(); changed.push('fullName') }
  }
  const phone = asString(body.phone)
  if (phone !== undefined && phone !== (member.phone ?? '')) { data.phone = phone || null; changed.push('phone') }
  const active = asBool(body.active)
  if (active !== undefined && active !== member.active) { data.active = active; changed.push('active') }

  if (Object.keys(data).length === 0) return ok({ staffMember: member })

  const updated = await db.staff.update({ where: { id }, data })

  // تعطيل الموظف → إبطال كوده النشط وجلساته
  if (active === false) {
    const codes = await db.accessCode.findMany({ where: { staffId: id, status: 'ACTIVE' }, select: { id: true } })
    if (codes.length > 0) {
      await db.$transaction([
        db.accessCode.updateMany({ where: { staffId: id, status: 'ACTIVE' }, data: { status: 'REVOKED' } }),
        db.session.updateMany({ where: { accessCodeId: { in: codes.map((c) => c.id) } }, data: { revoked: true } }),
      ])
    }
  }

  const lastCode = await db.accessCode.findFirst({ where: { staffId: id }, orderBy: { createdAt: 'desc' } })

  await audit(db, {
    action: 'STAFF_CHANGED',
    entityType: 'Staff',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'UPDATE', fullName: updated.fullName, changed, codesRevoked: active === false },
  })

  return ok({
    staffMember: {
      ...updated,
      lastCode: lastCode
        ? { codeMasked: lastCode.codeMasked, type: lastCode.type, status: lastCode.status, expiresAt: lastCode.expiresAt }
        : null,
    },
  })
}

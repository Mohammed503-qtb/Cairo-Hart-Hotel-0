// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/staff — الطاقم
// GET: مع أحدث كود وصول لكل موظف (كود فعّال واحد على الأكثر)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { asString, STAFF_ROLES } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const staff = await db.staff.findMany({
    orderBy: { createdAt: 'asc' },
    include: { accessCodes: { orderBy: { createdAt: 'desc' }, take: 1 } },
  })

  return ok({
    staff: staff.map((s) => {
      const last = s.accessCodes[0]
      return {
        id: s.id,
        fullName: s.fullName,
        role: s.role,
        phone: s.phone,
        active: s.active,
        createdAt: s.createdAt,
        lastCode: last
          ? { codeMasked: last.codeMasked, type: last.type, status: last.status, expiresAt: last.expiresAt }
          : null,
      }
    }),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const fullName = asString(body.fullName)?.trim()
  if (!fullName) return fail('اسم الموظف مطلوب')

  const role = asString(body.role)?.trim() ?? 'RECEPTION'
  if (!(STAFF_ROLES as readonly string[]).includes(role)) return fail('الدور غير صالح — استقبال أو إدارة أو مدير')

  const phone = asString(body.phone)?.trim()
  if (phone === '') return fail('رقم الهاتف غير صالح')

  const created = await db.staff.create({ data: { fullName, role, phone: phone || null } })

  await audit(db, {
    action: 'STAFF_CHANGED',
    entityType: 'Staff',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'CREATE', fullName, role },
  })

  return ok({ staffMember: { ...created, lastCode: null } }, 201)
}

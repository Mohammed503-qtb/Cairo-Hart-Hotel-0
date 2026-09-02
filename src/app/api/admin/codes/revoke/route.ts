// ─────────────────────────────────────────────────────────────
// POST /api/admin/codes/revoke — إبطال كود (يشمل أكواد الضيف)
// يبطل الكود + جميع جلساته فورًا
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<{ codeId?: string }>(req)
  const codeId = typeof body?.codeId === 'string' ? body.codeId.trim() : ''
  if (!codeId) return fail('معرّف الكود مطلوب')

  const code = await db.accessCode.findUnique({
    where: { id: codeId },
    include: {
      staff: { select: { fullName: true } },
      stay: { include: { guest: { select: { fullName: true } }, room: { select: { number: true } } } },
    },
  })
  if (!code) return fail('الكود غير موجود', 404)
  if (code.status === 'REVOKED') return fail('هذا الكود ملغى بالفعل')

  const context = code.staff?.fullName
    ?? (code.stay ? `ضيف — ${code.stay.guest.fullName} (غرفة ${code.stay.room.number})` : code.codeMasked)

  await db.$transaction([
    db.accessCode.update({ where: { id: codeId }, data: { status: 'REVOKED' } }),
    db.session.updateMany({ where: { accessCodeId: codeId }, data: { revoked: true } }),
  ])

  await audit(db, {
    action: 'CODE_REVOKED',
    entityType: 'AccessCode',
    entityId: codeId,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { codeMasked: code.codeMasked, type: code.type, context },
  })

  return ok({ revoked: true, message: `تم إبطال كود ${code.codeMasked} (${context}) وإبطال جلساته` })
}

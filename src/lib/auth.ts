// ─────────────────────────────────────────────────────────────
// AUTH — تحقق الجلسات والأدوار (Server-side only)
// الجلسة تُشتق من AccessCode → token. تُفحص صلاحية الكود
// والإقامة مع كل طلب.
// ─────────────────────────────────────────────────────────────
import { db } from '@/lib/db'

export type AuthContext =
  | { role: 'GUEST'; stayId: string; codeId: string; guestName: string }
  | { role: 'RECEPTION'; staffId: string; staffName: string; codeId: string }
  | { role: 'ADMIN'; staffId: string; staffName: string; codeId: string }

export async function getAuth(req: Request): Promise<AuthContext | null> {
  const header = req.headers.get('authorization') ?? ''
  const token = header.replace(/^Bearer\s+/i, '').trim()
  if (!token) return null

  const session = await db.session.findUnique({
    where: { token },
    include: { accessCode: true },
  })
  if (!session || session.revoked || session.expiresAt < new Date()) return null
  if (session.accessCode.status !== 'ACTIVE' || session.accessCode.expiresAt < new Date()) return null

  if (session.role === 'GUEST') {
    if (!session.accessCode.stayId) return null
    const stay = await db.stay.findUnique({
      where: { id: session.accessCode.stayId },
      include: { guest: true },
    })
    if (!stay || stay.status === 'CLOSED') return null
    return { role: 'GUEST', stayId: stay.id, codeId: session.accessCodeId, guestName: stay.guest.fullName }
  }

  if (!session.accessCode.staffId) return null
  const staff = await db.staff.findUnique({ where: { id: session.accessCode.staffId } })
  if (!staff || !staff.active) return null

  return session.role === 'ADMIN'
    ? { role: 'ADMIN', staffId: staff.id, staffName: staff.fullName, codeId: session.accessCodeId }
    : { role: 'RECEPTION', staffId: staff.id, staffName: staff.fullName, codeId: session.accessCodeId }
}

/** مساعد: يتطلب صلاحية محددة وإلا يرجع 401/403 */
export async function requireRole(
  req: Request,
  ...roles: Array<'GUEST' | 'RECEPTION' | 'ADMIN'>
): Promise<{ auth: AuthContext } | { error: string; status: number }> {
  const auth = await getAuth(req)
  if (!auth) return { error: 'جلسة غير صالحة أو منتهية — سجّل الدخول من جديد', status: 401 }
  if (!roles.includes(auth.role)) return { error: 'ليست لديك صلاحية للوصول لهذه البيانات', status: 403 }
  return { auth }
}

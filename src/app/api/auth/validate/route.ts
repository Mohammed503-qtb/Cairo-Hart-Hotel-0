// ─────────────────────────────────────────────────────────────
// POST /api/auth/validate — التحقق من كود الدخول وإنشاء جلسة
// الحماية: rate limit 5/دقيقة + قفل 15 دقيقة بعد 10 محاولات فاشلة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { isValidCodeFormat, normalizeCode, hashCode } from '@/lib/codes'
import { rateLimit, recordFailure, clearFailures, clientIp } from '@/lib/rate-limit'
import { audit } from '@/lib/audit'
import { v4 as uuidv4 } from 'uuid'

export const dynamic = 'force-dynamic'

const SESSION_MAX_HOURS = 12

export async function POST(req: NextRequest) {
  const ip = clientIp(req)

  // 1) حماية من التخمين: 5 محاولات / دقيقة
  const rl = rateLimit(`login:${ip}`, 5, 60_000)
  if (!rl.allowed) {
    return fail(`محاولات كثيرة جدًا. أعد المحاولة بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  const body = await readBody<{ code?: string }>(req)
  const code = typeof body?.code === 'string' ? normalizeCode(body.code) : ''

  if (!code) return fail('أدخل كود الدخول أولًا')
  if (!isValidCodeFormat(code)) {
    await audit(db, {
      action: 'CODE_LOGIN_FAILED',
      entityType: 'AccessCode',
      entityId: 'unknown',
      actor: ip,
      actorRole: 'SYSTEM',
      details: { reason: 'INVALID_FORMAT' },
    })
    return fail('كود غير صالح. تحقق من الكود وأعد المحاولة')
  }

  // 2) البحث بالهاش — الكود الخام لا يُخزَّن أبدًا
  const accessCode = await db.accessCode.findUnique({
    where: { codeHash: hashCode(code) },
    include: { stay: { include: { guest: true } }, staff: true },
  })

  if (!accessCode) {
    const lock = recordFailure(`codefail:${ip}`, 10, 15 * 60_000)
    if (lock.locked) {
      return fail(`محاولات فاشلة كثيرة. حاول مجددًا بعد ${Math.ceil(lock.retryAfterSec / 60)} دقيقة`, 429)
    }
    await audit(db, {
      action: 'CODE_LOGIN_FAILED',
      entityType: 'AccessCode',
      entityId: 'unknown',
      actor: ip,
      actorRole: 'SYSTEM',
      details: { reason: 'NOT_FOUND' },
    })
    return fail('كود غير صالح. تحقق من الكود وأعد المحاولة')
  }

  clearFailures(`codefail:${ip}`)

  // 3) الحالات المرفوضة
  if (accessCode.status === 'REVOKED') {
    return fail('تم إلغاء هذا الكود. تواصل مع إدارة الفندق')
  }
  if (accessCode.status === 'EXPIRED' || accessCode.expiresAt < new Date()) {
    if (accessCode.status === 'ACTIVE') {
      await db.accessCode.update({ where: { id: accessCode.id }, data: { status: 'EXPIRED' } })
    }
    return fail('انتهت صلاحية هذا الكود. تواصل مع الاستقبال')
  }

  // 4) سياق كل نوع كود
  let displayName = ''
  if (accessCode.type === 'GUEST') {
    if (!accessCode.stay || accessCode.stay.status === 'CLOSED') {
      return fail('انتهت إقامتك ولم يعد بإمكانك استخدام هذا الكود')
    }
    displayName = accessCode.stay.guest.fullName
  } else {
    if (!accessCode.staff || !accessCode.staff.active) {
      return fail('حساب الموظف غير مفعل. تواصل مع الإدارة')
    }
    displayName = accessCode.staff.fullName
  }

  // 5) إنشاء الجلسة — تنتهي مع الأقرب: صلاحية الكود أو 12 ساعة
  const maxExpiry = new Date(Date.now() + SESSION_MAX_HOURS * 3600_000)
  const expiresAt = accessCode.expiresAt < maxExpiry ? accessCode.expiresAt : maxExpiry
  const role = accessCode.type as 'GUEST' | 'RECEPTION' | 'ADMIN'

  const [session] = await db.$transaction([
    db.session.create({
      data: { token: uuidv4(), accessCodeId: accessCode.id, role, expiresAt },
    }),
    db.accessCode.update({ where: { id: accessCode.id }, data: { lastUsedAt: new Date() } }),
    db.auditLog.create({
      data: {
        action: 'CODE_LOGIN',
        entityType: 'Session',
        entityId: accessCode.id,
        actor: displayName,
        actorRole: role,
        details: JSON.stringify({ type: accessCode.type }),
      },
    }),
  ])

  return ok({
    token: session.token,
    role,
    name: displayName,
    expiresAt: expiresAt.toISOString(),
  })
}

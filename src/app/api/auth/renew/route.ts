// ─────────────────────────────────────────────────────────────
// POST /api/auth/renew — تجديد الجلسة (H3 — عقد المصادقة للعميل المحمول)
// المصادقة: Bearer التوكن الحالي (كل فحوص getAuth تجري هنا:
// الجلسة غير ملغاة/منتهية + الكود ACTIVE + سياق الدور/الإقامة).
// النجاح: مدّ expiresAt إلى min(الآن + 12 ساعة، صلاحية الكود) —
// نفس التوكن يُمدَّد (لا يُصدر توكنًا جديدًا؛ التوكن المخزَّن لدى
// العميل يبقى صالحًا) + تحديث lastSeenAt.
// الحماية: rate limit 10/دقيقة لكل IP.
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { getAuth } from '@/lib/auth'
import { rateLimit, clientIp } from '@/lib/rate-limit'

export const dynamic = 'force-dynamic'

const SESSION_MAX_HOURS = 12

export async function POST(req: NextRequest) {
  const ip = clientIp(req)

  // 1) حماية: 10 تجديدات / دقيقة لكل IP
  const rl = rateLimit(`renew:${ip}`, 10, 60_000)
  if (!rl.allowed) {
    return fail(`محاولات كثيرة جدًا. أعد المحاولة بعد ${rl.retryAfterSec} ثانية`, 429)
  }

  // 2) المصادقة بالتوكن الحالي — الجلسة غير الصالحة/المنتهية/الكود غير
  //    ACTIVE → 401 بنفس أسلوب requireRole
  const auth = await getAuth(req)
  if (!auth) {
    return fail('جلسة غير صالحة أو منتهية — سجّل الدخول من جديد', 401)
  }

  // 3) جلب الجلسة نفسها (getAuth لا يكشف التوكن) — تم التحقق منها للتو
  const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '').trim()
  const session = await db.session.findUnique({
    where: { token },
    include: { accessCode: true },
  })
  if (!session || session.revoked) {
    return fail('جلسة غير صالحة أو منتهية — سجّل الدخول من جديد', 401)
  }

  // 4) العمر الجديد: الأقرب من (الآن + 12 ساعة، صلاحية الكود)
  const maxExpiry = new Date(Date.now() + SESSION_MAX_HOURS * 3600_000)
  const expiresAt = session.accessCode.expiresAt < maxExpiry ? session.accessCode.expiresAt : maxExpiry
  const actor = auth.role === 'GUEST' ? auth.guestName : auth.staffName

  // 5) تمديد نفس التوكن + تدقيق AUTH_RENEW (نمط معاملة validate)
  const [updated] = await db.$transaction([
    db.session.update({
      where: { token },
      data: { expiresAt, lastSeenAt: new Date() },
    }),
    db.auditLog.create({
      data: {
        action: 'AUTH_RENEW',
        entityType: 'Session',
        entityId: session.id,
        actor,
        actorRole: auth.role,
        details: JSON.stringify({ role: auth.role, expiresAt: expiresAt.toISOString() }),
      },
    }),
  ])

  return ok({ expiresAt: updated.expiresAt.toISOString() })
}

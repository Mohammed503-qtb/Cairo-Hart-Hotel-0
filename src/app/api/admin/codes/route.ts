// ─────────────────────────────────────────────────────────────
// GET/POST /api/admin/codes — أكواد الوصول
// GET ?type=&status= : الأحدث أولًا مع سياق الموظف/الضيف
// POST: توليد كود خام يُعاد مرة واحدة فقط + إشعار للاستقبال
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { generateCode, hashCode, maskCode } from '@/lib/codes'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { asString, asInt, endOfDayAfter } from '../_shared'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { searchParams } = new URL(req.url)
  const type = searchParams.get('type') ?? ''
  const status = searchParams.get('status') ?? ''

  const where: Record<string, string> = {}
  if (['GUEST', 'RECEPTION', 'ADMIN'].includes(type)) where.type = type
  if (['ACTIVE', 'EXPIRED', 'REVOKED', 'USED'].includes(status)) where.status = status

  const codes = await db.accessCode.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    include: {
      staff: { select: { fullName: true, role: true } },
      stay: { include: { guest: { select: { fullName: true } }, room: { select: { number: true } } } },
    },
  })

  return ok({
    codes: codes.map((c) => ({
      id: c.id,
      codeMasked: c.codeMasked,
      type: c.type,
      status: c.status,
      expiresAt: c.expiresAt,
      lastUsedAt: c.lastUsedAt,
      createdAt: c.createdAt,
      staffName: c.staff?.fullName ?? null,
      staffRole: c.staff?.role ?? null,
      guestName: c.stay?.guest?.fullName ?? null,
      roomNumber: c.stay?.room?.number ?? null,
      stayReference: c.stay?.reference ?? null,
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<{ type?: string; staffId?: string; days?: number }>(req)
  if (!body) return fail('طلب غير صالح')

  // كود الضيف يُولَّد عند تسجيل الوصول من الاستقبال
  const type = body.type
  if (type !== 'RECEPTION' && type !== 'ADMIN') {
    return fail('النوع يجب أن يكون RECEPTION أو ADMIN — كود الضيف يُولَّد عند تسجيل الوصول')
  }

  const staffId = typeof body.staffId === 'string' ? body.staffId.trim() : ''
  if (!staffId) return fail('الموظف مطلوب')
  const staff = await db.staff.findUnique({ where: { id: staffId } })
  if (!staff) return fail('الموظف غير موجود', 404)
  if (!staff.active) return fail('هذا الموظف معطّل — فعّله أولًا قبل توليد كود له')

  // تطابق الدور: استقبال ← RECEPTION | إدارة/مدير ← ADMIN
  if (type === 'RECEPTION' && staff.role !== 'RECEPTION') {
    return fail('كود الاستقبال يُولَّد لموظف بدور «استقبال» فقط')
  }
  if (type === 'ADMIN' && !['ADMIN', 'MANAGER'].includes(staff.role)) {
    return fail('كود الإدارة يُولَّد لموظف بدور «إدارة» أو «مدير» فقط')
  }

  const days = asInt(body.days) ?? 7
  if (days < 1 || days > 30) return fail('الصلاحية يجب أن تكون بين 1 و 30 يومًا')

  const raw = generateCode(type)
  const expiresAt = endOfDayAfter(days)

  const created = await db.accessCode.create({
    data: {
      codeHash: hashCode(raw),
      codeMasked: maskCode(raw),
      type,
      staffId: staff.id,
      expiresAt,
      status: 'ACTIVE',
    },
  })

  await audit(db, {
    action: 'CODE_GENERATED',
    entityType: 'AccessCode',
    entityId: created.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { type, staffName: staff.fullName, days, codeMasked: created.codeMasked, expiresAt },
  })

  const notification = await db.notification.create({
    data: {
      audience: 'RECEPTION',
      type: 'INFO',
      title: 'كود دخول جديد',
      body: `تم توليد كود ${type === 'ADMIN' ? 'إدارة' : 'استقبال'} جديد لـ${staff.fullName} — صالح ${days} يومًا`,
    },
  })
  await emitEvent(wsRooms.reception, WS_EVENTS.NOTIFICATION_NEW, {
    id: notification.id,
    title: notification.title,
    body: notification.body,
    createdAt: notification.createdAt,
  })

  // الكود الخام يُعاد مرة واحدة فقط — لا يُخزَّن أبدًا
  return ok({
    codeId: created.id,
    code: raw,
    codeMasked: created.codeMasked,
    expiresAt,
    staffName: staff.fullName,
    days,
    type,
  }, 201)
}

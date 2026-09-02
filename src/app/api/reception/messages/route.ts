// ─────────────────────────────────────────────────────────────
// GET /api/reception/messages?stayId= + POST — محادثات الإقامات
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { ApiError } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const stayId = req.nextUrl.searchParams.get('stayId') ?? ''
  if (!stayId) return fail('حدد الإقامة')

  const stay = await db.stay.findUnique({ where: { id: stayId }, select: { id: true } })
  if (!stay) return fail('الإقامة غير موجودة', 404)

  const messages = await db.message.findMany({
    where: { stayId },
    orderBy: { createdAt: 'asc' },
    take: 200,
  })

  return ok({
    messages: messages.map((m) => ({
      id: m.id,
      sender: m.sender,
      senderName: m.senderName,
      body: m.body,
      createdAt: m.createdAt.toISOString(),
    })),
  })
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const body = await readBody<{ stayId?: string; body?: string }>(req)
  const stayId = typeof body?.stayId === 'string' ? body.stayId : ''
  const text = typeof body?.body === 'string' ? body.body.trim() : ''

  if (!stayId) return fail('حدد الإقامة')
  if (!text) return fail('اكتب نص الرسالة')
  if (text.length > 2000) return fail('الرسالة طويلة جدًا (الحد 2000 حرف)')

  try {
    const message = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({ where: { id: stayId }, select: { id: true, status: true } })
      if (!stay) throw new ApiError('الإقامة غير موجودة', 404)
      if (stay.status === 'CLOSED') throw new ApiError('الإقامة مغلقة — لا يمكن مراسلة الضيف')

      const created = await tx.message.create({
        data: { stayId, sender: 'RECEPTION', senderName: staffName, body: text },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId,
          type: 'CHAT',
          title: 'رسالة جديدة من الاستقبال',
          body: text.length > 80 ? `${text.slice(0, 80)}…` : text,
        },
      })

      await audit(tx, {
        action: 'CHAT_MESSAGE',
        entityType: 'Message',
        entityId: created.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { stayId },
      })

      return created
    })

    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.CHAT_MESSAGE, {
      id: message.id,
      sender: 'RECEPTION',
      senderName: staffName,
      body: text,
      createdAt: message.createdAt.toISOString(),
    })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.NOTIFICATION_NEW, { title: 'رسالة جديدة من الاستقبال' })

    return ok({
      message: {
        id: message.id,
        sender: message.sender,
        senderName: message.senderName,
        body: message.body,
        createdAt: message.createdAt.toISOString(),
      },
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('message failed', e)
    return fail('حدث خطأ أثناء إرسال الرسالة — أعد المحاولة', 500)
  }
}

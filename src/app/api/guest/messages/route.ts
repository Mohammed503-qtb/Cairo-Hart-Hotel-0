// ─────────────────────────────────────────────────────────────
// GET  /api/guest/messages — رسائل إقامة الضيف (تصاعدي)
// POST /api/guest/messages — إرسال رسالة للاستقبال
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { GuestApiError } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
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
  } catch (e) {
    console.error('guest messages list failed', e)
    return fail('حدث خطأ أثناء تحميل المحادثة — أعد المحاولة', 500)
  }
}

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const body = await readBody<{ body?: string }>(req)
  const text = typeof body?.body === 'string' ? body.body.trim() : ''

  if (text.length < 1) return fail('اكتب نص الرسالة أولًا')
  if (text.length > 1000) return fail('الرسالة طويلة جدًا (الحد 1000 حرف)')

  try {
    const message = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        select: { id: true, status: true, room: { select: { number: true } } },
      })
      if (!stay) throw new GuestApiError('الإقامة غير موجودة', 404)
      if (stay.status === 'CLOSED') {
        throw new GuestApiError('الإقامة مغلقة — لا يمكن إرسال الرسائل', 403)
      }

      const created = await tx.message.create({
        data: {
          stayId,
          sender: 'GUEST',
          senderName: guestName,
          body: text,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'CHAT',
          title: `رسالة جديدة من ${guestName} — غرفة ${stay.room.number}`,
          body: text.length > 80 ? `${text.slice(0, 80)}…` : text,
        },
      })

      await audit(tx, {
        action: 'CHAT_MESSAGE',
        entityType: 'Message',
        entityId: created.id,
        actor: guestName,
        actorRole: 'GUEST',
        details: { stayId, roomNumber: stay.room.number },
      })

      return created
    })

    // بث للاستقبال فقط — لا صدى لغرفة الضيف (الرسالة منشأة عنده محليًا)
    await emitEvent(wsRooms.reception, WS_EVENTS.CHAT_MESSAGE, {
      stayId,
      from: guestName,
    })

    return ok(
      {
        message: {
          id: message.id,
          sender: message.sender,
          senderName: message.senderName,
          body: message.body,
          createdAt: message.createdAt.toISOString(),
        },
      },
      201
    )
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest message send failed', e)
    return fail('حدث خطأ أثناء إرسال الرسالة — أعد المحاولة', 500)
  }
}

// ─────────────────────────────────────────────────────────────
// POST /api/guest/requests/[id]/cancel — إلغاء طلب بواسطة الضيف
// مسموح فقط NEW/ACKNOWLEDGED — عزل البيانات: الطلب يجب أن يخص stayId الجلسة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { serializeRequest, GuestApiError, requireGuest } from '../../../_lib'
export const dynamic = 'force-dynamic'

const CANCELLABLE = ['NEW', 'ACKNOWLEDGED']

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const { id } = await params

  try {
    const updated = await db.$transaction(async (tx) => {
      // عزل البيانات — الطلب يجب أن يخص إقامة الجلسة حصرًا
      const request = await tx.serviceRequest.findUnique({
        where: { id },
        include: {
          stay: { select: { id: true, room: { select: { number: true } } } },
          updates: { orderBy: { createdAt: 'asc' } },
        },
      })
      if (!request || request.stay.id !== stayId) {
        throw new GuestApiError('الطلب غير موجود', 404)
      }
      if (!CANCELLABLE.includes(request.status)) {
        throw new GuestApiError('لا يمكن إلغاء طلب قيد التنفيذ أو منتهٍ', 403)
      }

      const saved = await tx.serviceRequest.update({
        where: { id },
        data: { status: 'CANCELLED' },
      })

      await tx.requestUpdate.create({
        data: {
          requestId: id,
          status: 'CANCELLED',
          note: 'أُلغي بواسطة الضيف',
          byName: guestName,
          byRole: 'GUEST',
        },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'REQUEST',
          title: `إلغاء طلب — ${request.reference}`,
          body: `${guestName} (الغرفة ${request.stay.room.number}) ألغى طلب «${request.title}».`,
        },
      })

      await audit(tx, {
        action: 'REQUEST_UPDATED',
        entityType: 'ServiceRequest',
        entityId: id,
        actor: guestName,
        actorRole: 'GUEST',
        details: { from: request.status, to: 'CANCELLED', reason: 'guest-cancelled' },
      })

      return tx.serviceRequest.findUnique({
        where: { id },
        include: { updates: { orderBy: { createdAt: 'asc' } } },
      })
    })

    if (!updated) return fail('الطلب غير موجود', 404)

    const roomNumber = await db.stay.findUnique({
      where: { id: stayId },
      select: { room: { select: { number: true } } },
    })

    await emitEvent(wsRooms.reception, WS_EVENTS.REQUEST_UPDATED, {
      requestId: id,
      status: 'CANCELLED',
    })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.REQUEST_UPDATED, {
      requestId: id,
      status: 'CANCELLED',
    })

    return ok({
      request: serializeRequest(updated, roomNumber?.room.number ?? '—'),
    })
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest request cancel failed', e)
    return fail('حدث خطأ أثناء إلغاء الطلب — أعد المحاولة', 500)
  }
}

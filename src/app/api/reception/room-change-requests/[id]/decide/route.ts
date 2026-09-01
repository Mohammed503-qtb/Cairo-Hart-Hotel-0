// ─────────────────────────────────────────────────────────────
// POST /api/reception/room-change-requests/[id]/decide — الموافقة/الرفض
// موافقة: معاملة — toRoom متاحة؟ القديمة CLEANING، الجديدة OCCUPIED،
// نقل الإقامة + بند فرق السعر + إشعار + تدقيق ROOM_TRANSFERRED
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatMoney } from '@/lib/format'
import { ApiError } from '../../../_helpers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const { id } = await params
  const body = await readBody<{ approve?: boolean }>(req)
  const approve = body?.approve === true

  try {
    const result = await db.$transaction(async (tx) => {
      const request = await tx.roomChangeRequest.findUnique({
        where: { id },
        include: { stay: { include: { room: true, guest: true } } },
      })
      if (!request) throw new ApiError('طلب تغيير الغرفة غير موجود', 404)
      if (request.status !== 'PENDING') throw new ApiError('تم البت في هذا الطلب مسبقًا')

      const stay = request.stay
      if (stay.status !== 'ACTIVE' && stay.status !== 'CHECKOUT_REQUESTED') {
        throw new ApiError('الإقامة غير نشطة — لا يمكن تغيير الغرفة')
      }

      if (!approve) {
        await tx.roomChangeRequest.update({
          where: { id },
          data: { status: 'REJECTED', decidedBy: staffName, decidedAt: new Date() },
        })
        await tx.notification.create({
          data: {
            audience: 'GUEST',
            stayId: stay.id,
            type: 'ROOM_CHANGE',
            title: 'رد طلب تغيير الغرفة',
            body: 'تم رفض طلب تغيير الغرفة',
          },
        })
        await audit(tx, {
          action: 'ROOM_CHANGE_REJECTED',
          entityType: 'RoomChangeRequest',
          entityId: id,
          actor: staffName,
          actorRole: 'RECEPTION',
          details: { stayId: stay.id, fromRoom: stay.room.number, toRoom: request.toRoomNumber },
        })
        return { stayId: stay.id, approved: false, newRoomNumber: null as string | null }
      }

      // ── الموافقة ──
      const toRoom = await tx.room.findUnique({ where: { id: request.toRoomId } })
      if (!toRoom) throw new ApiError('الغرفة المطلوبة غير موجودة', 404)
      if (toRoom.status !== 'AVAILABLE') throw new ApiError('الغرفة المطلوبة لم تعد متاحة')

      const oldRoom = stay.room

      await tx.room.update({ where: { id: oldRoom.id }, data: { status: 'CLEANING' } })
      await tx.room.update({ where: { id: toRoom.id }, data: { status: 'OCCUPIED' } })
      await tx.stay.update({ where: { id: stay.id }, data: { roomId: toRoom.id } })

      if (request.priceDiffCents > 0) {
        await tx.charge.create({
          data: {
            stayId: stay.id,
            category: 'EXTRA',
            description: `نقل إلى غرفة ${toRoom.number}`,
            amountCents: request.priceDiffCents,
          },
        })
      }

      await tx.roomChangeRequest.update({
        where: { id },
        data: { status: 'APPROVED', decidedBy: staffName, decidedAt: new Date() },
      })
      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'ROOM_CHANGE',
          title: 'تم تغيير غرفتك',
          body: `تم تغيير غرفتك إلى ${toRoom.number}` + (request.priceDiffCents > 0 ? ` (${formatMoney(request.priceDiffCents)})` : ''),
        },
      })
      await audit(tx, {
        action: 'ROOM_TRANSFERRED',
        entityType: 'Stay',
        entityId: stay.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: {
          stayId: stay.id,
          reference: stay.reference,
          fromRoom: oldRoom.number,
          toRoom: toRoom.number,
          priceDiffCents: request.priceDiffCents,
        },
      })

      return { stayId: stay.id, approved: true, newRoomNumber: toRoom.number }
    })

    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.STAY_UPDATED, { kind: 'ROOM_CHANGE' })
    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.NOTIFICATION_NEW, { title: 'تغيير الغرفة' })
    await emitEvent(wsRooms.reception, WS_EVENTS.ROOM_STATUS, { kind: 'ROOM_CHANGE', stayId: result.stayId })

    return ok({ approved: result.approved, newRoomNumber: result.newRoomNumber })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('room change decide failed', e)
    return fail('حدث خطأ أثناء البت في طلب تغيير الغرفة — أعد المحاولة', 500)
  }
}

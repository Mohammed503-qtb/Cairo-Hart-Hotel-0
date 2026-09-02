// ─────────────────────────────────────────────────────────────
// POST /api/guest/room-change — طلب تغيير الغرفة
// الغرفة الهدف AVAILABLE + الإقامة نشطة + فرق سعر الليالي المتبقية
// RoomChangeRequest PENDING + إشعار وتدقيق وبث
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatMoney } from '@/lib/format'
import { loadStay, startOfDayLocal, nightsBetweenDays, GuestApiError } from '../_lib'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const body = await readBody<{ toRoomId?: string; reason?: string }>(req)
  const toRoomId = typeof body?.toRoomId === 'string' ? body.toRoomId : ''
  const reason = typeof body?.reason === 'string' ? body.reason.trim().slice(0, 300) : ''

  if (!toRoomId) return fail('حدد الغرفة المطلوبة')

  try {
    const created = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: {
          room: { include: { roomType: true } },
          reservation: { select: { currency: true } },
        },
      })
      if (!stay) throw new GuestApiError('الإقامة غير موجودة', 404)
      if (stay.status !== 'ACTIVE') {
        throw new GuestApiError('لا يمكن طلب تغيير الغرفة — إقامتك غير نشطة', 403)
      }
      if (toRoomId === stay.roomId) {
        throw new GuestApiError('اختر غرفة مختلفة عن غرفتك الحالية', 400)
      }

      const toRoom = await tx.room.findUnique({
        where: { id: toRoomId },
        include: { roomType: { select: { name: true, basePriceCents: true } } },
      })
      if (!toRoom) throw new GuestApiError('الغرفة المطلوبة غير موجودة', 404)
      if (toRoom.status !== 'AVAILABLE') {
        throw new GuestApiError('الغرفة المطلوبة غير متاحة حاليًا', 409)
      }

      // فرق السعر = (أساس الجديد − أساس الحالي) × الليالي المتبقية
      const today = startOfDayLocal(new Date())
      const remainingNights = Math.max(1, nightsBetweenDays(today, stay.expectedCheckOutAt))
      const diffCents =
        (toRoom.roomType.basePriceCents - stay.room.roomType.basePriceCents) * remainingNights
      const currency = stay.reservation.currency
      const diffLabel =
        diffCents === 0
          ? 'بدون فرق سعر'
          : diffCents > 0
            ? `فرق سعر ${formatMoney(diffCents, currency)} إضافية`
            : `وفرة ${formatMoney(Math.abs(diffCents), currency)}`

      const request = await tx.roomChangeRequest.create({
        data: {
          stayId,
          toRoomId,
          toRoomNumber: toRoom.number,
          priceDiffCents: diffCents,
          reason: reason || null,
          status: 'PENDING',
        },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'ROOM_CHANGE',
          title: 'طلب تغيير غرفة',
          body: `${guestName} (الغرفة ${stay.room.number}) يطلب الانتقال إلى الغرفة ${toRoom.number} (${toRoom.roomType.name}) — ${diffLabel} لـ ${remainingNights} ليلة متبقية.`,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId,
          type: 'ROOM_CHANGE',
          title: 'تم إرسال طلب تغيير الغرفة',
          body: `طلبك بالانتقال إلى الغرفة ${toRoom.number} قيد المراجعة من الاستقبال.`,
        },
      })

      await audit(tx, {
        action: 'ROOM_CHANGE_REQUESTED',
        entityType: 'RoomChangeRequest',
        entityId: request.id,
        actor: guestName,
        actorRole: 'GUEST',
        details: {
          stayId,
          fromRoom: stay.room.number,
          toRoom: toRoom.number,
          toRoomType: toRoom.roomType.name,
          priceDiffCents: diffCents,
          remainingNights,
        },
      })

      return { request, remainingNights, roomNumber: toRoom.number }
    })

    await emitEvent(wsRooms.reception, WS_EVENTS.NOTIFICATION_NEW, {
      title: 'طلب تغيير غرفة',
      stayId,
    })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.NOTIFICATION_NEW, {
      title: 'تم إرسال طلب تغيير الغرفة',
    })

    return ok(
      {
        request: {
          id: created.request.id,
          toRoomNumber: created.request.toRoomNumber,
          priceDiffCents: created.request.priceDiffCents,
          remainingNights: created.remainingNights,
          reason: created.request.reason,
          status: created.request.status,
          createdAt: created.request.createdAt.toISOString(),
        },
      },
      201
    )
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest room change failed', e)
    return fail('حدث خطأ أثناء إرسال طلب تغيير الغرفة — أعد المحاولة', 500)
  }
}

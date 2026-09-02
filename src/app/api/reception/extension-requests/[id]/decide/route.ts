// ─────────────────────────────────────────────────────────────
// POST /api/reception/extension-requests/[id]/decide — الموافقة/الرفض
// موافقة: معاملة ذرية — إعادة فحص توفر نوع الغرفة (مستثنيًا حجز الإقامة)
// + تمديد الخروج + بند ROOM_EXTENSION + إشعار + تدقيق
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { availableRoomCount } from '@/lib/availability'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatMoney, formatDateAr } from '@/lib/format'
import { ApiError, startOfDay, endOfDay } from '../../../_helpers'

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
      const request = await tx.extensionRequest.findUnique({
        where: { id },
        include: { stay: { include: { reservation: true, room: true, guest: true } } },
      })
      if (!request) throw new ApiError('طلب التمديد غير موجود', 404)
      if (request.status !== 'PENDING') throw new ApiError('تم البت في هذا الطلب مسبقًا')

      const stay = request.stay

      if (!approve) {
        await tx.extensionRequest.update({
          where: { id },
          data: { status: 'REJECTED', decidedBy: staffName, decidedAt: new Date() },
        })
        await tx.notification.create({
          data: {
            audience: 'GUEST',
            stayId: stay.id,
            type: 'EXTENSION',
            title: 'رد طلب التمديد',
            body: 'تم رفض طلب التمديد',
          },
        })
        await audit(tx, {
          action: 'EXTENSION_REJECTED',
          entityType: 'ExtensionRequest',
          entityId: id,
          actor: staffName,
          actorRole: 'RECEPTION',
          details: { stayId: stay.id, room: stay.room.number, reference: stay.reference },
        })
        return { stayId: stay.id, approved: false, newCheckOut: null as Date | null }
      }

      // ── الموافقة: إعادة فحص التوفر داخل المعاملة ──
      // نافذة التمديد: من نهاية الإقامة الحالية (reservation.checkOut) إلى الموعد الجديد.
      // حجز الإقامة نفسه لا يتداخل مع هذه النافذة (حدوده تنتهي عند بدايتها) فلا يُحتسب.
      const windowStart = startOfDay(stay.reservation.checkOut)
      const newCheckOut = startOfDay(request.newCheckOut)
      const available = await availableRoomCount(tx, stay.reservation.roomTypeId, windowStart, newCheckOut)
      if (available < 1) throw new ApiError('الغرفة لم تعد متاحة للتمديد')

      const newExpected = endOfDay(newCheckOut)

      await tx.stay.update({
        where: { id: stay.id },
        data: { expectedCheckOutAt: newExpected },
      })
      await tx.reservation.update({
        where: { id: stay.reservationId },
        data: { checkOut: newCheckOut },
      })
      await tx.charge.create({
        data: {
          stayId: stay.id,
          category: 'ROOM_EXTENSION',
          description: `تمديد إقامة ${request.nights} ${request.nights === 1 ? 'ليلة' : 'ليالٍ'}`,
          amountCents: request.priceCents,
        },
      })
      await tx.extensionRequest.update({
        where: { id },
        data: { status: 'APPROVED', decidedBy: staffName, decidedAt: new Date() },
      })
      // تمديد صلاحية كود الضيف حتى نهاية الإقامة الجديدة
      await tx.accessCode.updateMany({
        where: { stayId: stay.id, type: 'GUEST', status: 'ACTIVE' },
        data: { expiresAt: newExpected },
      })
      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'EXTENSION',
          title: 'تمت الموافقة على التمديد',
          body: `تمت الموافقة على التمديد حتى ${formatDateAr(newCheckOut)} — أُضيف ${formatMoney(request.priceCents, stay.reservation.currency)} لفاتورتك`,
        },
      })
      await audit(tx, {
        action: 'EXTENSION_APPROVED',
        entityType: 'ExtensionRequest',
        entityId: id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: {
          stayId: stay.id,
          room: stay.room.number,
          reference: stay.reference,
          newCheckOut: newCheckOut.toISOString(),
          priceCents: request.priceCents,
          nights: request.nights,
        },
      })

      return { stayId: stay.id, approved: true, newCheckOut: newExpected }
    })

    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.STAY_UPDATED, { kind: 'EXTENSION' })
    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.NOTIFICATION_NEW, { title: 'طلب التمديد' })
    await emitEvent(wsRooms.reception, WS_EVENTS.STAY_UPDATED, { kind: 'EXTENSION', stayId: result.stayId })

    return ok({
      approved: result.approved,
      newExpectedCheckOutAt: result.newCheckOut?.toISOString() ?? null,
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('extension decide failed', e)
    return fail('حدث خطأ أثناء البت في طلب التمديد — أعد المحاولة', 500)
  }
}

// ─────────────────────────────────────────────────────────────
// POST /api/guest/checkout-request — طلب تسجيل الخروج
// الإقامة النشطة فقط → CHECKOUT_REQUESTED + إشعارات بالرصيد + بث
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatMoney } from '@/lib/format'
import { computeStayBalance, GuestApiError } from '../_lib'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  try {
    const result = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: {
          room: { select: { number: true } },
          reservation: { select: { grandTotalCents: true, paidCents: true, currency: true } },
        },
      })
      if (!stay) throw new GuestApiError('الإقامة غير موجودة', 404)
      if (stay.status === 'CHECKOUT_REQUESTED') {
        throw new GuestApiError('تم إرسال طلب الخروج مسبقًا — الاستقبال سيتواصل معك', 409)
      }
      if (stay.status !== 'ACTIVE') {
        throw new GuestApiError('إقامتك غير نشطة', 403)
      }

      const chargesAgg = await tx.charge.aggregate({
        _sum: { amountCents: true },
        where: { stayId },
      })
      const chargesCents = chargesAgg._sum.amountCents ?? 0
      const balanceCents =
        stay.reservation.grandTotalCents + chargesCents - stay.reservation.paidCents
      const currency = stay.reservation.currency

      await tx.stay.update({
        where: { id: stayId },
        data: { status: 'CHECKOUT_REQUESTED' },
      })

      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'CHECKOUT',
          title: `طلب تسجيل خروج — الغرفة ${stay.room.number}`,
          body:
            balanceCents > 0
              ? `${guestName} يطلب تسجيل الخروج — الرصيد المستحق ${formatMoney(balanceCents, currency)} يجب تسويته قبل الخروج.`
              : `${guestName} يطلب تسجيل الخروج — لا مستحقات على الإقامة.`,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId,
          type: 'CHECKOUT',
          title: 'تم استلام طلب الخروج',
          body:
            balanceCents > 0
              ? `يرجى تسوية الرصيد المستحق (${formatMoney(balanceCents, currency)}) لدى الاستقبال قبل الخروج.`
              : 'سيقوم الاستقبال بتجهيز الخروج والعودة إليك خلال دقائق.',
        },
      })

      await audit(tx, {
        action: 'CHECKOUT_REQUESTED',
        entityType: 'Stay',
        entityId: stayId,
        actor: guestName,
        actorRole: 'GUEST',
        details: { stayId, roomNumber: stay.room.number, balanceCents, chargesCents },
      })

      return { balanceCents, chargesCents, currency }
    })

    await emitEvent(wsRooms.reception, WS_EVENTS.STAY_UPDATED, { stayId })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.STAY_UPDATED, { stayId })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.NOTIFICATION_NEW, {
      title: 'تم استلام طلب الخروج',
    })

    return ok({
      balanceCents: result.balanceCents,
      chargesCents: result.chargesCents,
      currency: result.currency,
    })
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest checkout request failed', e)
    return fail('حدث خطأ أثناء إرسال طلب الخروج — أعد المحاولة', 500)
  }
}

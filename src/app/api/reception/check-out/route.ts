// ─────────────────────────────────────────────────────────────
// POST /api/reception/check-out — تسجيل الخروج
// معاملة ذرية: فحص الرصيد → إغلاق الإقامة → غرفة DIRTY →
// إبطال كود الضيف وجلساته فورًا → تدقيق + إشعار وداع
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { ApiError, chargesTotal, computeBalance, failWith } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const body = await readBody<{ stayId?: string; confirmOutstanding?: boolean }>(req)
  const stayId = typeof body?.stayId === 'string' ? body.stayId : ''
  const confirmOutstanding = body?.confirmOutstanding === true

  if (!stayId) return fail('حدد الإقامة المطلوبة')

  try {
    const result = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: { reservation: true, room: true, charges: true, guest: true },
      })
      if (!stay) throw new ApiError('الإقامة غير موجودة', 404)
      if (stay.status !== 'ACTIVE' && stay.status !== 'CHECKOUT_REQUESTED') {
        throw new ApiError('الإقامة غير نشطة — لا يمكن تسجيل الخروج')
      }

      // 2) فحص الرصيد داخل المعاملة
      const balance = computeBalance(stay.reservation, chargesTotal(stay.charges))
      if (balance > 0 && !confirmOutstanding) {
        throw new ApiError(
          `يوجد رصيد غير مسدد ${'$' + (balance / 100).toFixed(2)} — سجّل دفعة أو أكّد الخروج مع الرصيد`,
          400,
          { balanceCents: balance }
        )
      }

      // 3) إغلاق الإقامة
      await tx.stay.update({
        where: { id: stay.id },
        data: { status: 'CLOSED', actualCheckOutAt: new Date() },
      })

      // 4) إكمال الحجز
      await tx.reservation.update({
        where: { id: stay.reservationId },
        data: { status: 'COMPLETED' },
      })

      // 5) الغرفة تحتاج تنظيفًا
      await tx.room.update({ where: { id: stay.roomId }, data: { status: 'DIRTY' } })

      // 6) إبطال كود الضيف + جلساته (يموت فورًا)
      await tx.accessCode.updateMany({
        where: { stayId: stay.id, type: 'GUEST', status: 'ACTIVE' },
        data: { status: 'REVOKED' },
      })
      await tx.session.updateMany({
        where: { revoked: false, accessCode: { stayId: stay.id } },
        data: { revoked: true },
      })

      // 7) تدقيق + إشعار وداع
      await audit(tx, {
        action: 'CHECK_OUT',
        entityType: 'Stay',
        entityId: stay.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: {
          room: stay.room.number,
          reference: stay.reference,
          balanceCents: balance,
          withOutstanding: balance > 0,
        },
      })
      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'INFO',
          title: 'شكرًا لإقامتك',
          body: 'شكرًا لإقامتك — نتمنى لك رحلة سعيدة',
        },
      })

      return { roomNumber: stay.room.number, balanceCents: balance, stayId: stay.id }
    })

    // بعد المعاملة — تطبيق الضيف سينتهي تلقائيًا (الكود REVOKED)
    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.STAY_UPDATED, { kind: 'CHECK_OUT' })
    await emitEvent(wsRooms.reception, WS_EVENTS.STAY_UPDATED, { kind: 'CHECK_OUT', stayId: result.stayId })
    await emitEvent(wsRooms.reception, WS_EVENTS.ROOM_STATUS, { roomNumber: result.roomNumber, status: 'DIRTY' })

    return ok({ closed: true, roomNumber: result.roomNumber, balanceCents: result.balanceCents })
  } catch (e) {
    if (e instanceof ApiError) {
      return (e.extra && Object.keys(e.extra).length > 0) ? failWith(e.message, e.status, e.extra) : fail(e.message, e.status)
    }
    console.error('check-out failed', e)
    return fail('حدث خطأ أثناء تسجيل الخروج — أعد المحاولة', 500)
  }
}

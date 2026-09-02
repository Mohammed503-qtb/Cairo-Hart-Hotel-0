// ─────────────────────────────────────────────────────────────
// POST /api/reception/payments — تسجيل دفعة على إقامة
// معاملة: Payment + تحديث المدفوع + إعادة حساب حالة الدفع + تدقيق + إشعار
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { formatMoney } from '@/lib/format'
import { ApiError, chargesTotal, computeBalance } from '../_helpers'

export const dynamic = 'force-dynamic'

const METHODS = ['CASH', 'CARD', 'TRANSFER']

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const body = await readBody<{ stayId?: string; method?: string; amountCents?: number; note?: string }>(req)
  const stayId = typeof body?.stayId === 'string' ? body.stayId : ''
  const method = typeof body?.method === 'string' ? body.method.toUpperCase() : ''
  const amountCents = Number(body?.amountCents)
  const note = typeof body?.note === 'string' ? body.note.trim() : ''

  if (!stayId) return fail('حدد الإقامة')
  if (!METHODS.includes(method)) return fail('طريقة دفع غير صالحة (نقدًا / بطاقة / حوالة)')
  if (!Number.isInteger(amountCents) || amountCents <= 0) return fail('أدخل مبلغًا صحيحًا أكبر من صفر')

  try {
    const result = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: { reservation: true, charges: true, room: true },
      })
      if (!stay) throw new ApiError('الإقامة غير موجودة', 404)
      if (stay.status !== 'ACTIVE' && stay.status !== 'CHECKOUT_REQUESTED') {
        throw new ApiError('الإقامة غير نشطة — لا يمكن تسجيل دفعات عليها')
      }

      const payment = await tx.payment.create({
        data: {
          reservationId: stay.reservationId,
          stayId: stay.id,
          method,
          amountCents,
          status: 'COMPLETED',
          note: note || null,
          recordedBy: staffName,
        },
      })

      const newPaid = stay.reservation.paidCents + amountCents
      const paymentStatus =
        newPaid >= stay.reservation.grandTotalCents ? 'PAID' : newPaid > 0 ? 'PARTIALLY_PAID' : 'UNPAID'

      await tx.reservation.update({
        where: { id: stay.reservationId },
        data: { paidCents: newPaid, paymentStatus },
      })

      await audit(tx, {
        action: 'PAYMENT_RECORDED',
        entityType: 'Payment',
        entityId: payment.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: {
          stayId: stay.id,
          room: stay.room.number,
          method,
          amountCents,
          reference: stay.reference,
        },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'PAYMENT',
          title: 'دفعة مسجلة',
          body: `تم تسجيل دفعة ${formatMoney(amountCents, stay.reservation.currency)} (${method === 'CASH' ? 'نقدًا' : method === 'CARD' ? 'بطاقة' : 'حوالة'})`,
        },
      })

      return {
        payment,
        newPaid,
        paymentStatus,
        balanceCents: computeBalance(
          { grandTotalCents: stay.reservation.grandTotalCents, paidCents: newPaid },
          chargesTotal(stay.charges)
        ),
        stayId: stay.id,
      }
    })

    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.STAY_UPDATED, { kind: 'PAYMENT' })

    return ok({
      payment: {
        id: result.payment.id,
        method: result.payment.method,
        amountCents: result.payment.amountCents,
        createdAt: result.payment.createdAt.toISOString(),
        recordedBy: result.payment.recordedBy,
      },
      paidCents: result.newPaid,
      paymentStatus: result.paymentStatus,
      balanceCents: result.balanceCents,
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('payment failed', e)
    return fail('حدث خطأ أثناء تسجيل الدفعة — أعد المحاولة', 500)
  }
}

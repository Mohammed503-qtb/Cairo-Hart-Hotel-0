// ─────────────────────────────────────────────────────────────
// POST /api/reception/charges — إضافة بند لفاتورة إقامة
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

const CATEGORIES = ['SERVICE', 'EXTRA', 'PENALTY']

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const body = await readBody<{ stayId?: string; description?: string; amountCents?: number; category?: string }>(req)
  const stayId = typeof body?.stayId === 'string' ? body.stayId : ''
  const description = typeof body?.description === 'string' ? body.description.trim() : ''
  const amountCents = Number(body?.amountCents)
  const category = typeof body?.category === 'string' ? body.category.toUpperCase() : ''

  if (!stayId) return fail('حدد الإقامة')
  if (description.length < 3) return fail('أدخل وصفًا للبند (3 أحرف على الأقل)')
  if (!CATEGORIES.includes(category)) return fail('فئة البند غير صالحة')
  if (!Number.isInteger(amountCents) || amountCents <= 0) return fail('أدخل مبلغًا صحيحًا أكبر من صفر')

  try {
    const result = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: { reservation: true, charges: true, room: true },
      })
      if (!stay) throw new ApiError('الإقامة غير موجودة', 404)
      if (stay.status !== 'ACTIVE' && stay.status !== 'CHECKOUT_REQUESTED') {
        throw new ApiError('الإقامة غير نشطة — لا يمكن إضافة بنود عليها')
      }

      const charge = await tx.charge.create({
        data: { stayId: stay.id, category, description, amountCents },
      })

      await audit(tx, {
        action: 'CHARGE_ADDED',
        entityType: 'Charge',
        entityId: charge.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { stayId: stay.id, room: stay.room.number, description, amountCents, category },
      })

      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'BILL',
          title: 'بند جديد على فاتورتك',
          body: `تمت إضافة بند لفاتورتك: ${description} (${formatMoney(amountCents, stay.reservation.currency)})`,
        },
      })

      return {
        charge,
        balanceCents: computeBalance(stay.reservation, chargesTotal(stay.charges) + amountCents),
        stayId: stay.id,
      }
    })

    await emitEvent(wsRooms.stay(result.stayId), WS_EVENTS.STAY_UPDATED, { kind: 'CHARGE' })

    return ok({
      charge: {
        id: result.charge.id,
        category: result.charge.category,
        description: result.charge.description,
        amountCents: result.charge.amountCents,
        createdAt: result.charge.createdAt.toISOString(),
      },
      balanceCents: result.balanceCents,
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('charge failed', e)
    return fail('حدث خطأ أثناء إضافة البند — أعد المحاولة', 500)
  }
}

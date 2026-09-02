// ─────────────────────────────────────────────────────────────
// POST /api/reception/requests/[id]/status — تحديث حالة طلب
// تحديث + خط زمني + إشعار للضيف حسب الحالة + تدقيق + بث فوري
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { ApiError } from '../../../_helpers'

export const dynamic = 'force-dynamic'

const VALID_STATUSES = ['ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING', 'COMPLETED', 'CANCELLED', 'REJECTED']
const TERMINAL = ['COMPLETED', 'CANCELLED', 'REJECTED']

const GUEST_MESSAGE: Record<string, { title: string; body: string }> = {
  ACKNOWLEDGED: { title: 'تحديث طلب', body: 'استلمنا طلبك وسيتم التعامل معه فورًا' },
  ASSIGNED: { title: 'تحديث طلب', body: 'تم إسناد طلبك إلى الفريق المختص' },
  IN_PROGRESS: { title: 'تحديث طلب', body: 'طلبك قيد التنفيذ الآن' },
  WAITING: { title: 'تحديث طلب', body: 'طلبك في انتظار — سنعاود التحديث قريبًا' },
  COMPLETED: { title: 'اكتمل الطلب', body: 'اكتمل تنفيذ طلبك بنجاح. نسعد بخدمتك' },
  CANCELLED: { title: 'إلغاء طلب', body: 'تم إلغاء طلبك' },
  REJECTED: { title: 'رفض طلب', body: 'تم رفض طلبك' },
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const { id } = await params
  const body = await readBody<{ status?: string; note?: string; assignedTo?: string }>(req)

  const status = typeof body?.status === 'string' ? body.status.toUpperCase() : ''
  const note = typeof body?.note === 'string' ? body.note.trim() : ''
  const assignedTo = typeof body?.assignedTo === 'string' ? body.assignedTo.trim() : ''

  if (!VALID_STATUSES.includes(status)) return fail('حالة طلب غير صالحة')

  try {
    const updated = await db.$transaction(async (tx) => {
      const request = await tx.serviceRequest.findUnique({
        where: { id },
        include: { stay: { include: { room: true, guest: true } } },
      })
      if (!request) throw new ApiError('الطلب غير موجود', 404)
      if (TERMINAL.includes(request.status)) throw new ApiError('لا يمكن تعديل طلب منتهٍ')

      const data: Record<string, unknown> = { status }
      if (assignedTo) data.assignedTo = assignedTo
      if (status === 'COMPLETED') data.completedAt = new Date()

      const saved = await tx.serviceRequest.update({
        where: { id },
        data: data as never,
        include: { stay: { include: { room: true, guest: true } }, updates: { orderBy: { createdAt: 'asc' } } },
      })

      await tx.requestUpdate.create({
        data: {
          requestId: id,
          status,
          note: note || null,
          byName: staffName,
          byRole: 'RECEPTION',
        },
      })

      const guestMsg = GUEST_MESSAGE[status]
      if (guestMsg) {
        await tx.notification.create({
          data: {
            audience: 'GUEST',
            stayId: request.stayId,
            type: 'REQUEST',
            title: `${guestMsg.title}: ${request.title}`,
            body: guestMsg.body + (assignedTo ? ` (${assignedTo})` : ''),
          },
        })
      }

      await audit(tx, {
        action: 'REQUEST_UPDATED',
        entityType: 'ServiceRequest',
        entityId: id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { from: request.status, to: status, note, assignedTo, reference: request.reference },
      })

      // إعادة الجلب بعد إضافة التحديث لعرض الخط الزمني الكامل
      return tx.serviceRequest.findUnique({
        where: { id },
        include: {
          stay: { include: { room: true, guest: true } },
          updates: { orderBy: { createdAt: 'asc' } },
        },
      })
    })

    if (!updated) return fail('الطلب غير موجود', 404)

    await emitEvent(wsRooms.stay(updated.stayId), WS_EVENTS.REQUEST_UPDATED, { requestId: id, status })
    await emitEvent(wsRooms.stay(updated.stayId), WS_EVENTS.NOTIFICATION_NEW, { title: 'تحديث طلب' })
    await emitEvent(wsRooms.reception, WS_EVENTS.REQUEST_UPDATED, { requestId: id, status })

    return ok({
      request: {
        id: updated.id,
        reference: updated.reference,
        category: updated.category,
        title: updated.title,
        description: updated.description,
        priority: updated.priority,
        status: updated.status,
        assignedTo: updated.assignedTo,
        createdAt: updated.createdAt.toISOString(),
        updatedAt: updated.updatedAt.toISOString(),
        completedAt: updated.completedAt?.toISOString() ?? null,
        stay: {
          id: updated.stay.id,
          reference: updated.stay.reference,
          roomNumber: updated.stay.room?.number ?? '—',
          guestName: updated.stay.guest?.fullName ?? '—',
        },
        updates: updated.updates.map((u) => ({
          id: u.id,
          status: u.status,
          note: u.note,
          byName: u.byName,
          byRole: u.byRole,
          createdAt: u.createdAt.toISOString(),
        })),
      },
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('request status failed', e)
    return fail('حدث خطأ أثناء تحديث الطلب — أعد المحاولة', 500)
  }
}

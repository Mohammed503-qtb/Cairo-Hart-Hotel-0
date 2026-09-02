// ─────────────────────────────────────────────────────────────
// GET  /api/guest/requests — طلبات إقامة الضيف (الأحدث أولًا)
// POST /api/guest/requests — إنشاء طلب خدمة
// تحقق + معاملة (طلب + تحديث أولي) + إشعارات + تدقيق + بث
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { nextRequestReference } from '@/lib/refs'
import { loadStay, serializeRequest, GuestApiError } from '../_lib'

export const dynamic = 'force-dynamic'

const CATEGORIES = ['HOUSEKEEPING', 'MAINTENANCE', 'GUEST_SERVICES', 'OTHER']
const PRIORITIES = ['NORMAL', 'URGENT']

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const stay = await db.stay.findUnique({
      where: { id: stayId },
      select: { id: true, room: { select: { number: true } } },
    })
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const requests = await db.serviceRequest.findMany({
      where: { stayId },
      orderBy: { createdAt: 'desc' },
      include: { updates: { orderBy: { createdAt: 'asc' } } },
    })

    return ok({
      requests: requests.map((r) => serializeRequest(r, stay.room.number)),
    })
  } catch (e) {
    console.error('guest requests list failed', e)
    return fail('حدث خطأ أثناء تحميل الطلبات — أعد المحاولة', 500)
  }
}

interface CreateBody {
  serviceId?: string
  category?: string
  title?: string
  description?: string
  priority?: string
}

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const body = await readBody<CreateBody>(req)
  const title = typeof body?.title === 'string' ? body.title.trim() : ''
  const description = typeof body?.description === 'string' ? body.description.trim() : ''
  const category = typeof body?.category === 'string' ? body.category.toUpperCase() : ''
  const priority = typeof body?.priority === 'string' ? body.priority.toUpperCase() : 'NORMAL'
  const serviceId = typeof body?.serviceId === 'string' && body.serviceId ? body.serviceId : null

  if (title.length < 3) return fail('عنوان الطلب قصير جدًا — 3 أحرف على الأقل')
  if (!CATEGORIES.includes(category)) return fail('قسم الطلب غير صالح')
  if (!PRIORITIES.includes(priority)) return fail('أولوية الطلب غير صالحة')

  try {
    if (serviceId) {
      const service = await db.service.findUnique({ where: { id: serviceId } })
      if (!service || !service.active) return fail('الخدمة المطلوبة غير متاحة')
    }

    const created = await db.$transaction(async (tx) => {
      const stay = await tx.stay.findUnique({
        where: { id: stayId },
        include: { room: { select: { number: true } } },
      })
      if (!stay) throw new GuestApiError('الإقامة غير موجودة', 404)
      // CLOSED محجوب في getAuth أصلًا — حزام أمان بنص الرسالة المعتمد
      if (stay.status === 'CLOSED') {
        throw new GuestApiError('لا يمكن إنشاء طلبات — إقامتك منتهية', 403)
      }

      const reference = await nextRequestReference(tx)

      const request = await tx.serviceRequest.create({
        data: {
          reference,
          stayId,
          serviceId,
          category,
          title,
          description: description || null,
          priority,
          status: 'NEW',
        },
      })

      await tx.requestUpdate.create({
        data: {
          requestId: request.id,
          status: 'NEW',
          note: 'تم استلام الطلب',
          byName: guestName,
          byRole: 'GUEST',
        },
      })

      await audit(tx, {
        action: 'REQUEST_CREATED',
        entityType: 'ServiceRequest',
        entityId: request.id,
        actor: guestName,
        actorRole: 'GUEST',
        details: { reference, title, priority, category, roomNumber: stay.room.number },
      })

      // إشعار الاستقبال — العاجل له صيغة خاصة
      const urgent = priority === 'URGENT'
      await tx.notification.create({
        data: {
          audience: 'RECEPTION',
          stayId,
          type: 'REQUEST',
          title: urgent ? `طلب عاجل — الغرفة ${stay.room.number}` : `طلب خدمة جديد — الغرفة ${stay.room.number}`,
          body: `${guestName}: ${title}`,
        },
      })

      // إشعار الضيف
      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId,
          type: 'REQUEST',
          title: 'تم استلام طلبك',
          body: `طلبك «${title}» وصل للاستقبال وسيتم التعامل معه فورًا.`,
        },
      })

      return tx.serviceRequest.findUnique({
        where: { id: request.id },
        include: { updates: { orderBy: { createdAt: 'asc' } } },
      })
    })

    if (!created) return fail('حدث خطأ أثناء إنشاء الطلب — أعد المحاولة', 500)

    const stayRoom = await db.stay.findUnique({
      where: { id: stayId },
      select: { room: { select: { number: true } } },
    })
    const roomNumber = stayRoom?.room.number ?? '—'

    // بث فوري — best-effort
    await emitEvent(wsRooms.reception, WS_EVENTS.REQUEST_NEW, {
      id: created.id,
      reference: created.reference,
      title: created.title,
      priority: created.priority,
      roomNumber,
      guestName,
    })
    await emitEvent(wsRooms.stay(stayId), WS_EVENTS.NOTIFICATION_NEW, {
      title: 'تم استلام طلبك',
    })

    return ok(
      {
        request: serializeRequest(created, roomNumber),
      },
      201
    )
  } catch (e) {
    if (e instanceof GuestApiError) return fail(e.message, e.status)
    console.error('guest request create failed', e)
    return fail('حدث خطأ أثناء إنشاء الطلب — أعد المحاولة', 500)
  }
}

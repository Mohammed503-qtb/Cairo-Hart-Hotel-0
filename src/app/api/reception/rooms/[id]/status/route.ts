// ─────────────────────────────────────────────────────────────
// POST /api/reception/rooms/[id]/status — تغيير حالة غرفة (v2)
// انتقالات التنظيف فقط: DIRTY→CLEANING→AVAILABLE (و DIRTY→AVAILABLE)
// OUT_OF_ORDER: تبديل من/إلى AVAILABLE — يُمنع تغيير غرفة مشغولة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { ApiError } from '../../../_helpers'

export const dynamic = 'force-dynamic'

/** الانتقالات المسموحة (تنظيف + خارج/داخل الخدمة) */
const ALLOWED: Record<string, string[]> = {
  DIRTY: ['CLEANING', 'AVAILABLE'],
  CLEANING: ['AVAILABLE'],
  AVAILABLE: ['OUT_OF_ORDER'],
  OUT_OF_ORDER: ['AVAILABLE'],
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const staffName = (guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>).staffName

  const { id } = await params
  const body = await readBody<{ status?: string; notes?: string }>(req)
  const status = typeof body?.status === 'string' ? body.status.toUpperCase() : ''
  const notes = typeof body?.notes === 'string' ? body.notes.trim() : ''

  if (!status) return fail('حدد الحالة الجديدة للغرفة')

  try {
    const result = await db.$transaction(async (tx) => {
      const room = await tx.room.findUnique({ where: { id } })
      if (!room) throw new ApiError('الغرفة غير موجودة', 404)

      if (room.status === 'OCCUPIED') throw new ApiError('لا يمكن تغيير حالة غرفة مشغولة — سجّل الخروج أولًا')
      if (room.status === 'RESERVED') throw new ApiError('لا يمكن تغيير حالة غرفة محجوزة')

      const allowedTargets = ALLOWED[room.status] ?? []
      if (!allowedTargets.includes(status)) {
        throw new ApiError(`انتقال غير مسموح (${room.status} → ${status})`)
      }

      const data: Record<string, unknown> = { status }
      if (status === 'OUT_OF_ORDER') data.notes = notes || null
      if (room.status === 'OUT_OF_ORDER' && status === 'AVAILABLE') data.notes = null

      const updated = await tx.room.update({ where: { id }, data: data as never })

      await audit(tx, {
        action: 'ROOM_CHANGED',
        entityType: 'Room',
        entityId: id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { from: room.status, to: status, room: room.number, notes },
      })

      return updated
    })

    await emitEvent(wsRooms.reception, WS_EVENTS.ROOM_STATUS, {
      roomId: id,
      roomNumber: result.number,
      status: result.status,
    })

    return ok({
      room: {
        id: result.id,
        number: result.number,
        floor: result.floor,
        status: result.status,
        notes: result.notes,
      },
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('room status failed', e)
    return fail('حدث خطأ أثناء تغيير حالة الغرفة — أعد المحاولة', 500)
  }
}

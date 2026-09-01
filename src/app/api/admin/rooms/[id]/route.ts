// ─────────────────────────────────────────────────────────────
// PATCH/DELETE /api/admin/rooms/[id]
// PATCH: ممنوع ضبط OCCUPIED يدويًا — تسجيل الوصول فقط
// تغيير الحالة → emitEvent(reception, ROOM_STATUS)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { asString, asInt, MANUALLY_SETTABLE_ROOM_STATUSES } from '../../_shared'

export const dynamic = 'force-dynamic'

export async function PATCH(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const room = await db.room.findUnique({ where: { id }, include: { roomType: { select: { name: true } } } })
  if (!room) return fail('الغرفة غير موجودة', 404)

  const body = await readBody<Record<string, unknown>>(req)
  if (!body) return fail('طلب غير صالح')

  const data: Record<string, string | number | null> = {}
  const changed: string[] = []
  let newStatus: string | null = null

  const floor = asInt(body.floor)
  if (floor !== undefined) {
    if (floor < 1 || floor > 30) return fail('الطابق يجب أن يكون بين 1 و 30')
    if (floor !== room.floor) { data.floor = floor; changed.push('floor') }
  }

  const roomTypeId = asString(body.roomTypeId)
  if (roomTypeId !== undefined) {
    const type = await db.roomType.findUnique({ where: { id: roomTypeId } })
    if (!type) return fail('نوع الغرفة غير موجود', 404)
    if (roomTypeId !== room.roomTypeId) { data.roomTypeId = roomTypeId; changed.push('roomType') }
  }

  const status = asString(body.status)
  if (status !== undefined) {
    if (status === 'OCCUPIED') {
      return fail('لا يمكن ضبط الغرفة «مشغولة» يدويًا — الحجز يتم عبر تسجيل الوصول من الاستقبال')
    }
    if (!(MANUALLY_SETTABLE_ROOM_STATUSES as readonly string[]).includes(status)) {
      return fail('حالة غرفة غير صالحة')
    }
    if (status !== room.status) { data.status = status; changed.push('status'); newStatus = status }
  }

  const notes = asString(body.notes)
  if (notes !== undefined && notes !== (room.notes ?? '')) { data.notes = notes; changed.push('notes') }

  if (Object.keys(data).length === 0) return ok({ room })

  const updated = await db.room.update({ where: { id }, data })

  await audit(db, {
    action: 'ROOM_CHANGED',
    entityType: 'Room',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'UPDATE', room: room.number, changed },
  })

  if (newStatus) {
    await emitEvent(wsRooms.reception, WS_EVENTS.ROOM_STATUS, {
      roomId: id,
      number: updated.number,
      status: newStatus,
      by: staffName,
    })
  }

  const type = await db.roomType.findUnique({ where: { id: updated.roomTypeId }, select: { name: true } })
  return ok({
    room: {
      id: updated.id,
      number: updated.number,
      floor: updated.floor,
      status: updated.status,
      notes: updated.notes,
      roomTypeId: updated.roomTypeId,
      roomTypeName: type?.name ?? room.roomType.name,
      guestName: null,
      expectedCheckOut: null,
      createdAt: updated.createdAt,
    },
    changedFields: changed,
  })
}

export async function DELETE(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>
  const { id } = await ctx.params

  const room = await db.room.findUnique({ where: { id }, include: { _count: { select: { stays: true } } } })
  if (!room) return fail('الغرفة غير موجودة', 404)

  if (room._count.stays > 0) {
    return fail(`لا يمكن حذف الغرفة ${room.number} لوجود سجل إقامات مرتبطة بها — استخدم حالة «خارج الخدمة» بدلًا من الحذف`)
  }

  await db.room.delete({ where: { id } })
  await audit(db, {
    action: 'ROOM_CHANGED',
    entityType: 'Room',
    entityId: id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { op: 'DELETE', room: room.number },
  })
  return ok({ deleted: true, message: `تم حذف الغرفة ${room.number} نهائيًا` })
}

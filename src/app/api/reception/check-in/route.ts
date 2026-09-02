// ─────────────────────────────────────────────────────────────
// POST /api/reception/check-in — تسجيل الوصول (العملية الأهم)
// معاملة ذرية: تحقق حجز/غرفة → إقامة → إشغال → كود ضيف → تدقيق ×3 → إشعار
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { generateCode, hashCode, maskCode } from '@/lib/codes'
import { nextStayReference } from '@/lib/refs'
import { audit } from '@/lib/audit'
import { emitEvent, wsRooms, WS_EVENTS } from '@/lib/events'
import { ApiError, endOfDay } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const auth = guard.auth as Extract<AuthContext, { role: 'RECEPTION' | 'ADMIN' }>
  const staffName = auth.staffName

  let body: { reservationId?: string; roomId?: string; idNumber?: string } | null = null
  try {
    body = (await req.json()) as { reservationId?: string; roomId?: string; idNumber?: string }
  } catch {
    body = null
  }
  const reservationId = typeof body?.reservationId === 'string' ? body.reservationId : ''
  const roomId = typeof body?.roomId === 'string' ? body.roomId : ''
  const idNumberRaw = typeof body?.idNumber === 'string' ? body.idNumber.trim() : ''

  if (!reservationId || !roomId) return fail('بيانات ناقصة — حدد الحجز والغرفة')

  try {
    const result = await db.$transaction(async (tx) => {
      // 1) الحجز — يجب أن يكون مؤكدًا
      const reservation = await tx.reservation.findUnique({
        where: { id: reservationId },
        include: { guest: true },
      })
      if (!reservation) throw new ApiError('الحجز غير موجود', 404)
      if (reservation.status !== 'CONFIRMED') throw new ApiError('الحجز ليس بحالة مؤكدة')

      // 2) الغرفة — نفس النوع + متاحة (إعادة فحص التوفر داخل المعاملة)
      const room = await tx.room.findUnique({ where: { id: roomId } })
      if (!room) throw new ApiError('الغرفة غير موجودة', 404)
      if (room.roomTypeId !== reservation.roomTypeId || room.status !== 'AVAILABLE') {
        throw new ApiError('الغرفة غير متاحة أو لا تطابق نوع الحجز')
      }

      // 3) تحديث الحجز + رقم هوية الضيف إن أُرسل
      await tx.reservation.update({
        where: { id: reservation.id },
        data: { status: 'CHECKED_IN' },
      })
      if (idNumberRaw) {
        await tx.guest.update({
          where: { id: reservation.guestId },
          data: { idNumber: idNumberRaw },
        })
      }

      // 4) إنشاء الإقامة
      const reference = await nextStayReference(tx)
      const expectedCheckOutAt = endOfDay(reservation.checkOut)
      const stay = await tx.stay.create({
        data: {
          reference,
          reservationId: reservation.id,
          guestId: reservation.guestId,
          roomId: room.id,
          checkInAt: new Date(),
          expectedCheckOutAt,
          status: 'ACTIVE',
        },
      })

      // 5) إشغال الغرفة
      await tx.room.update({ where: { id: room.id }, data: { status: 'OCCUPIED' } })

      // 6) توليد كود الضيف — الخام يُعاد مرة واحدة فقط
      const rawCode = generateCode('GUEST')
      await tx.accessCode.create({
        data: {
          codeHash: hashCode(rawCode),
          codeMasked: maskCode(rawCode),
          type: 'GUEST',
          stayId: stay.id,
          expiresAt: expectedCheckOutAt,
          status: 'ACTIVE',
        },
      })

      // 7) تدقيق ×3
      await audit(tx, {
        action: 'CHECK_IN',
        entityType: 'Stay',
        entityId: stay.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { room: room.number, reference, reservation: reservation.bookingReference },
      })
      await audit(tx, {
        action: 'ROOM_ASSIGNED',
        entityType: 'Room',
        entityId: room.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { room: room.number, stayId: stay.id, guest: reservation.guest.fullName },
      })
      await audit(tx, {
        action: 'CODE_GENERATED',
        entityType: 'AccessCode',
        entityId: stay.id,
        actor: staffName,
        actorRole: 'RECEPTION',
        details: { type: 'GUEST', stayId: stay.id, masked: maskCode(rawCode) },
      })

      // 8) إشعار ترحيب للضيف
      await tx.notification.create({
        data: {
          audience: 'GUEST',
          stayId: stay.id,
          type: 'WELCOME',
          title: 'أهلًا بك في فندق قلب القاهرة',
          body: `غرفتك ${room.number} جاهزة`,
        },
      })

      return { stay, room, rawCode, guestName: reservation.guest.fullName, guestPhone: reservation.guest.phone }
    })

    // بعد المعاملة — بث فوري (best-effort)
    await emitEvent(wsRooms.reception, WS_EVENTS.STAY_UPDATED, {
      stayId: result.stay.id,
      roomNumber: result.room.number,
      kind: 'CHECK_IN',
    })
    await emitEvent(wsRooms.stay(result.stay.id), WS_EVENTS.NOTIFICATION_NEW, {
      title: 'أهلًا بك في فندق قلب القاهرة',
    })

    return ok({
      stay: { id: result.stay.id, reference: result.stay.reference },
      roomNumber: result.room.number,
      guestCode: result.rawCode,
      guestName: result.guestName,
      guestPhone: result.guestPhone,
    })
  } catch (e) {
    if (e instanceof ApiError) return fail(e.message, e.status)
    console.error('check-in failed', e)
    return fail('حدث خطأ أثناء تسجيل الوصول — أعد المحاولة', 500)
  }
}

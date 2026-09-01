// ─────────────────────────────────────────────────────────────
// GET /api/reception/stays/[id] — تفاصيل إقامة كاملة
// الضيف + الغرفة + الحجز (مع لقطة السعر) + الفاتورة + الطلبات
// + طلبات التمديد/تغيير الغرفة + آخر الرسائل
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { buildBill } from '../../_helpers'

export const dynamic = 'force-dynamic'

function parseSnapshot(raw: string): Record<string, unknown> {
  try {
    const parsed = JSON.parse(raw)
    return typeof parsed === 'object' && parsed !== null ? (parsed as Record<string, unknown>) : {}
  } catch {
    return {}
  }
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { id } = await params

  const stay = await db.stay.findUnique({
    where: { id },
    include: {
      guest: true,
      room: { include: { roomType: true } },
      reservation: true,
      serviceRequests: {
        include: { updates: { orderBy: { createdAt: 'asc' } } },
        orderBy: { createdAt: 'desc' },
      },
      extensionRequests: { orderBy: { createdAt: 'desc' } },
      roomChangeRequests: { orderBy: { createdAt: 'desc' } },
      messages: { orderBy: { createdAt: 'desc' }, take: 5 },
    },
  })
  if (!stay) return fail('الإقامة غير موجودة', 404)

  const bill = await buildBill(db, stay.id)
  const messages = [...stay.messages].reverse()

  return ok({
    stay: {
      id: stay.id,
      reference: stay.reference,
      status: stay.status,
      checkInAt: stay.checkInAt.toISOString(),
      expectedCheckOutAt: stay.expectedCheckOutAt.toISOString(),
      actualCheckOutAt: stay.actualCheckOutAt?.toISOString() ?? null,
    },
    guest: {
      id: stay.guest.id,
      fullName: stay.guest.fullName,
      phone: stay.guest.phone,
      whatsapp: stay.guest.whatsapp,
      email: stay.guest.email,
      idNumber: stay.guest.idNumber,
      nationality: stay.guest.nationality,
    },
    room: {
      id: stay.room.id,
      number: stay.room.number,
      floor: stay.room.floor,
      status: stay.room.status,
      notes: stay.room.notes,
    },
    roomType: {
      id: stay.room.roomType.id,
      name: stay.room.roomType.name,
      bedConfig: stay.room.roomType.bedConfig,
      sizeSqm: stay.room.roomType.sizeSqm,
    },
    reservation: {
      id: stay.reservation.id,
      bookingReference: stay.reservation.bookingReference,
      status: stay.reservation.status,
      source: stay.reservation.source,
      checkIn: stay.reservation.checkIn.toISOString(),
      checkOut: stay.reservation.checkOut.toISOString(),
      adults: stay.reservation.adults,
      children: stay.reservation.children,
      roomsCount: stay.reservation.roomsCount,
      currency: stay.reservation.currency,
      subtotalCents: stay.reservation.subtotalCents,
      taxCents: stay.reservation.taxCents,
      grandTotalCents: stay.reservation.grandTotalCents,
      paidCents: stay.reservation.paidCents,
      paymentStatus: stay.reservation.paymentStatus,
      paymentMethod: stay.reservation.paymentMethod,
      specialRequests: stay.reservation.specialRequests,
      priceSnapshot: parseSnapshot(stay.reservation.priceSnapshot),
    },
    bill,
    requests: stay.serviceRequests.map((r) => ({
      id: r.id,
      reference: r.reference,
      category: r.category,
      title: r.title,
      description: r.description,
      priority: r.priority,
      status: r.status,
      assignedTo: r.assignedTo,
      createdAt: r.createdAt.toISOString(),
      updatedAt: r.updatedAt.toISOString(),
      completedAt: r.completedAt?.toISOString() ?? null,
      updates: r.updates.map((u) => ({
        id: u.id,
        status: u.status,
        note: u.note,
        byName: u.byName,
        byRole: u.byRole,
        createdAt: u.createdAt.toISOString(),
      })),
    })),
    extensionRequests: stay.extensionRequests.map((e) => ({
      id: e.id,
      newCheckOut: e.newCheckOut.toISOString(),
      nights: e.nights,
      priceCents: e.priceCents,
      note: e.note,
      status: e.status,
      decidedBy: e.decidedBy,
      decidedAt: e.decidedAt?.toISOString() ?? null,
      createdAt: e.createdAt.toISOString(),
    })),
    roomChangeRequests: stay.roomChangeRequests.map((c) => ({
      id: c.id,
      toRoomId: c.toRoomId,
      toRoomNumber: c.toRoomNumber,
      priceDiffCents: c.priceDiffCents,
      reason: c.reason,
      status: c.status,
      decidedBy: c.decidedBy,
      decidedAt: c.decidedAt?.toISOString() ?? null,
      createdAt: c.createdAt.toISOString(),
    })),
    messages: messages.map((m) => ({
      id: m.id,
      sender: m.sender,
      senderName: m.senderName,
      body: m.body,
      createdAt: m.createdAt.toISOString(),
    })),
  })
}

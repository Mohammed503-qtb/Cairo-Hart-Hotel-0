// ─────────────────────────────────────────────────────────────
// GET /api/reception/rooms — كل الغرف + ضيف الإقامة النشطة إن وجدت
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const [rooms, activeStays] = await Promise.all([
    db.room.findMany({ include: { roomType: { select: { id: true, name: true } } } }),
    db.stay.findMany({
      where: { status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] } },
      include: { guest: { select: { fullName: true } }, room: { select: { id: true } } },
    }),
  ])

  const stayByRoom = new Map(activeStays.map((s) => [s.roomId, s]))

  const sorted = [...rooms].sort(
    (a, b) => a.floor - b.floor || a.number.localeCompare(b.number, 'ar', { numeric: true })
  )

  return ok({
    rooms: sorted.map((r) => {
      const stay = stayByRoom.get(r.id)
      return {
        id: r.id,
        number: r.number,
        floor: r.floor,
        status: r.status,
        notes: r.notes,
        roomTypeId: r.roomTypeId,
        roomTypeName: r.roomType.name,
        guestName: stay?.guest.fullName ?? null,
        expectedCheckOutAt: stay?.expectedCheckOutAt.toISOString() ?? null,
        activeStayId: stay?.id ?? null,
      }
    }),
  })
}

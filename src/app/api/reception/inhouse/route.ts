// ─────────────────────────────────────────────────────────────
// GET /api/reception/inhouse — الإقامات النشطة (المقيمون الآن)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { chargesTotal, computeBalance } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const stays = await db.stay.findMany({
    where: { status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] } },
    include: {
      guest: true,
      room: { include: { roomType: true } },
      reservation: true,
      charges: true,
      serviceRequests: { where: { status: { in: ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING'] } }, select: { id: true } },
    },
    orderBy: { checkInAt: 'desc' },
  })

  const sorted = [...stays].sort((a, b) => a.room.number.localeCompare(b.room.number, 'ar', { numeric: true }))

  return ok({
    stays: sorted.map((s) => ({
      id: s.id,
      reference: s.reference,
      status: s.status,
      checkInAt: s.checkInAt.toISOString(),
      expectedCheckOutAt: s.expectedCheckOutAt.toISOString(),
      guest: { fullName: s.guest.fullName, phone: s.guest.phone },
      room: { number: s.room.number, floor: s.room.floor },
      roomType: { name: s.room.roomType.name },
      activeRequests: s.serviceRequests.length,
      balanceCents: computeBalance(s.reservation, chargesTotal(s.charges)),
      reservation: {
        grandTotalCents: s.reservation.grandTotalCents,
        paidCents: s.reservation.paidCents,
        paymentStatus: s.reservation.paymentStatus,
      },
    })),
  })
}

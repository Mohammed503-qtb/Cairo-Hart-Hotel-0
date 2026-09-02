// ─────────────────────────────────────────────────────────────
// GET /api/reception/departures?date=YYYY-MM-DD — المغادرون
// إقامات مستحقة بالتاريخ + المتأخرة (لم تُغلق بعد)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { startOfDay, endOfDay, parseDateParam, chargesTotal, computeBalance } from '../_helpers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const date = parseDateParam(req.nextUrl.searchParams.get('date')) ?? startOfDay(new Date())
  const dayStart = startOfDay(date)
  const dayEnd = endOfDay(date)

  const stays = await db.stay.findMany({
    where: {
      status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] },
      OR: [
        { expectedCheckOutAt: { gte: dayStart, lte: dayEnd } }, // مستحقة بالتاريخ
        { expectedCheckOutAt: { lt: dayStart } }, // متأخرة
      ],
    },
    include: {
      guest: true,
      room: { include: { roomType: true } },
      reservation: true,
      charges: true,
      serviceRequests: { where: { status: { in: ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING'] } }, select: { id: true } },
    },
    orderBy: { expectedCheckOutAt: 'asc' },
  })

  return ok({
    date: dayStart.toISOString(),
    departures: stays.map((s) => ({
      id: s.id,
      reference: s.reference,
      status: s.status,
      guestName: s.guest.fullName,
      guestPhone: s.guest.phone,
      roomNumber: s.room.number,
      roomTypeName: s.room.roomType.name,
      checkInAt: s.checkInAt.toISOString(),
      expectedCheckOutAt: s.expectedCheckOutAt.toISOString(),
      balanceCents: computeBalance(s.reservation, chargesTotal(s.charges)),
      activeRequests: s.serviceRequests.length,
      overdue: s.expectedCheckOutAt.getTime() < dayStart.getTime(),
    })),
  })
}

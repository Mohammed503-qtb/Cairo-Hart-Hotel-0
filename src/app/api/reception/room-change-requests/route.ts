// ─────────────────────────────────────────────────────────────
// GET /api/reception/room-change-requests — طلبات تغيير الغرفة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const requests = await db.roomChangeRequest.findMany({
    include: {
      stay: {
        include: {
          guest: { select: { fullName: true } },
          room: { select: { number: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  })

  return ok({
    requests: requests.map((c) => ({
      id: c.id,
      toRoomId: c.toRoomId,
      toRoomNumber: c.toRoomNumber,
      priceDiffCents: c.priceDiffCents,
      reason: c.reason,
      status: c.status,
      decidedBy: c.decidedBy,
      decidedAt: c.decidedAt?.toISOString() ?? null,
      createdAt: c.createdAt.toISOString(),
      stay: {
        id: c.stay.id,
        reference: c.stay.reference,
        roomNumber: c.stay.room?.number ?? '—',
        guestName: c.stay.guest?.fullName ?? '—',
        stayStatus: c.stay.status,
      },
    })),
  })
}

// ─────────────────────────────────────────────────────────────
// GET /api/reception/extension-requests — طلبات تمديد الإقامة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const requests = await db.extensionRequest.findMany({
    include: {
      stay: {
        include: {
          guest: { select: { fullName: true } },
          room: { select: { number: true } },
          reservation: { select: { checkOut: true, roomTypeId: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  })

  return ok({
    requests: requests.map((e) => ({
      id: e.id,
      newCheckOut: e.newCheckOut.toISOString(),
      nights: e.nights,
      priceCents: e.priceCents,
      note: e.note,
      status: e.status,
      decidedBy: e.decidedBy,
      decidedAt: e.decidedAt?.toISOString() ?? null,
      createdAt: e.createdAt.toISOString(),
      stay: {
        id: e.stay.id,
        reference: e.stay.reference,
        roomNumber: e.stay.room?.number ?? '—',
        guestName: e.stay.guest?.fullName ?? '—',
        expectedCheckOutAt: e.stay.expectedCheckOutAt.toISOString(),
        stayStatus: e.stay.status,
      },
    })),
  })
}

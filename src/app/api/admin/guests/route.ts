// ─────────────────────────────────────────────────────────────
// GET /api/admin/guests?q= — الضيوف + عدد الحجوزات + آخر حجز
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { searchParams } = new URL(req.url)
  const q = (searchParams.get('q') ?? '').trim()

  const where = q
    ? { OR: [{ fullName: { contains: q } }, { phone: { contains: q } }, { email: { contains: q } }] }
    : {}

  const guests = await db.guest.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    include: {
      _count: { select: { reservations: true } },
      reservations: { orderBy: { createdAt: 'desc' }, take: 1, select: { bookingReference: true, checkIn: true, status: true } },
    },
  })

  return ok({
    guests: guests.map((g) => ({
      id: g.id,
      fullName: g.fullName,
      phone: g.phone,
      email: g.email,
      nationality: g.nationality,
      createdAt: g.createdAt,
      reservationsCount: g._count.reservations,
      lastReservation: g.reservations[0]
        ? {
            bookingReference: g.reservations[0].bookingReference,
            checkIn: g.reservations[0].checkIn,
            status: g.reservations[0].status,
          }
        : null,
    })),
  })
}

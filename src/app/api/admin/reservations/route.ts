// ─────────────────────────────────────────────────────────────
// GET /api/admin/reservations?status=&q=&page=&limit=
// قائمة الحجوزات paginated مع فلاتر وبحث
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { Prisma } from '@prisma/client'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { searchParams } = new URL(req.url)
  const status = searchParams.get('status') ?? ''
  const q = (searchParams.get('q') ?? '').trim()
  const page = Math.max(1, parseInt(searchParams.get('page') ?? '1', 10) || 1)
  const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') ?? '20', 10) || 20))

  const where: Prisma.ReservationWhereInput = {}
  if (['PENDING', 'CONFIRMED', 'CANCELLED', 'CHECKED_IN', 'COMPLETED', 'NO_SHOW', 'EXPIRED'].includes(status)) {
    where.status = status
  }
  if (q) {
    where.OR = [
      { bookingReference: { contains: q } },
      { guest: { fullName: { contains: q } } },
      { guest: { phone: { contains: q } } },
    ]
  }

  const [total, reservations] = await Promise.all([
    db.reservation.count({ where }),
    db.reservation.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        guest: { select: { fullName: true, phone: true } },
        roomType: { select: { name: true } },
        stay: { select: { id: true } },
      },
    }),
  ])

  return ok({
    items: reservations.map((r) => ({
      id: r.id,
      reference: r.bookingReference,
      guestName: r.guest.fullName,
      guestPhone: r.guest.phone,
      roomTypeName: r.roomType.name,
      checkIn: r.checkIn,
      checkOut: r.checkOut,
      nights: Math.max(0, Math.round((r.checkOut.getTime() - r.checkIn.getTime()) / 86_400_000)),
      adults: r.adults,
      children: r.children,
      grandTotalCents: r.grandTotalCents,
      paidCents: r.paidCents,
      paymentStatus: r.paymentStatus,
      status: r.status,
      source: r.source,
      createdAt: r.createdAt,
      stayId: r.stay?.id ?? null,
    })),
    total,
    page,
    limit,
    pages: Math.max(1, Math.ceil(total / limit)),
  })
}

// ─────────────────────────────────────────────────────────────
// GET /api/reception/search?q= — بحث عام (حجوزات + إقامات نشطة)
// بالمرجع أو اسم الضيف أو الهاتف أو رقم الغرفة
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const q = (req.nextUrl.searchParams.get('q') ?? '').trim()
  if (q.length < 2) return ok({ reservations: [], stays: [] })

  // تنويعات الحالة (SQLite حساس لحالة الأحرف) — كل contains على حدة عبر OR
  const variants = Array.from(new Set([q, q.toUpperCase(), q.toLowerCase()]))
  const refOrGuest = [
    ...variants.map((v) => ({ bookingReference: { contains: v } })),
    ...variants.map((v) => ({ guest: { fullName: { contains: v } } })),
    ...variants.map((v) => ({ guest: { phone: { contains: v } } })),
  ]
  const stayMatches = [
    ...variants.map((v) => ({ reference: { contains: v } })),
    ...variants.map((v) => ({ guest: { fullName: { contains: v } } })),
    ...variants.map((v) => ({ guest: { phone: { contains: v } } })),
    ...variants.map((v) => ({ room: { number: { contains: v } } })),
  ]

  const [reservations, stays] = await Promise.all([
    db.reservation.findMany({
      where: { OR: refOrGuest },
      include: {
        guest: { select: { fullName: true, phone: true } },
        roomType: { select: { name: true } },
        stay: { select: { id: true, status: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 10,
    }),
    db.stay.findMany({
      where: {
        status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] },
        OR: stayMatches,
      },
      include: {
        guest: { select: { fullName: true, phone: true } },
        room: { include: { roomType: { select: { name: true } } } },
      },
      orderBy: { checkInAt: 'desc' },
      take: 10,
    }),
  ])

  return ok({
    reservations: reservations.map((r) => ({
      id: r.id,
      bookingReference: r.bookingReference,
      guestName: r.guest.fullName,
      guestPhone: r.guest.phone,
      status: r.status,
      checkIn: r.checkIn.toISOString(),
      checkOut: r.checkOut.toISOString(),
      roomTypeName: r.roomType.name,
      paymentStatus: r.paymentStatus,
      stayId: r.stay?.id ?? null,
    })),
    stays: stays.map((s) => ({
      id: s.id,
      reference: s.reference,
      guestName: s.guest.fullName,
      guestPhone: s.guest.phone,
      roomNumber: s.room.number,
      roomTypeName: s.room.roomType.name,
      status: s.status,
      expectedCheckOutAt: s.expectedCheckOutAt.toISOString(),
    })),
  })
}

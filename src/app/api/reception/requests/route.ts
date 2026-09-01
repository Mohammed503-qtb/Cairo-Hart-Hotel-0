// ─────────────────────────────────────────────────────────────
// GET /api/reception/requests?status=&priority= — طلبات الإقامات
// النشطة + المغلقة خلال آخر 7 أيام — الأحدث أولًا والعاجل أولًا
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { startOfDay, addDays } from '../_helpers'

export const dynamic = 'force-dynamic'

const PENDING = ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING']

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const statusParam = req.nextUrl.searchParams.get('status') ?? ''
  const priorityParam = req.nextUrl.searchParams.get('priority') ?? ''
  const weekAgo = addDays(new Date(), -7)

  const where: Record<string, unknown> = {
    stay: {
      OR: [
        { status: { in: ['ACTIVE', 'CHECKOUT_REQUESTED'] } },
        { status: 'CLOSED', actualCheckOutAt: { gte: weekAgo } },
      ],
    },
  }
  if (statusParam === 'PENDING') {
    where.status = { in: PENDING }
  } else if (statusParam && statusParam !== 'ALL') {
    where.status = statusParam
  }
  if (priorityParam && priorityParam !== 'ALL') {
    where.priority = priorityParam
  }

  const requests = await db.serviceRequest.findMany({
    where: where as never,
    include: {
      stay: { include: { room: true, guest: true } },
      updates: { orderBy: { createdAt: 'asc' } },
    },
    orderBy: { createdAt: 'desc' },
    take: 200,
  })

  // الأحدث أولًا (باليوم) — والعاجل أولًا داخل اليوم نفسه
  const sorted = [...requests].sort((a, b) => {
    const dayA = startOfDay(a.createdAt).getTime()
    const dayB = startOfDay(b.createdAt).getTime()
    if (dayB !== dayA) return dayB - dayA
    if (a.priority !== b.priority) return a.priority === 'URGENT' ? -1 : 1
    return b.createdAt.getTime() - a.createdAt.getTime()
  })

  return ok({
    requests: sorted.map((r) => ({
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
      stay: {
        id: r.stay.id,
        reference: r.stay.reference,
        roomNumber: r.stay.room?.number ?? '—',
        guestName: r.stay.guest?.fullName ?? '—',
      },
      updates: r.updates.map((u) => ({
        id: u.id,
        status: u.status,
        note: u.note,
        byName: u.byName,
        byRole: u.byRole,
        createdAt: u.createdAt.toISOString(),
      })),
    })),
  })
}

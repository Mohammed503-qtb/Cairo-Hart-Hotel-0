// ─────────────────────────────────────────────────────────────
// GET /api/reception/billing/[stayId] — فاتورة الإقامة (نفس شكل الضيف)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { ok, fail } from '@/lib/api'
import { requireRole } from '@/lib/auth'
import { db } from '@/lib/db'
import { buildBill } from '../../_helpers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest, { params }: { params: Promise<{ stayId: string }> }) {
  const guard = await requireRole(req, 'RECEPTION', 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  const { stayId } = await params

  const stayExists = await db.stay.findUnique({ where: { id: stayId }, select: { id: true } })
  if (!stayExists) return fail('الإقامة غير موجودة', 404)

  const bill = await buildBill(db, stayId)
  if (!bill) return fail('تعذر بناء الفاتورة', 500)

  return ok({ bill })
}

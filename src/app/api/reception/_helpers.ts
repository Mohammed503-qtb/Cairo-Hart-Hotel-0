// ─────────────────────────────────────────────────────────────
// RECEPTION API HELPERS — مشترك بين مسارات الاستقبال
// حدود الأيام المحلية + حساب الرصيد + بناء الفاتورة + أخطاء HTTP
// ─────────────────────────────────────────────────────────────
import { NextResponse } from 'next/server'
import type { Prisma } from '@prisma/client'
import type { BillPublic, BillLine } from '@/types'

/** خطأ قابل للتحويل لاستجابة API داخل المعاملات */
export class ApiError extends Error {
  status: number
  extra: Record<string, unknown>
  constructor(message: string, status = 400, extra: Record<string, unknown> = {}) {
    super(message)
    this.status = status
    this.extra = extra
  }
}

/** فشل مع بيانات إضافية (مثل balanceCents) */
export function failWith(error: string, status = 400, extra: Record<string, unknown> = {}) {
  return NextResponse.json({ ok: false, error, ...extra }, { status })
}

export function startOfDay(d: Date | string): Date {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x
}

export function endOfDay(d: Date | string): Date {
  const x = new Date(d)
  x.setHours(23, 59, 59, 999)
  return x
}

export function addDays(d: Date | string, n: number): Date {
  const x = new Date(d)
  x.setDate(x.getDate() + n)
  return x
}

/** تحليل باراميتر تاريخ YYYY-MM-DD — يرجع null إن كان غير صالح */
export function parseDateParam(v: string | null): Date | null {
  if (!v || !/^\d{4}-\d{2}-\d{2}$/.test(v.trim())) return null
  const d = new Date(`${v.trim()}T00:00:00`)
  return Number.isNaN(d.getTime()) ? null : d
}

type Tx = Prisma.TransactionClient

/** رصيد الإقامة = إجمالي الحجز + البنود الإضافية − المدفوع */
export function computeBalance(
  reservation: { grandTotalCents: number; paidCents: number },
  chargesTotalCents: number
): number {
  return reservation.grandTotalCents + chargesTotalCents - reservation.paidCents
}

/** إجمالي بنود إقامة */
export function chargesTotal(charges: { amountCents: number }[]): number {
  return charges.reduce((a, c) => a + c.amountCents, 0)
}

/** بناء فاتورة موحدة (نفس شكل BillPublic للضيف) */
export async function buildBill(tx: Tx, stayId: string): Promise<BillPublic | null> {
  const stay = await tx.stay.findUnique({
    where: { id: stayId },
    include: {
      reservation: true,
      charges: { orderBy: { createdAt: 'asc' } },
    },
  })
  if (!stay) return null

  const payments = await tx.payment.findMany({
    where: { reservationId: stay.reservationId },
    orderBy: { createdAt: 'asc' },
  })

  const extraCharges: BillLine[] = stay.charges.map((c) => ({
    description: c.description,
    amountCents: c.amountCents,
    category: c.category,
    date: c.createdAt.toISOString(),
  }))
  const extraTotalCents = chargesTotal(stay.charges)
  const roomTotalCents = stay.reservation.grandTotalCents
  const totalChargesCents = roomTotalCents + extraTotalCents
  const totalPaidCents = stay.reservation.paidCents

  return {
    stayId: stay.id,
    stayReference: stay.reference,
    roomTotalCents,
    roomSubtotalCents: stay.reservation.subtotalCents,
    roomTaxCents: stay.reservation.taxCents,
    extraCharges,
    extraTotalCents,
    payments: payments.map((p) => ({
      id: p.id,
      method: p.method,
      amountCents: p.amountCents,
      createdAt: p.createdAt.toISOString(),
      recordedBy: p.recordedBy,
    })),
    totalChargesCents,
    totalPaidCents,
    balanceCents: totalChargesCents - totalPaidCents,
    currency: stay.reservation.currency,
  }
}

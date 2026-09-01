'use client'

// ─────────────────────────────────────────────────────────────
// GUEST BILL — تبويب الفاتورة
// الشحنات + المدفوعات + الإجماليات + طلب تسجيل الخروج
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { ArrowUpRight, CreditCard, Receipt, ReceiptText, Wallet } from 'lucide-react'
import { useGuest } from './guest-context'
import { EmptyState, SectionTitle, pageMotion } from './bits'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { api } from '@/lib/api-client'
import { formatMoney, formatDateAr, CHARGE_CATEGORY_LABELS, PAYMENT_METHOD_LABELS } from '@/lib/format'
import { cn } from '@/lib/utils'
import type { GuestBillData } from './types'

export default function GuestBill() {
  const guest = useGuest()
  const [bill, setBill] = useState<GuestBillData | null>(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api<{ bill: GuestBillData }>('/api/guest/bill')
      setBill(res.bill)
    } catch {
      setBill(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const requestedCheckout = guest.dashboard?.stay.status === 'CHECKOUT_REQUESTED'

  if (loading && !bill) {
    return (
      <div className="space-y-4" aria-busy="true" aria-label="جارٍ تحميل الفاتورة">
        <Skeleton className="h-40 rounded-2xl" />
        <Skeleton className="h-52 rounded-2xl" />
        <Skeleton className="h-36 rounded-2xl" />
      </div>
    )
  }
  if (!bill) {
    return (
      <EmptyState
        icon={<ReceiptText className="h-6 w-6" aria-hidden />}
        title="تعذر تحميل الفاتورة"
        hint="حدث خطأ في الاتصال — أعد المحاولة"
        action={
          <Button variant="outline" onClick={() => void load()}>
            إعادة المحاولة
          </Button>
        }
      />
    )
  }

  const paid = bill.totalPaidCents
  const balance = bill.balanceCents

  return (
    <motion.div {...pageMotion} className="space-y-5">
      {/* رأس الفاتورة */}
      <Card className="border-border/70 bg-gradient-to-bl from-primary/5 to-transparent">
        <CardContent className="flex items-center justify-between gap-3 p-4">
          <div>
            <p className="text-xs text-muted-foreground">فاتورة إقامتك</p>
            <p className="text-sm font-extrabold" dir="auto">
              {bill.stayReference} — الغرفة {bill.roomNumber}
            </p>
          </div>
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-accent text-primary">
            <ReceiptText className="h-5.5 w-5.5" aria-hidden />
          </span>
        </CardContent>
      </Card>

      {/* ─── الشحنات ─── */}
      <section aria-label="بنود الفاتورة">
        <SectionTitle icon={<Receipt className="h-4.5 w-4.5" />}>البنود</SectionTitle>
        <Card className="mt-3 overflow-hidden border-border/70">
          <div className="overflow-hidden rounded-xl border border-border/70">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-muted/60 text-xs text-muted-foreground">
                  <th scope="col" className="px-3 py-2.5 text-start font-bold">
                    البند
                  </th>
                  <th scope="col" className="px-3 py-2.5 text-start font-bold">
                    التاريخ
                  </th>
                  <th scope="col" className="px-3 py-2.5 text-end font-bold">
                    المبلغ
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-t border-border/60 bg-accent/40">
                  <td className="px-3 py-3 font-bold">
                    إقامة الغرفة ({bill.roomNights} {bill.roomNights === 1 ? 'ليلة' : 'ليالٍ'})
                    <span className="mt-0.5 block text-[11px] font-normal text-muted-foreground">
                      يشمل الضريبة {formatMoney(bill.roomTaxCents, bill.currency)}
                    </span>
                  </td>
                  <td className="px-3 py-3 text-xs text-muted-foreground">
                    {formatDateAr(guest.dashboard?.stay.checkInAt ?? new Date())}
                  </td>
                  <td className="px-3 py-3 text-end font-mono font-bold" dir="ltr">
                    {formatMoney(bill.roomTotalCents, bill.currency)}
                  </td>
                </tr>
                {bill.extraCharges.map((c) => (
                  <tr key={c.id} className="border-t border-border/60">
                    <td className="px-3 py-3">
                      {c.description}
                      <span className="mt-0.5 block text-[11px] text-muted-foreground">
                        {CHARGE_CATEGORY_LABELS[c.category] ?? c.category}
                      </span>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted-foreground">
                      {formatDateAr(c.date)}
                    </td>
                    <td className="px-3 py-3 text-end font-mono" dir="ltr">
                      {formatMoney(c.amountCents, bill.currency)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </section>

      {/* ─── المدفوعات ─── */}
      <section aria-label="المدفوعات">
        <SectionTitle icon={<CreditCard className="h-4.5 w-4.5" />}>المدفوعات</SectionTitle>
        {bill.payments.length === 0 ? (
          <p className="mt-3 rounded-2xl border border-dashed border-border p-4 text-center text-sm text-muted-foreground">
            لا مدفوعات مسجلة بعد
          </p>
        ) : (
          <Card className="mt-3 overflow-hidden border-border/70">
            <CardContent className="divide-y divide-border/60 p-0">
              {bill.payments.map((p) => (
                <div key={p.id} className="flex items-center justify-between gap-3 px-4 py-3">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-8 w-8 items-center justify-center rounded-full bg-success/10 text-success">
                      <Wallet className="h-4 w-4" aria-hidden />
                    </span>
                    <div>
                      <p className="text-sm font-bold">
                        {PAYMENT_METHOD_LABELS[p.method] ?? p.method}
                      </p>
                      <p className="text-[11px] text-muted-foreground">
                        {formatDateAr(p.createdAt)}
                        {p.recordedBy ? ` — ${p.recordedBy}` : ''}
                      </p>
                    </div>
                  </div>
                  <p className="font-mono text-sm font-bold text-success" dir="ltr">
                    +{formatMoney(p.amountCents, bill.currency)}
                  </p>
                </div>
              ))}
            </CardContent>
          </Card>
        )}
      </section>

      {/* ─── الإجماليات ─── */}
      <section aria-label="الإجماليات">
        <SectionTitle icon={<Wallet className="h-4.5 w-4.5" />}>الإجماليات</SectionTitle>
        <Card
          className={cn(
            'mt-3 border-border/70',
            balance > 0 ? 'border-destructive/30 bg-destructive/5' : 'border-success/30 bg-success/5'
          )}
        >
          <CardContent className="space-y-2.5 p-4">
            <TotalRow label="إجمالي المستحقات" value={formatMoney(bill.totalChargesCents, bill.currency)} />
            <TotalRow label="إجمالي المدفوع" value={formatMoney(paid, bill.currency)} tone="success" />
            <div className="border-t border-border/70 pt-2.5">
              <div className="flex items-baseline justify-between gap-3">
                <p className="text-sm font-extrabold">المتبقي</p>
                <p
                  className={cn(
                    'font-mono text-2xl font-extrabold tabular-nums',
                    balance > 0 ? 'text-destructive' : 'text-success'
                  )}
                  dir="ltr"
                >
                  {formatMoney(balance, bill.currency)}
                </p>
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {balance > 0
                  ? 'يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة'
                  : 'حسابك مسوّى — شكرًا لك 💛'}
              </p>
            </div>
          </CardContent>
        </Card>
      </section>

      {/* ─── طلب الخروج ─── */}
      <Button
        size="lg"
        onClick={() => guest.openDialog('checkout')}
        disabled={requestedCheckout}
        className={cn(
          'h-12 w-full gap-2 rounded-xl text-base font-bold',
          requestedCheckout
            ? 'bg-muted text-muted-foreground'
            : 'bg-gold text-[#2A2110] hover:bg-gold/90'
        )}
      >
        <ArrowUpRight className="h-5 w-5" aria-hidden />
        {requestedCheckout ? 'طلب الخروج قيد المعالجة' : 'طلب تسجيل الخروج'}
      </Button>
    </motion.div>
  )
}

function TotalRow({
  label,
  value,
  tone,
}: {
  label: string
  value: string
  tone?: 'success'
}) {
  return (
    <div className="flex items-baseline justify-between gap-3">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p
        className={cn(
          'font-mono text-sm font-bold tabular-nums',
          tone === 'success' ? 'text-success' : 'text-foreground'
        )}
        dir="ltr"
      >
        {value}
      </p>
    </div>
  )
}

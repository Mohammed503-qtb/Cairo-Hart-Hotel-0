'use client'

// ─────────────────────────────────────────────────────────────
// CHECK-OUT WIZARD — معالج تسجيل الخروج (3 خطوات)
// مراجعة الإقامة → تسوية الرصيد (دفعة سريعة/تأكيد مع رصيد) → تأكيد نهائي
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { ApiError } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  PlaneTakeoff,
  Loader2,
  CheckCircle2,
  AlertTriangle,
  Receipt,
  Banknote,
  SprayCan,
  KeyRound,
} from 'lucide-react'
import type { StayDetailData } from './types'
import { RefCode, MoneyAmount, StayStatusBadge } from './bits'
import { formatDateWithDayAr, nightsBetweenDates, PAYMENT_METHOD_LABELS } from '@/lib/format'

const STEP_TITLES = ['مراجعة الإقامة', 'تسوية الرصيد', 'التأكيد النهائي']

export default function CheckOutWizard({
  stayId,
  onClose,
  onDone,
}: {
  stayId: string
  onClose: () => void
  onDone: () => void
}) {
  const { toast } = useToast()
  const [step, setStep] = useState(0)
  const [detail, setDetail] = useState<StayDetailData | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [payMethod, setPayMethod] = useState('CASH')
  const [payAmount, setPayAmount] = useState('')
  const [payLoading, setPayLoading] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [closed, setClosed] = useState(false)

  const reload = useCallback(async () => {
    try {
      const res = await api<StayDetailData>(`/api/reception/stays/${stayId}`)
      setDetail(res)
      setError(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'تعذر تحميل بيانات الإقامة')
    }
  }, [stayId])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<StayDetailData>(`/api/reception/stays/${stayId}`)
        if (!cancelled) {
          setDetail(res)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل بيانات الإقامة')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [stayId])

  const balance = detail?.bill.balanceCents ?? 0

  useEffect(() => {
    if (detail && balance > 0) setPayAmount((balance / 100).toFixed(2))
  }, [detail, balance])

  const recordPayment = async () => {
    const amountCents = Math.round(parseFloat(payAmount || '0') * 100)
    if (!Number.isFinite(amountCents) || amountCents <= 0) {
      toast({ title: 'أدخل مبلغًا صحيحًا', variant: 'destructive' })
      return
    }
    setPayLoading(true)
    try {
      await api('/api/reception/payments', {
        method: 'POST',
        body: { stayId, method: payMethod, amountCents, note: 'تسوية عند الخروج' },
      })
      toast({ title: `تم تسجيل دفعة ${PAYMENT_METHOD_LABELS[payMethod]} ✅` })
      await reload()
    } catch (e) {
      toast({ title: 'تعذر تسجيل الدفعة', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setPayLoading(false)
    }
  }

  const doCheckOut = async (confirmOutstanding: boolean) => {
    setLoading(true)
    try {
      await api<{ closed: boolean; roomNumber: string; balanceCents: number }>('/api/reception/check-out', {
        method: 'POST',
        body: { stayId, confirmOutstanding },
      })
      setClosed(true)
      toast({ title: 'تم تسجيل الخروج بنجاح ✅' })
    } catch (e) {
      if (e instanceof ApiError) {
        toast({ title: 'تعذر تسجيل الخروج', description: e.message, variant: 'destructive' })
      } else {
        toast({ title: 'تعذر تسجيل الخروج', variant: 'destructive' })
      }
      await reload()
      setStep(1)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <PlaneTakeoff className="w-5 h-5 text-coral" />
            تسجيل خروج {detail ? `— ${detail.guest.fullName}` : ''}
          </DialogTitle>
          {!closed && (
            <DialogDescription>
              <span className="flex items-center gap-1.5 mt-1 flex-wrap">
                {STEP_TITLES.map((t, i) => (
                  <span
                    key={t}
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      i === step ? 'bg-coral text-white' : i < step ? 'bg-success/15 text-success' : 'bg-muted text-muted-foreground'
                    }`}
                  >
                    {i + 1}. {t}
                  </span>
                ))}
              </span>
            </DialogDescription>
          )}
        </DialogHeader>

        {error && !closed ? (
          <div className="flex items-center gap-2 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
            <AlertTriangle className="w-4 h-4" /> {error}
          </div>
        ) : null}

        {/* ── النجاح ── */}
        {closed ? (
          <div className="space-y-4 text-center py-4">
            <div className="mx-auto w-16 h-16 rounded-full bg-success/15 flex items-center justify-center">
              <CheckCircle2 className="w-10 h-10 text-success" />
            </div>
            <p className="font-extrabold text-lg">تم تسجيل الخروج ✅</p>
            <p className="text-sm text-muted-foreground">
              إقامة <RefCode className="text-foreground">{detail?.stay.reference}</RefCode> أُغلقت — الغرفة{' '}
              <b dir="ltr">{detail?.room.number}</b> تحتاج تنظيفًا — انتهت صلاحية كود الضيف
            </p>
            <Button className="w-full" onClick={onDone}>تم</Button>
          </div>
        ) : !detail ? (
          <div className="space-y-2">
            <Skeleton className="h-24 rounded-lg" />
            <Skeleton className="h-32 rounded-lg" />
          </div>
        ) : step === 0 ? (
          /* ── الخطوة 1: مراجعة ── */
          <div className="space-y-4">
            <div className="rounded-lg border bg-muted/30 divide-y text-sm">
              <Row label="الضيف">{detail.guest.fullName}</Row>
              <Row label="الغرفة">
                <b dir="ltr" className="font-black">{detail.room.number}</b> · {detail.roomType.name}
              </Row>
              <Row label="الإقامة">
                {formatDateWithDayAr(detail.stay.checkInAt)} ← {formatDateWithDayAr(detail.stay.expectedCheckOutAt)} (
                {nightsBetweenDates(detail.stay.checkInAt, detail.stay.expectedCheckOutAt)} ليالٍ)
              </Row>
              <Row label="الحالة"><StayStatusBadge status={detail.stay.status} /></Row>
            </div>

            <MiniBill detail={detail} />

            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={onClose}>إلغاء</Button>
              <Button onClick={() => setStep(1)}>متابعة</Button>
            </div>
          </div>
        ) : step === 1 ? (
          /* ── الخطوة 2: تسوية الرصيد ── */
          <div className="space-y-4">
            <MiniBill detail={detail} />

            {balance > 0 ? (
              <>
                <div className="flex items-center gap-2 rounded-lg border border-warning/50 bg-warning/10 p-3 text-sm font-bold text-[#92600a] dark:text-warning">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  يوجد رصيد غير مسدد <MoneyAmount cents={balance} /> — سجّل دفعة أو أكّد الخروج مع الرصيد
                </div>

                <div className="rounded-lg border p-3 space-y-3">
                  <p className="text-xs font-bold text-muted-foreground flex items-center gap-1.5">
                    <Banknote className="w-4 h-4" /> دفعة سريعة
                  </p>
                  <div className="flex gap-2">
                    <Select value={payMethod} onValueChange={setPayMethod}>
                      <SelectTrigger className="w-32" aria-label="طريقة الدفع">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="CASH">نقدًا</SelectItem>
                        <SelectItem value="CARD">بطاقة</SelectItem>
                        <SelectItem value="TRANSFER">حوالة</SelectItem>
                      </SelectContent>
                    </Select>
                    <input
                      type="number"
                      inputMode="decimal"
                      min="0"
                      step="0.01"
                      value={payAmount}
                      onChange={(e) => setPayAmount(e.target.value)}
                      className="flex-1 rounded-lg border border-input bg-card px-3 py-2 text-sm font-bold tabular-nums focus:outline-none focus:ring-2 focus:ring-ring"
                      dir="ltr"
                      aria-label="مبلغ الدفعة بالدولار"
                    />
                    <Button onClick={recordPayment} disabled={payLoading}>
                      {payLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : 'تسجيل'}
                    </Button>
                  </div>
                </div>

                <div className="flex flex-col sm:flex-row justify-end gap-2">
                  <Button variant="outline" onClick={() => setStep(0)}>رجوع</Button>
                  <Button
                    variant="secondary"
                    className="text-white"
                    onClick={() => setConfirmOpen(true)}
                    style={{ backgroundColor: 'var(--destructive)' }}
                  >
                    <AlertTriangle className="w-4 h-4" />
                    تأكيد الخروج مع الرصيد
                  </Button>
                  <Button onClick={() => setStep(2)} disabled={balance > 0} className="hidden" aria-hidden="true">
                    متابعة
                  </Button>
                </div>

                <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
                  <AlertDialogContent dir="rtl">
                    <AlertDialogHeader>
                      <AlertDialogTitle>تأكيد الخروج مع رصيد غير مسدد؟</AlertDialogTitle>
                      <AlertDialogDescription>
                        سيتم إغلاق إقامة {detail.guest.fullName} مع بقاء رصيد مستحق{' '}
                        <MoneyAmount cents={balance} /> على الحساب. لا يمكن تسجيل دفعات على الإقامة بعد إغلاقها.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>تراجع</AlertDialogCancel>
                      <AlertDialogAction onClick={() => doCheckOut(true)}>نعم، أكّد الخروج</AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </>
            ) : (
              <div className="flex items-center gap-2 rounded-lg border border-success/40 bg-success/10 p-3 text-sm font-bold text-success">
                <CheckCircle2 className="w-4 h-4" />
                الفاتورة مسددة بالكامل ✅ — لا رصيد مستحق
              </div>
            )}

            {balance <= 0 && (
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setStep(0)}>رجوع</Button>
                <Button onClick={() => setStep(2)}>متابعة</Button>
              </div>
            )}
          </div>
        ) : (
          /* ── الخطوة 3: التأكيد النهائي ── */
          <div className="space-y-4">
            <p className="text-sm font-bold">سيتم تنفيذ ما يلي:</p>
            <ul className="space-y-2 text-sm">
              <li className="flex items-center gap-2 rounded-lg border p-2.5">
                <PlaneTakeoff className="w-4 h-4 text-coral shrink-0" />
                إغلاق الإقامة <RefCode className="text-foreground">{detail.stay.reference}</RefCode>
              </li>
              <li className="flex items-center gap-2 rounded-lg border p-2.5">
                <SprayCan className="w-4 h-4 text-warning shrink-0" />
                الغرفة <b dir="ltr">{detail.room.number}</b> تصبح «تحتاج تنظيف»
              </li>
              <li className="flex items-center gap-2 rounded-lg border p-2.5">
                <KeyRound className="w-4 h-4 text-destructive shrink-0" />
                انتهاء صلاحية كود تطبيق الضيف فورًا
              </li>
              {balance > 0 ? (
                <li className="flex items-center gap-2 rounded-lg border border-warning/40 bg-warning/10 p-2.5 text-[#92600a] dark:text-warning">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  الخروج مع رصيد <MoneyAmount cents={balance} />
                </li>
              ) : null}
            </ul>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setStep(1)} disabled={loading}>رجوع</Button>
              <Button onClick={() => doCheckOut(balance > 0)} disabled={loading}>
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                تأكيد الخروج
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

function MiniBill({ detail }: { detail: StayDetailData }) {
  const { bill } = detail
  return (
    <div className="rounded-lg border p-3 space-y-1.5 text-sm">
      <p className="flex items-center gap-1.5 font-bold mb-1">
        <Receipt className="w-4 h-4 text-primary" /> ملخص الفاتورة
      </p>
      <div className="flex justify-between"><span className="text-muted-foreground">إجمالي الغرفة</span><MoneyAmount cents={bill.roomTotalCents} /></div>
      {bill.extraCharges.length > 0 ? (
        <div className="flex justify-between"><span className="text-muted-foreground">بنود إضافية ({bill.extraCharges.length})</span><MoneyAmount cents={bill.extraTotalCents} /></div>
      ) : null}
      <div className="flex justify-between font-bold border-t pt-1.5">
        <span>الإجمالي المستحق</span>
        <MoneyAmount cents={bill.totalChargesCents} />
      </div>
      <div className="flex justify-between"><span className="text-muted-foreground">المدفوع</span><MoneyAmount cents={bill.totalPaidCents} colored /></div>
      <div className="flex justify-between font-extrabold text-base border-t pt-1.5">
        <span>الرصيد</span>
        <MoneyAmount cents={bill.balanceCents} colored />
      </div>
    </div>
  )
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2 px-3 py-2">
      <span className="text-xs font-bold text-muted-foreground w-24 shrink-0">{label}</span>
      <span className="min-w-0">{children}</span>
    </div>
  )
}

'use client'

// ─────────────────────────────────────────────────────────────
// ARRIVALS VIEW — وصولو اليوم: منتقي تاريخ + بطاقات + تفاصيل + تسجيل وصول
// ─────────────────────────────────────────────────────────────

import { useEffect, useMemo, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { PlaneLanding, Quote, Users2, CalendarDays, Phone, DoorOpen, Info } from 'lucide-react'
import type { ArrivalItem } from './types'
import { RefCode, MoneyAmount, PaymentStatusBadge, ReservationStatusBadge, EmptyState, SectionTitle } from './bits'
import { useReception } from './context'
import { formatDateWithDayAr, formatMoney, PAYMENT_METHOD_LABELS, SOURCE_LABELS, todayInputValue } from '@/lib/format'

export default function ArrivalsView({ version }: { version: number }) {
  const [date, setDate] = useState(todayInputValue())
  const [data, setData] = useState<{ date: string; arrivals: ArrivalItem[] } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [detail, setDetail] = useState<ArrivalItem | null>(null)
  const { openCheckIn } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ arrivals: ArrivalItem[] }>(`/api/reception/arrivals?date=${date}`)
        if (!cancelled) {
          setData({ date, arrivals: res.arrivals })
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل الوصولين')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [date, version])

  const arrivals = data?.date === date ? data.arrivals : null

  const isToday = date === todayInputValue()

  return (
    <div className="space-y-4">
      <SectionTitle icon={<PlaneLanding className="w-5 h-5 text-primary" />}>
        الوصولون {isToday ? 'اليوم' : ''}
      </SectionTitle>

      <div className="flex flex-wrap items-center gap-2">
        <label htmlFor="arrivals-date" className="text-sm font-bold text-muted-foreground">التاريخ:</label>
        <input
          id="arrivals-date"
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="rounded-lg border border-input bg-card px-3 py-1.5 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-ring"
        />
        <span className="text-xs text-muted-foreground">{formatDateWithDayAr(date)}</span>
      </div>

      {error ? <EmptyState title="تعذر التحميل" subtitle={error} /> : null}

      {!arrivals && !error ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-32 rounded-xl" />
          ))}
        </div>
      ) : null}

      {arrivals && arrivals.length === 0 ? (
        <EmptyState title={`لا وصولات في ${isToday ? 'اليوم' : 'هذا اليوم'} 🎉`} icon={<PlaneLanding className="w-8 h-8" />} />
      ) : null}

      {arrivals && arrivals.length > 0 ? (
        <div className="space-y-3">
          {arrivals.map((a) => (
            <ArrivalCard key={a.id} arrival={a} onDetail={() => setDetail(a)} onCheckIn={() => openCheckIn(a.id, a.checkIn)} />
          ))}
        </div>
      ) : null}

      {/* تفاصيل الحجز */}
      {detail ? <ArrivalDetailDialog arrival={detail} onClose={() => setDetail(null)} onCheckIn={() => { const a = detail; setDetail(null); openCheckIn(a.id, a.checkIn) }} /> : null}
    </div>
  )
}

function ArrivalCard({ arrival, onDetail, onCheckIn }: { arrival: ArrivalItem; onDetail: () => void; onCheckIn: () => void }) {
  const paidPercent = Math.min(100, Math.round((arrival.paidCents / Math.max(arrival.grandTotalCents, 1)) * 100))
  return (
    <article className="rounded-xl border bg-card p-4 hover:border-primary/40 transition-colors">
      <div className="flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-lg font-black">{arrival.guest.fullName}</h3>
            <ReservationStatusBadge status={arrival.status} />
          </div>
          <p className="mt-0.5 flex items-center gap-2 flex-wrap text-xs text-muted-foreground">
            <RefCode>{arrival.bookingReference}</RefCode>
            <span>·</span>
            <span>{arrival.roomType.name}</span>
            <span>·</span>
            <span>{arrival.nights} ليالٍ</span>
            <span>·</span>
            <span className="flex items-center gap-1">
              <Users2 className="w-3.5 h-3.5" />
              {arrival.adults} بالغ{arrival.children > 0 ? ` + ${arrival.children} طفل` : ''}
            </span>
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={onDetail}>
            <Info className="w-4 h-4" /> تفاصيل
          </Button>
          <Button size="sm" onClick={onCheckIn} disabled={arrival.status !== 'CONFIRMED'}>
            <DoorOpen className="w-4 h-4" /> تسجيل الوصول
          </Button>
        </div>
      </div>

      {/* حالة الدفع */}
      <div className="mt-3 rounded-lg bg-muted/40 border border-border/60 p-3">
        <div className="flex flex-wrap items-center justify-between gap-2 mb-2">
          <div className="flex items-center gap-2 text-sm">
            <PaymentStatusBadge status={arrival.paymentStatus} />
            <span className="text-muted-foreground">
              مدفوع <b className="text-foreground">{formatMoney(arrival.paidCents)}</b> من {formatMoney(arrival.grandTotalCents)}
              {arrival.paymentMethod ? ` · ${PAYMENT_METHOD_LABELS[arrival.paymentMethod] ?? arrival.paymentMethod}` : ''}
            </span>
          </div>
          <span className="text-xs font-bold text-muted-foreground">
            المتبقي: <MoneyAmount cents={arrival.grandTotalCents - arrival.paidCents} colored />
          </span>
        </div>
        <Progress value={paidPercent} className="h-1.5" />
      </div>

      {arrival.specialRequests ? (
        <p className="mt-2 flex items-start gap-1.5 text-xs text-muted-foreground">
          <Quote className="w-3.5 h-3.5 text-gold shrink-0 mt-0.5" />
          {arrival.specialRequests}
        </p>
      ) : null}
    </article>
  )
}

function ArrivalDetailDialog({
  arrival,
  onClose,
  onCheckIn,
}: {
  arrival: ArrivalItem
  onClose: () => void
  onCheckIn: () => void
}) {
  const paidPercent = Math.min(100, Math.round((arrival.paidCents / Math.max(arrival.grandTotalCents, 1)) * 100))
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle>{arrival.guest.fullName}</DialogTitle>
          <DialogDescription className="flex items-center gap-2">
            <RefCode>{arrival.bookingReference}</RefCode>
            <ReservationStatusBadge status={arrival.status} />
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3 text-sm">
          <div className="grid grid-cols-2 gap-2">
            <InfoBox label="الهاتف">
              <span dir="ltr" className="font-mono">{arrival.guest.phone}</span>
            </InfoBox>
            <InfoBox label="الجنسية">{arrival.guest.nationality ?? '—'}</InfoBox>
            <InfoBox label="المصدر">{SOURCE_LABELS[arrival.source] ?? arrival.source}</InfoBox>
            <InfoBox label="البريد">{arrival.guest.email ?? '—'}</InfoBox>
          </div>

          <div className="rounded-lg border bg-muted/30 p-3 space-y-1.5">
            <p className="flex items-center gap-2">
              <CalendarDays className="w-4 h-4 text-primary" />
              {formatDateWithDayAr(arrival.checkIn)} ← {formatDateWithDayAr(arrival.checkOut)} ({arrival.nights} ليالٍ)
            </p>
            <p className="text-muted-foreground text-xs">
              {arrival.roomType.name} · {arrival.roomType.bedConfig} · {arrival.roomType.sizeSqm}م²
            </p>
          </div>

          <div className="rounded-lg border p-3 space-y-1.5">
            <div className="flex justify-between"><span className="text-muted-foreground">المجموع الفرعي</span><MoneyAmount cents={arrival.subtotalCents} /></div>
            <div className="flex justify-between"><span className="text-muted-foreground">الضريبة</span><MoneyAmount cents={arrival.taxCents} /></div>
            <div className="flex justify-between font-bold border-t pt-1.5"><span>الإجمالي</span><MoneyAmount cents={arrival.grandTotalCents} /></div>
            <div className="flex justify-between"><span className="text-muted-foreground">المدفوع</span><MoneyAmount cents={arrival.paidCents} colored /></div>
            <div className="flex justify-between font-bold"><span>المتبقي</span><MoneyAmount cents={arrival.grandTotalCents - arrival.paidCents} /></div>
            <Progress value={paidPercent} className="h-1.5 mt-1" />
          </div>

          {arrival.specialRequests ? (
            <div className="flex items-start gap-2 rounded-lg border border-gold/40 bg-gold/10 p-3">
              <Quote className="w-4 h-4 text-gold shrink-0 mt-0.5" />
              <span><b>طلبات خاصة: </b>{arrival.specialRequests}</span>
            </div>
          ) : null}

          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose}>إغلاق</Button>
            <Button onClick={onCheckIn} disabled={arrival.status !== 'CONFIRMED'}>
              <DoorOpen className="w-4 h-4" /> تسجيل الوصول
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function InfoBox({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border bg-muted/30 px-3 py-2">
      <p className="text-[10px] font-bold text-muted-foreground">{label}</p>
      <p className="text-sm font-medium truncate">{children}</p>
    </div>
  )
}

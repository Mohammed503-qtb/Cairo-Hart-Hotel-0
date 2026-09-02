'use client'

// ─────────────────────────────────────────────────────────────
// DEPARTURES VIEW — المغادرون: مستحقو اليوم + المتأخرون
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PlaneTakeoff, Receipt, AlarmClock, Users2 } from 'lucide-react'
import type { DepartureItem } from './types'
import { RefCode, MoneyAmount, StayStatusBadge, EmptyState, SectionTitle } from './bits'
import { useReception } from './context'
import { formatDateWithDayAr, nightsBetweenDates, todayInputValue } from '@/lib/format'

export default function DeparturesView({ version }: { version: number }) {
  const [date, setDate] = useState(todayInputValue())
  const [data, setData] = useState<{ date: string; departures: DepartureItem[] } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const { openCheckOut, openStay } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ departures: DepartureItem[] }>(`/api/reception/departures?date=${date}`)
        if (!cancelled) {
          setData({ date, departures: res.departures })
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل المغادرات')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [date, version])

  const departures = data?.date === date ? data.departures : null

  const overdue = (departures ?? []).filter((d) => d.overdue)
  const dueToday = (departures ?? []).filter((d) => !d.overdue)

  return (
    <div className="space-y-4">
      <SectionTitle icon={<PlaneTakeoff className="w-5 h-5 text-coral" />}>
        المغادرون {date === todayInputValue() ? 'اليوم' : ''}
      </SectionTitle>

      <div className="flex flex-wrap items-center gap-2">
        <label htmlFor="dep-date" className="text-sm font-bold text-muted-foreground">التاريخ:</label>
        <input
          id="dep-date"
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="rounded-lg border border-input bg-card px-3 py-1.5 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-ring"
        />
        <span className="text-xs text-muted-foreground">{formatDateWithDayAr(date)}</span>
      </div>

      {error ? <EmptyState title="تعذر التحميل" subtitle={error} /> : null}

      {!departures && !error ? (
        <div className="space-y-3">
          {Array.from({ length: 2 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
      ) : null}

      {departures && overdue.length > 0 ? (
        <section aria-label="مغادرات متأخرة">
          <SectionTitle icon={<AlarmClock className="w-4 h-4 text-destructive" />}>مغادرات متأخرة</SectionTitle>
          <div className="space-y-3">
            {overdue.map((d) => (
              <DepartureCard key={d.id} dep={d} onCheckOut={() => openCheckOut(d.id)} onBill={() => openStay(d.id, 'bill')} />
            ))}
          </div>
        </section>
      ) : null}

      {departures ? (
        <section aria-label="مغادرات اليوم">
          <SectionTitle icon={<PlaneTakeoff className="w-4 h-4 text-coral" />}>
            مستحقو {date === todayInputValue() ? 'اليوم' : 'هذا اليوم'}
          </SectionTitle>
          {dueToday.length === 0 ? (
            <EmptyState title="لا مغادرات مستحقة" icon={<PlaneTakeoff className="w-8 h-8" />} />
          ) : (
            <div className="space-y-3">
              {dueToday.map((d) => (
                <DepartureCard key={d.id} dep={d} onCheckOut={() => openCheckOut(d.id)} onBill={() => openStay(d.id, 'bill')} />
              ))}
            </div>
          )}
        </section>
      ) : null}
    </div>
  )
}

function DepartureCard({
  dep,
  onCheckOut,
  onBill,
}: {
  dep: DepartureItem
  onCheckOut: () => void
  onBill: () => void
}) {
  const nights = nightsBetweenDates(dep.checkInAt, dep.expectedCheckOutAt)
  return (
    <article className={`rounded-xl border bg-card p-4 hover:border-primary/40 transition-colors ${dep.overdue ? 'border-destructive/45' : ''}`}>
      <div className="flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-lg font-black">{dep.guestName}</h3>
            <Badge variant="outline" className="font-mono">غرفة {dep.roomNumber}</Badge>
            {dep.overdue ? (
              <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/40 font-bold">
                <AlarmClock className="w-3 h-3" /> متأخر
              </Badge>
            ) : null}
            <StayStatusBadge status={dep.status} />
          </div>
          <p className="mt-1 flex items-center gap-2 flex-wrap text-xs text-muted-foreground">
            <RefCode>{dep.reference}</RefCode>
            <span>·</span>
            <span>{dep.roomTypeName}</span>
            <span>·</span>
            <span className="flex items-center gap-1">
              <Users2 className="w-3.5 h-3.5" />
              {nights} ليالٍ
            </span>
            <span>·</span>
            <span>خروج: {formatDateWithDayAr(dep.expectedCheckOutAt)}</span>
          </p>
          <p className="mt-1.5 text-sm font-bold">
            الرصيد: <MoneyAmount cents={dep.balanceCents} colored />{' '}
            {dep.activeRequests > 0 ? (
              <Badge variant="outline" className="ms-1 text-[10px]">{dep.activeRequests} طلب نشط</Badge>
            ) : null}
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" onClick={onBill}>
            <Receipt className="w-4 h-4" /> الفاتورة
          </Button>
          <Button size="sm" onClick={onCheckOut}>
            <PlaneTakeoff className="w-4 h-4" /> تسجيل الخروج
          </Button>
        </div>
      </div>
    </article>
  )
}

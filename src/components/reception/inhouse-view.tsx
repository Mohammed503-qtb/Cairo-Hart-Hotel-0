'use client'

// ─────────────────────────────────────────────────────────────
// INHOUSE VIEW — المقيمون الآن: بطاقات + فتح تفاصيل الإقامة
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Users, ConciergeBell, CalendarClock, Info } from 'lucide-react'
import type { InHouseStay } from './types'
import { RefCode, MoneyAmount, StayStatusBadge, EmptyState, SectionTitle } from './bits'
import { useReception } from './context'
import { formatDateAr, todayInputValue } from '@/lib/format'

export default function InHouseView({ version }: { version: number }) {
  const [stays, setStays] = useState<InHouseStay[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const { openStay } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ stays: InHouseStay[] }>('/api/reception/inhouse')
        if (!cancelled) {
          setStays(res.stays)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل المقيمين')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [version])

  const today = todayInputValue()

  return (
    <div className="space-y-4">
      <SectionTitle icon={<Users className="w-5 h-5 text-success" />}>
        المقيمون الآن {stays ? `(${stays.length})` : ''}
      </SectionTitle>

      {error ? <EmptyState title="تعذر التحميل" subtitle={error} /> : null}

      {!stays && !error ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
      ) : null}

      {stays && stays.length === 0 ? (
        <EmptyState title="لا توجد إقامات نشطة" icon={<Users className="w-8 h-8" />} subtitle="سجّل وصول الضيوف ليظهروا هنا" />
      ) : null}

      {stays && stays.length > 0 ? (
        <div className="grid sm:grid-cols-2 gap-3">
          {stays.map((s) => {
            const checkoutDate = s.expectedCheckOutAt.slice(0, 10)
            const isTodayOrOverdue = checkoutDate <= today
            return (
              <article key={s.id} className="rounded-xl border bg-card p-4 hover:border-primary/40 transition-colors">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-black text-base">{s.guest.fullName}</h3>
                      <StayStatusBadge status={s.status} />
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      <RefCode>{s.reference}</RefCode> · {s.roomType.name}
                    </p>
                  </div>
                  <div className="text-center shrink-0 rounded-lg bg-primary/8 border border-primary/25 px-3 py-1.5">
                    <p className="text-[10px] font-bold text-primary">الغرفة</p>
                    <p className="text-xl font-black text-primary leading-none" dir="ltr">{s.room.number}</p>
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-1.5 mt-3">
                  <Badge
                    variant="outline"
                    className={
                      isTodayOrOverdue
                        ? 'bg-destructive/10 text-destructive border-destructive/40 font-bold'
                        : 'bg-muted text-muted-foreground border-border'
                    }
                  >
                    <CalendarClock className="w-3 h-3" />
                    خروج: {formatDateAr(s.expectedCheckOutAt)}
                  </Badge>
                  {s.activeRequests > 0 ? (
                    <Badge variant="outline" className="bg-warning/10 text-[#92600a] dark:text-warning border-warning/40 font-bold">
                      <ConciergeBell className="w-3 h-3" />
                      {s.activeRequests} طلب نشط
                    </Badge>
                  ) : null}
                  <Badge variant="outline" className="bg-muted text-muted-foreground border-border">
                    رصيد: <MoneyAmount cents={s.balanceCents} colored />
                  </Badge>
                </div>

                <div className="mt-3 flex justify-end">
                  <Button size="sm" onClick={() => openStay(s.id)}>
                    <Info className="w-4 h-4" /> التفاصيل
                  </Button>
                </div>
              </article>
            )
          })}
        </div>
      ) : null}
    </div>
  )
}

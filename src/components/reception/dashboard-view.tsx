'use client'

// ─────────────────────────────────────────────────────────────
// DASHBOARD VIEW — لوحة تحكم الاستقبال اليومية
// بطاقات KPI + وصول/مغادرة اليوم + الطلبات المعلقة + إجراءات سريعة
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import {
  PlaneLanding,
  PlaneTakeoff,
  Users,
  ConciergeBell,
  LayoutGrid,
  Search,
  ArrowLeft,
  Zap,
  BedDouble,
} from 'lucide-react'
import type { DashboardData } from './types'
import { useReception } from './context'
import {
  RefCode,
  MoneyAmount,
  PaymentStatusBadge,
  PriorityBadge,
  RequestStatusBadge,
  EmptyState,
  SectionTitle,
} from './bits'

export default function DashboardView({ version }: { version: number }) {
  const [data, setData] = useState<DashboardData | null>(null)
  const [error, setError] = useState<string | null>(null)
  const { toast } = useToast()
  const { openCheckIn, openCheckOut, openRequest, openStay, setView } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<DashboardData>('/api/reception/dashboard')
        if (!cancelled) {
          setData(res)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل لوحة التحكم')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [version])

  if (error) {
    return <EmptyState title="تعذر تحميل لوحة التحكم" subtitle={error} className="mt-8" />
  }

  if (!data) {
    return (
      <div className="space-y-4">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
        <div className="grid lg:grid-cols-2 gap-4">
          <Skeleton className="h-64 rounded-xl" />
          <Skeleton className="h-64 rounded-xl" />
        </div>
      </div>
    )
  }

  const { stats } = data

  return (
    <div className="space-y-5">
      {/* ── بطاقات KPI ── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <KpiCard
          icon={<PlaneLanding className="w-5 h-5" />}
          label="وصول اليوم"
          value={stats.arrivalsToday}
          tone="primary"
          onClick={() => setView('arrivals')}
        />
        <KpiCard
          icon={<PlaneTakeoff className="w-5 h-5" />}
          label="مغادرة اليوم"
          value={stats.departuresToday}
          tone="coral"
          onClick={() => setView('departures')}
        />
        <KpiCard
          icon={<Users className="w-5 h-5" />}
          label="المقيمون الآن"
          value={stats.inHouseStays}
          tone="success"
          onClick={() => setView('inhouse')}
        />
        <KpiCard
          icon={<ConciergeBell className="w-5 h-5" />}
          label="طلبات معلقة"
          value={stats.pendingRequests}
          tone={stats.urgentRequests > 0 ? 'urgent' : 'warning'}
          sub={stats.urgentRequests > 0 ? `منها ${stats.urgentRequests} عاجل ⚡` : undefined}
          onClick={() => setView('requests')}
        />
      </div>

      {/* ── الإشغال ── */}
      <div className="rounded-xl border bg-card p-4">
        <div className="flex items-center justify-between mb-2">
          <span className="flex items-center gap-2 text-sm font-bold">
            <BedDouble className="w-4 h-4 text-primary" />
            إشغال الغرف
          </span>
          <span className="text-sm font-extrabold text-primary">{stats.occupancyPercent}%</span>
        </div>
        <Progress value={stats.occupancyPercent} className="h-2.5" />
        <p className="text-xs text-muted-foreground mt-1.5">
          {stats.occupiedRooms} مشغولة من {stats.totalRooms} غرفة
        </p>
      </div>

      {/* ── وصول ومغادرات اليوم ── */}
      <div className="grid lg:grid-cols-2 gap-4 items-start">
        <section aria-label="وصول اليوم">
          <SectionTitle
            icon={<PlaneLanding className="w-4 h-4 text-primary" />}
            action={
              <Button variant="ghost" size="sm" onClick={() => setView('arrivals')}>
                الكل <ArrowLeft className="w-3.5 h-3.5" />
              </Button>
            }
          >
            وصول اليوم
          </SectionTitle>
          {data.arrivals.length === 0 ? (
            <EmptyState title="لا وصولات اليوم 🎉" subtitle="استرح قليلًا" icon={<PlaneLanding className="w-8 h-8" />} />
          ) : (
            <div className="space-y-2">
              {data.arrivals.map((a) => (
                <div
                  key={a.reservationId}
                  className="rounded-xl border bg-card p-3 flex flex-wrap items-center gap-2 hover:border-primary/40 transition-colors"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-extrabold text-sm">{a.guestName}</span>
                      <RefCode>{a.bookingReference}</RefCode>
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {a.roomTypeName} · {a.nights} ليالٍ ·{' '}
                      <span className="text-success font-bold">{Math.round((a.paidCents / Math.max(a.grandTotalCents, 1)) * 100)}%</span> مدفوع
                    </p>
                  </div>
                  <PaymentStatusBadge status={a.paymentStatus} />
                  <Button size="sm" onClick={() => openCheckIn(a.reservationId, a.checkIn)}>
                    تسجيل وصول
                  </Button>
                </div>
              ))}
            </div>
          )}
        </section>

        <section aria-label="مغادرات اليوم">
          <SectionTitle
            icon={<PlaneTakeoff className="w-4 h-4 text-coral" />}
            action={
              <Button variant="ghost" size="sm" onClick={() => setView('departures')}>
                الكل <ArrowLeft className="w-3.5 h-3.5" />
              </Button>
            }
          >
            مغادرات اليوم
          </SectionTitle>
          {data.departures.length === 0 ? (
            <EmptyState title="لا مغادرات اليوم" icon={<PlaneTakeoff className="w-8 h-8" />} />
          ) : (
            <div className="space-y-2">
              {data.departures.map((d) => (
                <div
                  key={d.stayId}
                  className="rounded-xl border bg-card p-3 flex flex-wrap items-center gap-2 hover:border-primary/40 transition-colors"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-extrabold text-sm">{d.guestName}</span>
                      <Badge variant="outline" className="font-mono">غرفة {d.roomNumber}</Badge>
                      <RefCode>{d.reference}</RefCode>
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      الرصيد: <MoneyAmount cents={d.balanceCents} colored />
                    </p>
                  </div>
                  <Button size="sm" variant="secondary" onClick={() => openStay(d.stayId, 'bill')}>
                    الفاتورة
                  </Button>
                  <Button size="sm" onClick={() => openCheckOut(d.stayId)}>
                    تسجيل خروج
                  </Button>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* ── الطلبات المعلقة ── */}
      <section aria-label="الطلبات المعلقة">
        <SectionTitle
          icon={<ConciergeBell className="w-4 h-4 text-warning" />}
          action={
            <Button variant="ghost" size="sm" onClick={() => setView('requests')}>
              الكل <ArrowLeft className="w-3.5 h-3.5" />
            </Button>
          }
        >
          طلبات معلقة
        </SectionTitle>
        {data.pendingRequests.length === 0 ? (
          <EmptyState title="لا طلبات معلقة ✨" subtitle="كل شيء تحت السيطرة" />
        ) : (
          <div className="space-y-2">
            {data.pendingRequests.map((r) => (
              <div
                key={r.id}
                role="button"
                tabIndex={0}
                onClick={() => openRequest(r.id)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    openRequest(r.id)
                  }
                }}
                className={`w-full text-start rounded-xl border bg-card p-3 flex items-center gap-3 hover:border-primary/40 transition-colors cursor-pointer ${
                  r.priority === 'URGENT' ? 'border-destructive/40' : ''
                }`}
              >
                {r.priority === 'URGENT' ? (
                  <span className="shrink-0 w-9 h-9 rounded-full bg-destructive/10 flex items-center justify-center urgent-pulse">
                    <Zap className="w-4.5 h-4.5 text-destructive" />
                  </span>
                ) : (
                  <span className="shrink-0 w-9 h-9 rounded-full bg-muted flex items-center justify-center">
                    <ConciergeBell className="w-4.5 h-4.5 text-muted-foreground" />
                  </span>
                )}
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-bold text-sm">{r.title}</span>
                    <RequestStatusBadge status={r.status} />
                    <PriorityBadge priority={r.priority} />
                  </div>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    غرفة {r.roomNumber} — {r.guestName} · <RefCode>{r.reference}</RefCode>
                  </p>
                </div>
                <Button size="sm" variant="ghost" className="shrink-0" onClick={(e) => { e.stopPropagation(); openRequest(r.id); }}>
                  إدارة
                </Button>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* ── إجراءات سريعة ── */}
      <section aria-label="إجراءات سريعة">
        <SectionTitle>إجراءات سريعة</SectionTitle>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setView('rooms')}>
            <LayoutGrid className="w-4 h-4" /> لوحة الغرف
          </Button>
          <Button variant="outline" onClick={() => setView('departures')}>
            <PlaneTakeoff className="w-4 h-4" /> المغادرون
          </Button>
          <Button
            variant="outline"
            onClick={() => toast({ title: 'استخدم زر البحث أعلى الشاشة 🔍' })}
          >
            <Search className="w-4 h-4" /> بحث
          </Button>
        </div>
      </section>
    </div>
  )
}

function KpiCard({
  icon,
  label,
  value,
  tone,
  sub,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  value: number
  tone: 'primary' | 'coral' | 'success' | 'warning' | 'urgent'
  sub?: string
  onClick?: () => void
}) {
  const tones: Record<string, string> = {
    primary: 'bg-primary/8 border-primary/25 text-primary',
    coral: 'bg-coral/10 border-coral/35 text-coral',
    success: 'bg-success/10 border-success/35 text-success',
    warning: 'bg-warning/10 border-warning/40 text-[#92600a] dark:text-warning',
    urgent: 'bg-destructive/10 border-destructive/45 text-destructive',
  }
  return (
    <button
      onClick={onClick}
      className="rounded-xl border bg-card p-3 sm:p-4 text-start transition-all hover:shadow-md hover:-translate-y-0.5 active:translate-y-0 focus-visible:ring-2 focus-visible:ring-ring"
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold text-muted-foreground">{label}</span>
        <span className={`w-8 h-8 rounded-lg flex items-center justify-center ${tones[tone]}`}>{icon}</span>
      </div>
      <p className={`text-2xl sm:text-3xl font-black mt-1 tabular-nums ${tones[tone].split(' ').find((c) => c.startsWith('text-')) ?? ''}`}>
        {value}
      </p>
      {sub ? <p className="text-[11px] font-bold mt-0.5 text-destructive">{sub}</p> : null}
    </button>
  )
}

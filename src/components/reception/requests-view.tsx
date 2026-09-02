'use client'

// ─────────────────────────────────────────────────────────────
// REQUESTS VIEW — طلبات الخدمة: فلاتر + بطاقات + إدارة
// ─────────────────────────────────────────────────────────────

import { useEffect, useMemo, useState } from 'react'
import { api } from '@/lib/api-client'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { Zap, ConciergeBell, Clock } from 'lucide-react'
import type { RequestItem } from './types'
import { RefCode, RequestStatusBadge, PriorityBadge, EmptyState, SectionTitle } from './bits'
import { useReception } from './context'
import { REQUEST_STATUS_LABELS, timeAgoAr } from '@/lib/format'

const FILTERS: { key: string; label: string }[] = [
  { key: 'PENDING', label: 'المعلقة' },
  { key: 'NEW', label: 'جديد' },
  { key: 'ACKNOWLEDGED', label: 'قيد الاطلاع' },
  { key: 'ASSIGNED', label: 'مُسند' },
  { key: 'IN_PROGRESS', label: 'قيد التنفيذ' },
  { key: 'WAITING', label: 'انتظار' },
  { key: 'COMPLETED', label: 'مكتمل' },
  { key: 'CANCELLED', label: 'ملغي' },
]

const PENDING_SET = ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING']

export default function RequestsView({ version }: { version: number }) {
  const [requests, setRequests] = useState<RequestItem[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [filter, setFilter] = useState('PENDING')
  const [urgentOnly, setUrgentOnly] = useState(false)
  const { openRequest } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ requests: RequestItem[] }>('/api/reception/requests')
        if (!cancelled) {
          setRequests(res.requests)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل الطلبات')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [version])

  const filtered = useMemo(() => {
    if (!requests) return null
    return requests.filter((r) => {
      if (urgentOnly && r.priority !== 'URGENT') return false
      if (filter === 'ALL') return true
      if (filter === 'PENDING') return PENDING_SET.includes(r.status)
      return r.status === filter
    })
  }, [requests, filter, urgentOnly])

  const pendingCount = (requests ?? []).filter((r) => PENDING_SET.includes(r.status)).length
  const urgentCount = (requests ?? []).filter((r) => PENDING_SET.includes(r.status) && r.priority === 'URGENT').length

  return (
    <div className="space-y-4">
      <SectionTitle icon={<ConciergeBell className="w-5 h-5 text-warning" />}>
        الطلبات {requests ? `(${filtered?.length ?? 0} معروضة)` : ''}
      </SectionTitle>

      {/* فلاتر */}
      <div className="space-y-2">
        <div className="flex flex-wrap gap-1.5" role="group" aria-label="فلترة الحالات">
          <FilterChip label={`الكل (${requests?.length ?? 0})`} active={filter === 'ALL'} onClick={() => setFilter('ALL')} />
          {FILTERS.map((f) => (
            <FilterChip key={f.key} label={f.label} active={filter === f.key} onClick={() => setFilter(f.key)} />
          ))}
        </div>
        <div className="flex items-center gap-2 rounded-lg border bg-card px-3 py-2">
          <Switch id="urgent-only" checked={urgentOnly} onCheckedChange={setUrgentOnly} aria-label="العاجل فقط" />
          <Label htmlFor="urgent-only" className="text-sm font-bold cursor-pointer">
            ⚡ العاجل فقط {urgentCount > 0 ? `(${urgentCount})` : ''}
          </Label>
          {pendingCount > 0 ? (
            <Badge variant="outline" className="ms-auto text-[10px]">{pendingCount} معلق</Badge>
          ) : null}
        </div>
      </div>

      {error ? <EmptyState title="تعذر التحميل" subtitle={error} /> : null}

      {!requests && !error ? (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
      ) : null}

      {filtered && filtered.length === 0 ? (
        <EmptyState
          title={urgentOnly ? 'لا طلبات عاجلة 🎉' : 'لا طلبات بهذا الفلتر'}
          subtitle={filter === 'PENDING' && !urgentOnly ? 'كل الطلبات مكتملة' : undefined}
        />
      ) : null}

      {filtered && filtered.length > 0 ? (
        <div className="space-y-2.5">
          {filtered.map((r) => {
            const isUrgent = r.priority === 'URGENT'
            const isOpen = PENDING_SET.includes(r.status)
            return (
              <button
                key={r.id}
                onClick={() => openRequest(r.id)}
                className={`w-full text-start rounded-xl border bg-card p-3.5 hover:border-primary/40 hover:shadow-sm transition-all ${
                  isUrgent && isOpen ? 'border-destructive/40' : ''
                }`}
              >
                <div className="flex items-center gap-3">
                  {isUrgent ? (
                    <span className={`shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${isOpen ? 'bg-destructive/10 urgent-pulse' : 'bg-muted'}`}>
                      <Zap className={`w-5 h-5 ${isOpen ? 'text-destructive' : 'text-muted-foreground'}`} />
                    </span>
                  ) : (
                    <span className="shrink-0 w-10 h-10 rounded-full bg-muted flex items-center justify-center">
                      <ConciergeBell className="w-5 h-5 text-muted-foreground" />
                    </span>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <h3 className="font-bold text-sm">{r.title}</h3>
                      <RequestStatusBadge status={r.status} />
                      {!isUrgent && isOpen ? <PriorityBadge priority={r.priority} /> : null}
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5 truncate">
                      غرفة {r.stay.roomNumber} — {r.stay.guestName} · <RefCode>{r.reference}</RefCode>
                    </p>
                  </div>
                  <span className="shrink-0 flex items-center gap-1 text-[10px] text-muted-foreground">
                    <Clock className="w-3 h-3" />
                    {timeAgoAr(r.createdAt)}
                  </span>
                </div>
              </button>
            )
          })}
        </div>
      ) : null}
    </div>
  )
}

function FilterChip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-full border px-3 py-1 text-xs font-bold transition-colors ${
        active ? 'bg-primary text-primary-foreground border-primary' : 'bg-card text-muted-foreground hover:bg-accent hover:text-accent-foreground'
      }`}
      aria-pressed={active}
    >
      {label}
    </button>
  )
}

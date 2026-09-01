'use client'

// ─────────────────────────────────────────────────────────────
// ADMIN SHARED — مكونات وأدوات مشتركة لأقسام لوحة الإدارة
// ─────────────────────────────────────────────────────────────
import { useCallback, useEffect, useRef, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Progress } from '@/components/ui/progress'
import { AlertTriangle, ChevronLeft, ChevronRight, Inbox, RefreshCw } from 'lucide-react'
import { api } from '@/lib/api-client'
import {
  ROOM_STATUS_LABELS,
  RESERVATION_STATUS_LABELS,
  PAYMENT_STATUS_LABELS,
} from '@/lib/format'
import { useToast } from '@/hooks/use-toast'

// ───────────── Loader ─────────────

export function useLoader<T>(fetcher: () => Promise<T>, deps: unknown[] = []) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const alive = useRef(true)
  const fetcherRef = useRef(fetcher)

  // تحديث مرجع الجالب بعد كل تصيير (نمط آمن)
  useEffect(() => {
    fetcherRef.current = fetcher
  })

  useEffect(() => {
    alive.current = true
    return () => {
      alive.current = false
    }
  }, [])

  // الجالب الداخلي — كل setState بعد await (آمن للاستدعاء من effect)
  const fetchInternal = useCallback(async () => {
    try {
      const res = await fetcherRef.current()
      if (alive.current) {
        setData(res)
        setError(null)
        setLoading(false)
      }
    } catch (e) {
      if (alive.current) {
        setError(e instanceof Error ? e.message : 'حدث خطأ غير متوقع')
        setLoading(false)
      }
    }
  }, [])

  // إعادة الجلب عند تغيّر المفاتيح (سلسلة مشتقة من deps)
  const depsKey = JSON.stringify(deps)
  useEffect(() => {
    fetchInternal()
  }, [fetchInternal, depsKey])

  // لإعادة الجلب من معالجات الأحداث — يضبط حالة التحميل فورًا
  const reload = useCallback(() => {
    setLoading(true)
    setError(null)
    return fetchInternal()
  }, [fetchInternal])

  return { data, loading, error, reload, setData }
}

// ───────────── عناصر عرض ─────────────

export function SectionHeader({
  title,
  description,
  action,
}: {
  title: string
  description?: string
  action?: React.ReactNode
}) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-3 mb-4">
      <div>
        <h2 className="text-xl font-extrabold text-primary">{title}</h2>
        {description && <p className="text-sm text-muted-foreground mt-0.5">{description}</p>}
      </div>
      {action}
    </div>
  )
}

export function KpiCard({
  title,
  value,
  sub,
  icon: Icon,
  tone = 'default',
  progress,
  busy,
}: {
  title: string
  value: React.ReactNode
  sub?: React.ReactNode
  icon: React.ComponentType<{ className?: string }>
  tone?: 'default' | 'danger' | 'success' | 'gold'
  progress?: number
  busy?: boolean
}) {
  const toneClasses: Record<string, string> = {
    default: 'text-primary bg-primary/8',
    danger: 'text-destructive bg-destructive/10',
    success: 'text-success bg-success/10',
    gold: 'text-gold bg-gold/10',
  }
  return (
    <Card className="border-border/60">
      <CardContent className="p-4 flex items-start gap-3">
        <div className={`rounded-lg p-2.5 shrink-0 ${toneClasses[tone]}`}>
          <Icon className="w-5 h-5" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-xs text-muted-foreground font-medium">{title}</p>
          {busy ? (
            <Skeleton className="h-8 w-20 mt-1" />
          ) : (
            <p className="text-2xl font-extrabold tabular-nums leading-9">{value}</p>
          )}
          {sub && <p className="text-xs text-muted-foreground mt-0.5 leading-relaxed">{sub}</p>}
          {typeof progress === 'number' && !busy && <Progress value={progress} className="h-1.5 mt-2" />}
        </div>
      </CardContent>
    </Card>
  )
}

export function EmptyState({ title, description, icon: Icon = Inbox }: { title: string; description?: string; icon?: React.ComponentType<{ className?: string }> }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="rounded-full bg-muted p-4 mb-3">
        <Icon className="w-7 h-7 text-muted-foreground" />
      </div>
      <p className="font-bold">{title}</p>
      {description && <p className="text-sm text-muted-foreground mt-1 max-w-sm">{description}</p>}
    </div>
  )
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="rounded-full bg-destructive/10 p-4 mb-3">
        <AlertTriangle className="w-7 h-7 text-destructive" />
      </div>
      <p className="font-bold text-destructive">تعذر تحميل البيانات</p>
      <p className="text-sm text-muted-foreground mt-1 max-w-sm">{message}</p>
      {onRetry && (
        <Button variant="outline" size="sm" onClick={onRetry} className="mt-4 gap-2">
          <RefreshCw className="w-4 h-4" /> إعادة المحاولة
        </Button>
      )}
    </div>
  )
}

export function TableSkeleton({ rows = 5, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <div className="space-y-2 p-4">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="grid gap-2" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}>
          {Array.from({ length: cols }).map((_, c) => (
            <Skeleton key={c} className="h-6" />
          ))}
        </div>
      ))}
    </div>
  )
}

export function Pager({ page, pages, onPage, total }: { page: number; pages: number; onPage: (p: number) => void; total?: number }) {
  return (
    <div className="flex items-center justify-between gap-3 pt-3 pb-1">
      {typeof total === 'number' && (
        <p className="text-xs text-muted-foreground">الإجمالي: {total.toLocaleString('ar-EG')}</p>
      )}
      <div className="flex items-center gap-2 mr-auto">
        <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => onPage(page - 1)} className="gap-1">
          <ChevronRight className="w-4 h-4" /> السابق
        </Button>
        <span className="text-xs text-muted-foreground tabular-nums">
          صفحة {page} من {pages}
        </span>
        <Button variant="outline" size="sm" disabled={page >= pages} onClick={() => onPage(page + 1)} className="gap-1">
          التالي <ChevronLeft className="w-4 h-4" />
        </Button>
      </div>
    </div>
  )
}

/** نص لاتيني (مرجع/هاتف/كود) داخل صفحة RTL */
export function Ltr({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return <span dir="ltr" className={`font-mono tabular-nums ${className}`}>{children}</span>
}

// ───────────── شارات الحالات ─────────────

const RES_STATUS_CLS: Record<string, string> = {
  PENDING: 'bg-gold/15 text-[#8a6d1f] border-gold/40 dark:text-gold',
  CONFIRMED: 'bg-success/10 text-success border-success/40',
  CHECKED_IN: 'bg-primary/10 text-primary border-primary/40',
  COMPLETED: 'bg-muted text-muted-foreground border-border',
  CANCELLED: 'bg-destructive/10 text-destructive border-destructive/40',
  NO_SHOW: 'bg-destructive/10 text-destructive border-destructive/40',
  EXPIRED: 'bg-muted text-muted-foreground border-border',
}

export function ReservationStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={RES_STATUS_CLS[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {RESERVATION_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const PAY_STATUS_CLS: Record<string, string> = {
  PAID: 'bg-success/10 text-success border-success/40',
  PARTIALLY_PAID: 'bg-gold/15 text-[#8a6d1f] border-gold/40 dark:text-gold',
  UNPAID: 'bg-muted text-muted-foreground border-border',
  REFUNDED: 'bg-destructive/10 text-destructive border-destructive/40',
}

export function PaymentStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={PAY_STATUS_CLS[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {PAYMENT_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const ROOM_STATUS_CLS: Record<string, string> = {
  AVAILABLE: 'bg-success/10 text-success border-success/40',
  OCCUPIED: 'bg-primary/10 text-primary border-primary/40',
  RESERVED: 'bg-gold/15 text-[#8a6d1f] border-gold/40 dark:text-gold',
  CLEANING: 'bg-warning/10 text-[#a16207] border-warning/40 dark:text-warning',
  DIRTY: 'bg-coral/10 text-coral border-coral/40',
  OUT_OF_ORDER: 'bg-muted text-muted-foreground border-border',
}

export function RoomStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={ROOM_STATUS_CLS[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {ROOM_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const CODE_TYPE_CLS: Record<string, string> = {
  GUEST: 'bg-gold/15 text-[#8a6d1f] border-gold/40 dark:text-gold',
  RECEPTION: 'bg-blue-500/10 text-blue-700 dark:text-blue-300 border-blue-500/30',
  ADMIN: 'bg-primary/10 text-primary border-primary/40',
}
const CODE_TYPE_LABELS: Record<string, string> = { GUEST: 'ضيف', RECEPTION: 'استقبال', ADMIN: 'إدارة' }

export function CodeTypeBadge({ type }: { type: string }) {
  return (
    <Badge variant="outline" className={CODE_TYPE_CLS[type] ?? 'bg-muted text-muted-foreground border-border'}>
      {CODE_TYPE_LABELS[type] ?? type}
    </Badge>
  )
}

const CODE_STATUS_CLS: Record<string, string> = {
  ACTIVE: 'bg-success/10 text-success border-success/40',
  EXPIRED: 'bg-muted text-muted-foreground border-border',
  REVOKED: 'bg-destructive/10 text-destructive border-destructive/40',
  USED: 'bg-muted text-muted-foreground border-border',
}
const CODE_STATUS_LABELS: Record<string, string> = { ACTIVE: 'فعّال', EXPIRED: 'منتهي', REVOKED: 'ملغي', USED: 'مستخدم' }

export function CodeStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={CODE_STATUS_CLS[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {CODE_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const ROLE_CLS: Record<string, string> = {
  RECEPTION: 'bg-blue-500/10 text-blue-700 dark:text-blue-300 border-blue-500/30',
  ADMIN: 'bg-purple-500/10 text-purple-700 dark:text-purple-300 border-purple-500/30',
  MANAGER: 'bg-primary/10 text-primary border-primary/40',
}
const ROLE_LABELS: Record<string, string> = { RECEPTION: 'استقبال', ADMIN: 'إدارة', MANAGER: 'مدير' }

export function StaffRoleBadge({ role }: { role: string }) {
  return (
    <Badge variant="outline" className={ROLE_CLS[role] ?? 'bg-muted text-muted-foreground border-border'}>
      {ROLE_LABELS[role] ?? role}
    </Badge>
  )
}

/** شارة الفعل في سجل التدقيق — ملونة حسب دور الفاعل */
const AUDIT_ROLE_CLS: Record<string, string> = {
  WEBSITE: 'bg-blue-500/10 text-blue-700 dark:text-blue-300 border-blue-500/30',
  RECEPTION: 'bg-primary/10 text-primary border-primary/40',
  GUEST: 'bg-gold/15 text-[#8a6d1f] border-gold/40 dark:text-gold',
  ADMIN: 'bg-purple-500/10 text-purple-700 dark:text-purple-300 border-purple-500/30',
  SYSTEM: 'bg-muted text-muted-foreground border-border',
}

export function AuditRoleBadge({ role, label }: { role: string; label: string }) {
  return (
    <Badge variant="outline" className={AUDIT_ROLE_CLS[role] ?? 'bg-muted text-muted-foreground border-border'}>
      {label}
    </Badge>
  )
}

// ───────────── ألوان الرسوم ─────────────

export interface ChartPalette {
  primary: string
  gold: string
  coral: string
  success: string
  warning: string
  gray: string
}

const FALLBACK: ChartPalette = {
  primary: '#1A3C6E', gold: '#D4A843', coral: '#E87A5E', success: '#2D9B4E', warning: '#F59E0B', gray: '#6B7280',
}

/** يقرأ متغيرات CSS للهوية ويتابع تغيّر الوضع فاتح/داكن */
export function useChartPalette(): ChartPalette {
  const [colors, setColors] = useState<ChartPalette>(FALLBACK)

  useEffect(() => {
    const read = () => {
      const s = getComputedStyle(document.documentElement)
      const get = (v: string, fb: string) => s.getPropertyValue(v).trim() || fb
      setColors({
        primary: get('--chart-1', FALLBACK.primary),
        gold: get('--chart-2', FALLBACK.gold),
        coral: get('--chart-3', FALLBACK.coral),
        success: get('--chart-4', FALLBACK.success),
        gray: get('--chart-5', FALLBACK.gray),
        warning: get('--warning', FALLBACK.warning),
      })
    }
    read()
    const obs = new MutationObserver(read)
    obs.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
    return () => obs.disconnect()
  }, [])

  return colors
}

/** ألوان حالات الغرف للرسم الدائري */
export function roomStatusColors(p: ChartPalette): Record<string, string> {
  return {
    AVAILABLE: p.success,
    OCCUPIED: p.primary,
    RESERVED: p.gold,
    CLEANING: p.warning,
    DIRTY: p.coral,
    OUT_OF_ORDER: p.gray,
  }
}

// ───────────── أدوات ─────────────

export function useBusyAction() {
  const [busy, setBusy] = useState(false)
  const { toast } = useToast()
  const run = useCallback(
    async (action: () => Promise<void>, successMsg?: string) => {
      if (busy) return
      setBusy(true)
      try {
        await action()
        if (successMsg) toast({ title: successMsg })
      } catch (e) {
        toast({
          title: 'تعذّر تنفيذ العملية',
          description: e instanceof Error ? e.message : 'حدث خطأ غير متوقع',
          variant: 'destructive',
        })
      } finally {
        setBusy(false)
      }
    },
    [busy, toast]
  )
  return { busy, run, toast }
}

/** تحويل دولار (رقم عشري) → سنتات */
export function dollarsToCents(v: string | number): number | null {
  const n = typeof v === 'number' ? v : parseFloat(v)
  if (!Number.isFinite(n)) return null
  return Math.round(n * 100)
}

/** تحويل سنتات → دولار للعرض في حقل إدخال */
export function centsToDollarsInput(cents: number): string {
  return (cents / 100).toFixed(2)
}

/** تاريخ ISO من قيمة input[type=date] */
export function dateInputToISO(v: string, endOfDay = false): string | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) return null
  return new Date(`${v}T${endOfDay ? '23:59:59' : '00:00:00'}`).toISOString()
}

/** قيمة input[type=date] من ISO */
export function isoToDateInput(iso: string): string {
  return iso.slice(0, 10)
}

'use client'

// ─────────────────────────────────────────────────────────────
// RECEPTION BITS — عناصر عرض مشتركة (شارات الحالات، مبالغ، فراغ، مرجع)
// ─────────────────────────────────────────────────────────────
import type { ReactNode } from 'react'
import { Inbox } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { formatMoney } from '@/lib/format'
import {
  REQUEST_STATUS_LABELS,
  PRIORITY_LABELS,
  PAYMENT_STATUS_LABELS,
  ROOM_STATUS_LABELS,
  STAY_STATUS_LABELS,
  RESERVATION_STATUS_LABELS,
  EXTENSION_STATUS_LABELS,
} from '@/lib/format'

/** شارة مونوسبيس LTR للمراجع (HTL-… / ST-… / REQ-…) */
export function RefCode({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <span dir="ltr" className={`font-mono text-xs font-bold tracking-wide text-muted-foreground ${className}`}>
      {children}
    </span>
  )
}

/** مبلغ ملوّن: أخضر للسداد/الصفر — أحمر للرصيد المستحق */
export function MoneyAmount({
  cents,
  colored = false,
  currency = 'USD',
  className = '',
}: {
  cents: number
  colored?: boolean
  currency?: string
  className?: string
}) {
  const color = colored ? (cents > 0 ? 'text-destructive font-extrabold' : cents < 0 ? 'text-warning font-extrabold' : 'text-success font-extrabold') : ''
  return <span className={`tabular-nums ${color} ${className}`}>{formatMoney(cents, currency)}</span>
}

const REQUEST_BADGE: Record<string, string> = {
  NEW: 'bg-primary/10 text-primary border-primary/30',
  ACKNOWLEDGED: 'bg-primary/10 text-primary border-primary/30',
  ASSIGNED: 'bg-gold/15 text-[#8a6d1f] dark:text-gold border-gold/40',
  IN_PROGRESS: 'bg-gold/15 text-[#8a6d1f] dark:text-gold border-gold/40',
  WAITING: 'bg-muted text-muted-foreground border-border',
  COMPLETED: 'bg-success/10 text-success border-success/30',
  CANCELLED: 'bg-muted text-muted-foreground border-border line-through',
  REJECTED: 'bg-destructive/10 text-destructive border-destructive/30',
}

export function RequestStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={REQUEST_BADGE[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {REQUEST_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const PAYMENT_BADGE: Record<string, string> = {
  UNPAID: 'bg-destructive/10 text-destructive border-destructive/30',
  PARTIALLY_PAID: 'bg-gold/15 text-[#8a6d1f] dark:text-gold border-gold/40',
  PAID: 'bg-success/10 text-success border-success/30',
  REFUNDED: 'bg-muted text-muted-foreground border-border',
}

export function PaymentStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={PAYMENT_BADGE[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {PAYMENT_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const RESERVATION_BADGE: Record<string, string> = {
  PENDING: 'bg-gold/15 text-[#8a6d1f] dark:text-gold border-gold/40',
  CONFIRMED: 'bg-success/10 text-success border-success/30',
  CANCELLED: 'bg-muted text-muted-foreground border-border line-through',
  CHECKED_IN: 'bg-primary/10 text-primary border-primary/30',
  COMPLETED: 'bg-primary/10 text-primary border-primary/30',
  NO_SHOW: 'bg-destructive/10 text-destructive border-destructive/30',
  EXPIRED: 'bg-muted text-muted-foreground border-border',
}

export function ReservationStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={RESERVATION_BADGE[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {RESERVATION_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

const STAY_BADGE: Record<string, string> = {
  ACTIVE: 'bg-success/10 text-success border-success/30',
  CHECKOUT_REQUESTED: 'bg-gold/20 text-[#8a6d1f] dark:text-gold border-gold/50',
  CLOSED: 'bg-muted text-muted-foreground border-border',
}

export function StayStatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="outline" className={STAY_BADGE[status] ?? 'bg-muted text-muted-foreground border-border'}>
      {STAY_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

export function ExtensionStatusBadge({ status }: { status: string }) {
  const cls =
    status === 'PENDING'
      ? 'bg-gold/15 text-[#8a6d1f] dark:text-gold border-gold/40'
      : status === 'APPROVED'
        ? 'bg-success/10 text-success border-success/30'
        : 'bg-destructive/10 text-destructive border-destructive/30'
  return (
    <Badge variant="outline" className={cls}>
      {EXTENSION_STATUS_LABELS[status] ?? status}
    </Badge>
  )
}

export function PriorityBadge({ priority }: { priority: string }) {
  if (priority === 'URGENT') {
    return (
      <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/40 urgent-pulse">
        ⚡ {PRIORITY_LABELS[priority]}
      </Badge>
    )
  }
  return (
    <Badge variant="outline" className="bg-muted text-muted-foreground border-border">
      {PRIORITY_LABELS[priority] ?? priority}
    </Badge>
  )
}

export const ROOM_CARD_STYLE: Record<string, string> = {
  AVAILABLE: 'bg-success/10 border-success/40 text-success',
  OCCUPIED: 'bg-destructive/10 border-destructive/40',
  RESERVED: 'bg-primary/10 border-primary/30 text-primary',
  CLEANING: 'bg-gold/15 border-gold/40 text-[#8a6d1f] dark:text-gold',
  DIRTY: 'bg-warning/15 border-warning/50 text-[#92600a] dark:text-warning',
  OUT_OF_ORDER: 'bg-neutral-800/90 border-neutral-900 text-neutral-200 dark:bg-black/70 dark:text-neutral-300',
}

export function roomStatusLabel(status: string): string {
  return ROOM_STATUS_LABELS[status] ?? status
}

/** حالة فراغ أنيقة */
export function EmptyState({
  icon,
  title,
  subtitle,
  className = '',
}: {
  icon?: ReactNode
  title: string
  subtitle?: string
  className?: string
}) {
  return (
    <div className={`flex flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-border/70 bg-muted/30 p-8 text-center ${className}`}>
      <div className="text-muted-foreground/60">{icon ?? <Inbox className="w-8 h-8" />}</div>
      <p className="font-bold text-foreground/80">{title}</p>
      {subtitle ? <p className="text-xs text-muted-foreground">{subtitle}</p> : null}
    </div>
  )
}

/** عنوان قسم */
export function SectionTitle({ children, icon, action }: { children: ReactNode; icon?: ReactNode; action?: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-2 mb-3">
      <h2 className="flex items-center gap-2 text-base font-extrabold text-foreground">
        {icon}
        {children}
      </h2>
      {action}
    </div>
  )
}

/** تنسيق رقم هاتف لمشاركة واتساب */
export function normalizePhone(phone: string): string {
  return phone.replace(/[^\d]/g, '')
}

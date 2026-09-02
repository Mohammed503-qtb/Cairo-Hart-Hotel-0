'use client'

// ─────────────────────────────────────────────────────────────
// WEBSITE SHARED HELPERS — مساعدات واجهة موقع الفندق
// ─────────────────────────────────────────────────────────────
import { motion } from 'framer-motion'
import type { ReactNode } from 'react'
import type { ReservationPublic } from '@/types'
import { RESERVATION_STATUS_LABELS, PAYMENT_STATUS_LABELS } from '@/lib/format'

// ── الأنواع المشتركة لواجهة الموقع ──

export interface SearchParams {
  checkIn: string
  checkOut: string
  adults: number
  children: number
  roomsCount: number
}

export interface SnapshotBreakdown {
  nightly: { date: string; priceCents: number; rateName: string }[]
  subtotalCents: number
  taxCents: number
  grandTotalCents: number
  cancellationPolicy?: string
  checkInTime?: string
  checkOutTime?: string
}

export interface CancellationInfo {
  refundable: boolean
  penaltyCents: number
  freeUntil: string
}

export interface LookupResult {
  reservation: ReservationPublic
  snapshot: SnapshotBreakdown | null
  cancellation: CancellationInfo
}

export interface PrintData {
  reservation: ReservationPublic
  snapshot: SnapshotBreakdown | null
}

// ── أرقام وهواتف ──

export function digits(s: string): string {
  return (s ?? '').replace(/\D/g, '')
}

/** رابط واتساب من رقم (يتجاهل كل ما ليس رقمًا) */
export function waLink(phone: string, text?: string): string {
  const d = digits(phone)
  const base = `https://wa.me/${d}`
  return text ? `${base}?text=${encodeURIComponent(text)}` : base
}

// ── صيغ عربية ──

/** "14:00" → «02:00 م» */
export function formatClockAr(t?: string | null): string {
  if (!t || !/^\d{1,2}:\d{2}$/.test(t)) return t ?? ''
  const [hStr, m] = t.split(':')
  const h = Number(hStr)
  const h12 = h % 12 === 0 ? 12 : h % 12
  const period = h < 12 ? 'ص' : 'م'
  return `${String(h12).padStart(2, '0')}:${m} ${period}`
}

export function nightsText(n: number): string {
  if (n === 1) return 'ليلة واحدة'
  if (n === 2) return 'ليلتان'
  if (n >= 3 && n <= 10) return `${n} ليالٍ`
  return `${n} ليلة`
}

export function guestsText(adults: number, children: number): string {
  let s = ''
  if (adults === 1) s = 'بالغ واحد'
  else if (adults === 2) s = 'بالغان'
  else s = `${adults} بالغين`
  if (children > 0) {
    s += children === 1 ? ' + طفل واحد' : children === 2 ? ' + طفلان' : ` + ${children} أطفال`
  }
  return s
}

export function roomsText(n: number): string {
  if (n === 1) return 'غرفة واحدة'
  if (n === 2) return 'غرفتان'
  return `${n} غرف`
}

export function capacityText(adults: number, children: number): string {
  return guestsText(adults, children)
}

// ── شارات الحالات ──

interface BadgeStyle {
  label: string
  className: string
}

export function reservationStatusBadge(status: string): BadgeStyle {
  const label = RESERVATION_STATUS_LABELS[status] ?? status
  const base = 'inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-bold'
  switch (status) {
    case 'CONFIRMED':
      return { label, className: `${base} bg-success/10 text-success border-success/40` }
    case 'PENDING':
      return { label, className: `${base} bg-warning/10 text-warning border-warning/40` }
    case 'CANCELLED':
    case 'NO_SHOW':
    case 'EXPIRED':
      return { label, className: `${base} bg-destructive/10 text-destructive border-destructive/40` }
    case 'CHECKED_IN':
      return { label, className: `${base} bg-primary/10 text-primary border-primary/40` }
    case 'COMPLETED':
      return { label, className: `${base} bg-muted text-muted-foreground border-border` }
    default:
      return { label, className: `${base} bg-muted text-muted-foreground border-border` }
  }
}

export function paymentStatusBadge(ps: string): BadgeStyle {
  const label = PAYMENT_STATUS_LABELS[ps] ?? ps
  const base = 'inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-bold'
  switch (ps) {
    case 'PAID':
      return { label, className: `${base} bg-success/10 text-success border-success/40` }
    case 'PARTIALLY_PAID':
      return { label, className: `${base} bg-warning/10 text-warning border-warning/40` }
    case 'REFUNDED':
      return { label, className: `${base} bg-muted text-muted-foreground border-border` }
    default:
      return { label, className: `${base} bg-destructive/10 text-destructive border-destructive/40` }
  }
}

// ── الحركة (framer-motion) ──

export function Reveal({
  children,
  delay = 0,
  className,
  y = 24,
}: {
  children: ReactNode
  delay?: number
  className?: string
  y?: number
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-60px' }}
      transition={{ duration: 0.55, delay, ease: [0.21, 0.6, 0.35, 1] }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

export function SectionHeading({
  kicker,
  title,
  subtitle,
}: {
  kicker: string
  title: string
  subtitle?: string
}) {
  return (
    <Reveal className="mx-auto mb-10 max-w-2xl text-center">
      <span className="mb-3 inline-block rounded-full border border-gold/40 bg-accent px-4 py-1 text-xs font-bold tracking-wide text-primary dark:text-gold">
        {kicker}
      </span>
      <h2 className="text-3xl font-extrabold tracking-tight text-foreground sm:text-4xl">{title}</h2>
      {subtitle ? <p className="mt-3 text-base text-muted-foreground">{subtitle}</p> : null}
    </Reveal>
  )
}

/** أقصى عدد أطفال حسب السعة (لعرض «2 بالغين + طفل») */
export function miniCapacity(adults: number, children: number): string {
  const a = adults === 1 ? 'بالغ واحد' : `${adults} بالغين`
  if (children <= 0) return a
  const c = children === 1 ? 'طفل' : `${children} أطفال`
  return `${a} + ${c}`
}

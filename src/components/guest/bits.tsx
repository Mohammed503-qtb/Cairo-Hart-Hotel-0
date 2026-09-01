'use client'

// ─────────────────────────────────────────────────────────────
// GUEST BITS — مكونات مشتركة صغيرة لتطبيق الضيف
// شارات الحالات + اللافتات + حالات الفراغ + أيقونات الأقسام
// ─────────────────────────────────────────────────────────────

import type { ReactNode } from 'react'
import { motion } from 'framer-motion'
import {
  ConciergeBell,
  Sparkles,
  Wrench,
  Inbox,
  AlertTriangle,
  Info,
  Zap,
  CheckCircle2,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { REQUEST_STATUS_LABELS } from '@/lib/format'

// ─── شارة حالة الطلب (ألوان معتمدة من مواصفات المهمة) ───

const REQUEST_STATUS_STYLES: Record<string, string> = {
  NEW: 'bg-slate-100 text-slate-700 dark:bg-slate-800/70 dark:text-slate-300',
  ACKNOWLEDGED: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300',
  ASSIGNED: 'bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300',
  IN_PROGRESS: 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300',
  WAITING: 'bg-stone-100 text-stone-700 dark:bg-stone-800/70 dark:text-stone-300',
  COMPLETED: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300',
  CANCELLED: 'bg-red-100 text-red-700 dark:bg-red-950/60 dark:text-red-300',
  REJECTED: 'bg-red-100 text-red-700 dark:bg-red-950/60 dark:text-red-300',
}

export function RequestStatusBadge({ status, className }: { status: string; className?: string }) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold',
        REQUEST_STATUS_STYLES[status] ?? REQUEST_STATUS_STYLES.WAITING,
        className
      )}
    >
      {REQUEST_STATUS_LABELS[status] ?? status}
    </span>
  )
}

// ─── شارة العاجل (نبض) ───

export function UrgentMark() {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-red-600/10 px-2 py-0.5 text-xs font-bold text-red-600 dark:text-red-400">
      <Zap className="w-3.5 h-3.5 urgent-pulse fill-current" aria-hidden />
      عاجل
    </span>
  )
}

// ─── لافتات ───

export function Banner({
  tone,
  icon,
  title,
  children,
  className,
}: {
  tone: 'gold' | 'warning' | 'info' | 'danger'
  icon?: ReactNode
  title: string
  children?: ReactNode
  className?: string
}) {
  const tones = {
    gold: 'border-gold/40 bg-gold/10 text-foreground',
    warning: 'border-warning/40 bg-warning/10 text-foreground',
    info: 'border-primary/25 bg-primary/5 text-foreground',
    danger: 'border-destructive/40 bg-destructive/10 text-foreground',
  }
  const iconColors = {
    gold: 'text-gold',
    warning: 'text-warning',
    info: 'text-primary',
    danger: 'text-destructive',
  }
  return (
    <div
      role="status"
      className={cn('flex items-start gap-3 rounded-xl border p-3.5 text-sm', tones[tone], className)}
    >
      {icon ? <span className={cn('shrink-0 mt-0.5', iconColors[tone])}>{icon}</span> : null}
      <div className="min-w-0">
        <p className="font-bold">{title}</p>
        {children ? <div className="mt-0.5 text-muted-foreground leading-relaxed">{children}</div> : null}
      </div>
    </div>
  )
}

export function GoldBanner({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <Banner tone="gold" icon={<Info className="w-4.5 h-4.5" />} title={title}>
      {children}
    </Banner>
  )
}

export function BalanceBanner({ balance }: { balance: number }) {
  return (
    <Banner
      tone="warning"
      icon={<AlertTriangle className="w-4.5 h-4.5" />}
      title="لديك رصيد مستحق على الإقامة"
    >
      يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة.
    </Banner>
  )
}

// ─── حالة فراغ أنيقة ───

export function EmptyState({
  icon,
  title,
  hint,
  action,
}: {
  icon?: ReactNode
  title: string
  hint?: string
  action?: ReactNode
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-border bg-card/50 px-6 py-10 text-center"
    >
      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-muted text-muted-foreground">
        {icon ?? <Inbox className="w-6 h-6" aria-hidden />}
      </span>
      <p className="font-bold">{title}</p>
      {hint ? <p className="max-w-xs text-sm text-muted-foreground leading-relaxed">{hint}</p> : null}
      {action}
    </motion.div>
  )
}

// ─── عنوان قسم ───

export function SectionTitle({
  icon,
  children,
  action,
}: {
  icon?: ReactNode
  children: ReactNode
  action?: ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <h2 className="flex items-center gap-2 text-base font-extrabold text-foreground">
        {icon ? <span className="text-gold">{icon}</span> : null}
        {children}
      </h2>
      {action}
    </div>
  )
}

// ─── خريطة أيقونات أقسام الخدمات (أسماء lucide من قاعدة البيانات) ───

const CATEGORY_ICONS: Record<string, typeof Sparkles> = {
  sparkles: Sparkles,
  wrench: Wrench,
  'concierge-bell': ConciergeBell,
}

export function CategoryIcon({ name, className }: { name: string; className?: string }) {
  const Icon = CATEGORY_ICONS[name] ?? ConciergeBell
  return <Icon className={className} aria-hidden />
}

// ─── علامة تم (للخط الزمني) ───

export function DoneMark({ className }: { className?: string }) {
  return <CheckCircle2 className={cn('h-4.5 w-4.5 text-success', className)} aria-hidden />
}

// ─── انتقال الصفحة ───

export const pageMotion = {
  initial: { opacity: 0, y: 10 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -6 },
  transition: { duration: 0.22, ease: 'easeOut' as const },
}

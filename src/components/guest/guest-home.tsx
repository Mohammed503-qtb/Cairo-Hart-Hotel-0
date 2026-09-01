'use client'

// ─────────────────────────────────────────────────────────────
// GUEST HOME — تبويب الرئيسية
// ترحيب + إجراءات سريعة + ملخص الإقامة + آخر الإشعارات
// ─────────────────────────────────────────────────────────────

import { motion } from 'framer-motion'
import {
  BedDouble,
  CalendarClock,
  ConciergeBell,
  Hotel,
  MessageCircle,
  Moon,
  Star,
  ArrowUpRight,
  Bed,
  Users,
  AlertTriangle,
  Info,
} from 'lucide-react'
import { useGuest } from './guest-context'
import { BalanceBanner, GoldBanner, SectionTitle, EmptyState } from './bits'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { formatDateWithDayAr, formatMoney, STAY_STATUS_LABELS, timeAgoAr } from '@/lib/format'
import type { ReactNode } from 'react'

const QUICK_ACTIONS: {
  key: string
  label: string
  icon: typeof ConciergeBell
  action: (g: ReturnType<typeof useGuest>) => void
}[] = [
  {
    key: 'service',
    label: 'طلب خدمة',
    icon: ConciergeBell,
    action: (g) => {
      g.setTab('services')
      g.setServicesView('catalog')
    },
  },
  { key: 'chat', label: 'محادثة الاستقبال', icon: MessageCircle, action: (g) => g.setChatOpen(true) },
  { key: 'extension', label: 'تمديد الإقامة', icon: CalendarClock, action: (g) => g.openDialog('extension') },
  { key: 'room', label: 'تغيير الغرفة', icon: Bed, action: (g) => g.openDialog('room-change') },
  { key: 'checkout', label: 'طلب الخروج', icon: ArrowUpRight, action: (g) => g.openDialog('checkout') },
  { key: 'feedback', label: 'ملاحظات', icon: Star, action: (g) => g.openDialog('feedback') },
]

export default function GuestHome() {
  const guest = useGuest()
  const dash = guest.dashboard

  if (guest.dashboardLoading && !dash) {
    return <HomeSkeleton />
  }
  if (!dash) {
    return (
      <EmptyState
        icon={<Hotel className="h-6 w-6" aria-hidden />}
        title="تعذر تحميل بيانات الإقامة"
        hint="حدث خطأ في الاتصال — أعد المحاولة"
        action={
          <Button variant="outline" onClick={() => void guest.refreshDashboard()}>
            إعادة المحاولة
          </Button>
        }
      />
    )
  }

  const stay = dash.stay
  const requestedCheckout = stay.status === 'CHECKOUT_REQUESTED'

  return (
    <div className="space-y-5">
      {/* ─── بطاقة الترحيب ─── */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35 }}
        aria-labelledby="welcome-heading"
        className="relative overflow-hidden rounded-3xl bg-gradient-to-bl from-primary via-primary to-primary/85 p-6 text-primary-foreground shadow-lg"
      >
        <div
          className="pointer-events-none absolute -left-10 -top-10 h-40 w-40 rounded-full bg-white/10"
          aria-hidden
        />
        <div
          className="pointer-events-none absolute -left-4 top-16 h-24 w-24 rounded-full bg-gold/20"
          aria-hidden
        />
        <div className="relative">
          <h1 id="welcome-heading" className="text-lg font-bold">
            مرحبًا {guest.guestName} 👋
          </h1>
          <div className="mt-4 flex items-end justify-between gap-4">
            <div>
              <p className="text-sm text-primary-foreground/75">رقم غرفتك</p>
              <p className="text-5xl font-extrabold leading-tight tracking-tight" dir="ltr">
                {stay.room.number}
              </p>
              <p className="mt-1 text-sm text-primary-foreground/90">
                {stay.roomType.name} — الطابق {stay.room.floor}
              </p>
            </div>
            <div className="flex flex-col items-end gap-1.5 text-end">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-1 text-xs font-bold">
                <Moon className="h-3.5 w-3.5" aria-hidden />
                {stay.remainingNights > 0
                  ? `${stay.remainingNights} ${stay.remainingNights === 1 ? 'ليلة متبقية' : 'ليالٍ متبقية'}`
                  : 'آخر يوم اليوم'}
              </span>
              <span className="text-xs text-primary-foreground/75">{stay.roomType.bedConfig}</span>
            </div>
          </div>
          <div className="mt-5 flex items-center justify-between gap-3 border-t border-white/20 pt-4 text-sm">
            <div>
              <p className="text-primary-foreground/70">إقامتك حتى</p>
              <p className="font-bold">{formatDateWithDayAr(stay.expectedCheckOutAt)}</p>
            </div>
            <Badge className="border-transparent bg-gold text-[#2A2110]">
              {STAY_STATUS_LABELS[stay.status] ?? stay.status}
            </Badge>
          </div>
        </div>
      </motion.section>

      {/* ─── اللافتات ─── */}
      {requestedCheckout && (
        <GoldBanner title="تم إرسال طلب تسجيل الخروج">
          الاستقبال سيجهّز مغادرتك ويتواصل معك قريبًا — يرجى تسوية الرصيد إن وُجد.
        </GoldBanner>
      )}
      {dash.balanceCents > 0 && <BalanceBanner balance={dash.balanceCents} />}

      {/* ─── الإجراءات السريعة ─── */}
      <section aria-label="إجراءات سريعة">
        <SectionTitle icon={<ConciergeBell className="h-4.5 w-4.5" />}>إجراءات سريعة</SectionTitle>
        <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-3">
          {QUICK_ACTIONS.map((a, i) => {
            const Icon = a.icon
            return (
              <motion.button
                key={a.key}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.04, duration: 0.25 }}
                onClick={() => a.action(guest)}
                disabled={a.key === 'checkout' && requestedCheckout}
                className="group flex min-h-[4.75rem] flex-col items-center justify-center gap-1.5 rounded-2xl border border-border/70 bg-card p-3 text-center shadow-sm transition-all hover:border-primary/40 hover:shadow-md active:scale-95 disabled:cursor-not-allowed disabled:opacity-50"
              >
                <span className="flex h-9 w-9 items-center justify-center rounded-full bg-accent text-primary transition-colors group-hover:bg-primary group-hover:text-primary-foreground">
                  <Icon className="h-4.5 w-4.5" aria-hidden />
                </span>
                <span className="text-xs font-bold leading-tight">{a.label}</span>
              </motion.button>
            )
          })}
        </div>
      </section>

      {/* ─── ملخص الإقامة ─── */}
      <section aria-label="ملخص الإقامة">
        <SectionTitle
          icon={<BedDouble className="h-4.5 w-4.5" />}
          action={
            <button
              onClick={() => guest.setTab('stay')}
              className="text-xs font-bold text-primary hover:underline"
            >
              عرض التفاصيل
            </button>
          }
        >
          ملخص إقامتك
        </SectionTitle>
        <Card className="mt-3 border-border/70">
          <CardContent className="grid grid-cols-2 gap-3 p-4">
            <SummaryCell icon={<Users className="h-4 w-4" aria-hidden />} label="الضيوف">
              {stay.reservation.adults} بالغ
              {stay.reservation.children > 0 ? ` + ${stay.reservation.children} طفل` : ''}
            </SummaryCell>
            <SummaryCell icon={<Moon className="h-4 w-4" aria-hidden />} label="مدة الإقامة">
              {stay.totalNights} {stay.totalNights === 1 ? 'ليلة' : 'ليالٍ'}
            </SummaryCell>
            <SummaryCell icon={<BedDouble className="h-4 w-4" aria-hidden />} label="مرجع الحجز">
              <span dir="ltr" className="font-mono text-sm">
                {stay.reservation.bookingReference}
              </span>
            </SummaryCell>
            <SummaryCell icon={<Hotel className="h-4 w-4" aria-hidden />} label="الرصيد المستحق">
              <span className={dash.balanceCents > 0 ? 'font-bold text-destructive' : 'font-bold text-success'}>
                {formatMoney(dash.balanceCents, dash.currency)}
              </span>
            </SummaryCell>
          </CardContent>
        </Card>
      </section>

      {/* ─── آخر الإشعارات ─── */}
      <section aria-label="آخر الإشعارات">
        <SectionTitle
          icon={<Info className="h-4.5 w-4.5" />}
          action={
            <button
              onClick={() => guest.setNotificationsOpen(true)}
              className="text-xs font-bold text-primary hover:underline"
            >
              كل الإشعارات
            </button>
          }
        >
          آخر الإشعارات
        </SectionTitle>
        <div className="mt-3 space-y-2">
          {dash.notifications.length === 0 ? (
            <p className="rounded-2xl border border-dashed border-border p-4 text-center text-sm text-muted-foreground">
              لا إشعارات بعد — سنعلمك بكل جديد
            </p>
          ) : (
            dash.notifications.slice(0, 3).map((n) => (
              <button
                key={n.id}
                onClick={() => guest.setNotificationsOpen(true)}
                className="flex w-full items-start gap-3 rounded-2xl border border-border/70 bg-card p-3.5 text-start shadow-sm transition-colors hover:border-primary/40"
              >
                <span
                  className={`mt-1 h-2 w-2 shrink-0 rounded-full ${n.read ? 'bg-muted-foreground/30' : 'bg-gold'}`}
                  aria-hidden
                />
                <span className="min-w-0 flex-1">
                  <span className="flex items-center justify-between gap-2">
                    <span className="truncate text-sm font-bold">{n.title}</span>
                    <span className="shrink-0 text-[11px] text-muted-foreground">
                      {timeAgoAr(n.createdAt)}
                    </span>
                  </span>
                  {n.body ? (
                    <span className="mt-0.5 line-clamp-2 block text-xs leading-relaxed text-muted-foreground">
                      {n.body}
                    </span>
                  ) : null}
                </span>
              </button>
            ))
          )}
        </div>
      </section>

      {dash.activeRequests > 0 && (
        <Card className="border-primary/25 bg-accent/60">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm">
              <ConciergeBell className="h-4 w-4 text-primary" aria-hidden />
              لديك {dash.activeRequests} {dash.activeRequests === 1 ? 'طلب نشط' : 'طلبات نشطة'}
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-0">
            <Button size="sm" variant="outline" onClick={guest.goRequests} className="w-full">
              متابعة طلباتي
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

function SummaryCell({
  icon,
  label,
  children,
}: {
  icon: ReactNode
  label: string
  children: ReactNode
}) {
  return (
    <div className="rounded-xl bg-muted/50 p-3">
      <p className="flex items-center gap-1.5 text-[11px] font-medium text-muted-foreground">
        {icon}
        {label}
      </p>
      <p className="mt-1 text-sm font-bold text-foreground">{children}</p>
    </div>
  )
}

function HomeSkeleton() {
  return (
    <div className="space-y-5" aria-busy="true" aria-label="جارٍ تحميل الرئيسية">
      <Skeleton className="h-56 w-full rounded-3xl" />
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-20 rounded-2xl" />
        ))}
      </div>
      <Skeleton className="h-28 w-full rounded-2xl" />
      <Skeleton className="h-24 w-full rounded-2xl" />
    </div>
  )
}

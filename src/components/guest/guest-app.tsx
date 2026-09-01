'use client'

// ─────────────────────────────────────────────────────────────
// GUEST APP — تطبيق الضيف (وضع الجوال)
// هيدر ثابت + تنقل سفلي (موبايل) / علوي (ديسكتوب) + Realtime
// ─────────────────────────────────────────────────────────────

import { useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import {
  BedDouble,
  Bell,
  ConciergeBell,
  Home,
  LogOut,
  MessageCircle,
  ReceiptText,
  Loader2,
} from 'lucide-react'
import { useAppStore } from '@/lib/store'
import { api } from '@/lib/api-client'
import { useSocket } from '@/hooks/use-socket'
import { useToast } from '@/hooks/use-toast'
import { wsRooms, WS_EVENTS } from '@/lib/events'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { GuestProvider, useGuest } from './guest-context'
import GuestHome from './guest-home'
import GuestStay from './guest-stay'
import GuestServices from './guest-services'
import GuestBill from './guest-bill'
import ChatDialog from './chat-dialog'
import ExtensionDialog from './extension-dialog'
import RoomChangeDialog from './room-change-dialog'
import CheckoutDialog from './checkout-dialog'
import FeedbackDialog from './feedback-dialog'
import NotificationsSheet from './notifications-sheet'
import type { GuestTab } from './types'

export default function GuestApp() {
  return (
    <GuestProvider>
      <GuestShell />
    </GuestProvider>
  )
}

const TABS: { key: GuestTab; label: string; icon: typeof Home }[] = [
  { key: 'home', label: 'الرئيسية', icon: Home },
  { key: 'stay', label: 'إقامتي', icon: BedDouble },
  { key: 'services', label: 'الخدمات', icon: ConciergeBell },
  { key: 'bill', label: 'الفاتورة', icon: ReceiptText },
]

function GuestShell() {
  const guest = useGuest()
  const { toast } = useToast()
  const logoutStore = useAppStore((s) => s.logout)

  // ── Realtime: غرفة الإقامة
  const onNotification = useCallback(
    (payload: unknown) => {
      const title =
        payload && typeof payload === 'object' && 'title' in payload && typeof (payload as { title: unknown }).title === 'string'
          ? (payload as { title: string }).title
          : 'إشعار جديد'
      toast({ title })
      void guest.refreshNotifications()
      void guest.refreshDashboard()
    },
    [toast, guest]
  )

  useSocket(guest.stayId ? wsRooms.stay(guest.stayId) : null, {
    [WS_EVENTS.NOTIFICATION_NEW]: onNotification,
    [WS_EVENTS.REQUEST_UPDATED]: () => void guest.refreshRequests(),
    [WS_EVENTS.STAY_UPDATED]: () => {
      void guest.refreshDashboard()
      if (guest.tab === 'stay') void guest.refreshStay()
    },
    [WS_EVENTS.CHAT_MESSAGE]: () => void guest.refreshMessages(),
  })

  const handleLogout = useCallback(async () => {
    try {
      await api('/api/auth/logout', { method: 'POST' })
    } catch {
      // الجلسة تُنهى محليًا في كل الأحوال
    }
    logoutStore()
  }, [logoutStore])

  const hotelName = guest.dashboard?.hotel.name ?? 'الفندق'

  return (
    <div className="flex min-h-screen flex-col bg-background pattern-arabic">
      {/* ─── الهيدر الثابت ─── */}
      <header className="sticky top-0 z-40 border-b border-border/70 bg-card/90 backdrop-blur supports-[backdrop-filter]:bg-card/75">
        <div className="mx-auto flex h-16 max-w-lg items-center gap-2 px-4">
          <img src="/logo-hotel.svg" alt={`شعار ${hotelName}`} className="h-9 w-9 shrink-0" />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-extrabold leading-tight text-primary">{hotelName}</p>
            <p className="truncate text-[11px] leading-tight text-muted-foreground">
              {guest.guestName} — تطبيق الضيف
            </p>
          </div>

          {/* جرس الإشعارات */}
          <Button
            variant="ghost"
            size="icon"
            className="relative h-11 w-11 shrink-0 rounded-full"
            onClick={() => guest.setNotificationsOpen(true)}
            aria-label={`الإشعارات${guest.unreadCount > 0 ? ` — ${guest.unreadCount} غير مقروء` : ''}`}
          >
            <Bell className="h-5 w-5" aria-hidden />
            {guest.unreadCount > 0 && (
              <Badge
                variant="destructive"
                className="absolute -top-0.5 -left-0.5 h-5 min-w-5 rounded-full px-1 text-[10px] font-bold"
                aria-hidden
              >
                {guest.unreadCount > 9 ? '9+' : guest.unreadCount}
              </Badge>
            )}
          </Button>

          {/* خروج */}
          <Button
            variant="ghost"
            size="icon"
            className="h-11 w-11 shrink-0 rounded-full text-destructive hover:bg-destructive/10 hover:text-destructive"
            onClick={handleLogout}
            aria-label="تسجيل الخروج"
          >
            <LogOut className="h-5 w-5" aria-hidden />
          </Button>
        </div>

        {/* تنقل علوي (ديسكتوب فقط) */}
        <nav aria-label="التنقل الرئيسي" className="mx-auto hidden max-w-lg px-4 pb-2 md:block">
          <TabBar />
        </nav>
      </header>

      {/* ─── المحتوى ─── */}
      <main className="mx-auto w-full max-w-lg flex-1 px-4 pb-32 pt-4 md:pb-10">
        <AnimatePresence mode="wait">
          <motion.div
            key={guest.tab}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.22, ease: 'easeOut' }}
          >
            {guest.tab === 'home' && <GuestHome />}
            {guest.tab === 'stay' && <GuestStay />}
            {guest.tab === 'services' && <GuestServices />}
            {guest.tab === 'bill' && <GuestBill />}
          </motion.div>
        </AnimatePresence>
      </main>

      {/* ─── زر المحادثة العائم ─── */}
      <button
        onClick={() => guest.setChatOpen(true)}
        className="fixed bottom-[calc(5.75rem+env(safe-area-inset-bottom))] left-4 z-40 flex h-13 w-13 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg transition-all hover:bg-primary/90 hover:shadow-xl active:scale-95 md:bottom-6 md:left-[max(1.5rem,calc(50%-21rem))]"
        aria-label="محادثة الاستقبال"
      >
        <MessageCircle className="h-6 w-6" aria-hidden />
      </button>

      {/* ─── شريط التنقل السفلي (موبايل) ─── */}
      <nav
        aria-label="التنقل الرئيسي"
        className="fixed inset-x-0 bottom-0 z-40 border-t border-border/70 bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/90 md:hidden"
      >
        <div className="mx-auto flex max-w-lg items-stretch justify-around px-2 pb-[env(safe-area-inset-bottom)]">
          {TABS.map((t) => {
            const active = guest.tab === t.key
            const Icon = t.icon
            return (
              <button
                key={t.key}
                onClick={() => guest.setTab(t.key)}
                aria-current={active ? 'page' : undefined}
                className={cn(
                  'flex min-h-[3.5rem] flex-1 flex-col items-center justify-center gap-0.5 rounded-xl px-2 py-1.5 text-[11px] font-bold transition-colors',
                  active ? 'text-primary' : 'text-muted-foreground hover:text-foreground'
                )}
              >
                <Icon className="h-5.5 w-5.5" aria-hidden />
                {t.label}
                {active && (
                  <motion.span
                    layoutId="guest-nav-dot"
                    className="h-1 w-6 rounded-full bg-primary"
                    aria-hidden
                  />
                )}
              </button>
            )
          })}
        </div>
      </nav>

      {/* ─── الحواريات والصفائح ─── */}
      <NotificationsSheet />
      <ChatDialog />
      <ExtensionDialog />
      <RoomChangeDialog />
      <CheckoutDialog />
      <FeedbackDialog />
    </div>
  )
}

/** شريط تبويبات علوي (ديسكتوب) */
function TabBar() {
  const guest = useGuest()
  return (
    <div className="flex items-center gap-1 rounded-2xl border border-border/70 bg-muted/60 p-1">
      {TABS.map((t) => {
        const active = guest.tab === t.key
        const Icon = t.icon
        return (
          <button
            key={t.key}
            onClick={() => guest.setTab(t.key)}
            aria-current={active ? 'page' : undefined}
            className={cn(
              'flex h-10 flex-1 items-center justify-center gap-1.5 rounded-xl text-sm font-bold transition-all',
              active
                ? 'bg-primary text-primary-foreground shadow-sm'
                : 'text-muted-foreground hover:bg-accent hover:text-foreground'
            )}
          >
            <Icon className="h-4 w-4" aria-hidden />
            {t.label}
          </button>
        )
      })}
    </div>
  )
}

/** مؤشر تحميل مركزي */
export function GuestLoading() {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-muted-foreground">
      <Loader2 className="h-7 w-7 animate-spin" aria-hidden />
      <p className="text-sm font-medium">جارٍ التحميل…</p>
    </div>
  )
}

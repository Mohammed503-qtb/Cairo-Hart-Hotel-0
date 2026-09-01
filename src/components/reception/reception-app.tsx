'use client'

// ─────────────────────────────────────────────────────────────
// RECEPTION APP — وضع الاستقبال (لوحة تشغيل الفندق اليومية)
// هيدر + تنقل (جانبي ديسكتوب / سفلي موبايل) + بث فوري + حوارات عامة
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useState } from 'react'
import { useAppStore } from '@/lib/store'
import { api } from '@/lib/api-client'
import { useSocket } from '@/hooks/use-socket'
import { useToast } from '@/hooks/use-toast'
import { WS_EVENTS } from '@/lib/events'
import {
  LayoutDashboard,
  PlaneLanding,
  PlaneTakeoff,
  Users,
  ConciergeBell,
  LayoutGrid,
  LogOut,
  Search,
  Bell,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { ReceptionContext } from './context'
import type { ViewKey, NotificationItem } from './types'
import DashboardView from './dashboard-view'
import ArrivalsView from './arrivals-view'
import DeparturesView from './departures-view'
import InHouseView from './inhouse-view'
import RequestsView from './requests-view'
import RoomsView from './rooms-view'
import CheckInWizard from './check-in-wizard'
import CheckOutWizard from './check-out-wizard'
import StayDetailDialog from './stay-detail-dialog'
import RequestDetailDialog from './request-detail-dialog'
import SearchDialog from './search-dialog'
import NotificationsSheet from './notifications-sheet'

const NAV: { key: ViewKey; label: string; icon: typeof LayoutDashboard; primary: boolean }[] = [
  { key: 'dashboard', label: 'لوحة التحكم', icon: LayoutDashboard, primary: true },
  { key: 'arrivals', label: 'الوصولون', icon: PlaneLanding, primary: true },
  { key: 'inhouse', label: 'المقيمون', icon: Users, primary: true },
  { key: 'requests', label: 'الطلبات', icon: ConciergeBell, primary: true },
  { key: 'departures', label: 'المغادرون', icon: PlaneTakeoff, primary: false },
  { key: 'rooms', label: 'حالة الغرف', icon: LayoutGrid, primary: false },
]

export default function ReceptionApp() {
  const session = useAppStore((s) => s.session)
  const logout = useAppStore((s) => s.logout)
  const { toast } = useToast()

  const [view, setView] = useState<ViewKey>('dashboard')
  const [version, setVersion] = useState(0)
  const bump = useCallback(() => setVersion((v) => v + 1), [])

  // الحوارات العامة
  const [searchOpen, setSearchOpen] = useState(false)
  const [notifOpen, setNotifOpen] = useState(false)
  const [unread, setUnread] = useState(0)
  const [notifVersion, setNotifVersion] = useState(0)

  const [checkIn, setCheckIn] = useState<{ reservationId: string; checkInISO: string } | null>(null)
  const [checkOut, setCheckOut] = useState<string | null>(null)
  const [stayDialog, setStayDialog] = useState<{ stayId: string; initialTab?: 'guest' | 'bill' | 'requests' | 'messages' | 'actions' } | null>(null)
  const [requestDialog, setRequestDialog] = useState<string | null>(null)

  // ── إشعارات غير المقروءة ──
  const refreshNotif = useCallback(async () => {
    try {
      const res = await api<{ unreadCount: number }>('/api/reception/notifications')
      setUnread(res.unreadCount)
    } catch {
      /* لا يهم */
    }
  }, [])

  useEffect(() => {
    void refreshNotif()
  }, [refreshNotif, notifVersion])

  // ── البث الفوري ──
  useSocket('reception', {
    [WS_EVENTS.REQUEST_NEW]: (payload) => {
      const p = (payload ?? {}) as { title?: string; roomNumber?: string; reference?: string }
      toast({
        title: `🔔 طلب جديد: ${p.title ?? 'خدمة'}`,
        description: p.roomNumber ? `غرفة ${p.roomNumber}${p.reference ? ` — ${p.reference}` : ''}` : undefined,
      })
      bump()
      setNotifVersion((v) => v + 1)
    },
    [WS_EVENTS.RESERVATION_NEW]: (payload) => {
      const p = (payload ?? {}) as { reference?: string; bookingReference?: string; guestName?: string }
      toast({
        title: '🆕 حجز جديد من الموقع',
        description: `${p.bookingReference ?? p.reference ?? ''}${p.guestName ? ` — ${p.guestName}` : ''}`,
      })
      bump()
      setNotifVersion((v) => v + 1)
    },
    [WS_EVENTS.CHAT_MESSAGE]: (payload) => {
      const p = (payload ?? {}) as { senderName?: string; stayId?: string }
      if (p.senderName && p.senderName !== session?.name) {
        toast({ title: '💬 رسالة جديدة', description: p.senderName })
      }
      bump()
    },
    [WS_EVENTS.STAY_UPDATED]: () => bump(),
    [WS_EVENTS.ROOM_STATUS]: () => bump(),
    [WS_EVENTS.REQUEST_UPDATED]: () => bump(),
    [WS_EVENTS.NOTIFICATION_NEW]: () => setNotifVersion((v) => v + 1),
  })

  const actions = {
    bump,
    openStay: (stayId: string, initialTab?: 'guest' | 'bill' | 'requests' | 'messages' | 'actions') =>
      setStayDialog({ stayId, initialTab }),
    openRequest: (requestId: string) => setRequestDialog(requestId),
    openCheckIn: (reservationId: string, checkInISO: string) => setCheckIn({ reservationId, checkInISO }),
    openCheckOut: (stayId: string) => setCheckOut(stayId),
    setView,
  }

  return (
    <ReceptionContext.Provider value={actions}>
      <div className="min-h-screen flex flex-col bg-background">
        {/* ── الهيدر ── */}
        <header className="sticky top-0 z-40 border-b bg-card/90 backdrop-blur supports-[backdrop-filter]:bg-card/75">
          <div className="mx-auto max-w-6xl w-full flex items-center gap-2 px-3 sm:px-4 h-14 sm:h-16">
            <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="w-8 h-8 sm:w-10 sm:h-10 shrink-0" />
            <div className="flex flex-col leading-tight me-1">
              <span className="font-extrabold text-sm sm:text-base text-primary">لوحة الاستقبال</span>
              <span className="text-[10px] sm:text-xs text-muted-foreground">فندق قلب القاهرة — عدن</span>
            </div>

            <div className="flex-1" />

            <Badge variant="secondary" className="hidden sm:inline-flex items-center gap-1.5 font-bold">
              <span className="w-2 h-2 rounded-full bg-success" />
              {session?.name ?? 'الاستقبال'}
            </Badge>

            <Tooltip>
              <TooltipTrigger asChild>
                <Button variant="ghost" size="icon" aria-label="بحث" onClick={() => setSearchOpen(true)}>
                  <Search className="w-5 h-5" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="bottom">بحث عام</TooltipContent>
            </Tooltip>

            <div className="relative">
              <Button variant="ghost" size="icon" aria-label="الإشعارات" onClick={() => setNotifOpen(true)}>
                <Bell className="w-5 h-5" />
                {unread > 0 && (
                  <span className="absolute -top-0.5 -end-0.5 min-w-4 h-4 px-1 rounded-full bg-destructive text-destructive-foreground text-[10px] font-bold flex items-center justify-center">
                    {unread > 9 ? '9+' : unread}
                  </span>
                )}
              </Button>
            </div>

            <Button
              variant="ghost"
              size="icon"
              aria-label="تسجيل الخروج"
              onClick={() => {
                logout()
                toast({ title: 'تم تسجيل الخروج' })
              }}
            >
              <LogOut className="w-5 h-5" />
            </Button>
          </div>
        </header>

        <div className="flex-1 flex w-full mx-auto max-w-6xl">
          {/* ── التنقل الجانبي (ديسكتوب) ── */}
          <aside className="hidden lg:flex flex-col gap-1 w-52 shrink-0 p-3 sticky top-16 self-start" aria-label="التنقل الرئيسي">
            {NAV.map((item) => {
              const Icon = item.icon
              const active = view === item.key
              return (
                <button
                  key={item.key}
                  onClick={() => setView(item.key)}
                  className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-bold transition-colors text-start ${
                    active ? 'bg-primary text-primary-foreground shadow' : 'text-foreground/75 hover:bg-accent hover:text-accent-foreground'
                  }`}
                  aria-current={active ? 'page' : undefined}
                >
                  <Icon className="w-5 h-5 shrink-0" />
                  {item.label}
                  {!item.primary && (
                    <span className="ms-auto text-[10px] font-normal opacity-60">ثانوي</span>
                  )}
                </button>
              )
            })}
            <div className="mt-auto p-3 rounded-lg bg-muted/50 text-[11px] text-muted-foreground leading-relaxed">
              الوضع: تشغيل يومي
              <br />
              انتبه للطلبات العاجلة ⚡
            </div>
          </aside>

          {/* ── المحتوى ── */}
          <main className="flex-1 min-w-0 p-3 sm:p-4 pb-24 lg:pb-8 lg:ps-1" aria-live="polite">
            {view === 'dashboard' && <DashboardView version={version} />}
            {view === 'arrivals' && <ArrivalsView version={version} />}
            {view === 'departures' && <DeparturesView version={version} />}
            {view === 'inhouse' && <InHouseView version={version} />}
            {view === 'requests' && <RequestsView version={version} />}
            {view === 'rooms' && <RoomsView version={version} />}
          </main>
        </div>

        {/* ── التنقل السفلي (موبايل) ── */}
        <nav
          className="lg:hidden fixed bottom-0 inset-x-0 z-40 border-t bg-card/95 backdrop-blur pb-[env(safe-area-inset-bottom)]"
          aria-label="التنقل الرئيسي"
        >
          <div className="grid grid-cols-4">
            {NAV.filter((n) => n.primary).map((item) => {
              const Icon = item.icon
              const active = view === item.key
              return (
                <button
                  key={item.key}
                  onClick={() => setView(item.key)}
                  className={`flex flex-col items-center justify-center gap-0.5 py-2 min-h-14 text-[10px] font-bold transition-colors ${
                    active ? 'text-primary' : 'text-muted-foreground'
                  }`}
                  aria-current={active ? 'page' : undefined}
                >
                  <Icon className={`w-5 h-5 ${active ? 'scale-110' : ''} transition-transform`} />
                  {item.label}
                  <span className={`w-6 h-0.5 rounded-full ${active ? 'bg-primary' : 'bg-transparent'}`} />
                </button>
              )
            })}
          </div>
        </nav>

        {/* ── الحوارات العامة ── */}
        {checkIn && (
          <CheckInWizard
            reservationId={checkIn.reservationId}
            checkInISO={checkIn.checkInISO}
            onClose={() => setCheckIn(null)}
            onDone={() => {
              setCheckIn(null)
              bump()
              setNotifVersion((v) => v + 1)
            }}
          />
        )}

        {checkOut && (
          <CheckOutWizard
            stayId={checkOut}
            onClose={() => setCheckOut(null)}
            onDone={() => {
              setCheckOut(null)
              bump()
              setNotifVersion((v) => v + 1)
            }}
          />
        )}

        {stayDialog && (
          <StayDetailDialog
            stayId={stayDialog.stayId}
            initialTab={stayDialog.initialTab}
            onClose={() => {
              setStayDialog(null)
              bump()
            }}
          />
        )}

        {requestDialog && (
          <RequestDetailDialog
            requestId={requestDialog}
            onClose={() => {
              setRequestDialog(null)
              bump()
            }}
          />
        )}

        <SearchDialog
          open={searchOpen}
          onClose={() => setSearchOpen(false)}
          onSelectStay={(stayId, tab) => {
            setSearchOpen(false)
            setStayDialog({ stayId, initialTab: tab })
          }}
          onSelectReservation={(reservation) => {
            setSearchOpen(false)
            if (reservation.stayId) {
              setStayDialog({ stayId: reservation.stayId })
            } else {
              setCheckIn({ reservationId: reservation.id, checkInISO: reservation.checkIn })
            }
          }}
        />

        <NotificationsSheet
          open={notifOpen}
          onOpenChange={(open) => {
            setNotifOpen(open)
            if (!open) setNotifVersion((v) => v + 1)
          }}
          notifVersion={notifVersion}
          onRead={(notifications: NotificationItem[]) => void onNotificationsRead(notifications)}
        />
      </div>
    </ReceptionContext.Provider>
  )

  async function onNotificationsRead(items: NotificationItem[]) {
    // يُستدعى عند فتح الورقة — تعليم المعروض كمقروء
    const unreadIds = items.filter((n) => !n.read).map((n) => n.id)
    if (unreadIds.length === 0) return
    try {
      await api('/api/reception/notifications/read', { method: 'POST', body: { ids: unreadIds } })
      setUnread(0)
    } catch {
      /* تجاهل */
    }
  }
}

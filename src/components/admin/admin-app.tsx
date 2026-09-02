'use client'

// ─────────────────────────────────────────────────────────────
// ADMIN APP — وضع الإدارة (المدير/المالك)
// هيدر + تنقل جانبي ديسكتوب (قابل للطي) / شريط سفلي موبايل
// Realtime عبر socket (غرفة admin)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  LayoutDashboard, Settings, BedDouble, DoorOpen, CalendarRange, ConciergeBell,
  KeyRound, ClipboardList, Users, BarChart3, ScrollText, Bell, LogOut, Menu,
  PanelRightClose, PanelRightOpen, Hotel,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'
import { ScrollArea } from '@/components/ui/scroll-area'
import { useAppStore } from '@/lib/store'
import { api } from '@/lib/api-client'
import { useSocket } from '@/hooks/use-socket'
import { useToast } from '@/hooks/use-toast'
import { timeAgoAr } from '@/lib/format'
import type { NotificationItem, SectionKey } from './types'
import { useLoader } from './shared'
import DashboardSection from './sections/dashboard'
import HotelSettingsSection from './sections/hotel-settings'
import RoomTypesSection from './sections/room-types'
import RoomsSection from './sections/rooms'
import RatesSection from './sections/rates'
import ServicesSection from './sections/services'
import StaffCodesSection from './sections/staff-codes'
import ReservationsSection from './sections/reservations'
import GuestsSection from './sections/guests'
import ReportsSection from './sections/reports'
import AuditLogSection from './sections/audit-log'

const SECTIONS: Array<{ key: SectionKey; label: string; icon: React.ComponentType<{ className?: string }> }> = [
  { key: 'dashboard', label: 'لوحة التحكم', icon: LayoutDashboard },
  { key: 'hotel', label: 'إعدادات الفندق', icon: Settings },
  { key: 'room-types', label: 'أنواع الغرف', icon: BedDouble },
  { key: 'rooms', label: 'الغرف', icon: DoorOpen },
  { key: 'rates', label: 'الأسعار', icon: CalendarRange },
  { key: 'services', label: 'الخدمات', icon: ConciergeBell },
  { key: 'staff', label: 'الطاقم والأكواد', icon: KeyRound },
  { key: 'reservations', label: 'الحجوزات', icon: ClipboardList },
  { key: 'guests', label: 'الضيوف', icon: Users },
  { key: 'reports', label: 'التقارير', icon: BarChart3 },
  { key: 'audit', label: 'سجل التدقيق', icon: ScrollText },
]

const MOBILE_PRIMARY: SectionKey[] = ['dashboard', 'rooms', 'reservations', 'staff']

export default function AdminApp() {
  const session = useAppStore((s) => s.session)
  const logout = useAppStore((s) => s.logout)
  const { toast } = useToast()

  const [section, setSection] = useState<SectionKey>('dashboard')
  const [collapsed, setCollapsed] = useState(false)
  const [moreOpen, setMoreOpen] = useState(false)
  const [notifOpen, setNotifOpen] = useState(false)
  const [dashKey, setDashKey] = useState(0)

  // الإشعارات — تُحمّل عبر useLoader (مع تحديثها عند الأحداث الفورية)
  const { data: notifData, reload: reloadNotifications } = useLoader<{
    notifications: NotificationItem[]
    unreadCount: number
  }>(() => api('/api/admin/notifications'))
  const notifications = notifData?.notifications ?? []

  // Realtime — غرفة الإدارة
  useSocket('admin', {
    'notification:new': (payload) => {
      const p = payload as { title?: string; body?: string }
      toast({ title: p?.title ?? 'إشعار جديد', description: p?.body ?? '' })
      reloadNotifications()
    },
    'reservation:new': (payload) => {
      const p = payload as { reference?: string; guestName?: string }
      toast({ title: 'حجز جديد', description: p?.reference ? `${p.reference} — ${p.guestName ?? ''}` : 'وصل حجز جديد من الموقع' })
      setDashKey((k) => k + 1)
    },
    'room:status': () => {
      setDashKey((k) => k + 1)
    },
  })

  const unread = notifications.filter((n) => !n.read).length

  const doLogout = async () => {
    try {
      await api('/api/auth/logout', { method: 'POST' })
    } catch {
      // نتجاهل — الخروج محلي على أي حال
    }
    logout()
  }

  const navigate = (key: SectionKey) => {
    setSection(key)
    setMoreOpen(false)
  }

  const renderSection = () => {
    switch (section) {
      case 'dashboard':
        return <DashboardSection key={dashKey} onNavigate={navigate} />
      case 'hotel':
        return <HotelSettingsSection />
      case 'room-types':
        return <RoomTypesSection />
      case 'rooms':
        return <RoomsSection />
      case 'rates':
        return <RatesSection />
      case 'services':
        return <ServicesSection />
      case 'staff':
        return <StaffCodesSection />
      case 'reservations':
        return <ReservationsSection />
      case 'guests':
        return <GuestsSection />
      case 'reports':
        return <ReportsSection />
      case 'audit':
        return <AuditLogSection />
    }
  }

  const activeLabel = SECTIONS.find((s) => s.key === section)?.label ?? ''

  return (
    <TooltipProvider delayDuration={0}>
      <div className="min-h-screen flex flex-col bg-background">
        {/* ── الهيدر ── */}
        <header className="sticky top-0 z-40 border-b bg-background/90 backdrop-blur supports-[backdrop-filter]:bg-background/75">
          <div className="flex items-center gap-3 px-4 h-16">
            <img src="/logo-hotel.svg" alt="شعار الفندق" className="w-9 h-9 shrink-0" />
            <div className="min-w-0">
              <h1 className="font-extrabold text-primary leading-tight text-base md:text-lg">لوحة الإدارة</h1>
              <p className="text-[11px] text-muted-foreground truncate leading-tight">
                {session?.name ?? 'المدير'} · {activeLabel}
              </p>
            </div>

            <div className="mr-auto flex items-center gap-1.5">
              {/* جرس الإشعارات */}
              <Sheet open={notifOpen} onOpenChange={setNotifOpen}>
                <SheetTrigger asChild>
                  <Button variant="outline" size="icon" className="relative h-10 w-10" aria-label="الإشعارات">
                    <Bell className="w-4.5 h-4.5" />
                    {unread > 0 && (
                      <span className="absolute -top-1 -left-1 min-w-5 h-5 px-1 rounded-full bg-destructive text-white text-[10px] font-bold flex items-center justify-center tabular-nums">
                        {unread > 9 ? '9+' : unread}
                      </span>
                    )}
                  </Button>
                </SheetTrigger>
                <SheetContent side="left" className="w-[85vw] sm:max-w-md">
                  <SheetHeader className="pb-0">
                    <SheetTitle className="text-right">إشعارات التشغيل</SheetTitle>
                    <SheetDescription className="text-right">آخر 30 إشعارًا تشغيليًا للإدارة والاستقبال</SheetDescription>
                  </SheetHeader>
                  <ScrollArea className="flex-1 px-4 pb-4" dir="rtl">
                    {notifications.length === 0 ? (
                      <div className="py-16 text-center text-sm text-muted-foreground">
                        لا توجد إشعارات حاليًا — ستصلك هنا تحديثات الحجوزات والطلبات فور حدوثها
                      </div>
                    ) : (
                      <div className="space-y-2.5">
                        {notifications.map((n) => (
                          <div key={n.id} className="rounded-lg border bg-card p-3">
                            <div className="flex items-center justify-between gap-2 mb-1">
                              <p className="font-bold text-sm">{n.title}</p>
                              <Badge variant={n.audience === 'ADMIN' ? 'default' : 'secondary'} className="text-[10px]">
                                {n.audience === 'ADMIN' ? 'إدارة' : 'استقبال'}
                              </Badge>
                            </div>
                            {n.body && <p className="text-xs text-muted-foreground leading-relaxed">{n.body}</p>}
                            <p className="text-[11px] text-muted-foreground/70 mt-1.5">{timeAgoAr(n.createdAt)}</p>
                          </div>
                        ))}
                      </div>
                    )}
                  </ScrollArea>
                </SheetContent>
              </Sheet>

              <Button variant="outline" size="icon" className="h-10 w-10" onClick={doLogout} aria-label="خروج" title="تسجيل الخروج">
                <LogOut className="w-4.5 h-4.5" />
              </Button>
            </div>
          </div>
        </header>

        <div className="flex-1 flex w-full max-w-[1500px] mx-auto">
          {/* ── الشريط الجانبي (ديسكتوب) ── */}
          <aside
            className={`hidden md:flex flex-col shrink-0 border-l bg-card/50 transition-all duration-200 ${
              collapsed ? 'w-14' : 'w-56'
            }`}
          >
            <div className="flex items-center justify-end p-2">
              <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setCollapsed(!collapsed)} aria-label="طي القائمة">
                {collapsed ? <PanelRightOpen className="w-4 h-4" /> : <PanelRightClose className="w-4 h-4" />}
              </Button>
            </div>
            <nav className="flex-1 px-2 pb-4 space-y-1 overflow-y-auto max-h-[calc(100vh-10rem)]">
              {SECTIONS.map((s) => {
                const Icon = s.icon
                const active = section === s.key
                const btn = (
                  <button
                    key={s.key}
                    onClick={() => navigate(s.key)}
                    className={`w-full flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                      active
                        ? 'bg-primary text-primary-foreground shadow-sm'
                        : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                    } ${collapsed ? 'justify-center px-0' : ''}`}
                    aria-current={active ? 'page' : undefined}
                  >
                    <Icon className="w-4.5 h-4.5 shrink-0" />
                    {!collapsed && <span className="truncate">{s.label}</span>}
                  </button>
                )
                if (!collapsed) return btn
                return (
                  <Tooltip key={s.key}>
                    <TooltipTrigger asChild>{btn}</TooltipTrigger>
                    <TooltipContent side="left">{s.label}</TooltipContent>
                  </Tooltip>
                )
              })}
            </nav>
            {!collapsed && (
              <div className="px-3 pb-4 text-[10px] text-muted-foreground/60 leading-relaxed border-t pt-3">
                <Hotel className="w-3 h-3 inline-block ml-1 -mt-0.5" />
                فندق قلب القاهرة — عدن
              </div>
            )}
          </aside>

          {/* ── المحتوى ── */}
          <main className="flex-1 min-w-0 p-4 md:p-6 pb-28 md:pb-10">
            <motion.div key={section} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}>
              {renderSection()}
            </motion.div>
          </main>
        </div>

        {/* ── الشريط السفلي (موبايل) ── */}
        <nav className="md:hidden fixed bottom-0 inset-x-0 z-40 border-t bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/85 pb-[env(safe-area-inset-bottom)]">
          <div className="grid grid-cols-5">
            {MOBILE_PRIMARY.map((key) => {
              const s = SECTIONS.find((x) => x.key === key)!
              const Icon = s.icon
              const active = section === s.key
              return (
                <button
                  key={key}
                  onClick={() => navigate(key)}
                  className={`flex flex-col items-center gap-0.5 py-2.5 min-h-[56px] transition-colors ${
                    active ? 'text-primary' : 'text-muted-foreground'
                  }`}
                  aria-current={active ? 'page' : undefined}
                >
                  <Icon className="w-5 h-5" />
                  <span className="text-[10px] font-medium">{s.label}</span>
                </button>
              )
            })}
            <button
              onClick={() => setMoreOpen(true)}
              className={`flex flex-col items-center gap-0.5 py-2.5 min-h-[56px] transition-colors ${
                !MOBILE_PRIMARY.includes(section) ? 'text-primary' : 'text-muted-foreground'
              }`}
              aria-label="المزيد من الأقسام"
            >
              <Menu className="w-5 h-5" />
              <span className="text-[10px] font-medium">المزيد</span>
            </button>
          </div>
        </nav>

        {/* قائمة الأقسام الكاملة — موبايل */}
        <Sheet open={moreOpen} onOpenChange={setMoreOpen}>
          <SheetContent side="bottom" className="h-[70vh]">
            <SheetHeader className="pb-0">
              <SheetTitle className="text-right">كل الأقسام</SheetTitle>
              <SheetDescription className="text-right">تنقّل إلى أي قسم من أقسام لوحة الإدارة</SheetDescription>
            </SheetHeader>
            <div className="grid grid-cols-2 gap-2 p-4 overflow-y-auto" dir="rtl">
              {SECTIONS.map((s) => {
                const Icon = s.icon
                const active = section === s.key
                return (
                  <button
                    key={s.key}
                    onClick={() => navigate(s.key)}
                    className={`flex items-center gap-3 rounded-lg border p-3.5 text-sm font-medium transition-colors text-start ${
                      active ? 'border-primary bg-primary/5 text-primary' : 'border-border hover:bg-accent'
                    }`}
                  >
                    <Icon className="w-5 h-5 shrink-0" />
                    <span className="truncate">{s.label}</span>
                  </button>
                )
              })}
            </div>
          </SheetContent>
        </Sheet>
      </div>
    </TooltipProvider>
  )
}

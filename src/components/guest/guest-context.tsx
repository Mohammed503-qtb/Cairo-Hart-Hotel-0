'use client'

// ─────────────────────────────────────────────────────────────
// GUEST CONTEXT — مركز بيانات تطبيق الضيف
// تحميل / تحديث / إجراءات + حالة التنقل والحواريات
// ─────────────────────────────────────────────────────────────

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { api } from '@/lib/api-client'
import { useAppStore } from '@/lib/store'
import type { MessagePublic, NotificationPublic } from '@/types'
import type {
  GuestDashboardData,
  GuestDialogKind,
  GuestRequest,
  GuestServiceCategory,
  GuestStayData,
  GuestTab,
} from './types'

interface GuestContextValue {
  guestName: string
  stayId: string | null
  // ─ لوحة التحكم
  dashboard: GuestDashboardData | null
  dashboardLoading: boolean
  refreshDashboard: () => Promise<void>
  // ─ الإقامة التفصيلية
  stayData: GuestStayData | null
  stayLoading: boolean
  refreshStay: () => Promise<void>
  // ─ الطلبات
  requests: GuestRequest[]
  requestsLoading: boolean
  refreshRequests: () => Promise<void>
  // ─ المحادثة
  messages: MessagePublic[]
  messagesLoading: boolean
  chatOpen: boolean
  setChatOpen: (open: boolean) => void
  refreshMessages: () => Promise<void>
  sendMessage: (body: string) => Promise<boolean>
  // ─ الخدمات
  services: GuestServiceCategory[]
  servicesLoading: boolean
  refreshServices: () => Promise<void>
  // ─ الإشعارات
  notifications: NotificationPublic[]
  unreadCount: number
  notificationsOpen: boolean
  setNotificationsOpen: (open: boolean) => void
  refreshNotifications: () => Promise<void>
  markAllRead: () => Promise<void>
  // ─ التنقل
  tab: GuestTab
  setTab: (t: GuestTab) => void
  servicesView: 'catalog' | 'requests'
  setServicesView: (v: 'catalog' | 'requests') => void
  goRequests: () => void
  // ─ الحواريات
  dialog: GuestDialogKind
  openDialog: (d: Exclude<GuestDialogKind, null>) => void
  closeDialog: () => void
}

const GuestContext = createContext<GuestContextValue | null>(null)

export function useGuest(): GuestContextValue {
  const ctx = useContext(GuestContext)
  if (!ctx) throw new Error('useGuest must be used within GuestProvider')
  return ctx
}

export function GuestProvider({ children }: { children: ReactNode }) {
  const session = useAppStore((s) => s.session)
  const guestName = session?.name ?? 'ضيف'

  const [stayId, setStayId] = useState<string | null>(null)
  const [dashboard, setDashboard] = useState<GuestDashboardData | null>(null)
  const [dashboardLoading, setDashboardLoading] = useState(true)
  const [stayData, setStayData] = useState<GuestStayData | null>(null)
  const [stayLoading, setStayLoading] = useState(true)
  const [requests, setRequests] = useState<GuestRequest[]>([])
  const [requestsLoading, setRequestsLoading] = useState(true)
  const [messages, setMessages] = useState<MessagePublic[]>([])
  const [messagesLoading, setMessagesLoading] = useState(false)
  const [chatOpen, setChatOpen] = useState(false)
  const [services, setServices] = useState<GuestServiceCategory[]>([])
  const [servicesLoading, setServicesLoading] = useState(true)
  const [notifications, setNotifications] = useState<NotificationPublic[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [tab, setTab] = useState<GuestTab>('home')
  const [servicesView, setServicesView] = useState<'catalog' | 'requests'>('catalog')
  const [dialog, setDialog] = useState<GuestDialogKind>(null)

  const inflight = useRef<Set<string>>(new Set())

  // ── لوحة التحكم
  const refreshDashboard = useCallback(async () => {
    if (inflight.current.has('dash')) return
    inflight.current.add('dash')
    setDashboardLoading(true)
    try {
      const res = await api<GuestDashboardData & { ok: true }>('/api/guest/dashboard')
      setDashboard(res)
      setStayId(res.stay.id)
    } catch {
      // api-client يتكفل بإنهاء الجلسة عند 401
    } finally {
      setDashboardLoading(false)
      inflight.current.delete('dash')
    }
  }, [])

  // ── تفاصيل الإقامة
  const refreshStay = useCallback(async () => {
    if (inflight.current.has('stay')) return
    inflight.current.add('stay')
    setStayLoading(true)
    try {
      const res = await api<GuestStayData & { ok: true }>('/api/guest/stay')
      setStayData(res)
    } catch {
      // تجاهل — التبويب يعرض حالة الخطأ
    } finally {
      setStayLoading(false)
      inflight.current.delete('stay')
    }
  }, [])

  // ── الطلبات
  const refreshRequests = useCallback(async () => {
    if (inflight.current.has('req')) return
    inflight.current.add('req')
    setRequestsLoading(true)
    try {
      const res = await api<{ requests: GuestRequest[] }>('/api/guest/requests')
      setRequests(res.requests ?? [])
    } catch {
      // تجاهل
    } finally {
      setRequestsLoading(false)
      inflight.current.delete('req')
    }
  }, [])

  // ── الرسائل
  const refreshMessages = useCallback(async () => {
    if (inflight.current.has('msg')) return
    inflight.current.add('msg')
    try {
      const res = await api<{ messages: MessagePublic[] }>('/api/guest/messages')
      setMessages(res.messages ?? [])
    } catch {
      // تجاهل
    } finally {
      inflight.current.delete('msg')
    }
  }, [])

  const sendMessage = useCallback(
    async (body: string): Promise<boolean> => {
      try {
        const res = await api<{ message: MessagePublic }>('/api/guest/messages', {
          method: 'POST',
          body: { body },
        })
        if (res.message) setMessages((prev) => [...prev, res.message])
        return true
      } catch {
        return false
      }
    },
    []
  )

  // ── الخدمات
  const refreshServices = useCallback(async () => {
    if (inflight.current.has('svc')) return
    inflight.current.add('svc')
    setServicesLoading(true)
    try {
      const res = await api<{ categories: GuestServiceCategory[] }>('/api/guest/services')
      setServices(res.categories ?? [])
    } catch {
      // تجاهل
    } finally {
      setServicesLoading(false)
      inflight.current.delete('svc')
    }
  }, [])

  // ── الإشعارات
  const refreshNotifications = useCallback(async () => {
    if (inflight.current.has('notif')) return
    inflight.current.add('notif')
    try {
      const res = await api<{ notifications: NotificationPublic[]; unreadCount: number }>(
        '/api/guest/notifications'
      )
      setNotifications(res.notifications ?? [])
      setUnreadCount(res.unreadCount ?? 0)
    } catch {
      // تجاهل
    } finally {
      inflight.current.delete('notif')
    }
  }, [])

  const markAllRead = useCallback(async () => {
    try {
      await api('/api/guest/notifications/read', { method: 'POST' })
      setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
      setUnreadCount(0)
    } catch {
      // تجاهل
    }
  }, [])

  // ── التنقل
  const goRequests = useCallback(() => {
    setTab('services')
    setServicesView('requests')
  }, [])

  const openDialog = useCallback((d: Exclude<GuestDialogKind, null>) => setDialog(d), [])
  const closeDialog = useCallback(() => setDialog(null), [])

  // ── التحميل الأولي
  useEffect(() => {
    void refreshDashboard()
    void refreshNotifications()
    void refreshRequests()
    void refreshServices()
  }, [refreshDashboard, refreshNotifications, refreshRequests, refreshServices])

  // ── تفاصيل الإقامة عند فتح تبويبها فقط
  useEffect(() => {
    if (tab === 'stay' && !stayData) void refreshStay()
  }, [tab, stayData, refreshStay])

  // ── الرسائل عند فتح المحادثة + polling احتياطي كل 12 ثانية
  useEffect(() => {
    if (!chatOpen) return
    void refreshMessages()
    const timer = setInterval(() => void refreshMessages(), 12_000)
    return () => clearInterval(timer)
  }, [chatOpen, refreshMessages])

  const value = useMemo<GuestContextValue>(
    () => ({
      guestName,
      stayId,
      dashboard,
      dashboardLoading,
      refreshDashboard,
      stayData,
      stayLoading,
      refreshStay,
      requests,
      requestsLoading,
      refreshRequests,
      messages,
      messagesLoading,
      chatOpen,
      setChatOpen,
      refreshMessages,
      sendMessage,
      services,
      servicesLoading,
      refreshServices,
      notifications,
      unreadCount,
      notificationsOpen,
      setNotificationsOpen,
      refreshNotifications,
      markAllRead,
      tab,
      setTab,
      servicesView,
      setServicesView,
      goRequests,
      dialog,
      openDialog,
      closeDialog,
    }),
    [
      guestName,
      stayId,
      dashboard,
      dashboardLoading,
      refreshDashboard,
      stayData,
      stayLoading,
      refreshStay,
      requests,
      requestsLoading,
      refreshRequests,
      messages,
      messagesLoading,
      chatOpen,
      refreshMessages,
      sendMessage,
      services,
      servicesLoading,
      refreshServices,
      notifications,
      unreadCount,
      notificationsOpen,
      refreshNotifications,
      markAllRead,
      tab,
      servicesView,
      goRequests,
      dialog,
      openDialog,
      closeDialog,
    ]
  )

  return <GuestContext.Provider value={value}>{children}</GuestContext.Provider>
}

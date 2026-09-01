'use client'

// ─────────────────────────────────────────────────────────────
// NOTIFICATIONS SHEET — إشعارات الاستقبال (جانبية) + تحديد كمقروء
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Bell, CheckCheck, ConciergeBell, CalendarPlus, MessageSquare, Banknote, Info } from 'lucide-react'
import type { NotificationItem } from './types'
import { timeAgoAr } from '@/lib/format'

const TYPE_ICON: Record<string, React.ReactNode> = {
  REQUEST: <ConciergeBell className="w-4 h-4" />,
  EXTENSION: <CalendarPlus className="w-4 h-4" />,
  CHAT: <MessageSquare className="w-4 h-4" />,
  PAYMENT: <Banknote className="w-4 h-4" />,
}

export default function NotificationsSheet({
  open,
  onOpenChange,
  notifVersion,
  onRead,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  notifVersion: number
  onRead: (items: NotificationItem[]) => Promise<void> | void
}) {
  const [items, setItems] = useState<NotificationItem[] | null>(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!open) return
    let cancelled = false
    setLoading(true)
    ;(async () => {
      try {
        const res = await api<{ notifications: NotificationItem[] }>('/api/reception/notifications')
        if (!cancelled) {
          setItems(res.notifications)
          // تعليم المعروض كمقروء تلقائيًا
          void onRead(res.notifications)
        }
      } catch {
        if (!cancelled) setItems([])
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [open, notifVersion])

  const unread = (items ?? []).filter((n) => !n.read).length

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-md overflow-y-auto p-0" dir="rtl">
        <SheetHeader className="p-4 pb-3 border-b bg-card sticky top-0 z-10">
          <SheetTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-primary" /> الإشعارات
            {unread > 0 ? <Badge variant="destructive">{unread} جديد</Badge> : null}
          </SheetTitle>
          <SheetDescription>
            {items ? `${items.length} إشعار (آخر 30)` : 'جارٍ التحميل…'}
          </SheetDescription>
          <Button
            size="sm"
            variant="outline"
            className="mt-1 w-full"
            onClick={async () => {
              await api('/api/reception/notifications/read', { method: 'POST', body: {} })
              setItems((prev) => (prev ?? []).map((n) => ({ ...n, read: true })))
            }}
          >
            <CheckCheck className="w-4 h-4" /> تحديد الكل كمقروء
          </Button>
        </SheetHeader>

        <div className="p-3 space-y-2">
          {loading && !items ? (
            Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-lg" />)
          ) : items && items.length === 0 ? (
            <p className="text-center text-sm text-muted-foreground py-10">لا إشعارات بعد 🔕</p>
          ) : (
            (items ?? []).map((n) => (
              <article
                key={n.id}
                className={`rounded-lg border p-3 ${n.read ? 'bg-card' : 'bg-primary/5 border-primary/25'}`}
              >
                <div className="flex items-start gap-2.5">
                  <span className={`shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${n.read ? 'bg-muted text-muted-foreground' : 'bg-primary/10 text-primary'}`}>
                    {TYPE_ICON[n.type] ?? <Info className="w-4 h-4" />}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="font-bold text-sm leading-snug">{n.title}</p>
                    {n.body ? <p className="text-xs text-muted-foreground mt-0.5 leading-relaxed">{n.body}</p> : null}
                    <p className="text-[10px] text-muted-foreground/70 mt-1">{timeAgoAr(n.createdAt)}</p>
                  </div>
                  {!n.read ? <span className="w-2 h-2 rounded-full bg-primary shrink-0 mt-1.5" aria-label="غير مقروء" /> : null}
                </div>
              </article>
            ))
          )}
        </div>
      </SheetContent>
    </Sheet>
  )
}

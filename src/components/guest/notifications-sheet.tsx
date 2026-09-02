'use client'

// ─────────────────────────────────────────────────────────────
// NOTIFICATIONS SHEET — صفيحة إشعارات الضيف
// قائمة قابلة للتمرير + تعليم الكل كمقروء
// ─────────────────────────────────────────────────────────────

import { CheckCheck, Bell, Info } from 'lucide-react'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { useGuest } from './guest-context'
import { formatDateTimeAr, timeAgoAr } from '@/lib/format'
import { cn } from '@/lib/utils'

export default function NotificationsSheet() {
  const guest = useGuest()

  return (
    <Sheet open={guest.notificationsOpen} onOpenChange={guest.setNotificationsOpen}>
      <SheetContent side="right" className="flex w-full flex-col gap-0 p-0 sm:max-w-md" dir="rtl">
        <SheetHeader className="border-b border-border/70 bg-accent/40 p-4">
          <SheetTitle className="flex items-center gap-2 text-base">
            <span className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-primary-foreground">
              <Bell className="h-4.5 w-4.5" aria-hidden />
            </span>
            الإشعارات
            {guest.unreadCount > 0 ? (
              <span className="rounded-full bg-destructive px-2 py-0.5 text-[11px] font-bold text-white">
                {guest.unreadCount}
              </span>
            ) : null}
          </SheetTitle>
          <SheetDescription className="ps-11">
            تحديثات إقامتك وطلباتك لحظة بلحظة
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto p-3">
          {guest.notifications.length === 0 ? (
            <div className="flex h-full flex-col items-center justify-center gap-2 text-center">
              <Info className="h-10 w-10 text-muted-foreground/40" aria-hidden />
              <p className="text-sm font-bold text-muted-foreground">لا إشعارات بعد</p>
              <p className="max-w-56 text-xs text-muted-foreground/80">
                ستصلك هنا تحديثات الطلبات والرسائل وكل ما يخص إقامتك
              </p>
            </div>
          ) : (
            <ul className="space-y-2">
              {guest.notifications.map((n) => (
                <li
                  key={n.id}
                  className={cn(
                    'rounded-2xl border p-3.5 transition-colors',
                    n.read
                      ? 'border-border/50 bg-card/50'
                      : 'border-gold/40 bg-accent/50'
                  )}
                >
                  <div className="flex items-start justify-between gap-2">
                    <p className="flex items-center gap-2 text-sm font-bold">
                      {!n.read ? <span className="h-2 w-2 shrink-0 rounded-full bg-gold" aria-hidden /> : null}
                      {n.title}
                    </p>
                    <span className="shrink-0 text-[11px] text-muted-foreground">
                      {timeAgoAr(n.createdAt)}
                    </span>
                  </div>
                  {n.body ? (
                    <p className="mt-1 text-xs leading-relaxed text-muted-foreground">{n.body}</p>
                  ) : null}
                  <p className="mt-1.5 text-[10px] text-muted-foreground/70">
                    {formatDateTimeAr(n.createdAt)}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="border-t border-border/70 bg-card p-3">
          <Button
            onClick={() => void guest.markAllRead()}
            disabled={guest.unreadCount === 0}
            className="h-11 w-full gap-1.5"
            variant="outline"
          >
            <CheckCheck className="h-4.5 w-4.5" aria-hidden />
            {guest.unreadCount === 0 ? 'كل الإشعارات مقروءة' : 'تعليم الكل كمقروء'}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}

export function NotificationsSkeleton() {
  return (
    <div className="space-y-2 p-3" aria-busy="true">
      {Array.from({ length: 4 }).map((_, i) => (
        <Skeleton key={i} className="h-20 rounded-2xl" />
      ))}
    </div>
  )
}

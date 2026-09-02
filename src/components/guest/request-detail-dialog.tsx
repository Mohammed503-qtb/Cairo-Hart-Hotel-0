'use client'

// ─────────────────────────────────────────────────────────────
// REQUEST DETAIL DIALOG — تفاصيل الطلب
// معلومات + خط زمني التحديثات + إلغاء (جديد/قيد الاطلاع فقط)
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { Ban, ClipboardList, User } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import { useToast } from '@/hooks/use-toast'
import { api } from '@/lib/api-client'
import {
  REQUEST_STATUS_LABELS,
  formatDateTimeAr,
  timeAgoAr,
} from '@/lib/format'
import { DoneMark, RequestStatusBadge, UrgentMark } from './bits'
import type { GuestRequest } from './types'

const CANCELLABLE = ['NEW', 'ACKNOWLEDGED']

const CATEGORY_LABELS: Record<string, string> = {
  HOUSEKEEPING: 'خدمات التنظيف',
  MAINTENANCE: 'الصيانة',
  GUEST_SERVICES: 'خدمات الضيافة',
  OTHER: 'طلب خاص',
}

export default function RequestDetailDialog({
  request,
  onClose,
  onChanged,
}: {
  request: GuestRequest | null
  onClose: () => void
  onChanged: () => void
}) {
  const { toast } = useToast()
  const [cancelling, setCancelling] = useState(false)

  const cancel = async () => {
    if (!request || cancelling) return
    setCancelling(true)
    try {
      await api(`/api/guest/requests/${request.id}/cancel`, { method: 'POST' })
      toast({ title: 'تم إلغاء الطلب', description: request.reference })
      onChanged()
      onClose()
    } catch (err) {
      toast({
        title: 'تعذر إلغاء الطلب',
        description: err instanceof Error ? err.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setCancelling(false)
    }
  }

  if (!request) return null

  return (
    <Dialog
      open={request !== null}
      onOpenChange={(open) => {
        if (!open) onClose()
      }}
    >
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center gap-2 pe-6">
            <span className="min-w-0">{request.title}</span>
            {request.priority === 'URGENT' && <UrgentMark />}
          </DialogTitle>
          <DialogDescription className="flex flex-wrap items-center gap-x-3 gap-y-1">
            <span dir="auto">{request.reference}</span>
            <span>الغرفة {request.roomNumber}</span>
            <span>{CATEGORY_LABELS[request.category] ?? request.category}</span>
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            <RequestStatusBadge status={request.status} />
            <span className="text-xs text-muted-foreground">
              أُنشئ {timeAgoAr(request.createdAt)}
            </span>
          </div>

          {request.description ? (
            <p className="rounded-xl bg-muted/50 p-3 text-sm leading-relaxed">
              {request.description}
            </p>
          ) : null}

          {request.assignedTo ? (
            <p className="flex items-center gap-2 text-sm text-muted-foreground">
              <User className="h-4 w-4" aria-hidden />
              المسند إلى: <span className="font-bold text-foreground">{request.assignedTo}</span>
            </p>
          ) : null}

          <Separator />

          {/* الخط الزمني */}
          <div>
            <p className="mb-3 flex items-center gap-2 text-sm font-bold">
              <ClipboardList className="h-4 w-4 text-primary" aria-hidden />
              سجل الطلب
            </p>
            <ol className="relative space-y-4 border-r-2 border-border pr-4">
              {request.updates.map((u, i) => (
                <li key={u.id} className="relative">
                  <span
                    className="absolute -right-[1.4rem] top-0.5 flex h-4.5 w-4.5 items-center justify-center rounded-full bg-muted text-muted-foreground"
                    aria-hidden
                  >
                    {i === request.updates.length - 1 ? (
                      <DoneMark className="h-3 w-3" />
                    ) : (
                      <span className="h-1.5 w-1.5 rounded-full bg-current" />
                    )}
                  </span>
                  <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5">
                    {u.status ? (
                      <span className="text-sm font-bold">
                        {REQUEST_STATUS_LABELS[u.status] ?? u.status}
                      </span>
                    ) : null}
                    <span className="text-[11px] text-muted-foreground">
                      {formatDateTimeAr(u.createdAt)}
                    </span>
                  </div>
                  {u.note ? (
                    <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">{u.note}</p>
                  ) : null}
                  <p className="mt-0.5 text-[11px] text-muted-foreground">
                    بواسطة {u.byName}
                    {u.byRole === 'GUEST' ? ' (أنت)' : ''}
                  </p>
                </li>
              ))}
            </ol>
          </div>
        </div>

        {CANCELLABLE.includes(request.status) ? (
          <DialogFooter>
            <Button
              variant="destructive"
              onClick={cancel}
              disabled={cancelling}
              className="h-11 w-full gap-1.5"
            >
              <Ban className="h-4 w-4" aria-hidden />
              {cancelling ? 'جارٍ الإلغاء…' : 'إلغاء الطلب'}
            </Button>
          </DialogFooter>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}

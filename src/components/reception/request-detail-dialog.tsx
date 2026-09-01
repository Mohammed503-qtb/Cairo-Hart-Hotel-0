'use client'

// ─────────────────────────────────────────────────────────────
// REQUEST DETAIL DIALOG — تفاصيل الطلب + خط زمني + إجراءات الحالة
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Zap, ConciergeBell, Loader2, CheckCircle2, XCircle, Ban, Clock, UserCheck, UserPlus, Play, PauseCircle } from 'lucide-react'
import type { RequestItem } from './types'
import { RefCode, RequestStatusBadge, PriorityBadge } from './bits'
import { formatDateTimeAr, timeAgoAr } from '@/lib/format'

/** الإجراءات المتاحة لكل حالة */
const ACTIONS: Record<string, { status: string; label: string; icon: typeof CheckCircle2; variant?: 'default' | 'secondary' | 'outline' | 'destructive'; confirm?: boolean }[]> = {
  NEW: [
    { status: 'ACKNOWLEDGED', label: 'استلام', icon: UserCheck },
    { status: 'ASSIGNED', label: 'إسناد', icon: UserPlus },
    { status: 'REJECTED', label: 'رفض', icon: XCircle, variant: 'destructive', confirm: true },
    { status: 'CANCELLED', label: 'إلغاء', icon: Ban, variant: 'outline', confirm: true },
  ],
  ACKNOWLEDGED: [
    { status: 'ASSIGNED', label: 'إسناد', icon: UserPlus },
    { status: 'IN_PROGRESS', label: 'بدء التنفيذ', icon: Play },
    { status: 'CANCELLED', label: 'إلغاء', icon: Ban, variant: 'outline', confirm: true },
  ],
  ASSIGNED: [
    { status: 'IN_PROGRESS', label: 'بدء التنفيذ', icon: Play },
    { status: 'WAITING', label: 'انتظار', icon: PauseCircle, variant: 'outline' },
    { status: 'CANCELLED', label: 'إلغاء', icon: Ban, variant: 'outline', confirm: true },
  ],
  IN_PROGRESS: [
    { status: 'COMPLETED', label: 'إكمال', icon: CheckCircle2, variant: 'secondary' },
    { status: 'WAITING', label: 'انتظار', icon: PauseCircle, variant: 'outline' },
    { status: 'CANCELLED', label: 'إلغاء', icon: Ban, variant: 'outline', confirm: true },
  ],
  WAITING: [
    { status: 'IN_PROGRESS', label: 'بدء التنفيذ', icon: Play },
    { status: 'COMPLETED', label: 'إكمال', icon: CheckCircle2, variant: 'secondary' },
    { status: 'CANCELLED', label: 'إلغاء', icon: Ban, variant: 'outline', confirm: true },
  ],
}

const ASSIGNEE_TEAMS = ['التنظيف', 'الصيانة', 'الاستقبال']

export default function RequestDetailDialog({
  requestId,
  onClose,
}: {
  requestId: string
  onClose: () => void
}) {
  const { toast } = useToast()
  const [request, setRequest] = useState<RequestItem | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [note, setNote] = useState('')
  const [assignedTo, setAssignedTo] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [confirmAction, setConfirmAction] = useState<{ status: string; label: string } | null>(null)

  const load = async () => {
    try {
      const res = await api<{ requests: RequestItem[] }>('/api/reception/requests')
      const found = res.requests.find((r) => r.id === requestId)
      if (!found) {
        setError('لم يتم العثور على الطلب')
      } else {
        setRequest(found)
        setError(null)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'تعذر تحميل الطلب')
    }
  }

  useEffect(() => {
    void load()
  }, [requestId])

  const applyStatus = async (status: string, noteText: string, assignee: string) => {
    setBusy(status)
    try {
      const res = await api<{ request: RequestItem }>(`/api/reception/requests/${requestId}/status`, {
        method: 'POST',
        body: { status, note: noteText || undefined, assignedTo: assignee || undefined },
      })
      setRequest(res.request)
      setNote('')
      setAssignedTo('')
      toast({ title: 'تم تحديث الطلب ✅', description: res.request.title })
    } catch (e) {
      toast({ title: 'تعذر تحديث الطلب', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setBusy(null)
    }
  }

  const actions = request ? (ACTIONS[request.status] ?? []) : []
  const needsAssignee = (status: string) => status === 'ASSIGNED'

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg max-h-[92vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center gap-2">
            {request ? (
              <>
                <span className={request.priority === 'URGENT' ? 'text-destructive' : ''}>{request.title}</span>
                {request.priority === 'URGENT' ? (
                  <span className="w-7 h-7 rounded-full bg-destructive/10 flex items-center justify-center urgent-pulse">
                    <Zap className="w-4 h-4 text-destructive" />
                  </span>
                ) : null}
              </>
            ) : (
              'تفاصيل الطلب'
            )}
          </DialogTitle>
          {request ? (
            <DialogDescription className="flex flex-wrap items-center gap-2">
              <RefCode>{request.reference}</RefCode>
              <span>·</span>
              <span>غرفة {request.stay.roomNumber} — {request.stay.guestName}</span>
              <RequestStatusBadge status={request.status} />
              <PriorityBadge priority={request.priority} />
            </DialogDescription>
          ) : (
            <DialogDescription>جارٍ تحميل تفاصيل الطلب…</DialogDescription>
          )}
        </DialogHeader>

        {error ? <p className="text-sm text-destructive font-bold">{error}</p> : null}

        {!request ? (
          <div className="space-y-2">
            <Skeleton className="h-20 rounded-lg" />
            <Skeleton className="h-32 rounded-lg" />
          </div>
        ) : (
          <div className="space-y-4">
            {request.description ? (
              <p className="rounded-lg border bg-muted/30 p-3 text-sm leading-relaxed">{request.description}</p>
            ) : null}

            {request.assignedTo ? (
              <p className="text-xs text-muted-foreground flex items-center gap-1.5">
                <UserPlus className="w-3.5 h-3.5" /> مُسند إلى: <b>{request.assignedTo}</b>
              </p>
            ) : null}

            {/* الخط الزمني */}
            <div className="rounded-lg border p-3">
              <p className="font-bold text-xs text-muted-foreground mb-2">الخط الزمني</p>
              <ol className="relative border-s-2 border-border ms-2 space-y-3">
                <li className="ps-3">
                  <span className="absolute -start-[7px] w-3.5 h-3.5 rounded-full bg-primary border-2 border-card" />
                  <p className="text-xs"><b>أُنشئ</b> · {formatDateTimeAr(request.createdAt)}</p>
                </li>
                {request.updates.map((u) => (
                  <li key={u.id} className="ps-3">
                    <span className="absolute -start-[5px] w-3 h-3 rounded-full bg-gold border-2 border-card" />
                    <p className="text-xs">
                      {u.status ? <RequestStatusBadge status={u.status} /> : null}
                      <span className="text-muted-foreground"> · {u.byName} ({u.byRole === 'RECEPTION' ? 'الاستقبال' : u.byRole === 'GUEST' ? 'الضيف' : 'النظام'}) · {timeAgoAr(u.createdAt)}</span>
                    </p>
                    {u.note ? <p className="text-xs mt-0.5 text-foreground/80">{u.note}</p> : null}
                  </li>
                ))}
                {request.completedAt ? (
                  <li className="ps-3">
                    <span className="absolute -start-[5px] w-3 h-3 rounded-full bg-success border-2 border-card" />
                    <p className="text-xs text-success font-bold">اكتمل · {formatDateTimeAr(request.completedAt)}</p>
                  </li>
                ) : null}
              </ol>
            </div>

            {/* الإجراءات */}
            {actions.length > 0 ? (
              <div className="space-y-3 rounded-lg border bg-card p-3">
                <p className="text-xs font-bold text-muted-foreground flex items-center gap-1.5">
                  <ConciergeBell className="w-4 h-4" /> إجراءات الاستقبال
                </p>

                <Textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="ملاحظة تُضاف للخط الزمني (اختياري)…"
                  rows={2}
                  className="resize-none"
                />

                {actions.some((a) => needsAssignee(a.status)) ? (
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-muted-foreground shrink-0">إسناد إلى:</span>
                    <Select value={assignedTo} onValueChange={setAssignedTo}>
                      <SelectTrigger className="w-36" aria-label="الفريق">
                        <SelectValue placeholder="اختر فريقًا" />
                      </SelectTrigger>
                      <SelectContent>
                        {ASSIGNEE_TEAMS.map((t) => (
                          <SelectItem key={t} value={t}>{t}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                ) : null}

                <div className="flex flex-wrap gap-2">
                  {actions.map((a) => {
                    const Icon = a.icon
                    if (a.confirm) {
                      return (
                        <Button
                          key={a.status}
                          size="sm"
                          variant={a.variant ?? 'outline'}
                          onClick={() => setConfirmAction({ status: a.status, label: a.label })}
                          disabled={busy !== null}
                        >
                          <Icon className="w-4 h-4" /> {a.label}
                        </Button>
                      )
                    }
                    const disabled = needsAssignee(a.status) && !assignedTo
                    return (
                      <Button
                        key={a.status}
                        size="sm"
                        variant={a.variant ?? 'default'}
                        onClick={() => applyStatus(a.status, note, assignedTo)}
                        disabled={busy !== null || disabled}
                        title={disabled ? 'اختر الفريق أولًا' : undefined}
                        className={a.status === 'COMPLETED' ? 'bg-success text-white hover:bg-success/90' : undefined}
                      >
                        {busy === a.status ? <Loader2 className="w-4 h-4 animate-spin" /> : <Icon className="w-4 h-4" />}
                        {a.label}
                      </Button>
                    )
                  })}
                </div>
              </div>
            ) : (
              <p className="rounded-lg border border-dashed p-3 text-center text-sm text-muted-foreground">
                <Clock className="w-4 h-4 inline me-1" />
                الطلب منتهٍ — لا مزيد من الإجراءات
              </p>
            )}
          </div>
        )}

        <div className="flex justify-end">
          <Button variant="outline" onClick={onClose}>إغلاق</Button>
        </div>

        {confirmAction ? (
          <AlertDialog open onOpenChange={(open) => !open && setConfirmAction(null)}>
            <AlertDialogContent dir="rtl">
              <AlertDialogHeader>
                <AlertDialogTitle>تأكيد «{confirmAction.label}»؟</AlertDialogTitle>
                <AlertDialogDescription>
                  سيتم إشعار الضيف بهذا القرار ولا يمكن التراجع عن الطلب بعد ذلك.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>تراجع</AlertDialogCancel>
                <AlertDialogAction
                  onClick={() => {
                    const a = confirmAction
                    setConfirmAction(null)
                    void applyStatus(a.status, note, assignedTo)
                  }}
                >
                  نعم، أكّد
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}

'use client'

// ─────────────────────────────────────────────────────────────
// ROOM DIALOG — بطاقة الغرفة + انتقالات التنظيف / خارج الخدمة
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
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
import {
  SprayCan,
  CheckCircle2,
  Wrench,
  RotateCcw,
  Loader2,
  Users,
  CalendarClock,
  DoorClosed,
  AlertTriangle,
} from 'lucide-react'
import type { RoomItem } from './types'
import { roomStatusLabel, ROOM_CARD_STYLE } from './bits'
import { formatDateWithDayAr } from '@/lib/format'

export default function RoomDialog({
  room,
  onClose,
  onShowStay,
  onChanged,
}: {
  room: RoomItem
  onClose: () => void
  onShowStay: (stayId: string) => void
  onChanged?: () => void
}) {
  const { toast } = useToast()
  const [busy, setBusy] = useState<string | null>(null)
  const [notes, setNotes] = useState('')
  const [confirm, setConfirm] = useState<{ status: string; label: string } | null>(null)

  const applyStatus = async (status: string, extraNotes?: string) => {
    setBusy(status)
    try {
      await api(`/api/reception/rooms/${room.id}/status`, {
        method: 'POST',
        body: { status, notes: extraNotes },
      })
      toast({ title: `الغرفة ${room.number}: ${roomStatusLabel(status)} ✅` })
      onChanged?.()
      onClose()
    } catch (e) {
      toast({ title: 'تعذر تغيير حالة الغرفة', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setBusy(null)
    }
  }

  const cardStyle = ROOM_CARD_STYLE[room.status] ?? 'bg-muted border-border'

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <span className={`w-14 h-14 rounded-lg border-2 flex items-center justify-center text-2xl font-black ${cardStyle}`} dir="ltr">
              {room.number}
            </span>
            <span className="flex flex-col gap-1">
              <span>{roomStatusLabel(room.status)}</span>
              <span className="text-xs font-normal text-muted-foreground">
                {room.roomTypeName} · طابق {room.floor}
              </span>
            </span>
          </DialogTitle>
          <DialogDescription>
            {room.status === 'OCCUPIED' && room.guestName
              ? `مشغولة — ${room.guestName}${room.expectedCheckOutAt ? ` · خروج ${formatDateWithDayAr(room.expectedCheckOutAt)}` : ''}`
              : `${room.roomTypeName} · طابق ${room.floor}`}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          {room.status === 'OCCUPIED' && room.guestName ? (
            <div className="rounded-lg border bg-muted/30 p-3 flex items-center gap-2 text-sm">
              <Users className="w-4 h-4 text-primary" />
              <span className="font-bold">{room.guestName}</span>
              {room.expectedCheckOutAt ? (
                <Badge variant="outline" className="ms-auto text-[10px]">
                  <CalendarClock className="w-3 h-3" /> {formatDateWithDayAr(room.expectedCheckOutAt)}
                </Badge>
              ) : null}
            </div>
          ) : null}

          {room.notes ? (
            <p className="rounded-lg border border-muted bg-muted/40 p-2.5 text-xs flex items-start gap-1.5">
              <AlertTriangle className="w-3.5 h-3.5 text-warning shrink-0 mt-0.5" />
              {room.notes}
            </p>
          ) : null}

          {/* الانتقالات حسب الحالة */}
          {room.status === 'DIRTY' ? (
            <div className="flex flex-wrap gap-2">
              <Button size="sm" onClick={() => applyStatus('CLEANING')} disabled={busy !== null}>
                {busy === 'CLEANING' ? <Loader2 className="w-4 h-4 animate-spin" /> : <SprayCan className="w-4 h-4" />}
                بدء التنظيف
              </Button>
              <Button size="sm" variant="secondary" onClick={() => setConfirm({ status: 'AVAILABLE', label: 'اعتمادها متاحة مباشرة' })} disabled={busy !== null}>
                <CheckCircle2 className="w-4 h-4" /> متاحة
              </Button>
            </div>
          ) : null}

          {room.status === 'CLEANING' ? (
            <Button size="sm" onClick={() => applyStatus('AVAILABLE')} disabled={busy !== null}>
              {busy === 'AVAILABLE' ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
              اكتمل التنظيف → متاحة
            </Button>
          ) : null}

          {room.status === 'AVAILABLE' ? (
            <div className="space-y-2">
              <Textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="سبب إخراج الغرفة من الخدمة (اختياري)…"
                rows={2}
                className="resize-none"
              />
              <Button size="sm" variant="destructive" onClick={() => setConfirm({ status: 'OUT_OF_ORDER', label: 'خارج الخدمة' })} disabled={busy !== null}>
                {busy === 'OUT_OF_ORDER' ? <Loader2 className="w-4 h-4 animate-spin" /> : <Wrench className="w-4 h-4" />}
                خارج الخدمة
              </Button>
            </div>
          ) : null}

          {room.status === 'OUT_OF_ORDER' ? (
            <Button size="sm" onClick={() => applyStatus('AVAILABLE')} disabled={busy !== null}>
              {busy === 'AVAILABLE' ? <Loader2 className="w-4 h-4 animate-spin" /> : <RotateCcw className="w-4 h-4" />}
              إعادة للخدمة
            </Button>
          ) : null}

          {room.status === 'OCCUPIED' && room.activeStayId ? (
            <Button size="sm" variant="secondary" onClick={() => onShowStay(room.activeStayId!)}>
              <DoorClosed className="w-4 h-4" /> عرض الإقامة
            </Button>
          ) : null}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>إغلاق</Button>
        </DialogFooter>

        {confirm ? (
          <AlertDialog open onOpenChange={(open) => !open && setConfirm(null)}>
            <AlertDialogContent dir="rtl">
              <AlertDialogHeader>
                <AlertDialogTitle>
                  {confirm.status === 'AVAILABLE' ? 'اعتماد الغرفة متاحة؟' : 'إخراج الغرفة من الخدمة؟'}
                </AlertDialogTitle>
                <AlertDialogDescription>
                  {confirm.status === 'AVAILABLE'
                    ? `سيتم اعتماد الغرفة ${room.number} كمتاحة للحجز مباشرة دون مرحلة التنظيف.`
                    : `الغرفة ${room.number} لن تُحسب ضمن المخزون المتاح حتى إعادتها للخدمة.`}
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>تراجع</AlertDialogCancel>
                <AlertDialogAction
                  onClick={() => {
                    const a = confirm
                    setConfirm(null)
                    void applyStatus(a.status, a.status === 'OUT_OF_ORDER' ? notes : undefined)
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

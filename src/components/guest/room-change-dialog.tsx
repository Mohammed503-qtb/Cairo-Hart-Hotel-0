'use client'

// ─────────────────────────────────────────────────────────────
// ROOM CHANGE DIALOG — طلب تغيير الغرفة
// الغرف المتاحة (رقم/طابق/نوع/فرق السعر) + سبب
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useState } from 'react'
import { ArrowLeftRight, BedDouble, Loader2, MapPin, Send } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { useToast } from '@/hooks/use-toast'
import { useGuest } from './guest-context'
import { api } from '@/lib/api-client'
import { formatMoney } from '@/lib/format'
import { cn } from '@/lib/utils'
import type { RoomChangeResult, RoomOption } from './types'

export default function RoomChangeDialog() {
  const guest = useGuest()
  const { toast } = useToast()
  const open = guest.dialog === 'room-change'

  const [rooms, setRooms] = useState<RoomOption[]>([])
  const [current, setCurrent] = useState<{ number: string; typeName: string } | null>(null)
  const [loading, setLoading] = useState(false)
  const [selected, setSelected] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [sending, setSending] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api<{
        rooms: RoomOption[]
        currentRoom: { number: string; typeName: string }
      }>('/api/guest/room-options')
      setRooms(res.rooms)
      setCurrent(res.currentRoom)
      setSelected(null)
    } catch {
      setRooms([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (open) {
      setReason('')
      void load()
    }
  }, [open, load])

  const submit = async () => {
    if (!selected || sending) return
    setSending(true)
    try {
      const res = await api<RoomChangeResult>('/api/guest/room-change', {
        method: 'POST',
        body: { toRoomId: selected, reason: reason.trim() || undefined },
      })
      const diff = res.request.priceDiffCents
      toast({
        title: `تم إرسال طلب الانتقال إلى الغرفة ${res.request.toRoomNumber} ✅`,
        description:
          diff === 0
            ? 'بدون فرق سعر — بانتظار موافقة الاستقبال'
            : `${diff > 0 ? 'فرق سعر' : 'وفرة'} ${formatMoney(Math.abs(diff))} — بانتظار موافقة الاستقبال`,
        duration: 8000,
      })
      guest.closeDialog()
    } catch (err) {
      toast({
        title: 'تعذر إرسال الطلب',
        description: err instanceof Error ? err.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setSending(false)
    }
  }

  const selectedRoom = rooms.find((r) => r.roomId === selected)

  return (
    <Dialog open={open} onOpenChange={(o) => (o ? guest.openDialog('room-change') : guest.closeDialog())}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg">
            <ArrowLeftRight className="h-5 w-5 text-gold" aria-hidden />
            تغيير الغرفة
          </DialogTitle>
          <DialogDescription>
            {current ? `غرفتك الحالية ${current.number} — ${current.typeName}` : 'اختر غرفتك الجديدة'}
            <span className="block">الطلب يخضع لموافقة الاستقبال</span>
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          {loading ? (
            <>
              <Skeleton className="h-16 rounded-xl" />
              <Skeleton className="h-16 rounded-xl" />
              <Skeleton className="h-16 rounded-xl" />
            </>
          ) : rooms.length === 0 ? (
            <p className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-muted-foreground">
              لا غرف متاحة للنقل حاليًا — جرّب لاحقًا
            </p>
          ) : (
            <div className="space-y-2" role="radiogroup" aria-label="الغرف المتاحة">
              {rooms.map((r) => {
                const active = selected === r.roomId
                return (
                  <button
                    key={r.roomId}
                    role="radio"
                    aria-checked={active}
                    onClick={() => setSelected(r.roomId)}
                    className={cn(
                      'flex w-full items-center justify-between gap-3 rounded-xl border p-3 text-start transition-all',
                      active
                        ? 'border-primary bg-primary/5 ring-2 ring-primary/20'
                        : 'border-border hover:border-primary/40'
                    )}
                  >
                    <div className="flex items-center gap-3">
                      <span
                        className={cn(
                          'flex h-10 w-10 items-center justify-center rounded-lg font-extrabold',
                          active ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground'
                        )}
                        dir="ltr"
                      >
                        {r.number}
                      </span>
                      <div>
                        <p className="text-sm font-bold">{r.typeName}</p>
                        <p className="flex items-center gap-1 text-[11px] text-muted-foreground">
                          <MapPin className="h-3 w-3" aria-hidden />
                          الطابق {r.floor}
                        </p>
                      </div>
                    </div>
                    <span
                      className={cn(
                        'shrink-0 rounded-full px-2.5 py-1 text-xs font-bold',
                        r.diffCents === 0
                          ? 'bg-success/10 text-success'
                          : r.diffCents > 0
                            ? 'bg-warning/10 text-warning'
                            : 'bg-primary/10 text-primary'
                      )}
                    >
                      {r.diffCents === 0
                        ? 'بدون فرق'
                        : r.diffCents > 0
                          ? `+${formatMoney(r.diffCents)}`
                          : `−${formatMoney(Math.abs(r.diffCents))}`}
                    </span>
                  </button>
                )
              })}
            </div>
          )}

          <div className="space-y-1.5">
            <Label htmlFor="rc-reason">سبب التغيير (اختياري)</Label>
            <Textarea
              id="rc-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="مثال: أرغب بإطلالة أفضل..."
              rows={2}
              maxLength={300}
            />
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={guest.closeDialog} className="h-11" disabled={sending}>
            إلغاء
          </Button>
          <Button
            onClick={submit}
            disabled={sending || !selected}
            className="h-11 min-w-28 gap-1.5"
          >
            {sending ? (
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
            ) : (
              <BedDouble className="h-4 w-4" aria-hidden />
            )}
            {selectedRoom ? `طلب الغرفة ${selectedRoom.number}` : 'إرسال الطلب'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

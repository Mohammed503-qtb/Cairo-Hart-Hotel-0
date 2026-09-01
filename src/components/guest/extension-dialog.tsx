'use client'

// ─────────────────────────────────────────────────────────────
// EXTENSION DIALOG — طلب تمديد الإقامة
// الخروج الحالي + التاريخ الجديد + الليالي المحسوبة + ملاحظة
// ─────────────────────────────────────────────────────────────

import { useEffect, useMemo, useState } from 'react'
import { CalendarClock, Loader2, Moon, Send } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { useToast } from '@/hooks/use-toast'
import { useGuest } from './guest-context'
import { api } from '@/lib/api-client'
import {
  addDaysInput,
  formatDateAr,
  formatMoney,
  nightsBetweenDates,
} from '@/lib/format'
import type { ExtensionResult } from './types'

export default function ExtensionDialog() {
  const guest = useGuest()
  const { toast } = useToast()
  const open = guest.dialog === 'extension'

  const stay = guest.dashboard?.stay
  const expectedKey = useMemo(() => {
    if (!stay) return ''
    const d = new Date(stay.expectedCheckOutAt)
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }, [stay])

  const minKey = expectedKey ? addDaysInput(expectedKey, 1) : ''

  const [newCheckOut, setNewCheckOut] = useState('')
  const [note, setNote] = useState('')
  const [sending, setSending] = useState(false)

  useEffect(() => {
    if (open) {
      setNewCheckOut(minKey || '')
      setNote('')
    }
  }, [open, minKey])

  const nights = newCheckOut ? nightsBetweenDates(expectedKey, newCheckOut) : 0

  const submit = async () => {
    if (!newCheckOut || sending) return
    if (nights < 1) {
      toast({ title: 'اختر تاريخًا بعد الخروج الحالي', variant: 'destructive' })
      return
    }
    setSending(true)
    try {
      const res = await api<ExtensionResult>('/api/guest/extension', {
        method: 'POST',
        body: { newCheckOut, note: note.trim() || undefined },
      })
      toast({
        title: 'تم إرسال طلب التمديد ✅',
        description: `التكلفة التقديرية ${formatMoney(res.quote.grandTotalCents, res.quote.currency)} لـ ${res.quote.nights} ${
          res.quote.nights === 1 ? 'ليلة' : 'ليالٍ'
        } — بانتظار موافقة الاستقبال`,
        duration: 8000,
      })
      guest.closeDialog()
      void guest.refreshDashboard()
    } catch (err) {
      toast({
        title: 'تعذر إرسال طلب التمديد',
        description: err instanceof Error ? err.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setSending(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={(o) => (o ? guest.openDialog('extension') : guest.closeDialog())}>
      <DialogContent className="sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg">
            <CalendarClock className="h-5 w-5 text-gold" aria-hidden />
            تمديد الإقامة
          </DialogTitle>
          <DialogDescription>طلبك يخضع لتوفر الغرفة وموافقة الاستقبال</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="flex items-center gap-3 rounded-xl bg-muted/50 p-3">
            <span className="flex h-10 w-10 items-center justify-center rounded-full bg-accent text-primary">
              <Moon className="h-4.5 w-4.5" aria-hidden />
            </span>
            <div>
              <p className="text-xs text-muted-foreground">الخروج الحالي</p>
              <p className="text-sm font-bold">
                {stay ? formatDateAr(stay.expectedCheckOutAt) : '—'}
              </p>
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="ext-date">تاريخ الخروج الجديد</Label>
            <Input
              id="ext-date"
              type="date"
              value={newCheckOut}
              min={minKey || undefined}
              onChange={(e) => setNewCheckOut(e.target.value)}
              className="h-11"
            />
            {nights > 0 ? (
              <p className="pt-1 text-xs font-bold text-primary">
                {nights} {nights === 1 ? 'ليلة إضافية' : 'ليالٍ إضافية'} — التكلفة التقديرية تُحسب عند الإرسال
              </p>
            ) : null}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="ext-note">ملاحظة (اختياري)</Label>
            <Textarea
              id="ext-note"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="سبب التمديد أو أي تفاصيل..."
              rows={2}
              maxLength={300}
            />
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={guest.closeDialog} className="h-11" disabled={sending}>
            إلغاء
          </Button>
          <Button onClick={submit} disabled={sending || !newCheckOut} className="h-11 min-w-28 gap-1.5">
            {sending ? (
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
            ) : (
              <Send className="h-4 w-4 -scale-x-100" aria-hidden />
            )}
            إرسال الطلب
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

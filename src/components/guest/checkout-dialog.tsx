'use client'

// ─────────────────────────────────────────────────────────────
// CHECKOUT DIALOG — طلب تسجيل الخروج
// ملخص الرصيد + تحذير التسوية + تأكيد
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { AlertTriangle, ArrowUpRight, Loader2 } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { useToast } from '@/hooks/use-toast'
import { useGuest } from './guest-context'
import { api } from '@/lib/api-client'
import { formatMoney } from '@/lib/format'
import { cn } from '@/lib/utils'

export default function CheckoutDialog() {
  const guest = useGuest()
  const { toast } = useToast()
  const open = guest.dialog === 'checkout'

  const [sending, setSending] = useState(false)

  const dash = guest.dashboard
  const balance = dash?.balanceCents ?? 0
  const currency = dash?.currency ?? 'USD'

  const submit = async () => {
    if (sending) return
    setSending(true)
    try {
      const res = await api<{ balanceCents: number }>('/api/guest/checkout-request', {
        method: 'POST',
      })
      toast({
        title: 'تم إرسال طلب الخروج ✅',
        description:
          res.balanceCents > 0
            ? `يرجى تسوية الرصيد (${formatMoney(res.balanceCents, currency)}) لدى الاستقبال`
            : 'سيجهّز الاستقبال مغادرتك خلال دقائق',
        duration: 8000,
      })
      guest.closeDialog()
      void guest.refreshDashboard()
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

  return (
    <Dialog open={open} onOpenChange={(o) => (o ? guest.openDialog('checkout') : guest.closeDialog())}>
      <DialogContent className="sm:max-w-sm" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg">
            <ArrowUpRight className="h-5 w-5 text-gold" aria-hidden />
            طلب تسجيل الخروج
          </DialogTitle>
          <DialogDescription>
            سيُبلَغ الاستقبال لتجهيز مغادرتك الآن
          </DialogDescription>
        </DialogHeader>

        <div
          className={cn(
            'rounded-2xl border p-4',
            balance > 0
              ? 'border-warning/40 bg-warning/10'
              : 'border-success/40 bg-success/10'
          )}
        >
          <p className="text-xs text-muted-foreground">رصيد إقامتك الحالي</p>
          <p
            className={cn(
              'font-mono text-3xl font-extrabold tabular-nums',
              balance > 0 ? 'text-destructive' : 'text-success'
            )}
            dir="ltr"
          >
            {formatMoney(balance, currency)}
          </p>
          {balance > 0 ? (
            <p className="mt-2 flex items-start gap-2 text-xs leading-relaxed text-foreground">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-warning" aria-hidden />
              يرجى تسوية الرصيد لدى الاستقبال قبل الخروج.
            </p>
          ) : (
            <p className="mt-2 text-xs text-muted-foreground">حسابك مسوّى — لا مستحقات عليك</p>
          )}
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={guest.closeDialog} className="h-11" disabled={sending}>
            رجوع
          </Button>
          <Button onClick={submit} disabled={sending} className="h-11 min-w-32 gap-1.5">
            {sending ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : null}
            تأكيد طلب الخروج
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

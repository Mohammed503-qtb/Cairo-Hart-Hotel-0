'use client'

// ─────────────────────────────────────────────────────────────
// PAYMENT DIALOG — تسجيل دفعة على إقامة (نقدًا/بطاقة/حوالة)
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Banknote, Loader2 } from 'lucide-react'
import { formatMoney } from '@/lib/format'

export default function PaymentDialog({
  stayId,
  defaultAmountCents,
  balanceCents,
  onClose,
  onDone,
}: {
  stayId: string
  defaultAmountCents?: number
  balanceCents?: number
  onClose: () => void
  onDone: () => void
}) {
  const { toast } = useToast()
  const [method, setMethod] = useState('CASH')
  const [amount, setAmount] = useState(((defaultAmountCents ?? 0) / 100).toFixed(2))
  const [note, setNote] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (defaultAmountCents !== undefined) setAmount((defaultAmountCents / 100).toFixed(2))
  }, [defaultAmountCents])

  const submit = async () => {
    const amountCents = Math.round(parseFloat(amount || '0') * 100)
    if (!Number.isFinite(amountCents) || amountCents <= 0) {
      toast({ title: 'أدخل مبلغًا صحيحًا أكبر من صفر', variant: 'destructive' })
      return
    }
    setLoading(true)
    try {
      const res = await api<{ balanceCents: number }>('/api/reception/payments', {
        method: 'POST',
        body: { stayId, method, amountCents, note: note.trim() || undefined },
      })
      toast({ title: `تم تسجيل دفعة ${formatMoney(amountCents)} ✅`, description: `الرصيد الآن: ${formatMoney(res.balanceCents)}` })
      onDone()
    } catch (e) {
      toast({ title: 'تعذر تسجيل الدفعة', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Banknote className="w-5 h-5 text-success" /> تسجيل دفعة
          </DialogTitle>
          <DialogDescription>
            {balanceCents !== undefined ? (
              <>
                الرصيد الحالي المستحق: <b className="text-destructive">{formatMoney(balanceCents)}</b>
              </>
            ) : (
              'تُضاف الدفعة لفاتورة الضيف فورًا مع إشعار له'
            )}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="pay-method">طريقة الدفع</Label>
              <Select value={method} onValueChange={setMethod}>
                <SelectTrigger id="pay-method" aria-label="طريقة الدفع">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="CASH">نقدًا</SelectItem>
                  <SelectItem value="CARD">بطاقة</SelectItem>
                  <SelectItem value="TRANSFER">حوالة</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="pay-amount">المبلغ (USD)</Label>
              <Input
                id="pay-amount"
                type="number"
                inputMode="decimal"
                min="0"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                dir="ltr"
                className="font-bold tabular-nums"
              />
            </div>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="pay-note">ملاحظة (اختياري)</Label>
            <Input id="pay-note" value={note} onChange={(e) => setNote(e.target.value)} placeholder="مثال: دفعة عند الخروج" />
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose} disabled={loading}>إلغاء</Button>
          <Button onClick={submit} disabled={loading}>
            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Banknote className="w-4 h-4" />}
            تسجيل الدفعة
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

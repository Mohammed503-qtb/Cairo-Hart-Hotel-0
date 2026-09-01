'use client'

// ─────────────────────────────────────────────────────────────
// CHARGE DIALOG — إضافة بند لفاتورة الإقامة (خدمة/إضافي/غرامة)
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ListPlus, Loader2 } from 'lucide-react'
import { CHARGE_CATEGORY_LABELS } from '@/lib/format'

export default function ChargeDialog({
  stayId,
  onClose,
  onDone,
}: {
  stayId: string
  onClose: () => void
  onDone: () => void
}) {
  const { toast } = useToast()
  const [description, setDescription] = useState('')
  const [amount, setAmount] = useState('')
  const [category, setCategory] = useState('SERVICE')
  const [loading, setLoading] = useState(false)

  const submit = async () => {
    const amountCents = Math.round(parseFloat(amount || '0') * 100)
    if (description.trim().length < 3) {
      toast({ title: 'أدخل وصفًا للبند (3 أحرف على الأقل)', variant: 'destructive' })
      return
    }
    if (!Number.isFinite(amountCents) || amountCents <= 0) {
      toast({ title: 'أدخل مبلغًا صحيحًا أكبر من صفر', variant: 'destructive' })
      return
    }
    setLoading(true)
    try {
      await api('/api/reception/charges', {
        method: 'POST',
        body: { stayId, description: description.trim(), amountCents, category },
      })
      toast({ title: 'تمت إضافة البند للفاتورة ✅' })
      onDone()
    } catch (e) {
      toast({ title: 'تعذر إضافة البند', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ListPlus className="w-5 h-5 text-gold" /> إضافة بند للفاتورة
          </DialogTitle>
          <DialogDescription>سيظهر البند في فاتورة الضيف فورًا مع إشعار له</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="charge-desc">الوصف</Label>
            <Input
              id="charge-desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="مثال: ميني بار — خدمة غرف"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="charge-category">الفئة</Label>
              <Select value={category} onValueChange={setCategory}>
                <SelectTrigger id="charge-category" aria-label="فئة البند">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {['SERVICE', 'EXTRA', 'PENALTY'].map((c) => (
                    <SelectItem key={c} value={c}>{CHARGE_CATEGORY_LABELS[c]}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="charge-amount">المبلغ (USD)</Label>
              <Input
                id="charge-amount"
                type="number"
                inputMode="decimal"
                min="0"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                dir="ltr"
                placeholder="0.00"
                className="font-bold tabular-nums"
              />
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose} disabled={loading}>إلغاء</Button>
          <Button onClick={submit} disabled={loading}>
            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <ListPlus className="w-4 h-4" />}
            إضافة البند
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

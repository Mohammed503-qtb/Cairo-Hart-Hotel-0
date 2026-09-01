'use client'

// ─────────────────────────────────────────────────────────────
// REQUEST DIALOG — إنشاء طلب خدمة
// العنوان (معبأ قابل للتعديل) + الوصف + الأولوية + إرسال
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { Loader2, Send, Zap } from 'lucide-react'
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
import { api } from '@/lib/api-client'
import { cn } from '@/lib/utils'
import { PRIORITY_LABELS } from '@/lib/format'
import type { GuestRequest } from './types'

export interface RequestPreset {
  serviceId?: string
  category: 'HOUSEKEEPING' | 'MAINTENANCE' | 'GUEST_SERVICES' | 'OTHER'
  title: string
}

const CATEGORY_LABELS: Record<string, string> = {
  HOUSEKEEPING: 'خدمات التنظيف',
  MAINTENANCE: 'الصيانة',
  GUEST_SERVICES: 'خدمات الضيافة',
  OTHER: 'طلب خاص',
}

export default function RequestDialog({
  preset,
  onClose,
  onCreated,
}: {
  preset: RequestPreset | null
  onClose: () => void
  onCreated: () => void
}) {
  const { toast } = useToast()
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<'NORMAL' | 'URGENT'>('NORMAL')
  const [sending, setSending] = useState(false)

  useEffect(() => {
    if (preset) {
      setTitle(preset.title ?? '')
      setDescription('')
      setPriority('NORMAL')
    }
  }, [preset])

  const submit = async () => {
    if (!preset || sending) return
    if (title.trim().length < 3) {
      toast({ title: 'اكتب عنوانًا للطلب (3 أحرف على الأقل)', variant: 'destructive' })
      return
    }
    setSending(true)
    try {
      await api<{ request: GuestRequest }>('/api/guest/requests', {
        method: 'POST',
        body: {
          serviceId: preset.serviceId,
          category: preset.category,
          title: title.trim(),
          description: description.trim() || undefined,
          priority,
        },
      })
      toast({
        title: priority === 'URGENT' ? 'تم إرسال طلبك العاجل 🔔' : 'تم إرسال طلبك',
        description: 'يظهر الآن في «طلباتي» مع حالته لحظة بلحظة',
      })
      onCreated()
      onClose()
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
    <Dialog
      open={preset !== null}
      onOpenChange={(open) => {
        if (!open) onClose()
      }}
    >
      <DialogContent className="sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg">
            {CATEGORY_LABELS[preset?.category ?? 'OTHER'] ?? 'طلب خدمة'}
          </DialogTitle>
          <DialogDescription>
            يصل طلبك للاستقبال فورًا وسيتولى التعامل معه
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="req-title">عنوان الطلب</Label>
            <Input
              id="req-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="مثال: تنظيف الغرفة"
              maxLength={80}
              className="h-11"
              autoFocus
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="req-desc">تفاصيل إضافية (اختياري)</Label>
            <Textarea
              id="req-desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="أضف أي تفاصيل تساعد الفريق..."
              rows={3}
              maxLength={500}
            />
          </div>

          <div className="space-y-1.5">
            <Label>الأولوية</Label>
            <div className="grid grid-cols-2 gap-2">
              {(['NORMAL', 'URGENT'] as const).map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setPriority(p)}
                  aria-pressed={priority === p}
                  className={cn(
                    'flex h-11 items-center justify-center gap-1.5 rounded-xl border text-sm font-bold transition-all',
                    priority === p
                      ? p === 'URGENT'
                        ? 'border-destructive bg-destructive/10 text-destructive'
                        : 'border-primary bg-primary/10 text-primary'
                      : 'border-border text-muted-foreground hover:border-primary/40'
                  )}
                >
                  {p === 'URGENT' ? <Zap className="h-4 w-4" aria-hidden /> : null}
                  {PRIORITY_LABELS[p]}
                </button>
              ))}
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose} className="h-11" disabled={sending}>
            إلغاء
          </Button>
          <Button onClick={submit} disabled={sending} className="h-11 min-w-28 gap-1.5">
            {sending ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : <Send className="h-4 w-4" aria-hidden />}
            إرسال الطلب
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

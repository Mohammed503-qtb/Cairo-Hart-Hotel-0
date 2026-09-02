'use client'

// ─────────────────────────────────────────────────────────────
// FEEDBACK DIALOG — تقييم الإقامة
// نجوم 1-5 قابلة للنقر + وسوم سريعة + تعليق (upsert)
// ─────────────────────────────────────────────────────────────

import { useEffect, useState } from 'react'
import { Loader2, Star } from 'lucide-react'
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
import { useToast } from '@/hooks/use-toast'
import { useGuest } from './guest-context'
import { api } from '@/lib/api-client'
import { cn } from '@/lib/utils'

const QUICK_TAGS = ['نظافة', 'طاقم ممتاز', 'راحة', 'إفطار', 'يحتاج تحسينًا']

export default function FeedbackDialog() {
  const guest = useGuest()
  const { toast } = useToast()
  const open = guest.dialog === 'feedback'

  const [rating, setRating] = useState(0)
  const [hover, setHover] = useState(0)
  const [tags, setTags] = useState<string[]>([])
  const [comment, setComment] = useState('')
  const [sending, setSending] = useState(false)

  useEffect(() => {
    if (open) {
      setRating(0)
      setHover(0)
      setTags([])
      setComment('')
    }
  }, [open])

  const toggleTag = (t: string) => {
    setTags((prev) => (prev.includes(t) ? prev.filter((x) => x !== t) : [...prev, t]))
  }

  const submit = async () => {
    if (rating < 1) {
      toast({ title: 'اختر عدد النجوم أولًا', variant: 'destructive' })
      return
    }
    if (sending) return
    setSending(true)
    try {
      await api('/api/guest/feedback', {
        method: 'POST',
        body: {
          rating,
          tags,
          comment: comment.trim() || undefined,
        },
      })
      toast({ title: 'شكرًا لك على تقييمك 💛', description: 'رأيك يهمنا ويطوّر خدمتنا' })
      guest.closeDialog()
    } catch (err) {
      toast({
        title: 'تعذر حفظ التقييم',
        description: err instanceof Error ? err.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setSending(false)
    }
  }

  const shown = hover || rating

  return (
    <Dialog open={open} onOpenChange={(o) => (o ? guest.openDialog('feedback') : guest.closeDialog())}>
      <DialogContent className="sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg">
            <Star className="h-5 w-5 text-gold" aria-hidden />
            قيّم إقامتك
          </DialogTitle>
          <DialogDescription>رأيك يساعدنا على تحسين تجربة الضيافة</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* النجوم */}
          <div
            className="flex justify-center gap-1.5"
            role="radiogroup"
            aria-label="التقييم بالنجوم"
          >
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                role="radio"
                aria-checked={rating === n}
                aria-label={`${n} ${n === 1 ? 'نجمة' : n === 2 ? 'نجمتان' : 'نجوم'}`}
                onClick={() => setRating(n)}
                onMouseEnter={() => setHover(n)}
                onMouseLeave={() => setHover(0)}
                className="flex h-12 w-12 items-center justify-center rounded-xl transition-transform hover:scale-110 active:scale-95"
              >
                <Star
                  className={cn(
                    'h-8 w-8 transition-colors',
                    n <= shown ? 'fill-gold text-gold' : 'fill-muted text-muted'
                  )}
                  aria-hidden
                />
              </button>
            ))}
          </div>
          {rating > 0 ? (
            <p className="text-center text-sm font-bold text-gold">
              {['', 'ضعيف', 'مقبول', 'جيد', 'جيد جدًا', 'ممتاز!'][rating]}
            </p>
          ) : null}

          {/* الوسوم */}
          <div className="space-y-1.5">
            <Label>وسوم سريعة</Label>
            <div className="flex flex-wrap gap-2">
              {QUICK_TAGS.map((t) => {
                const active = tags.includes(t)
                return (
                  <button
                    key={t}
                    type="button"
                    onClick={() => toggleTag(t)}
                    aria-pressed={active}
                    className={cn(
                      'min-h-9 rounded-full border px-3 py-1.5 text-xs font-bold transition-all',
                      active
                        ? t === 'يحتاج تحسينًا'
                          ? 'border-warning bg-warning/10 text-warning'
                          : 'border-gold bg-gold/15 text-[#8a6d1f] dark:text-gold'
                        : 'border-border text-muted-foreground hover:border-primary/40'
                    )}
                  >
                    {t}
                  </button>
                )
              })}
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="fb-comment">تعليقك (اختياري)</Label>
            <Textarea
              id="fb-comment"
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              placeholder="شاركنا تجربتك بصفتك الخاصة..."
              rows={3}
              maxLength={500}
            />
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={guest.closeDialog} className="h-11" disabled={sending}>
            إلغاء
          </Button>
          <Button
            onClick={submit}
            disabled={sending || rating < 1}
            className="h-11 min-w-28 gap-1.5 bg-gold text-[#2A2110] hover:bg-gold/90"
          >
            {sending ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : null}
            إرسال التقييم
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

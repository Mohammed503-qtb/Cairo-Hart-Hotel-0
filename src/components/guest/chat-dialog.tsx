'use client'

// ─────────────────────────────────────────────────────────────
// CHAT DIALOG — محادثة الضيف مع الاستقبال
// فقاعات RTL + فاصل أيام + إرسال + تمرير تلقائي + Realtime/Polling
// ─────────────────────────────────────────────────────────────

import { useEffect, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import { Loader2, MessageCircle, Send } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useToast } from '@/hooks/use-toast'
import { useGuest } from './guest-context'
import { formatDateAr, formatTimeAr } from '@/lib/format'
import { cn } from '@/lib/utils'
import type { MessagePublic } from '@/types'

/** مفتاح اليوم YYYY-MM-DD بالتوقيت المحلي */
function dayKey(d: string): string {
  const date = new Date(d)
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function dayLabel(key: string): string {
  const today = new Date()
  const todayKey = dayKey(today.toISOString())
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  if (key === todayKey) return 'اليوم'
  if (key === dayKey(yesterday.toISOString())) return 'أمس'
  return formatDateAr(key)
}

export default function ChatDialog() {
  const guest = useGuest()
  const { toast } = useToast()
  const [text, setText] = useState('')
  const [sending, setSending] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  const open = guest.chatOpen

  // تمرير تلقائي لآخر رسالة
  useEffect(() => {
    if (!open) return
    const el = scrollRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [open, guest.messages.length])

  const send = async () => {
    const body = text.trim()
    if (!body || sending) return
    setSending(true)
    try {
      const ok = await guest.sendMessage(body)
      if (ok) {
        setText('')
      } else {
        toast({ title: 'تعذر إرسال الرسالة — أعد المحاولة', variant: 'destructive' })
      }
    } finally {
      setSending(false)
    }
  }

  // تجميع الرسائل بأيام
  const groups: { key: string; label: string; items: MessagePublic[] }[] = []
  for (const m of guest.messages) {
    const key = dayKey(m.createdAt)
    const last = groups[groups.length - 1]
    if (last && last.key === key) last.items.push(m)
    else groups.push({ key, label: dayLabel(key), items: [m] })
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => guest.setChatOpen(o)}
    >
      <DialogContent
        className="flex h-[82vh] flex-col gap-0 overflow-hidden p-0 sm:max-w-md"
        dir="rtl"
        showCloseButton
      >
        <DialogHeader className="border-b border-border/70 bg-accent/50 p-4">
          <DialogTitle className="flex items-center gap-2 text-base">
            <span className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-primary-foreground">
              <MessageCircle className="h-4.5 w-4.5" aria-hidden />
            </span>
            محادثة الاستقبال
          </DialogTitle>
          <DialogDescription className="ps-11">
            ردود فورية خلال دقائق — نسعد بخدمتك
          </DialogDescription>
        </DialogHeader>

        {/* الرسائل */}
        <div
          ref={scrollRef}
          className="flex-1 space-y-3 overflow-y-auto bg-muted/30 p-4"
          role="log"
          aria-label="رسائل المحادثة"
          aria-live="polite"
        >
          {guest.messagesLoading && guest.messages.length === 0 ? (
            <div className="flex h-full items-center justify-center text-muted-foreground">
              <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
            </div>
          ) : groups.length === 0 ? (
            <div className="flex h-full flex-col items-center justify-center gap-2 text-center">
              <MessageCircle className="h-10 w-10 text-muted-foreground/40" aria-hidden />
              <p className="text-sm font-bold text-muted-foreground">لا رسائل بعد</p>
              <p className="max-w-56 text-xs text-muted-foreground/80">
                ابدأ المحادثة — اكتب تحيتك وسيرد الاستقبال فورًا
              </p>
            </div>
          ) : (
            groups.map((g) => (
              <div key={g.key} className="space-y-2.5">
                <div className="flex justify-center">
                  <span className="rounded-full bg-muted px-3 py-0.5 text-[11px] font-bold text-muted-foreground">
                    {g.label}
                  </span>
                </div>
                {g.items.map((m) => (
                  <MessageBubble key={m.id} message={m} />
                ))}
              </div>
            ))
          )}
        </div>

        {/* الإرسال */}
        <div className="flex items-center gap-2 border-t border-border/70 bg-card p-3">
          <Input
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault()
                void send()
              }
            }}
            placeholder="اكتب رسالتك…"
            maxLength={1000}
            disabled={sending}
            className="h-11 rounded-xl"
            aria-label="نص الرسالة"
          />
          <Button
            onClick={() => void send()}
            disabled={sending || !text.trim()}
            className="h-11 w-11 shrink-0 rounded-xl p-0"
            aria-label="إرسال الرسالة"
          >
            {sending ? (
              <Loader2 className="h-4.5 w-4.5 animate-spin" aria-hidden />
            ) : (
              <Send className="h-4.5 w-4.5 -scale-x-100" aria-hidden />
            )}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function MessageBubble({ message }: { message: MessagePublic }) {
  const own = message.sender === 'GUEST'
  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      // RTL: الضيف يمين (main-start) والاستقبال يسار (main-end)
      className={cn('flex', own ? 'justify-start' : 'justify-end')}
    >
      <div
        className={cn(
          'max-w-[80%] rounded-2xl px-3.5 py-2 shadow-sm',
          own
            ? 'rounded-ss-sm bg-primary text-primary-foreground'
            : 'rounded-se-sm bg-muted text-foreground'
        )}
      >
        {!own ? (
          <p className="mb-0.5 text-[11px] font-bold text-primary">{message.senderName}</p>
        ) : null}
        <p className="whitespace-pre-wrap break-words text-sm leading-relaxed">{message.body}</p>
        <p
          className={cn(
            'mt-1 text-[10px] text-end',
            own ? 'text-primary-foreground/70' : 'text-muted-foreground'
          )}
        >
          {formatTimeAr(message.createdAt)}
        </p>
      </div>
    </motion.div>
  )
}

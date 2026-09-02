'use client'

// ─────────────────────────────────────────────────────────────
// STAY DETAIL DIALOG — تفاصيل إقامة كاملة بتبويبات
// الضيف / الفاتورة / الطلبات / الرسائل / الإجراءات
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useRef, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Textarea } from '@/components/ui/textarea'
import {
  User,
  Receipt,
  ConciergeBell,
  MessageSquare,
  Wrench,
  Banknote,
  ListPlus,
  PlaneTakeoff,
  Send,
  Loader2,
  CalendarPlus,
  DoorClosed,
  CalendarDays,
  Phone,
  BedDouble,
} from 'lucide-react'
import type { StayDetailData } from './types'
import { RefCode, MoneyAmount, PaymentStatusBadge, RequestStatusBadge, PriorityBadge, StayStatusBadge, ExtensionStatusBadge } from './bits'
import { useReception } from './context'
import PaymentDialog from './payment-dialog'
import ChargeDialog from './charge-dialog'
import {
  formatDateAr,
  formatDateWithDayAr,
  formatDateTimeAr,
  formatMoney,
  formatTimeAr,
  nightsBetweenDates,
  CHARGE_CATEGORY_LABELS,
  PAYMENT_METHOD_LABELS,
  SOURCE_LABELS,
} from '@/lib/format'

type TabKey = 'guest' | 'bill' | 'requests' | 'messages' | 'actions'

export default function StayDetailDialog({
  stayId,
  initialTab,
  onClose,
}: {
  stayId: string
  initialTab?: TabKey
  onClose: () => void
}) {
  const [tab, setTab] = useState<TabKey>(initialTab ?? 'guest')
  const [detail, setDetail] = useState<StayDetailData | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [paymentOpen, setPaymentOpen] = useState(false)
  const [chargeOpen, setChargeOpen] = useState(false)

  const reload = useCallback(async () => {
    try {
      const res = await api<StayDetailData>(`/api/reception/stays/${stayId}`)
      setDetail(res)
      setError(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'تعذر تحميل تفاصيل الإقامة')
    }
  }, [stayId])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<StayDetailData>(`/api/reception/stays/${stayId}`)
        if (!cancelled) {
          setDetail(res)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل تفاصيل الإقامة')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [stayId])

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl max-h-[92vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center gap-2">
            {detail ? (
              <>
                {detail.guest.fullName}
                <Badge variant="outline" className="font-mono">غرفة {detail.room.number}</Badge>
                <StayStatusBadge status={detail.stay.status} />
              </>
            ) : (
              'تفاصيل الإقامة'
            )}
          </DialogTitle>
          {detail ? (
            <DialogDescription className="flex items-center gap-2 flex-wrap">
              <RefCode>{detail.stay.reference}</RefCode>
              <span>·</span>
              <span>{detail.roomType.name}</span>
              <span>·</span>
              <span>الرصيد: <MoneyAmount cents={detail.bill.balanceCents} colored /></span>
            </DialogDescription>
          ) : (
            <DialogDescription>جارٍ تحميل تفاصيل الإقامة…</DialogDescription>
          )}
        </DialogHeader>

        {error ? <p className="text-sm text-destructive font-bold">{error}</p> : null}

        {!detail ? (
          <div className="space-y-2">
            <Skeleton className="h-10 rounded-lg" />
            <Skeleton className="h-40 rounded-lg" />
          </div>
        ) : (
          <Tabs value={tab} onValueChange={(v) => setTab(v as TabKey)}>
            <TabsList className="grid grid-cols-5 w-full">
              <TabsTrigger value="guest" className="text-xs sm:text-sm gap-1">
                <User className="w-3.5 h-3.5" /> الضيف
              </TabsTrigger>
              <TabsTrigger value="bill" className="text-xs sm:text-sm gap-1">
                <Receipt className="w-3.5 h-3.5" /> الفاتورة
              </TabsTrigger>
              <TabsTrigger value="requests" className="text-xs sm:text-sm gap-1 relative">
                <ConciergeBell className="w-3.5 h-3.5" /> الطلبات
                {detail.requests.some((r) => !['COMPLETED', 'CANCELLED', 'REJECTED'].includes(r.status)) ? (
                  <span className="absolute -top-1 -end-1 w-2 h-2 rounded-full bg-destructive" />
                ) : null}
              </TabsTrigger>
              <TabsTrigger value="messages" className="text-xs sm:text-sm gap-1">
                <MessageSquare className="w-3.5 h-3.5" /> الرسائل
              </TabsTrigger>
              <TabsTrigger value="actions" className="text-xs sm:text-sm gap-1">
                <Wrench className="w-3.5 h-3.5" /> الإجراءات
              </TabsTrigger>
            </TabsList>

            <TabsContent value="guest" className="space-y-3">
              <GuestTab detail={detail} />
            </TabsContent>

            <TabsContent value="bill" className="space-y-3">
              <BillTab detail={detail} onPayment={() => setPaymentOpen(true)} onCharge={() => setChargeOpen(true)} />
            </TabsContent>

            <TabsContent value="requests" className="space-y-3">
              <RequestsTab detail={detail} />
            </TabsContent>

            <TabsContent value="messages" className="space-y-3">
              <MessagesTab stayId={stayId} embedded={detail.messages} />
            </TabsContent>

            <TabsContent value="actions" className="space-y-3">
              <ActionsTab detail={detail} onChanged={reload} onChat={() => setTab('messages')} />
            </TabsContent>
          </Tabs>
        )}

        {paymentOpen && detail ? (
          <PaymentDialog
            stayId={stayId}
            balanceCents={detail.bill.balanceCents}
            onClose={() => setPaymentOpen(false)}
            onDone={() => {
              setPaymentOpen(false)
              void reload()
            }}
          />
        ) : null}

        {chargeOpen ? (
          <ChargeDialog
            stayId={stayId}
            onClose={() => setChargeOpen(false)}
            onDone={() => {
              setChargeOpen(false)
              void reload()
            }}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  )
}

// ── تبويب الضيف ──
function GuestTab({ detail }: { detail: StayDetailData }) {
  const r = detail.reservation
  const snapshotNights = Array.isArray(r.priceSnapshot?.nightly) ? r.priceSnapshot.nightly : []
  return (
    <div className="space-y-3 text-sm">
      <div className="grid grid-cols-2 gap-2">
        <InfoCell label="الاسم">{detail.guest.fullName}</InfoCell>
        <InfoCell label="الهاتف">
          <span dir="ltr" className="font-mono">{detail.guest.phone}</span>
        </InfoCell>
        <InfoCell label="الجنسية">{detail.guest.nationality ?? '—'}</InfoCell>
        <InfoCell label="رقم الهوية">
          <span dir="ltr" className="font-mono">{detail.guest.idNumber ?? '—'}</span>
        </InfoCell>
        <InfoCell label="الغرفة">
          <b dir="ltr">{detail.room.number}</b> · طابق {detail.room.floor}
        </InfoCell>
        <InfoCell label="نوع الغرفة">
          <span className="flex items-center gap-1"><BedDouble className="w-3.5 h-3.5 text-primary" /> {detail.roomType.name}</span>
        </InfoCell>
      </div>

      <div className="rounded-lg border bg-muted/30 p-3 space-y-1.5">
        <p className="flex items-center gap-2 font-bold">
          <RefCode className="text-foreground">{r.bookingReference}</RefCode>
          <Badge variant="outline">{SOURCE_LABELS[r.source] ?? r.source}</Badge>
        </p>
        <p className="flex items-center gap-2 text-muted-foreground">
          <CalendarDays className="w-4 h-4" />
          {formatDateWithDayAr(r.checkIn)} ← {formatDateWithDayAr(r.checkOut)} (
          {nightsBetweenDates(r.checkIn, r.checkOut)} ليالٍ · {r.adults} بالغ{r.children ? ` + ${r.children} طفل` : ''})
        </p>
        <p className="flex items-center gap-2">
          <Phone className="w-4 h-4 text-muted-foreground" />
          <span dir="ltr" className="font-mono">{detail.guest.phone}</span>
        </p>
        <p className="text-xs text-muted-foreground">وصول فعلي: {formatDateTimeAr(detail.stay.checkInAt)}</p>
      </div>

      {snapshotNights.length > 0 ? (
        <div className="rounded-lg border p-3">
          <p className="font-bold mb-2 text-xs text-muted-foreground">لقطة سعر الليالي (عند الحجز)</p>
          <div className="max-h-40 overflow-y-auto space-y-1">
            {snapshotNights.map((n) => (
              <div key={n.date} className="flex justify-between text-xs">
                <span className="text-muted-foreground">{formatDateAr(n.date)} · {n.rateName}</span>
                <span className="font-bold tabular-nums">{formatMoney(n.priceCents)}</span>
              </div>
            ))}
          </div>
          <div className="flex justify-between text-xs border-t mt-2 pt-2 font-bold">
            <span>المجموع + الضريبة</span>
            <MoneyAmount cents={r.grandTotalCents} />
          </div>
        </div>
      ) : null}

      {r.specialRequests ? (
        <p className="rounded-lg border border-gold/40 bg-gold/10 p-3 text-xs">💬 <b>طلبات خاصة: </b>{r.specialRequests}</p>
      ) : null}
    </div>
  )
}

// ── تبويب الفاتورة ──
function BillTab({ detail, onPayment, onCharge }: { detail: StayDetailData; onPayment: () => void; onCharge: () => void }) {
  const bill = detail.bill
  return (
    <div className="space-y-3 text-sm">
      <div className="rounded-lg border p-3 space-y-1.5">
        <div className="flex justify-between"><span className="text-muted-foreground">إجمالي الغرفة (شامل الضريبة)</span><MoneyAmount cents={bill.roomTotalCents} /></div>
        <div className="flex justify-between text-xs text-muted-foreground"><span>المجموع الفرعي {formatMoney(bill.roomSubtotalCents)} + ضريبة {formatMoney(bill.roomTaxCents)}</span></div>
        <div className="flex justify-between"><span className="text-muted-foreground">بنود إضافية</span><MoneyAmount cents={bill.extraTotalCents} /></div>
        <div className="flex justify-between font-bold border-t pt-1.5"><span>الإجمالي المستحق</span><MoneyAmount cents={bill.totalChargesCents} /></div>
        <div className="flex justify-between"><span className="text-muted-foreground">إجمالي المدفوع</span><MoneyAmount cents={bill.totalPaidCents} colored /></div>
        <div className="flex justify-between items-center border-t pt-2 text-base font-black">
          <span>الرصيد</span>
          <MoneyAmount cents={bill.balanceCents} colored />
        </div>
      </div>

      {bill.extraCharges.length > 0 ? (
        <div className="rounded-lg border p-3">
          <p className="font-bold text-xs text-muted-foreground mb-2">البنود الإضافية</p>
          <div className="space-y-1.5">
            {bill.extraCharges.map((c, i) => (
              <div key={i} className="flex justify-between items-center gap-2 text-xs">
                <span className="min-w-0">
                  <Badge variant="outline" className="me-1 text-[9px]">{CHARGE_CATEGORY_LABELS[c.category ?? 'EXTRA'] ?? c.category}</Badge>
                  {c.description}
                  {c.date ? <span className="text-muted-foreground"> · {formatTimeAr(c.date)}</span> : null}
                </span>
                <MoneyAmount cents={c.amountCents} className="shrink-0 font-bold" />
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {bill.payments.length > 0 ? (
        <div className="rounded-lg border p-3">
          <p className="font-bold text-xs text-muted-foreground mb-2">المدفوعات</p>
          <div className="space-y-1.5">
            {bill.payments.map((p) => (
              <div key={p.id} className="flex justify-between items-center gap-2 text-xs">
                <span>
                  <Badge variant="outline" className="me-1 text-[9px]">{PAYMENT_METHOD_LABELS[p.method] ?? p.method}</Badge>
                  {formatDateTimeAr(p.createdAt)}
                  {p.recordedBy ? <span className="text-muted-foreground"> · {p.recordedBy}</span> : null}
                </span>
                <MoneyAmount cents={p.amountCents} className="shrink-0 font-bold text-success" />
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="secondary" onClick={onPayment} disabled={detail.stay.status === 'CLOSED'}>
          <Banknote className="w-4 h-4" /> تسجيل دفعة
        </Button>
        <Button size="sm" variant="outline" onClick={onCharge} disabled={detail.stay.status === 'CLOSED'}>
          <ListPlus className="w-4 h-4" /> إضافة بند
        </Button>
      </div>
    </div>
  )
}

// ── تبويب الطلبات ──
function RequestsTab({ detail }: { detail: StayDetailData }) {
  const { openRequest } = useReception()
  if (detail.requests.length === 0) {
    return <p className="rounded-lg border border-dashed p-4 text-center text-sm text-muted-foreground">لا توجد طلبات لهذه الإقامة</p>
  }
  return (
    <div className="space-y-2">
      {detail.requests.map((r) => (
        <button
          key={r.id}
          onClick={() => openRequest(r.id)}
          className="w-full text-start rounded-lg border bg-card p-2.5 hover:border-primary/40 transition-colors"
        >
          <div className="flex items-center gap-2 flex-wrap">
            <span className="font-bold text-sm">{r.title}</span>
            <RequestStatusBadge status={r.status} />
            <PriorityBadge priority={r.priority} />
          </div>
          <p className="text-[11px] text-muted-foreground mt-0.5">
            <RefCode>{r.reference}</RefCode> · آخر تحديث {formatDateTimeAr(r.updatedAt)}
          </p>
        </button>
      ))}
    </div>
  )
}

// ── تبويب الرسائل ──
function MessagesTab({ stayId, embedded }: { stayId: string; embedded: StayDetailData['messages'] }) {
  const { toast } = useToast()
  const [messages, setMessages] = useState(embedded)
  const [all, setAll] = useState<StayDetailData['messages'] | null>(null)
  const [body, setBody] = useState('')
  const [sending, setSending] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ messages: StayDetailData['messages'] }>(`/api/reception/messages?stayId=${stayId}`)
        if (!cancelled) setAll(res.messages)
      } catch {
        /* نستخدم المدمجة */
      }
    })()
    return () => {
      cancelled = true
    }
  }, [stayId])

  const list = all ?? messages ?? []

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight })
  }, [list.length])

  const send = async () => {
    const text = body.trim()
    if (!text) return
    setSending(true)
    try {
      const res = await api<{ message: StayDetailData['messages'][number] }>('/api/reception/messages', {
        method: 'POST',
        body: { stayId, body: text },
      })
      setAll((prev) => [...(prev ?? []), res.message])
      setBody('')
    } catch (e) {
      toast({ title: 'تعذر إرسال الرسالة', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="space-y-3">
      <div ref={scrollRef} className="max-h-72 overflow-y-auto rounded-lg border bg-muted/20 p-3 space-y-2" aria-live="polite">
        {list.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-6">لا رسائل بعد — ابدأ المحادثة 👋</p>
        ) : (
          list.map((m) => (
            <div key={m.id} className={`flex ${m.sender === 'RECEPTION' ? 'justify-start' : 'justify-end'}`}>
              <div
                className={`max-w-[80%] rounded-xl px-3 py-2 text-sm ${
                  m.sender === 'RECEPTION'
                    ? 'bg-primary text-primary-foreground rounded-tl-sm'
                    : 'bg-card border rounded-tr-sm'
                }`}
              >
                <p className="text-[10px] font-bold opacity-70 mb-0.5">
                  {m.senderName} · {formatTimeAr(m.createdAt)}
                </p>
                <p className="leading-relaxed whitespace-pre-wrap">{m.body}</p>
              </div>
            </div>
          ))
        )}
      </div>

      <div className="flex gap-2">
        <Textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="اكتب رسالة للضيف…"
          className="resize-none"
          rows={2}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              void send()
            }
          }}
        />
        <Button onClick={send} disabled={sending || !body.trim()} className="self-end" aria-label="إرسال">
          {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
        </Button>
      </div>
    </div>
  )
}

// ── تبويب الإجراءات ──
function ActionsTab({
  detail,
  onChanged,
  onChat,
}: {
  detail: StayDetailData
  onChanged: () => void
  onChat: () => void
}) {
  const { toast } = useToast()
  const { openCheckOut } = useReception()
  const [busy, setBusy] = useState<string | null>(null)

  const pendingExtensions = detail.extensionRequests.filter((e) => e.status === 'PENDING')
  const pendingRoomChanges = detail.roomChangeRequests.filter((c) => c.status === 'PENDING')
  const stayClosed = detail.stay.status === 'CLOSED'

  const decideExtension = async (id: string, approve: boolean) => {
    setBusy(`ext-${id}`)
    try {
      await api(`/api/reception/extension-requests/${id}/decide`, { method: 'POST', body: { approve } })
      toast({ title: approve ? 'تمت الموافقة على التمديد ✅' : 'تم رفض طلب التمديد' })
      onChanged()
    } catch (e) {
      toast({ title: 'تعذر البت في الطلب', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setBusy(null)
    }
  }

  const decideRoomChange = async (id: string, approve: boolean) => {
    setBusy(`rc-${id}`)
    try {
      await api(`/api/reception/room-change-requests/${id}/decide`, { method: 'POST', body: { approve } })
      toast({ title: approve ? 'تم تغيير الغرفة ✅' : 'تم رفض طلب تغيير الغرفة' })
      onChanged()
    } catch (e) {
      toast({ title: 'تعذر البت في الطلب', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="space-y-3 text-sm">
      {stayClosed ? (
        <p className="rounded-lg border border-muted bg-muted/30 p-3 text-center text-muted-foreground">
          الإقامة مغلقة — لا إجراءات متاحة
        </p>
      ) : null}

      {/* طلبات التمديد */}
      <section aria-label="طلبات التمديد">
        <p className="font-bold text-xs text-muted-foreground mb-2 flex items-center gap-1.5">
          <CalendarPlus className="w-4 h-4" /> طلبات التمديد
        </p>
        {detail.extensionRequests.length === 0 ? (
          <p className="text-xs text-muted-foreground rounded-lg border border-dashed p-3 text-center">لا طلبات تمديد</p>
        ) : (
          <div className="space-y-2">
            {detail.extensionRequests.map((e) => (
              <div key={e.id} className="rounded-lg border p-3 space-y-2">
                <div className="flex flex-wrap items-center gap-2">
                  <ExtensionStatusBadge status={e.status} />
                  <span className="font-bold">حتى {formatDateWithDayAr(e.newCheckOut)}</span>
                  <span className="text-muted-foreground text-xs">({e.nights} {e.nights === 1 ? 'ليلة' : 'ليالٍ'})</span>
                  <MoneyAmount cents={e.priceCents} className="ms-auto" />
                </div>
                {e.note ? <p className="text-xs text-muted-foreground">📝 {e.note}</p> : null}
                {e.status === 'PENDING' ? (
                  <div className="flex gap-2">
                    <Button size="sm" onClick={() => decideExtension(e.id, true)} disabled={busy !== null} className="flex-1">
                      {busy === `ext-${e.id}` ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                      موافقة ({formatMoney(e.priceCents)})
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => decideExtension(e.id, false)} disabled={busy !== null} className="flex-1">
                      رفض
                    </Button>
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        )}
        {pendingExtensions.length === 0 && detail.extensionRequests.length > 0 ? null : null}
      </section>

      {/* طلبات تغيير الغرفة */}
      <section aria-label="طلبات تغيير الغرفة">
        <p className="font-bold text-xs text-muted-foreground mb-2 flex items-center gap-1.5">
          <DoorClosed className="w-4 h-4" /> طلبات تغيير الغرفة
        </p>
        {detail.roomChangeRequests.length === 0 ? (
          <p className="text-xs text-muted-foreground rounded-lg border border-dashed p-3 text-center">لا طلبات تغيير غرفة</p>
        ) : (
          <div className="space-y-2">
            {detail.roomChangeRequests.map((c) => (
              <div key={c.id} className="rounded-lg border p-3 space-y-2">
                <div className="flex flex-wrap items-center gap-2">
                  <ExtensionStatusBadge status={c.status} />
                  <span className="font-bold">
                    من <b dir="ltr">{detail.room.number}</b> إلى <b dir="ltr">{c.toRoomNumber}</b>
                  </span>
                  {c.priceDiffCents > 0 ? (
                    <Badge variant="outline" className="text-warning border-warning/40">+ {formatMoney(c.priceDiffCents)}</Badge>
                  ) : null}
                </div>
                {c.reason ? <p className="text-xs text-muted-foreground">📝 {c.reason}</p> : null}
                {c.status === 'PENDING' ? (
                  <div className="flex gap-2">
                    <Button size="sm" onClick={() => decideRoomChange(c.id, true)} disabled={busy !== null} className="flex-1">
                      {busy === `rc-${c.id}` ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                      موافقة
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => decideRoomChange(c.id, false)} disabled={busy !== null} className="flex-1">
                      رفض
                    </Button>
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        )}
      </section>

      {!stayClosed ? (
        <section aria-label="إجراءات عامة" className="flex flex-wrap gap-2 pt-2 border-t">
          <Button size="sm" variant="secondary" onClick={onChat}>
            <MessageSquare className="w-4 h-4" /> محادثة
          </Button>
          <Button size="sm" onClick={() => openCheckOut(detail.stay.id)}>
            <PlaneTakeoff className="w-4 h-4" /> تسجيل خروج
          </Button>
        </section>
      ) : null}
    </div>
  )
}

function InfoCell({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border bg-muted/30 px-3 py-2">
      <p className="text-[10px] font-bold text-muted-foreground">{label}</p>
      <p className="text-sm font-medium truncate">{children}</p>
    </div>
  )
}

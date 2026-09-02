'use client'

// ─────────────────────────────────────────────────────────────
// CHECK-IN WIZARD — معالج تسجيل الوصول (4 خطوات)
// تحقق الضيف → تعيين غرفة (نفس النوع ومتاحة) → تأكيد → كود الضيف
// ─────────────────────────────────────────────────────────────

import { useCallback, useEffect, useMemo, useState } from 'react'
import { api } from '@/lib/api-client'
import { useToast } from '@/hooks/use-toast'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { Progress } from '@/components/ui/progress'
import {
  CheckCircle2,
  Loader2,
  Copy,
  MessageCircle,
  Check,
  DoorOpen,
  AlertTriangle,
  UserCheck,
  UserX,
  Phone,
  Users2,
  Quote,
  CalendarDays,
} from 'lucide-react'
import type { ArrivalItem, CheckInResult, RoomItem } from './types'
import { RefCode, MoneyAmount, PaymentStatusBadge, ReservationStatusBadge, normalizePhone } from './bits'
import { formatDateWithDayAr, formatMoney } from '@/lib/format'

const STEP_TITLES = ['التحقق من الضيف', 'تعيين الغرفة', 'التأكيد النهائي', 'تم تسجيل الوصول']

export default function CheckInWizard({
  reservationId,
  checkInISO,
  onClose,
  onDone,
}: {
  reservationId: string
  checkInISO: string
  onClose: () => void
  onDone: () => void
}) {
  const { toast } = useToast()
  const [step, setStep] = useState(0)
  const [arrival, setArrival] = useState<ArrivalItem | null>(null)
  const [rooms, setRooms] = useState<RoomItem[] | null>(null)
  const [idNumber, setIdNumber] = useState('')
  const [roomId, setRoomId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [result, setResult] = useState<CheckInResult | null>(null)
  const [copied, setCopied] = useState(false)
  // رقم الواتساب المُرسل إليه — يتحكم به المستخدم (استقبال/إدارة)، افتراضيًا هاتف الضيف
  const [waNumber, setWaNumber] = useState('')

  const dateKey = useMemo(() => {
    const d = new Date(checkInISO)
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${d.getFullYear()}-${m}-${day}`
  }, [checkInISO])

  // جلب بيانات الحجز
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ arrivals: ArrivalItem[] }>(`/api/reception/arrivals?date=${dateKey}`)
        if (cancelled) return
        const found = res.arrivals.find((a) => a.id === reservationId)
        if (!found) {
          setError('لم يتم العثور على الحجز في وصولات هذا اليوم — قد يكون سُجّل دخوله بالفعل')
        } else {
          setArrival(found)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل بيانات الحجز')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [reservationId, dateKey])

  // جلب الغرف عند الوصول لخطوة الغرفة
  const loadRooms = useCallback(async () => {
    if (rooms || !arrival) return
    try {
      const res = await api<{ rooms: RoomItem[] }>('/api/reception/rooms')
      setRooms(res.rooms)
    } catch (e) {
      toast({ title: 'تعذر تحميل الغرف', description: e instanceof Error ? e.message : undefined, variant: 'destructive' })
    }
  }, [rooms, arrival, toast])

  useEffect(() => {
    if (step === 1) void loadRooms()
  }, [step, loadRooms])

  const availableRooms = useMemo(
    () => (rooms ?? []).filter((r) => r.status === 'AVAILABLE' && r.roomTypeId === arrival?.roomType.id),
    [rooms, arrival]
  )

  const submit = async () => {
    if (!roomId) return
    setLoading(true)
    try {
      const res = await api<CheckInResult>('/api/reception/check-in', {
        method: 'POST',
        body: {
          reservationId,
          roomId,
          ...(idNumber.trim() ? { idNumber: idNumber.trim() } : {}),
        },
      })
      setResult(res)
      setWaNumber(res.guestPhone)
      setStep(3)
    } catch (e) {
      toast({
        title: 'تعذر تسجيل الوصول',
        description: e instanceof Error ? e.message : undefined,
        variant: 'destructive',
      })
      // عد لخطوة الغرفة — ربما تغيّرت الحالة
      setRooms(null)
      setRoomId(null)
      setStep(1)
    } finally {
      setLoading(false)
    }
  }

  const copyCode = async () => {
    if (!result) return
    try {
      await navigator.clipboard.writeText(result.guestCode)
      setCopied(true)
      toast({ title: 'تم نسخ الكود ✅' })
      setTimeout(() => setCopied(false), 2000)
    } catch {
      toast({ title: 'تعذر النسخ — انسخ الكود يدويًا', variant: 'destructive' })
    }
  }

  const whatsappLink = () => {
    if (!result) return '#'
    const phone = normalizePhone(waNumber)
    if (!phone) return '#'
    const text = `أهلًا بك في فندق قلب القاهرة ❤️\nغرفتك: ${result.roomNumber}\nكود تطبيق الفندق: ${result.guestCode} — افتح التطبيق وأدخل الكود`
    return `https://wa.me/${phone}?text=${encodeURIComponent(text)}`
  }

  const selectedRoom = availableRooms.find((r) => r.id === roomId) ?? null

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <DoorOpen className="w-5 h-5 text-primary" />
            تسجيل وصول {arrival ? `— ${arrival.guest.fullName}` : ''}
          </DialogTitle>
          <DialogDescription>
            <span className="flex items-center gap-1.5 mt-1 flex-wrap">
              {STEP_TITLES.map((t, i) => (
                <span
                  key={t}
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    i === step ? 'bg-primary text-primary-foreground' : i < step ? 'bg-success/15 text-success' : 'bg-muted text-muted-foreground'
                  }`}
                >
                  {i + 1}. {t}
                </span>
              ))}
            </span>
          </DialogDescription>
        </DialogHeader>

        {error && step !== 3 ? (
          <div className="flex items-center gap-2 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            {error}
          </div>
        ) : null}

        {/* ── الخطوة 1: التحقق من الضيف ── */}
        {step === 0 && (
          <div className="space-y-4">
            {!arrival ? (
              <div className="space-y-2">
                <Skeleton className="h-16 rounded-lg" />
                <Skeleton className="h-10 rounded-lg" />
              </div>
            ) : (
              <>
                <div className="rounded-lg border bg-muted/30 divide-y">
                  <Row icon={<UserCheck className="w-4 h-4" />} label="الاسم">{arrival.guest.fullName}</Row>
                  <Row icon={<Phone className="w-4 h-4" />} label="الهاتف">
                    <span dir="ltr" className="font-mono text-sm">{arrival.guest.phone}</span>
                  </Row>
                  <Row icon={<Quote className="w-4 h-4" />} label="الحجز">
                    <span className="flex items-center gap-2">
                      <RefCode className="text-foreground">{arrival.bookingReference}</RefCode>
                      <ReservationStatusBadge status={arrival.status} />
                    </span>
                  </Row>
                  <Row icon={<CalendarDays className="w-4 h-4" />} label="المواعيد">
                    {formatDateWithDayAr(arrival.checkIn)} ← {formatDateWithDayAr(arrival.checkOut)} ({arrival.nights} ليالٍ)
                  </Row>
                  <Row icon={<Users2 className="w-4 h-4" />} label="نوع الغرفة">
                    {arrival.roomType.name} · {arrival.adults} بالغ{arrival.children > 0 ? ` + ${arrival.children} طفل` : ''}
                  </Row>
                  <Row icon={<CheckCircle2 className="w-4 h-4" />} label="الإجمالي / المدفوع">
                    <span className="flex items-center gap-2">
                      <MoneyAmount cents={arrival.grandTotalCents} />
                      <span className="text-muted-foreground">/</span>
                      <MoneyAmount cents={arrival.paidCents} colored />
                      <PaymentStatusBadge status={arrival.paymentStatus} />
                    </span>
                  </Row>
                </div>

                {arrival.specialRequests ? (
                  <div className="flex items-start gap-2 rounded-lg border border-gold/40 bg-gold/10 p-3 text-sm">
                    <Quote className="w-4 h-4 text-gold shrink-0 mt-0.5" />
                    <span>
                      <span className="font-bold">طلبات خاصة: </span>
                      {arrival.specialRequests}
                    </span>
                  </div>
                ) : null}

                {arrival.paidCents < arrival.grandTotalCents ? (
                  <div className="flex items-center gap-2 rounded-lg border border-warning/40 bg-warning/10 p-3 text-sm">
                    <AlertTriangle className="w-4 h-4 text-warning shrink-0" />
                    متبقٍّ مستحق <MoneyAmount cents={arrival.grandTotalCents - arrival.paidCents} /> — يمكن تسجيل الدفعة بعد الوصول
                  </div>
                ) : null}

                <div className="space-y-1.5">
                  <label htmlFor="id-number" className="text-xs font-bold text-muted-foreground">
                    رقم الهوية / جواز السفر (اختياري)
                  </label>
                  <Input
                    id="id-number"
                    value={idNumber}
                    onChange={(e) => setIdNumber(e.target.value)}
                    placeholder="مثال: 9988776"
                    dir="ltr"
                  />
                </div>

                <div className="flex justify-end gap-2">
                  <Button variant="outline" onClick={onClose}>إلغاء</Button>
                  <Button onClick={() => setStep(1)} disabled={!arrival || arrival.status !== 'CONFIRMED'}>
                    متابعة <UserCheck className="w-4 h-4" />
                  </Button>
                </div>
              </>
            )}
          </div>
        )}

        {/* ── الخطوة 2: تعيين الغرفة ── */}
        {step === 1 && (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              الغرف <b className="text-success">المتاحة</b> من نوع <b>{arrival?.roomType.name}</b> فقط — اختر غرفة:
            </p>
            {!rooms ? (
              <div className="grid grid-cols-3 gap-2">
                {Array.from({ length: 6 }).map((_, i) => (
                  <Skeleton key={i} className="h-20 rounded-lg" />
                ))}
              </div>
            ) : availableRooms.length === 0 ? (
              <div className="flex items-center gap-2 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
                <UserX className="w-4 h-4" />
                لا توجد غرف متاحة من هذا النوع حاليًا — راجع لوحة الغرف
              </div>
            ) : (
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-2 max-h-64 overflow-y-auto">
                {availableRooms.map((r) => (
                  <button
                    key={r.id}
                    onClick={() => setRoomId(r.id)}
                    className={`rounded-lg border-2 p-2.5 text-center transition-all ${
                      roomId === r.id
                        ? 'border-success bg-success/15 shadow'
                        : 'border-success/30 bg-success/5 hover:border-success/60'
                    }`}
                    aria-pressed={roomId === r.id}
                  >
                    <span className="block text-lg font-black text-success" dir="ltr">{r.number}</span>
                    <span className="block text-[10px] text-muted-foreground">الطابق {r.floor}</span>
                    {roomId === r.id && <Check className="w-4 h-4 text-success mx-auto mt-0.5" />}
                  </button>
                ))}
              </div>
            )}
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setStep(0)}>رجوع</Button>
              <Button onClick={() => setStep(2)} disabled={!roomId}>
                متابعة
              </Button>
            </div>
          </div>
        )}

        {/* ── الخطوة 3: التأكيد ── */}
        {step === 2 && arrival && (
          <div className="space-y-4">
            <div className="rounded-lg border bg-muted/30 divide-y text-sm">
              <Row label="الضيف">{arrival.guest.fullName}</Row>
              <Row label="نوع الغرفة">{arrival.roomType.name}</Row>
              <Row label="الغرفة المختارة">
                <span className="font-black text-success" dir="ltr">{selectedRoom?.number}</span> (طابق {selectedRoom?.floor})
              </Row>
              <Row label="الوصول">{formatDateWithDayAr(arrival.checkIn)}</Row>
              <Row label="المغادرة المتوقعة">{formatDateWithDayAr(arrival.checkOut)}</Row>
              <Row label="الإجمالي"><MoneyAmount cents={arrival.grandTotalCents} /></Row>
              <Row label="المدفوع"><MoneyAmount cents={arrival.paidCents} colored /></Row>
              <Row label="المتبقي"><MoneyAmount cents={arrival.grandTotalCents - arrival.paidCents} /></Row>
              {idNumber.trim() ? <Row label="رقم الهوية"><span dir="ltr" className="font-mono">{idNumber.trim()}</span></Row> : null}
            </div>
            <div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/5 p-3 text-xs text-muted-foreground">
              <CheckCircle2 className="w-4 h-4 text-primary shrink-0" />
              سيتم توليد كود تطبيق خاص بالضيف صالح حتى نهاية يوم المغادرة
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setStep(1)}>رجوع</Button>
              <Button onClick={submit} disabled={loading || !roomId}>
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                تأكيد تسجيل الوصول
              </Button>
            </div>
          </div>
        )}

        {/* ── الخطوة 4: النجاح + كود الضيف ── */}
        {step === 3 && result && (
          <div className="space-y-4 text-center">
            <div className="mx-auto w-16 h-16 rounded-full bg-success/15 flex items-center justify-center">
              <CheckCircle2 className="w-10 h-10 text-success" />
            </div>
            <div>
              <p className="font-extrabold text-lg">تم تسجيل الوصول ✅</p>
              <p className="text-sm text-muted-foreground">
                إقامة <RefCode className="text-foreground">{result.stay.reference}</RefCode> — غرفة{' '}
                <b className="text-success" dir="ltr">{result.roomNumber}</b> — {result.guestName}
              </p>
            </div>

            <div className="rounded-xl bg-neutral-900 dark:bg-black/80 border border-neutral-700 p-4">
              <p className="text-[11px] text-neutral-400 mb-1">كود تطبيق الضيف — يظهر مرة واحدة فقط</p>
              <p className="text-3xl font-black font-mono tracking-[0.2em] text-gold select-all" dir="ltr">
                {result.guestCode}
              </p>
            </div>

            <p className="flex items-center justify-center gap-1.5 text-xs text-destructive font-bold">
              <AlertTriangle className="w-3.5 h-3.5" />
              احتفظ بالكود الآن — لن يمكن استرجعه لاحقًا
            </p>

            <div className="space-y-1.5">
              <label htmlFor="wa-dest" className="text-xs font-bold text-muted-foreground flex items-center gap-1">
                <Phone className="w-3.5 h-3.5" aria-hidden />
                رقم الواتساب المُرسَل إليه — قابل للتعديل
              </label>
              <Input
                id="wa-dest"
                value={waNumber}
                onChange={(e) => setWaNumber(e.target.value)}
                dir="ltr"
                inputMode="tel"
                placeholder="+9677XXXXXXXX"
                aria-label="رقم الواتساب المُرسَل إليه"
              />
              <p className="text-[11px] text-muted-foreground leading-relaxed">
                افتراضيًا هاتف الضيف من الحجز — عدّله إن كان رقم واتساب الضيف مختلفًا قبل الإرسال.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-2">
              <Button variant="outline" className="flex-1" onClick={copyCode}>
                {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                نسخ الكود
              </Button>
              <Button className="flex-1 bg-[#25D366] text-white hover:bg-[#20bd5a]" asChild>
                <a href={whatsappLink()} target="_blank" rel="noopener noreferrer">
                  <MessageCircle className="w-4 h-4" />
                  إرسال واتساب
                </a>
              </Button>
              <Button className="flex-1" onClick={onDone}>تم</Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

function Row({ icon, label, children }: { icon?: React.ReactNode; label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2 px-3 py-2">
      {icon ? <span className="text-muted-foreground shrink-0">{icon}</span> : null}
      <span className="text-xs font-bold text-muted-foreground w-24 shrink-0">{label}</span>
      <span className="text-sm font-medium min-w-0">{children}</span>
    </div>
  )
}

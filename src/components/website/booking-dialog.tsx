'use client'

// ─────────────────────────────────────────────────────────────
// BOOKING DIALOG — نافذة الحجز (5 خطوات)
// 1) النتائج  2) بيانات الضيف  3) المراجعة  4) المعالجة  5) التأكيد
// الخادم هو مصدر الحقيقة: كل الأسعار من استجاباته فقط
// ─────────────────────────────────────────────────────────────
import { useCallback, useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import {
  CalendarDays,
  Users,
  BedDouble,
  CheckCircle2,
  Copy,
  Printer,
  MessageCircle,
  ClipboardList,
  Loader2,
  AlertCircle,
  SearchX,
  RefreshCw,
  Pencil,
  Info,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Checkbox } from '@/components/ui/checkbox'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Skeleton } from '@/components/ui/skeleton'
import { Separator } from '@/components/ui/separator'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { useToast } from '@/hooks/use-toast'
import { api, ApiError } from '@/lib/api-client'
import { formatMoney, formatDateAr, addDaysInput, todayInputValue } from '@/lib/format'
import type { HotelPublic, ReservationPublic, AvailabilityItem } from '@/types'
import {
  nightsText,
  guestsText,
  roomsText,
  miniCapacity,
  formatClockAr,
  digits,
  waLink,
  paymentStatusBadge,
  type SearchParams,
  type SnapshotBreakdown,
} from './helpers'

const STEP_LABELS = ['التوفر', 'بياناتك', 'المراجعة', 'الدفع', 'التأكيد']

interface GuestForm {
  fullName: string
  phone: string
  whatsapp: string
  email: string
  specialRequests: string
}

const EMPTY_GUEST: GuestForm = { fullName: '', phone: '', whatsapp: '', email: '', specialRequests: '' }

interface BookingDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  hotel: HotelPublic | null
  initialSearch: SearchParams
  presetRoomTypeId?: string
  onManageBooking: (reference: string) => void
  onPrint: (data: { reservation: ReservationPublic; snapshot: SnapshotBreakdown | null }) => void
}

export function BookingDialog({
  open,
  onOpenChange,
  hotel,
  initialSearch,
  presetRoomTypeId,
  onManageBooking,
  onPrint,
}: BookingDialogProps) {
  const { toast } = useToast()

  const [step, setStep] = useState(1)
  const [search, setSearch] = useState<SearchParams>(initialSearch)
  const [editOpen, setEditOpen] = useState(false)
  const [items, setItems] = useState<AvailabilityItem[]>([])
  const [searching, setSearching] = useState(false)
  const [searchError, setSearchError] = useState<string | null>(null)
  const [selected, setSelected] = useState<AvailabilityItem | null>(null)
  const [guest, setGuest] = useState<GuestForm>(EMPTY_GUEST)
  const [policyAccepted, setPolicyAccepted] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [paymentMethod, setPaymentMethod] = useState<'PAY_AT_HOTEL' | 'CARD'>('PAY_AT_HOTEL')
  const [confirmed, setConfirmed] = useState<ReservationPublic | null>(null)

  // آخر قيم props (تُقرأ عند الفتح دون إعادة تشغيل التأثيرات)
  const initialSearchRef = useRef(initialSearch)
  initialSearchRef.current = initialSearch
  const presetRef = useRef(presetRoomTypeId)
  presetRef.current = presetRoomTypeId

  // مفتاح idempotency — يولد مرة لكل تدفق حجز ويثبت
  const idemKeyRef = useRef('')
  const submittingRef = useRef(false)

  // ── البحث ──
  const runSearch = useCallback(
    async (s: SearchParams): Promise<AvailabilityItem[]> => {
      setSearching(true)
      setSearchError(null)
      try {
        const res = await api<{ items: AvailabilityItem[] }>('/api/public/availability', {
          method: 'POST',
          body: s,
        })
        setItems(res.items)
        return res.items
      } catch (e) {
        setItems([])
        const msg = e instanceof ApiError ? e.message : 'تعذر البحث عن الغرف — يرجى المحاولة مرة أخرى'
        setSearchError(msg)
        return []
      } finally {
        setSearching(false)
      }
    },
    []
  )

  // ── إعادة التعيين + البحث التلقائي عند الفتح ──
  useEffect(() => {
    if (!open) return
    const s = initialSearchRef.current
    const preset = presetRef.current
    setStep(1)
    setSearch(s)
    setEditOpen(false)
    setItems([])
    setSearchError(null)
    setSelected(null)
    setGuest(EMPTY_GUEST)
    setPolicyAccepted(false)
    setErrors({})
    setPaymentMethod('PAY_AT_HOTEL')
    setConfirmed(null)
    idemKeyRef.current = ''
    submittingRef.current = false

    let cancelled = false
    void runSearch(s).then((result) => {
      if (cancelled) return
      // تحديد مسبق لنوع الغرفة (زر «احجز الآن» من بطاقة الغرفة)
      if (preset) {
        const match = result.find((i) => i.roomType.id === preset)
        if (match) {
          setSelected(match)
          setStep(2)
        } else if (result.length > 0) {
          toast({
            title: 'هذا النوع غير متاح للمواعيد المختارة',
            description: 'اختر أحد الخيارات المتاحة أدناه أو عدّل المواعيد',
          })
        }
      }
    })
    return () => {
      cancelled = true
    }
  }, [open])

  // ── الخطوة 4: إرسال الحجز تلقائيًا (مرة واحدة لكل دخول) ──
  const submitBooking = useCallback(async () => {
    if (!selected || !hotel) return
    submittingRef.current = true
    if (!idemKeyRef.current) {
      idemKeyRef.current =
        typeof crypto !== 'undefined' && 'randomUUID' in crypto
          ? crypto.randomUUID()
          : `idem-${Date.now()}-${Math.random().toString(36).slice(2)}`
    }
    const key = idemKeyRef.current

    try {
      const res = await api<{ reservation: ReservationPublic }>('/api/public/bookings', {
        method: 'POST',
        body: {
          checkIn: search.checkIn,
          checkOut: search.checkOut,
          adults: search.adults,
          children: search.children,
          roomsCount: search.roomsCount,
          roomTypeId: selected.roomType.id,
          guest: {
            fullName: guest.fullName.trim(),
            phone: guest.phone.trim(),
            ...(guest.whatsapp.trim() ? { whatsapp: guest.whatsapp.trim() } : {}),
            ...(guest.email.trim() ? { email: guest.email.trim() } : {}),
          },
          ...(guest.specialRequests.trim() ? { specialRequests: guest.specialRequests.trim() } : {}),
          paymentMethod,
          idempotencyKey: key,
        },
      })
      setConfirmed(res.reservation)
      setStep(5)
      toast({ title: 'تم تأكيد حجزك بنجاح', description: res.reservation.bookingReference })
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : 'حدث خطأ غير متوقع أثناء الحجز'
      if (e instanceof ApiError && e.status === 409) {
        // فشل التوفر → عودة للخطوة 1 + تحديث النتائج
        setStep(1)
        toast({ title: 'تنبيه', description: msg })
        setSelected(null)
        void runSearch(search)
      } else {
        setStep(3)
        toast({ title: 'تعذر إتمام الحجز', description: msg, variant: 'destructive' })
      }
    } finally {
      submittingRef.current = false
    }
  }, [selected, hotel, search, guest, paymentMethod, runSearch, toast])

  useEffect(() => {
    if (step === 4 && !submittingRef.current) {
      void submitBooking()
    }
  }, [step])

  // ── إجراءات ──
  const submitSearchEdit = () => {
    if (search.checkOut <= search.checkIn) {
      setSearchError('تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول')
      return
    }
    void runSearch(search)
    setEditOpen(false)
  }

  const validateGuest = () => {
    const errs: Record<string, string> = {}
    if (guest.fullName.trim().length < 3) errs.fullName = 'يرجى إدخال الاسم الكامل (3 أحرف على الأقل)'
    if (digits(guest.phone).length < 9) errs.phone = 'يرجى إدخال رقم هاتف صحيح (9 أرقام على الأقل)'
    if (guest.whatsapp.trim() && digits(guest.whatsapp).length < 9)
      errs.whatsapp = 'رقم الواتساب غير صحيح (9 أرقام على الأقل)'
    if (guest.email.trim() && !/^\S+@\S+\.\S+$/.test(guest.email.trim()))
      errs.email = 'يرجى إدخال بريد إلكتروني صحيح أو تركه فارغًا'
    if (!policyAccepted) errs.policy = 'يرجى الإقرار بسياسة الإلغاء للمتابعة'
    setErrors(errs)
    return Object.keys(errs).length === 0
  }

  const copyReference = async (ref: string) => {
    try {
      await navigator.clipboard.writeText(ref)
      toast({ title: 'تم النسخ', description: `تم نسخ رقم الحجز ${ref}` })
    } catch {
      toast({ title: 'تعذر النسخ', description: ref, variant: 'destructive' })
    }
  }

  const closeDialog = () => onOpenChange(false)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent aria-describedby={undefined} className="flex max-h-[90vh] flex-col overflow-hidden gap-0 p-0 sm:max-w-3xl [&>button]:z-10">
        <DialogHeader className="border-b p-4 pb-3 sm:p-5 sm:pb-4">
          <DialogTitle className="text-lg font-extrabold sm:text-xl">
            {step === 5 ? 'تم الحجز' : 'احجز إقامتك'}
          </DialogTitle>
          <StepIndicator step={step} />
        </DialogHeader>

        <div className="flex-1 overflow-y-auto p-4 sm:p-5">
          <AnimatePresence mode="wait">
            <motion.div
              key={step}
              initial={{ opacity: 0, x: -16 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 16 }}
              transition={{ duration: 0.22, ease: 'easeOut' }}
            >
              {step === 1 ? (
                <StepResults
                  search={search}
                  onSearchChange={setSearch}
                  items={items}
                  searching={searching}
                  error={searchError}
                  editOpen={editOpen}
                  onEditToggle={() => setEditOpen((o) => !o)}
                  onSearchSubmit={submitSearchEdit}
                  onRetry={() => void runSearch(search)}
                  onSelect={(item) => {
                    setSelected(item)
                    setStep(2)
                  }}
                />
              ) : null}

              {step === 2 && selected ? (
                <StepGuest
                  guest={guest}
                  onChange={(g) => setGuest(g)}
                  errors={errors}
                  hotel={hotel}
                  policyAccepted={policyAccepted}
                  onPolicyChange={(c) => setPolicyAccepted(c)}
                  onBack={() => setStep(1)}
                  onSubmit={() => {
                    if (validateGuest()) setStep(3)
                  }}
                />
              ) : null}

              {step === 3 && selected ? (
                <StepReview
                  hotel={hotel}
                  selected={selected}
                  search={search}
                  guest={guest}
                  paymentMethod={paymentMethod}
                  onPaymentChange={setPaymentMethod}
                  onBack={() => setStep(2)}
                  onConfirm={() => setStep(4)}
                />
              ) : null}

              {step === 4 ? <StepProcessing /> : null}

              {step === 5 && confirmed ? (
                <StepConfirmation
                  hotel={hotel}
                  reservation={confirmed}
                  snapshot={selected ? snapshotFromQuote(selected, hotel) : null}
                  paymentMethod={paymentMethod}
                  onCopy={copyReference}
                  onPrint={() =>
                    onPrint({
                      reservation: confirmed,
                      snapshot: selected ? snapshotFromQuote(selected, hotel) : null,
                    })
                  }
                  onManage={() => {
                    onManageBooking(confirmed.bookingReference)
                  }}
                  onClose={closeDialog}
                />
              ) : null}
            </motion.div>
          </AnimatePresence>
        </div>
      </DialogContent>
    </Dialog>
  )
}

/** بناء لقطة عرض من عرض السعر (الملخص فقط — المجاميع من استجابة الخادم) */
function snapshotFromQuote(item: AvailabilityItem, hotel: HotelPublic | null): SnapshotBreakdown {
  return {
    nightly: item.quote.nightly,
    subtotalCents: item.quote.subtotalCents,
    taxCents: item.quote.taxCents,
    grandTotalCents: item.quote.grandTotalCents,
    cancellationPolicy: hotel?.cancellationPolicy,
    checkInTime: hotel?.checkInTime,
    checkOutTime: hotel?.checkOutTime,
  }
}

// ─────────────────────────── مؤشر الخطوات ───────────────────────────

function StepIndicator({ step }: { step: number }) {
  return (
    <ol className="mt-3 flex items-center gap-1.5" aria-label="خطوات الحجز">
      {STEP_LABELS.map((label, i) => {
        const n = i + 1
        const done = n < step
        const active = n === step
        return (
          <li key={label} className="flex flex-1 items-center gap-1.5">
            <span
              className={`flex size-6 shrink-0 items-center justify-center rounded-full text-[11px] font-black transition-colors ${
                done
                  ? 'bg-success text-white'
                  : active
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-muted-foreground'
              }`}
              aria-current={active ? 'step' : undefined}
            >
              {done ? <CheckCircle2 className="size-4" /> : n}
            </span>
            <span
              className={`hidden text-[11px] font-bold sm:inline ${
                active ? 'text-foreground' : 'text-muted-foreground'
              }`}
            >
              {label}
            </span>
            {n < STEP_LABELS.length ? (
              <span className={`h-px flex-1 ${done ? 'bg-success/60' : 'bg-border'}`} />
            ) : null}
          </li>
        )
      })}
    </ol>
  )
}

// ─────────────────────────── الخطوة 1: النتائج ───────────────────────────

function StepResults({
  search,
  onSearchChange,
  items,
  searching,
  error,
  editOpen,
  onEditToggle,
  onSearchSubmit,
  onRetry,
  onSelect,
}: {
  search: SearchParams
  onSearchChange: (s: SearchParams) => void
  items: AvailabilityItem[]
  searching: boolean
  error: string | null
  editOpen: boolean
  onEditToggle: () => void
  onSearchSubmit: () => void
  onRetry: () => void
  onSelect: (item: AvailabilityItem) => void
}) {
  const set = (patch: Partial<SearchParams>) => {
    const next = { ...search, ...patch }
    if (next.checkOut <= next.checkIn) next.checkOut = addDaysInput(next.checkIn, 1)
    onSearchChange(next)
  }

  return (
    <div className="space-y-4">
      {/* ملخص البحث */}
      <div className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-muted/50 px-3 py-2">
        <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm font-semibold text-foreground">
          <span className="inline-flex items-center gap-1.5">
            <CalendarDays className="size-4 text-primary dark:text-gold" />
            {formatDateAr(search.checkIn)} ← {formatDateAr(search.checkOut)}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <Users className="size-4 text-primary dark:text-gold" />
            {guestsText(search.adults, search.children)}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <BedDouble className="size-4 text-primary dark:text-gold" />
            {roomsText(search.roomsCount)}
          </span>
        </div>
        <Button variant="outline" size="sm" onClick={onEditToggle}>
          <Pencil className="size-3.5" />
          {editOpen ? 'إخفاء' : 'تعديل'}
        </Button>
      </div>

      {/* نموذج التعديل */}
      {editOpen ? (
        <div className="grid grid-cols-2 gap-3 rounded-lg border p-3 md:grid-cols-3 xl:grid-cols-6">
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">الوصول</Label>
            <Input type="date" dir="ltr" value={search.checkIn} min={todayInputValue()} onChange={(e) => set({ checkIn: e.target.value })} />
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">المغادرة</Label>
            <Input
              type="date"
              dir="ltr"
              value={search.checkOut}
              min={addDaysInput(search.checkIn, 1)}
              onChange={(e) => set({ checkOut: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">البالغون</Label>
            <Select value={String(search.adults)} onValueChange={(v) => set({ adults: Number(v) })}>
              <SelectTrigger dir="rtl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {[1, 2, 3, 4, 5, 6].map((n) => (
                  <SelectItem key={n} value={String(n)}>
                    {n === 1 ? 'بالغ واحد' : n === 2 ? 'بالغان' : `${n} بالغين`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">الأطفال</Label>
            <Select value={String(search.children)} onValueChange={(v) => set({ children: Number(v) })}>
              <SelectTrigger dir="rtl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {[0, 1, 2, 3, 4].map((n) => (
                  <SelectItem key={n} value={String(n)}>
                    {n === 0 ? 'بدون' : n === 1 ? 'طفل واحد' : n === 2 ? 'طفلان' : `${n} أطفال`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">الغرف</Label>
            <Select value={String(search.roomsCount)} onValueChange={(v) => set({ roomsCount: Number(v) })}>
              <SelectTrigger dir="rtl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {[1, 2, 3].map((n) => (
                  <SelectItem key={n} value={String(n)}>
                    {n === 1 ? 'غرفة واحدة' : n === 2 ? 'غرفتان' : `${n} غرف`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="col-span-2 flex items-end md:col-span-3 xl:col-span-1">
            <Button className="w-full" onClick={onSearchSubmit}>
              تحديث النتائج
            </Button>
          </div>
        </div>
      ) : null}

      {/* الحالات */}
      {searching ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex gap-3 rounded-xl border p-3">
              <Skeleton className="h-20 w-28 shrink-0 rounded-lg" />
              <div className="flex-1 space-y-2 py-1">
                <Skeleton className="h-5 w-36" />
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-4 w-28" />
              </div>
              <Skeleton className="h-9 w-20 self-center" />
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-destructive/30 bg-destructive/5 p-8 text-center">
          <AlertCircle className="size-10 text-destructive" />
          <p className="text-sm font-semibold text-foreground">{error}</p>
          <Button variant="outline" onClick={onRetry}>
            <RefreshCw className="size-4" />
            إعادة المحاولة
          </Button>
        </div>
      ) : items.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed p-8 text-center">
          <SearchX className="size-10 text-muted-foreground" />
          <p className="text-sm font-semibold text-foreground">
            لا توجد غرف متاحة لهذه المواعيد — جرّب مواعيد أخرى
          </p>
          <Button variant="outline" onClick={onEditToggle}>
            <Pencil className="size-4" />
            تعديل المواعيد
          </Button>
        </div>
      ) : (
        <ul className="space-y-3">
          {items.map((item) => (
            <li
              key={item.roomType.id}
              className="flex flex-col gap-3 rounded-xl border p-3 transition-all hover:border-primary/40 hover:shadow-md sm:flex-row sm:items-center"
            >
              <img
                src={item.roomType.images[0] ?? '/images/room-double.png'}
                alt={item.roomType.name}
                className="h-20 w-full shrink-0 rounded-lg object-cover sm:w-28"
                loading="lazy"
              />
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                  <h4 className="text-base font-extrabold text-foreground">{item.roomType.name}</h4>
                  <span className="text-xs font-bold text-muted-foreground">
                    {miniCapacity(item.roomType.capacityAdults, item.roomType.capacityChildren)}
                  </span>
                  <span className="text-xs font-bold text-muted-foreground">
                    · {nightsText(item.quote.nights)}
                  </span>
                </div>
                <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-0.5 text-xs text-muted-foreground">
                  <span dir="ltr">
                    {formatMoney(item.quote.nightly[0]?.priceCents ?? item.roomType.basePriceCents)} / ليلة
                  </span>
                  {item.quote.nightly.some((n) => n.priceCents !== item.quote.nightly[0]?.priceCents) ? (
                    <span className="text-gold">· أسعار متغيرة (تشمل زيادة نهاية الأسبوع)</span>
                  ) : null}
                  {item.availableCount <= 2 ? (
                    <span className="font-bold text-warning">
                      · متبقٍ {item.availableCount === 1 ? 'غرفة واحدة' : `${item.availableCount} غرف`} فقط!
                    </span>
                  ) : null}
                </div>
              </div>
              <div className="flex items-center justify-between gap-3 sm:flex-col sm:items-end">
                <div className="text-left sm:text-right">
                  <div className="text-xs text-muted-foreground">الإجمالي شامل الضريبة</div>
                  <div className="text-xl font-black text-primary dark:text-gold" dir="ltr">
                    {formatMoney(item.quote.grandTotalCents)}
                  </div>
                </div>
                <Button onClick={() => onSelect(item)} className="shrink-0">
                  اختر
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

// ─────────────────────────── الخطوة 2: بيانات الضيف ───────────────────────────

function StepGuest({
  guest,
  onChange,
  errors,
  hotel,
  policyAccepted,
  onPolicyChange,
  onBack,
  onSubmit,
}: {
  guest: GuestForm
  onChange: (g: GuestForm) => void
  errors: Record<string, string>
  hotel: HotelPublic | null
  policyAccepted: boolean
  onPolicyChange: (accepted: boolean) => void
  onBack: () => void
  onSubmit: () => void
}) {
  const set = (patch: Partial<GuestForm>) => onChange({ ...guest, ...patch })

  return (
    <form
      className="space-y-4"
      onSubmit={(e) => {
        e.preventDefault()
        onSubmit()
      }}
    >
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <Label htmlFor="bk-name">الاسم الكامل *</Label>
          <Input
            id="bk-name"
            value={guest.fullName}
            onChange={(e) => set({ fullName: e.target.value })}
            placeholder="مثال: أحمد محمد الشرعبي"
            autoComplete="name"
            aria-invalid={!!errors.fullName}
          />
          {errors.fullName ? <FieldError msg={errors.fullName} /> : null}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="bk-phone">رقم الهاتف *</Label>
          <Input
            id="bk-phone"
            dir="ltr"
            value={guest.phone}
            onChange={(e) => set({ phone: e.target.value })}
            placeholder="+967 7XX XXX XXX"
            inputMode="tel"
            autoComplete="tel"
            className="text-left"
            aria-invalid={!!errors.phone}
          />
          {errors.phone ? <FieldError msg={errors.phone} /> : null}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="bk-wa">رقم الواتساب (اختياري)</Label>
          <Input
            id="bk-wa"
            dir="ltr"
            value={guest.whatsapp}
            onChange={(e) => set({ whatsapp: e.target.value })}
            placeholder="+967 7XX XXX XXX"
            inputMode="tel"
            className="text-left"
            aria-invalid={!!errors.whatsapp}
          />
          {errors.whatsapp ? <FieldError msg={errors.whatsapp} /> : null}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="bk-email">البريد الإلكتروني (اختياري)</Label>
          <Input
            id="bk-email"
            dir="ltr"
            type="email"
            value={guest.email}
            onChange={(e) => set({ email: e.target.value })}
            placeholder="name@example.com"
            inputMode="email"
            autoComplete="email"
            className="text-left"
            aria-invalid={!!errors.email}
          />
          {errors.email ? <FieldError msg={errors.email} /> : null}
        </div>
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="bk-requests">طلبات خاصة (اختياري)</Label>
        <Textarea
          id="bk-requests"
          value={guest.specialRequests}
          onChange={(e) => set({ specialRequests: e.target.value })}
          placeholder="مثال: طابق مرتفع إن أمكن"
          rows={3}
        />
      </div>

      {/* الإقرار بسياسة الإلغاء */}
      <div className="rounded-lg border bg-muted/40 p-3">
        <div className="flex items-start gap-2.5">
          <Checkbox
            id="bk-policy"
            checked={policyAccepted}
            onCheckedChange={(c) => onPolicyChange(Boolean(c))}
            className="mt-0.5"
            aria-invalid={!!errors.policy}
          />
          <div>
            <Label htmlFor="bk-policy" className="cursor-pointer text-sm font-bold">
              أقر بسياسة الإلغاء
            </Label>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              {hotel?.cancellationPolicy ?? 'الإلغاء مجاني حتى 24 ساعة قبل موعد الوصول.'}
            </p>
            {errors.policy ? <FieldError msg={errors.policy} /> : null}
          </div>
        </div>
      </div>

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-between">
        <Button type="button" variant="outline" onClick={onBack}>
          رجوع للنتائج
        </Button>
        <Button type="submit" size="lg" className="flex-1 sm:flex-none sm:min-w-40">
          متابعة للمراجعة
        </Button>
      </div>
    </form>
  )
}

function FieldError({ msg }: { msg: string }) {
  return (
    <p className="flex items-center gap-1 text-xs font-semibold text-destructive" role="alert">
      <AlertCircle className="size-3.5 shrink-0" />
      {msg}
    </p>
  )
}

// ─────────────────────────── الخطوة 3: المراجعة ───────────────────────────

function StepReview({
  hotel,
  selected,
  search,
  guest,
  paymentMethod,
  onPaymentChange,
  onBack,
  onConfirm,
}: {
  hotel: HotelPublic | null
  selected: AvailabilityItem
  search: SearchParams
  guest: GuestForm
  paymentMethod: 'PAY_AT_HOTEL' | 'CARD'
  onPaymentChange: (m: 'PAY_AT_HOTEL' | 'CARD') => void
  onBack: () => void
  onConfirm: () => void
}) {
  const quote = selected.quote
  const nightly = quote.nightly
  const uniform = nightly.length > 0 && nightly.every((n) => n.priceCents === nightly[0].priceCents)
  const deposit = Math.round(quote.grandTotalCents / 2)

  return (
    <div className="space-y-4">
      {/* بطاقة الملخص */}
      <div className="rounded-xl border bg-card">
        <div className="border-b bg-muted/40 px-4 py-3">
          <div className="text-sm font-bold text-muted-foreground">{hotel?.name ?? 'فندق قلب القاهرة'}</div>
          <div className="mt-0.5 text-lg font-extrabold text-foreground">{selected.roomType.name}</div>
        </div>

        <div className="grid grid-cols-2 gap-x-4 gap-y-3 p-4 text-sm sm:grid-cols-4">
          <div>
            <div className="text-xs text-muted-foreground">الوصول</div>
            <div className="mt-0.5 font-bold text-foreground">{formatDateAr(search.checkIn)}</div>
            <div className="text-xs text-muted-foreground" dir="ltr">
              {formatClockAr(hotel?.checkInTime)}
            </div>
          </div>
          <div>
            <div className="text-xs text-muted-foreground">المغادرة</div>
            <div className="mt-0.5 font-bold text-foreground">{formatDateAr(search.checkOut)}</div>
            <div className="text-xs text-muted-foreground" dir="ltr">
              {formatClockAr(hotel?.checkOutTime)}
            </div>
          </div>
          <div>
            <div className="text-xs text-muted-foreground">المدة</div>
            <div className="mt-0.5 font-bold text-foreground">{nightsText(quote.nights)}</div>
            <div className="text-xs text-muted-foreground">{roomsText(quote.roomsCount)}</div>
          </div>
          <div>
            <div className="text-xs text-muted-foreground">الضيوف</div>
            <div className="mt-0.5 font-bold text-foreground">{guestsText(search.adults, search.children)}</div>
            <div className="text-xs text-muted-foreground">{guest.fullName}</div>
          </div>
        </div>

        <Separator />

        {/* جدول الأسعار — من الخادم فقط */}
        <div className="p-4">
          <h4 className="mb-2 text-sm font-bold text-foreground">تفصيل الأسعار</h4>
          <div className="space-y-1.5 text-sm">
            {uniform ? (
              <PriceRow
                label={`${formatMoney(nightly[0].priceCents)} × ${nightsText(quote.nights)}${
                  quote.roomsCount > 1 ? ` × ${quote.roomsCount}` : ''
                }`}
                value={formatMoney(quote.subtotalCents)}
              />
            ) : (
              nightly.map((n) => (
                <PriceRow
                  key={n.date}
                  label={`${formatDateAr(n.date)}${n.rateName ? ` — ${n.rateName}` : ''}`}
                  value={formatMoney(n.priceCents * quote.roomsCount)}
                  muted
                />
              ))
            )}
            <PriceRow label={`المجموع الفرعي`} value={formatMoney(quote.subtotalCents)} />
            <PriceRow label={`الضريبة (${quote.taxPercent}%)`} value={formatMoney(quote.taxCents)} />
            <Separator className="my-2" />
            <div className="flex items-center justify-between">
              <span className="text-base font-black text-foreground">الإجمالي</span>
              <span className="text-2xl font-black text-primary dark:text-gold" dir="ltr">
                {formatMoney(quote.grandTotalCents)}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* طريقة الدفع */}
      <div>
        <h4 className="mb-2.5 text-sm font-bold text-foreground">طريقة الدفع</h4>
        <RadioGroup
          value={paymentMethod}
          onValueChange={(v) => onPaymentChange(v as 'PAY_AT_HOTEL' | 'CARD')}
          className="grid grid-cols-1 gap-3 sm:grid-cols-2"
        >
          <label
            className={`flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition-all ${
              paymentMethod === 'PAY_AT_HOTEL' ? 'border-primary bg-primary/5 shadow-sm' : 'hover:border-primary/40'
            }`}
          >
            <RadioGroupItem value="PAY_AT_HOTEL" className="mt-1" />
            <div>
              <div className="text-sm font-extrabold text-foreground">الدفع في الفندق</div>
              <div className="mt-1 text-xs leading-relaxed text-muted-foreground">
                تسدد كامل المبلغ عند الوصول — نقدًا أو بالبطاقة
              </div>
            </div>
          </label>
          <label
            className={`flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition-all ${
              paymentMethod === 'CARD' ? 'border-primary bg-primary/5 shadow-sm' : 'hover:border-primary/40'
            }`}
          >
            <RadioGroupItem value="CARD" className="mt-1" />
            <div>
              <div className="text-sm font-extrabold text-foreground">
                بطاقة — عربون <span dir="ltr">{formatMoney(deposit)}</span>
              </div>
              <div className="mt-1 text-xs leading-relaxed text-muted-foreground">
                يُحجز العربون إلكترونيًا الآن (50%) والباقي يُسدد بالفندق
              </div>
            </div>
          </label>
        </RadioGroup>
      </div>

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-between">
        <Button variant="outline" onClick={onBack}>
          رجوع
        </Button>
        <Button size="lg" className="flex-1 sm:flex-none sm:min-w-48" onClick={onConfirm}>
          تأكيد الحجز
        </Button>
      </div>
    </div>
  )
}

function PriceRow({ label, value, muted }: { label: string; value: string; muted?: boolean }) {
  return (
    <div className="flex items-center justify-between">
      <span className={muted ? 'text-xs text-muted-foreground' : 'text-muted-foreground'}>{label}</span>
      <span className={`font-semibold ${muted ? 'text-xs text-muted-foreground' : 'text-foreground'}`} dir="ltr">
        {value}
      </span>
    </div>
  )
}

// ─────────────────────────── الخطوة 4: المعالجة ───────────────────────────

function StepProcessing() {
  return (
    <div className="flex flex-col items-center gap-4 py-14 text-center">
      <Loader2 className="size-14 animate-spin text-primary dark:text-gold" />
      <p className="text-lg font-extrabold text-foreground">جارٍ تأكيد حجزك…</p>
      <p className="max-w-xs text-sm text-muted-foreground">
        يتم التحقق من التوفر وحجز غرفتك بأمان — لا تغلق النافذة
      </p>
    </div>
  )
}

// ─────────────────────────── الخطوة 5: التأكيد ───────────────────────────

function StepConfirmation({
  hotel,
  reservation,
  snapshot,
  paymentMethod,
  onCopy,
  onPrint,
  onManage,
  onClose,
}: {
  hotel: HotelPublic | null
  reservation: ReservationPublic
  snapshot: SnapshotBreakdown | null
  paymentMethod: 'PAY_AT_HOTEL' | 'CARD'
  onCopy: (ref: string) => void
  onPrint: () => void
  onManage: () => void
  onClose: () => void
}) {
  const remaining = Math.max(0, reservation.grandTotalCents - reservation.paidCents)
  const payBadge = paymentStatusBadge(reservation.paymentStatus)

  return (
    <div className="space-y-5">
      {/* النجاح */}
      <div className="flex flex-col items-center gap-3 pt-2 text-center">
        <CheckCircle2 className="size-16 text-success" />
        <h3 className="text-2xl font-black text-foreground">تم تأكيد حجزك!</h3>
        <p className="text-sm text-muted-foreground">أرسلنا التفاصيل إلى رقم هاتفك المسجل</p>

        {/* رقم الحجز copyable */}
        <button
          type="button"
          onClick={() => onCopy(reservation.bookingReference)}
          className="group flex items-center gap-2.5 rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 px-5 py-3 transition-colors hover:border-primary"
          title="اضغط للنسخ"
        >
          <span className="font-mono text-2xl font-black tracking-wider text-primary dark:text-gold sm:text-3xl" dir="ltr">
            {reservation.bookingReference}
          </span>
          <Copy className="size-5 text-muted-foreground transition-colors group-hover:text-primary" />
        </button>
        <span className="text-xs text-muted-foreground">رقم الحجز — اضغط عليه للنسخ واحتفظ به لإدارة حجزك</span>
      </div>

      <Separator />

      {/* الملخص */}
      <div className="grid grid-cols-2 gap-x-4 gap-y-3 rounded-xl border bg-muted/40 p-4 text-sm sm:grid-cols-4">
        <SummaryCell label="الضيف" value={reservation.guest.fullName} />
        <SummaryCell label="الغرفة" value={reservation.roomType.name} />
        <SummaryCell
          label="الوصول"
          value={`${formatDateAr(reservation.checkIn)} · ${formatClockAr(snapshot?.checkInTime ?? hotel?.checkInTime)}`}
        />
        <SummaryCell
          label="المغادرة"
          value={`${formatDateAr(reservation.checkOut)} · ${formatClockAr(snapshot?.checkOutTime ?? hotel?.checkOutTime)}`}
        />
        <SummaryCell label="المدة" value={nightsText(reservation.nights)} />
        <SummaryCell label="الضيوف" value={guestsText(reservation.adults, reservation.children)} />
        <SummaryCell label="الإجمالي" value={formatMoney(reservation.grandTotalCents)} ltr bold />
        <div>
          <div className="text-xs text-muted-foreground">حالة الدفع</div>
          <span className={`mt-0.5 inline-block ${payBadge.className}`}>{payBadge.label}</span>
        </div>
      </div>

      {/* تفصيل الدفع */}
      <div className="rounded-xl border p-4">
        <div className="flex items-center justify-between text-sm">
          <span className="font-bold text-foreground">
            {paymentMethod === 'CARD' ? 'بطاقة — عربون 50% مدفوع إلكترونيًا' : 'الدفع في الفندق عند الوصول'}
          </span>
        </div>
        {paymentMethod === 'CARD' && remaining > 0 ? (
          <div className="mt-2 flex items-center justify-between text-sm">
            <span className="text-muted-foreground">
              المدفوع <span className="font-bold text-success" dir="ltr">{formatMoney(reservation.paidCents)}</span> ·
              المتبقي بالفندق <span className="font-bold text-warning" dir="ltr">{formatMoney(remaining)}</span>
            </span>
          </div>
        ) : null}
      </div>

      {/* الأزرار */}
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        <Button size="lg" onClick={onPrint}>
          <Printer className="size-4" />
          تحميل / طباعة التأكيد
        </Button>
        {hotel?.whatsapp ? (
          <Button size="lg" variant="outline" asChild>
            <a
              href={waLink(hotel.whatsapp, `حجز جديد ${reservation.bookingReference}`)}
              target="_blank"
              rel="noopener noreferrer"
            >
              <MessageCircle className="size-4" />
              تواصل واتساب
            </a>
          </Button>
        ) : null}
        <Button size="lg" variant="outline" onClick={onManage}>
          <ClipboardList className="size-4" />
          إدارة الحجز
        </Button>
        <Button size="lg" onClick={onClose}>
          <CheckCircle2 className="size-4" />
          تم
        </Button>
      </div>

      <p className="flex items-center justify-center gap-1.5 text-center text-xs text-muted-foreground">
        <Info className="size-3.5" />
        الإلغاء مجاني حتى 24 ساعة قبل الوصول — من «إدارة الحجز»
      </p>
    </div>
  )
}

function SummaryCell({ label, value, ltr, bold }: { label: string; value: string; ltr?: boolean; bold?: boolean }) {
  return (
    <div>
      <div className="text-xs text-muted-foreground">{label}</div>
      <div
        className={`mt-0.5 ${bold ? 'font-black text-primary dark:text-gold' : 'font-bold text-foreground'}`}
        dir={ltr ? 'ltr' : undefined}
      >
        {value}
      </div>
    </div>
  )
}

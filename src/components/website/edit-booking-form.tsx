'use client'

// ─────────────────────────────────────────────────────────────
// EDIT BOOKING FORM — نموذج تعديل الحجز المؤهل (المسار C · REQ-01)
// يظهر لحجز CONFIRMED داخل نافذة التعديل المجاني (24 ساعة قبل الوصول)
// المعاينة الحية من /api/public/availability مع استثناء الحجز نفسه،
// والقرار النهائي (السعر/التوفر) دائمًا من الخادم عبر /api/public/edit
// ─────────────────────────────────────────────────────────────
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  Loader2,
  AlertCircle,
  Pencil,
  ArrowRight,
  CalendarDays,
  BedDouble,
  Users,
  Receipt,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Separator } from '@/components/ui/separator'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { api, ApiError } from '@/lib/api-client'
import { formatMoney, todayInputValue, addDaysInput } from '@/lib/format'
import type { AvailabilityItem, HotelPublic } from '@/types'
import { formatClockAr, nightsText, type LookupResult } from './helpers'

/** ISO → قيمة إدخال تاريخ محلي YYYY-MM-DD */
function isoToDateInput(iso: string): string {
  const d = new Date(iso)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

interface EditBookingFormProps {
  hotel: HotelPublic | null
  result: LookupResult
  phone: string
  onDone: (res: LookupResult) => void
  onBack: () => void
}

export function EditBookingForm({ hotel, result, phone, onDone, onBack }: EditBookingFormProps) {
  const r = result.reservation

  // ── القيم القابلة للتعديل (مهيأة من الحجز الحالي) ──
  const [checkIn, setCheckIn] = useState(isoToDateInput(r.checkIn))
  const [checkOut, setCheckOut] = useState(isoToDateInput(r.checkOut))
  const [adults, setAdults] = useState(r.adults)
  const [children, setChildren] = useState(r.children)
  const [roomsCount, setRoomsCount] = useState(r.roomsCount)
  const [roomTypeId, setRoomTypeId] = useState(r.roomType.id)
  const [specialRequests, setSpecialRequests] = useState(r.specialRequests ?? '')

  // ── المعاينة الحية ──
  const [items, setItems] = useState<AvailabilityItem[] | null>(null)
  const [previewing, setPreviewing] = useState(true)
  const [previewError, setPreviewError] = useState<string | null>(null)

  // ── الإرسال ──
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  const prevType = useRef(r.roomType.id)
  prevType.current = r.roomType.id

  // ── تحقق عميل خفيف للمدخلات ──
  const datesValid = checkOut > checkIn && checkIn >= todayInputValue()
  const nights = useMemo(() => {
    if (!datesValid) return 0
    return Math.round(
      (new Date(`${checkOut}T00:00:00`).getTime() - new Date(`${checkIn}T00:00:00`).getTime()) / 86_400_000
    )
  }, [checkIn, checkOut, datesValid])

  // هل القيم مطابقة تمامًا للحجز الحالي؟ (نفس منطق الخادم)
  const noChanges =
    datesValid &&
    isoToDateInput(r.checkIn) === checkIn &&
    isoToDateInput(r.checkOut) === checkOut &&
    r.roomType.id === roomTypeId &&
    r.adults === adults &&
    r.children === children &&
    r.roomsCount === roomsCount &&
    (r.specialRequests ?? '') === specialRequests.trim()

  // ── جلب المعاينة (debounce) عند تغيّر المواعيد/الضيوف ──
  useEffect(() => {
    if (!datesValid) {
      setItems(null)
      return
    }
    const t = setTimeout(async () => {
      setPreviewing(true)
      setPreviewError(null)
      try {
        const res = await api<{ items: AvailabilityItem[] }>('/api/public/availability', {
          method: 'POST',
          body: {
            checkIn,
            checkOut,
            adults,
            children,
            roomsCount,
            // استثناء ذاتي: غرف هذا الحجز تُحرَّر للمعاينة
            reference: r.bookingReference,
            phone: phone.trim(),
          },
        })
        setItems(res.items)
        // النوع المختار إن لم يعد متاحًا → أول نوع متاح
        if (!res.items.some((i) => i.roomType.id === roomTypeId)) {
          setRoomTypeId(res.items[0]?.roomType.id ?? '')
        }
      } catch (e) {
        setItems([])
        setPreviewError(e instanceof ApiError ? e.message : 'تعذر جلب التوفر — يرجى المحاولة مجددًا')
      } finally {
        setPreviewing(false)
      }
    }, 350)
    return () => clearTimeout(t)
  }, [checkIn, checkOut, adults, children, roomsCount, datesValid])

  const selectedItem = items?.find((i) => i.roomType.id === roomTypeId) ?? null

  // ── ملخص قبل/بعد ──
  const oldTotal = r.grandTotalCents
  const newTotal = selectedItem?.quote.grandTotalCents ?? null
  const totalDiff = newTotal !== null ? newTotal - oldTotal : null

  // ── الإرسال: القرار النهائي من الخادم ──
  const submit = async () => {
    if (!datesValid || !selectedItem || noChanges || submitting) return
    setSubmitting(true)
    setSubmitError(null)
    try {
      const res = await api<LookupResult>('/api/public/edit', {
        method: 'POST',
        body: {
          reference: r.bookingReference,
          phone: phone.trim(),
          checkIn,
          checkOut,
          roomTypeId,
          adults,
          children,
          roomsCount,
          specialRequests: specialRequests.trim(),
        },
      })
      onDone(res)
    } catch (e) {
      setSubmitError(e instanceof ApiError ? e.message : 'حدث خطأ غير متوقع — يرجى المحاولة مرة أخرى')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-4">
      {/* الرأس */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <span className="rounded-lg border-2 border-dashed border-primary/40 bg-primary/5 px-3 py-1.5 font-mono text-base font-black text-primary dark:text-gold" dir="ltr">
            {r.bookingReference}
          </span>
          <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 border border-primary/30 px-2.5 py-1 text-xs font-bold text-primary dark:text-gold">
            <Pencil className="size-3" />
            تعديل الحجز
          </span>
        </div>
        <Button variant="ghost" size="sm" onClick={onBack}>
          <ArrowRight className="size-4" />
          رجوع للتفاصيل
        </Button>
      </div>

      {/* المواعيد والضيوف */}
      <div className="grid grid-cols-2 gap-3 rounded-xl border bg-muted/40 p-4 md:grid-cols-3 xl:grid-cols-6">
        <div className="space-y-1.5">
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <CalendarDays className="size-3" /> الوصول
            </span>
          </Label>
          <Input
            type="date"
            dir="ltr"
            value={checkIn}
            min={todayInputValue()}
            onChange={(e) => {
              const v = e.target.value
              setCheckIn(v)
              if (checkOut <= v) setCheckOut(addDaysInput(v, 1))
            }}
          />
        </div>
        <div className="space-y-1.5">
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <CalendarDays className="size-3" /> المغادرة
            </span>
          </Label>
          <Input
            type="date"
            dir="ltr"
            value={checkOut}
            min={addDaysInput(checkIn, 1)}
            onChange={(e) => setCheckOut(e.target.value)}
          />
        </div>
        <div className="space-y-1.5">
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <Users className="size-3" /> البالغون
            </span>
          </Label>
          <Select value={String(adults)} onValueChange={(v) => setAdults(Number(v))}>
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
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <Users className="size-3" /> الأطفال
            </span>
          </Label>
          <Select value={String(children)} onValueChange={(v) => setChildren(Number(v))}>
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
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <BedDouble className="size-3" /> الغرف
            </span>
          </Label>
          <Select value={String(roomsCount)} onValueChange={(v) => setRoomsCount(Number(v))}>
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
        <div className="space-y-1.5 md:col-span-3 xl:col-span-1">
          <Label className="text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <BedDouble className="size-3" /> نوع الغرفة
            </span>
          </Label>
          {previewing ? (
            <Skeleton className="h-9 w-full" />
          ) : items && items.length > 0 ? (
            <Select value={roomTypeId} onValueChange={setRoomTypeId}>
              <SelectTrigger dir="rtl" className="w-full">
                <SelectValue placeholder="اختر نوع الغرفة" />
              </SelectTrigger>
              <SelectContent>
                {items.map((i) => (
                  <SelectItem key={i.roomType.id} value={i.roomType.id}>
                    {i.roomType.name}
                    {i.roomType.id === prevType.current ? ' (الحالي)' : ''} — {formatMoney(i.quote.grandTotalCents)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          ) : (
            <div className="flex h-9 items-center rounded-md border border-dashed px-2 text-xs text-muted-foreground">
              لا توجد أنواع متاحة
            </div>
          )}
        </div>
      </div>

      {/* طلبات خاصة */}
      <div className="space-y-1.5">
        <Label htmlFor="edit-requests" className="text-xs text-muted-foreground">طلبات خاصة (اختياري)</Label>
        <Textarea
          id="edit-requests"
          value={specialRequests}
          onChange={(e) => setSpecialRequests(e.target.value)}
          placeholder="مثال: طابق مرتفع، سرير إضافي…"
          rows={2}
          className="resize-none"
        />
      </div>

      {!datesValid ? (
        <p className="flex items-center gap-1.5 text-sm font-semibold text-destructive" role="alert">
          <AlertCircle className="size-4 shrink-0" />
          تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول وبعد اليوم
        </p>
      ) : null}
      {previewError ? (
        <p className="flex items-center gap-1.5 text-sm font-semibold text-destructive" role="alert">
          <AlertCircle className="size-4 shrink-0" />
          {previewError}
        </p>
      ) : null}

      {/* ملخص التعديل قبل/بعد */}
      {!previewing && datesValid && !previewError ? (
        items && items.length === 0 ? (
          <div className="rounded-xl border border-warning/40 bg-warning/5 p-3 text-sm font-semibold text-foreground">
            لا توجد غرف متاحة بهذه المواعيد وعدد الضيوف — جرّب تغيير المواعيد أو تقليل عدد الغرف
          </div>
        ) : selectedItem ? (
          <div className="rounded-xl border p-4">
            <h4 className="mb-2 flex items-center gap-1.5 text-sm font-bold text-foreground">
              <Receipt className="size-4 text-primary dark:text-gold" />
              ملخص التعديل
            </h4>
            <div className="space-y-1.5 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">المدة</span>
                <span className="font-semibold text-foreground">
                  {nightsText(r.nights)} ← {nightsText(nights)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">الغرفة</span>
                <span className="font-semibold text-foreground">
                  {r.roomType.name} ← {selectedItem.roomType.name}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">أوقات الفندق</span>
                <span className="font-semibold text-foreground" dir="rtl">
                  وصول {formatClockAr(hotel?.checkInTime)} · مغادرة {formatClockAr(hotel?.checkOutTime)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">الإجمالي القديم</span>
                <span className="font-semibold text-muted-foreground line-through" dir="ltr">
                  {formatMoney(oldTotal)}
                </span>
              </div>
              <div className="flex items-center justify-between border-t pt-2">
                <span className="text-base font-black text-foreground">الإجمالي الجديد</span>
                <span className="text-xl font-black text-primary dark:text-gold" dir="ltr">
                  {formatMoney(newTotal ?? 0)}
                </span>
              </div>
              {totalDiff !== null && totalDiff !== 0 ? (
                <div className="flex items-center justify-between">
                  <span className={totalDiff > 0 ? 'font-semibold text-warning' : 'font-semibold text-success'}>
                    {totalDiff > 0 ? 'فرق يُدفع عند الفندق' : 'فرق لصالحك'}
                  </span>
                  <span className={`font-bold ${totalDiff > 0 ? 'text-warning' : 'text-success'}`} dir="ltr">
                    {formatMoney(Math.abs(totalDiff))}
                  </span>
                </div>
              ) : null}
              {r.paidCents > 0 ? (
                <p className="rounded-md bg-muted/60 p-2 text-xs text-muted-foreground">
                  مدفوعاتك الحالية ({formatMoney(r.paidCents)}) تُنقل كما هي — أي فرق يُسوَّى عند الفندق وفق
                  سياسة الدفع.
                </p>
              ) : null}
            </div>
          </div>
        ) : null
      ) : null}

      {submitError ? (
        <p className="flex items-center gap-1.5 text-sm font-semibold text-destructive" role="alert">
          <AlertCircle className="size-4 shrink-0" />
          {submitError}
        </p>
      ) : null}

      <Separator />

      {/* أزرار الإجراء */}
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        <Button
          size="lg"
          onClick={submit}
          disabled={!datesValid || !selectedItem || noChanges || submitting || previewing}
        >
          {submitting ? <Loader2 className="size-4 animate-spin" /> : <Pencil className="size-4" />}
          {submitting ? 'جارٍ حفظ التعديل…' : 'حفظ التعديل'}
        </Button>
        <Button variant="outline" size="lg" onClick={onBack} disabled={submitting}>
          إلغاء
        </Button>
      </div>

      {noChanges && datesValid ? (
        <p className="text-center text-xs text-muted-foreground">
          القيم الحالية مطابقة لحجزك — عدّل المواعيد أو نوع الغرفة أو عدد الضيوف لتفعيل الحفظ
        </p>
      ) : null}
      <p className="text-center text-xs text-muted-foreground">
        التعديل متاح مجانًا حتى 24 ساعة قبل موعد الوصول — بعدها يرجى التواصل مع الفندق
      </p>
    </div>
  )
}

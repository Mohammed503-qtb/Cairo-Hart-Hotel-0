'use client'

// ─────────────────────────────────────────────────────────────
// MANAGE BOOKING DIALOG — إدارة الحجز (عرض + إلغاء + طباعة)
// ─────────────────────────────────────────────────────────────
import { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search,
  Loader2,
  AlertCircle,
  Printer,
  MessageCircle,
  Ban,
  User,
  BedDouble,
  CalendarDays,
  Users,
  Receipt,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'
import { useToast } from '@/hooks/use-toast'
import { api, ApiError } from '@/lib/api-client'
import { formatMoney, formatDateWithDayAr, formatDateTimeAr } from '@/lib/format'
import type { HotelPublic, ReservationPublic } from '@/types'
import {
  nightsText,
  guestsText,
  roomsText,
  formatClockAr,
  digits,
  waLink,
  reservationStatusBadge,
  paymentStatusBadge,
  type LookupResult,
  type PrintData,
} from './helpers'

interface ManageBookingDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  hotel: HotelPublic | null
  initialReference?: string
  onPrint: (data: PrintData) => void
}

export function ManageBookingDialog({
  open,
  onOpenChange,
  hotel,
  initialReference,
  onPrint,
}: ManageBookingDialogProps) {
  const { toast } = useToast()
  const [reference, setReference] = useState('')
  const [phone, setPhone] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [result, setResult] = useState<LookupResult | null>(null)
  const [cancelling, setCancelling] = useState(false)

  const initialRef = useRef(initialReference)
  initialRef.current = initialReference

  // إعادة تعيين عند الفتح (مع تعبئة المرجع إن وُجد)
  useEffect(() => {
    if (!open) return
    setReference(initialRef.current ?? '')
    setPhone('')
    setError(null)
    setResult(null)
    setLoading(false)
    setCancelling(false)
  }, [open])

  const doLookup = async () => {
    const ref = reference.trim().toUpperCase()
    if (!ref) {
      setError('يرجى إدخال رقم الحجز (مثال: HTL-2026-000421)')
      return
    }
    if (digits(phone).length < 9) {
      setError('يرجى إدخال رقم الهاتف المسجل مع الحجز (9 أرقام على الأقل)')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const res = await api<LookupResult>('/api/public/lookup', {
        method: 'POST',
        body: { reference: ref, phone: phone.trim() },
      })
      setResult(res)
    } catch (e) {
      setResult(null)
      setError(e instanceof ApiError ? e.message : 'تعذر جلب تفاصيل الحجز — يرجى المحاولة مرة أخرى')
    } finally {
      setLoading(false)
    }
  }

  const doCancel = async () => {
    if (!result) return
    setCancelling(true)
    try {
      const res = await api<{ reservation: ReservationPublic; refundable: boolean; penaltyCents: number }>(
        '/api/public/cancel',
        {
          method: 'POST',
          body: { reference: result.reservation.bookingReference, phone: phone.trim() },
        }
      )
      setResult({ ...result, reservation: res.reservation })
      toast({
        title: 'تم إلغاء الحجز',
        description: res.refundable
          ? `أُلغي حجز ${res.reservation.bookingReference} مجانًا دون رسوم`
          : `أُلغي حجز ${res.reservation.bookingReference} مع رسوم ليلة واحدة ${formatMoney(res.penaltyCents)}`,
      })
    } catch (e) {
      toast({
        title: 'تعذر الإلغاء',
        description: e instanceof ApiError ? e.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setCancelling(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle className="text-lg font-extrabold sm:text-xl">إدارة حجزك</DialogTitle>
        </DialogHeader>

        {/* نموذج البحث */}
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label htmlFor="mg-ref">رقم الحجز</Label>
            <Input
              id="mg-ref"
              dir="ltr"
              value={reference}
              onChange={(e) => setReference(e.target.value)}
              placeholder="HTL-2026-000421"
              className="font-mono text-left"
              autoComplete="off"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="mg-phone">رقم الهاتف المسجل</Label>
            <Input
              id="mg-phone"
              dir="ltr"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+967 7XX XXX XXX"
              inputMode="tel"
              className="text-left"
            />
          </div>
        </div>

        <Button size="lg" onClick={doLookup} disabled={loading} className="w-full">
          {loading ? <Loader2 className="size-4 animate-spin" /> : <Search className="size-4" />}
          {loading ? 'جارٍ البحث…' : 'عرض حجزي'}
        </Button>

        {error ? (
          <p className="flex items-center gap-1.5 text-sm font-semibold text-destructive" role="alert">
            <AlertCircle className="size-4 shrink-0" />
            {error}
          </p>
        ) : null}

        <Separator />

        {/* النتيجة */}
        <AnimatePresence mode="wait">
          {result ? (
            <motion.div
              key={result.reservation.id + result.reservation.status}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.25 }}
            >
              <ReservationDetails
                hotel={hotel}
                result={result}
                cancelling={cancelling}
                onCancel={doCancel}
                onPrint={() => onPrint({ reservation: result.reservation, snapshot: result.snapshot })}
              />
            </motion.div>
          ) : (
            <p className="py-4 text-center text-sm text-muted-foreground">
              أدخل رقم الحجز ورقم الهاتف المسجل معه لعرض تفاصيل حجزك
            </p>
          )}
        </AnimatePresence>
      </DialogContent>
    </Dialog>
  )
}

// ─────────────────────────── تفاصيل الحجز ───────────────────────────

function ReservationDetails({
  hotel,
  result,
  cancelling,
  onCancel,
  onPrint,
}: {
  hotel: HotelPublic | null
  result: LookupResult
  cancelling: boolean
  onCancel: () => void
  onPrint: () => void
}) {
  const { reservation: r, snapshot, cancellation } = result
  const status = reservationStatusBadge(r.status)
  const payStatus = paymentStatusBadge(r.paymentStatus)
  const remaining = Math.max(0, r.grandTotalCents - r.paidCents)
  const nightly = snapshot?.nightly ?? []
  const uniform = nightly.length > 0 && nightly.every((n) => n.priceCents === nightly[0].priceCents)
  const canCancel = r.status === 'CONFIRMED'

  return (
    <div className="space-y-4">
      {/* الرأس */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <span className="rounded-lg border-2 border-dashed border-primary/40 bg-primary/5 px-3 py-1.5 font-mono text-base font-black text-primary dark:text-gold" dir="ltr">
            {r.bookingReference}
          </span>
          <span className={status.className}>{status.label}</span>
        </div>
        <span className={payStatus.className}>{payStatus.label}</span>
      </div>

      {/* بيانات */}
      <div className="grid grid-cols-1 gap-3 rounded-xl border bg-muted/40 p-4 text-sm sm:grid-cols-2">
        <DetailRow icon={User} label="الضيف" value={r.guest.fullName} />
        <DetailRow icon={BedDouble} label="الغرفة" value={r.roomType.name} />
        <DetailRow icon={CalendarDays} label="الوصول" value={`${formatDateWithDayAr(r.checkIn)} — ${formatClockAr(snapshot?.checkInTime ?? hotel?.checkInTime)}`} />
        <DetailRow icon={CalendarDays} label="المغادرة" value={`${formatDateWithDayAr(r.checkOut)} — ${formatClockAr(snapshot?.checkOutTime ?? hotel?.checkOutTime)}`} />
        <DetailRow icon={Users} label="الضيوف" value={`${guestsText(r.adults, r.children)} · ${roomsText(r.roomsCount)}`} />
        <DetailRow icon={CalendarDays} label="المدة" value={nightsText(r.nights)} />
        <DetailRow icon={User} label="الهاتف" value={r.guest.phone} ltr />
        {r.specialRequests ? (
          <div className="col-span-full rounded-md bg-background p-2.5 text-xs text-muted-foreground">
            <span className="font-bold text-foreground">طلبات خاصة: </span>
            {r.specialRequests}
          </div>
        ) : null}
      </div>

      {/* تفصيل الأسعار من لقطة الحجز */}
      {snapshot ? (
        <div className="rounded-xl border p-4">
          <h4 className="mb-2 flex items-center gap-1.5 text-sm font-bold text-foreground">
            <Receipt className="size-4 text-primary dark:text-gold" />
            تفصيل الأسعار (وقت الحجز)
          </h4>
          <div className="space-y-1.5 text-sm">
            {uniform ? (
              <PriceRow
                label={`${formatMoney(nightly[0].priceCents)} × ${nightsText(r.nights)}${r.roomsCount > 1 ? ` × ${r.roomsCount}` : ''}`}
                value={formatMoney(snapshot.subtotalCents)}
              />
            ) : (
              nightly.map((n) => (
                <PriceRow
                  key={n.date}
                  label={`${formatDateWithDayAr(n.date)}${n.rateName ? ` — ${n.rateName}` : ''}`}
                  value={formatMoney(n.priceCents * r.roomsCount)}
                  muted
                />
              ))
            )}
            <PriceRow label="المجموع الفرعي" value={formatMoney(snapshot.subtotalCents)} />
            <PriceRow label={`الضريبة (${snapshot.subtotalCents > 0 ? Math.round((snapshot.taxCents / snapshot.subtotalCents) * 100) : 0}%)`} value={formatMoney(snapshot.taxCents)} />
            <div className="flex items-center justify-between border-t pt-2">
              <span className="text-base font-black text-foreground">الإجمالي</span>
              <span className="text-xl font-black text-primary dark:text-gold" dir="ltr">
                {formatMoney(snapshot.grandTotalCents)}
              </span>
            </div>
            {r.paidCents > 0 ? (
              <div className="flex items-center justify-between">
                <span className="font-semibold text-success">المدفوع</span>
                <span className="font-bold text-success" dir="ltr">
                  {formatMoney(r.paidCents)}
                </span>
              </div>
            ) : null}
            {remaining > 0 ? (
              <div className="flex items-center justify-between">
                <span className="font-semibold text-warning">المتبقي</span>
                <span className="font-bold text-warning" dir="ltr">
                  {formatMoney(remaining)}
                </span>
              </div>
            ) : null}
          </div>
        </div>
      ) : null}

      {/* سياسة الإلغاء الحالية */}
      {canCancel ? (
        <div className="rounded-xl border border-warning/40 bg-warning/5 p-3 text-xs leading-relaxed text-foreground">
          {cancellation.refundable ? (
            <>
              <span className="font-bold text-success">الإلغاء مجاني الآن</span> — مجانًا حتى{' '}
              {formatDateTimeAr(cancellation.freeUntil)}.
            </>
          ) : (
            <>
              <span className="font-bold text-warning">الإلغاء برسوم</span> — تجاوزت مهل الإلغاء المجاني، وتترتب
              عليه رسوم ليلة واحدة <span className="font-black" dir="ltr">{formatMoney(cancellation.penaltyCents)}</span>.
            </>
          )}
        </div>
      ) : null}

      {/* الأزرار */}
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
        {canCancel ? (
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" disabled={cancelling}>
                {cancelling ? <Loader2 className="size-4 animate-spin" /> : <Ban className="size-4" />}
                إلغاء الحجز
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>تأكيد إلغاء الحجز {r.bookingReference}؟</AlertDialogTitle>
                <AlertDialogDescription asChild>
                  <div className="space-y-2 leading-relaxed">
                    {cancellation.refundable ? (
                      <p>
                        الإلغاء <span className="font-bold text-success">مجاني</span> — أنت ضمن المهلة المسموحة (حتى{' '}
                        {formatDateTimeAr(cancellation.freeUntil)}).
                      </p>
                    ) : (
                      <p>
                        سيتم تطبيق <span className="font-bold text-destructive">رسوم إلغاء ليلة واحدة</span> بقيمة{' '}
                        <span className="font-black" dir="ltr">{formatMoney(cancellation.penaltyCents)}</span> وفق سياسة
                        الفندق.
                      </p>
                    )}
                    <p className="text-xs text-muted-foreground">
                      نظام تجريبي — لا تتم أي عملية استرداد مالية فعلية.
                    </p>
                  </div>
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>تراجع</AlertDialogCancel>
                <AlertDialogAction
                  onClick={(e) => {
                    // منع الإغلاق التلقائي حتى تكتمل العملية
                    e.preventDefault()
                    onCancel()
                  }}
                  className="bg-destructive text-white hover:bg-destructive/90"
                >
                  تأكيد الإلغاء
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        ) : null}

        <Button variant="outline" onClick={onPrint}>
          <Printer className="size-4" />
          طباعة التأكيد
        </Button>

        {hotel?.whatsapp ? (
          <Button variant="outline" asChild>
            <a
              href={waLink(hotel.whatsapp, `استفسار عن الحجز ${r.bookingReference}`)}
              target="_blank"
              rel="noopener noreferrer"
            >
              <MessageCircle className="size-4" />
              واتساب
            </a>
          </Button>
        ) : null}
      </div>
    </div>
  )
}

function DetailRow({
  icon: Icon,
  label,
  value,
  ltr,
}: {
  icon: typeof User
  label: string
  value: string
  ltr?: boolean
}) {
  return (
    <div className="flex items-baseline gap-2">
      <Icon className="size-4 shrink-0 translate-y-0.5 text-primary dark:text-gold" />
      <span className="w-16 shrink-0 text-xs font-bold text-muted-foreground">{label}</span>
      <span className="min-w-0 font-bold text-foreground" dir={ltr ? 'ltr' : undefined}>
        {value}
      </span>
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

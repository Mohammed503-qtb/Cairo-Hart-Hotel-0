'use client'

// ─────────────────────────────────────────────────────────────
// PRINT CONFIRMATION — مستند تأكيد رسمي قابل للطباعة
// يُعرض داخل نافذة معاينة، والنسخة المطبوعة عبر .print-area
// ─────────────────────────────────────────────────────────────
import { Printer } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { formatMoney, formatDateAr, formatDateWithDayAr, formatDateTimeAr } from '@/lib/format'
import type { HotelPublic, ReservationPublic } from '@/types'
import {
  reservationStatusBadge,
  paymentStatusBadge,
  formatClockAr,
  guestsText,
  nightsText,
  roomsText,
  type SnapshotBreakdown,
  type PrintData,
} from './helpers'

/** المستند الرسمي — ألوان صريحة محايدة لضمان صحة الطباعة في الوضعين */
export function PrintConfirmationDocument({
  hotel,
  reservation,
  snapshot,
}: {
  hotel: HotelPublic | null
  reservation: ReservationPublic
  snapshot: SnapshotBreakdown | null
}) {
  const nightly = snapshot?.nightly ?? []
  const uniform = nightly.length > 0 && nightly.every((n) => n.priceCents === nightly[0].priceCents)
  const paid = reservation.paidCents
  const remaining = Math.max(0, reservation.grandTotalCents - paid)

  return (
    <div className="print-area bg-white p-8 text-black" dir="rtl">
      {/* الترويسة */}
      <div className="flex items-start justify-between border-b-2 border-black/70 pb-4">
        <div className="flex items-center gap-3">
          <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="h-14 w-14" />
          <div>
            <div className="text-2xl font-black text-black">{hotel?.name ?? 'فندق قلب القاهرة'}</div>
            <div className="text-sm text-black/60">{hotel?.tagline}</div>
            <div className="mt-1 text-xs text-black/60">
              {hotel?.address}، {hotel?.city} — <span dir="ltr">{hotel?.phone}</span>
            </div>
          </div>
        </div>
        <div className="text-left">
          <div className="text-lg font-black">تأكيد حجز</div>
          <div className="text-xs text-black/60">Booking Confirmation</div>
        </div>
      </div>

      {/* رقم الحجز */}
      <div className="mt-5 flex items-center justify-between rounded-lg border-2 border-black/20 bg-black/[0.03] px-4 py-3">
        <span className="text-sm font-bold text-black/70">رقم الحجز</span>
        <span className="font-mono text-2xl font-black tracking-wider" dir="ltr">
          {reservation.bookingReference}
        </span>
      </div>

      <div className="mt-2 flex items-center justify-between px-1 text-xs text-black/60">
        <span>
          الحالة:{' '}
          <span className={`font-bold ${reservation.status === 'CANCELLED' ? 'text-red-700' : 'text-green-700'}`}>
            {reservationStatusBadge(reservation.status).label}
          </span>
        </span>
        <span>تاريخ الإصدار: {formatDateTimeAr(reservation.createdAt)}</span>
      </div>

      {/* بيانات الضيف والإقامة */}
      <div className="mt-5 grid grid-cols-2 gap-x-8 gap-y-3">
        <InfoRow label="اسم الضيف" value={reservation.guest.fullName} />
        <InfoRow label="نوع الغرفة" value={reservation.roomType.name} />
        <InfoRow label="رقم الهاتف" value={reservation.guest.phone} ltr />
        <InfoRow label="عدد الغرف" value={roomsText(reservation.roomsCount)} />
        <InfoRow
          label="تاريخ الوصول"
          value={`${formatDateWithDayAr(reservation.checkIn)} — ${formatClockAr(snapshot?.checkInTime ?? hotel?.checkInTime)}`}
        />
        <InfoRow
          label="تاريخ المغادرة"
          value={`${formatDateWithDayAr(reservation.checkOut)} — ${formatClockAr(snapshot?.checkOutTime ?? hotel?.checkOutTime)}`}
        />
        <InfoRow label="مدة الإقامة" value={nightsText(reservation.nights)} />
        <InfoRow label="الضيوف" value={guestsText(reservation.adults, reservation.children)} />
      </div>

      {reservation.specialRequests ? (
        <div className="mt-3 rounded-md bg-black/[0.03] px-3 py-2 text-xs">
          <span className="font-bold">طلبات خاصة: </span>
          <span className="text-black/70">{reservation.specialRequests}</span>
        </div>
      ) : null}

      {/* تفصيل الأسعار */}
      <h3 className="mt-6 border-b border-black/30 pb-1 text-sm font-black">تفصيل الأسعار</h3>
      <table className="mt-2 w-full text-sm">
        <tbody>
          {uniform ? (
            <tr className="border-b border-black/10">
              <td className="py-1.5 text-black/70">
                {formatMoney(nightly[0].priceCents)} × {nightsText(reservation.nights)}
                {reservation.roomsCount > 1 ? ` × ${roomsText(reservation.roomsCount)}` : ''}
              </td>
              <td className="py-1.5 text-left font-semibold" dir="ltr">
                {formatMoney(reservation.subtotalCents)}
              </td>
            </tr>
          ) : (
            nightly.map((n) => (
              <tr key={n.date} className="border-b border-black/10">
                <td className="py-1.5 text-black/70">
                  {formatDateAr(n.date)}
                  {n.rateName ? ` — ${n.rateName}` : ''}
                </td>
                <td className="py-1.5 text-left font-semibold" dir="ltr">
                  {formatMoney(n.priceCents * reservation.roomsCount)}
                </td>
              </tr>
            ))
          )}
          <tr className="border-b border-black/10">
            <td className="py-1.5 text-black/70">المجموع الفرعي</td>
            <td className="py-1.5 text-left font-semibold" dir="ltr">
              {formatMoney(reservation.subtotalCents)}
            </td>
          </tr>
          <tr className="border-b border-black/10">
            <td className="py-1.5 text-black/70">
              الضريبة (
              {reservation.subtotalCents > 0
                ? Math.round((reservation.taxCents / reservation.subtotalCents) * 100)
                : 0}
              %)
            </td>
            <td className="py-1.5 text-left font-semibold" dir="ltr">
              {formatMoney(reservation.taxCents)}
            </td>
          </tr>
          <tr className="border-b-2 border-black/30">
            <td className="py-2 text-base font-black">الإجمالي</td>
            <td className="py-2 text-left text-base font-black" dir="ltr">
              {formatMoney(reservation.grandTotalCents)}
            </td>
          </tr>
          {paid > 0 ? (
            <tr className="border-b border-black/10">
              <td className="py-1.5 text-green-800 font-semibold">المدفوع (عربون إلكتروني)</td>
              <td className="py-1.5 text-left font-semibold text-green-800" dir="ltr">
                {formatMoney(paid)}
              </td>
            </tr>
          ) : null}
          {remaining > 0 ? (
            <tr className="border-b border-black/10">
              <td className="py-1.5 font-semibold text-black/80">المتبقي (يُسدد بالفندق)</td>
              <td className="py-1.5 text-left font-semibold text-black/80" dir="ltr">
                {formatMoney(remaining)}
              </td>
            </tr>
          ) : null}
        </tbody>
      </table>

      {/* السياسات */}
      <div className="mt-5 rounded-md border border-black/20 bg-black/[0.02] p-3">
        <h4 className="text-xs font-black">سياسة الإلغاء</h4>
        <p className="mt-1 text-xs leading-relaxed text-black/70">
          {snapshot?.cancellationPolicy ?? hotel?.cancellationPolicy}
        </p>
      </div>

      <p className="mt-5 text-center text-xs text-black/50">
        شكرًا لاختياركم فندق قلب القاهرة — عدن · هذا المستند يُقدم عند الوصول لتسجيل الدخول
      </p>
    </div>
  )
}

function InfoRow({ label, value, ltr }: { label: string; value: string; ltr?: boolean }) {
  return (
    <div className="flex items-baseline gap-2">
      <span className="w-24 shrink-0 text-xs font-bold text-black/50">{label}</span>
      <span className="text-sm font-semibold text-black" dir={ltr ? 'ltr' : undefined}>
        {value}
      </span>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────

/** نافذة معاينة الطباعة — نسخة للعرض + نسخة مطبوعة مخفية في جذر الصفحة */
export function PrintPreviewDialog({
  open,
  onOpenChange,
  hotel,
  data,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  hotel: HotelPublic | null
  data: PrintData | null
}) {
  return (
    <>
      {/* تحديد موضع المستند عند الطباعة: انسياب طبيعي داخل الصفحة */}
      <style>{`
@media print {
  .website-print-root .print-area {
    position: static !important;
    inset: auto !important;
  }
}
      `}</style>

      {/* النسخة المخفية في جذر الصفحة — تطبع عند window.print */}
      {data && open ? (
        <div className="website-print-root hidden print:block">
          <PrintConfirmationDocument hotel={hotel} reservation={data.reservation} snapshot={data.snapshot} />
        </div>
      ) : null}

      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent aria-describedby={undefined} className="max-h-[92vh] max-w-2xl overflow-y-auto sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">معاينة تأكيد الحجز</DialogTitle>
          </DialogHeader>

          {data ? (
            <>
              {/* نسخة المعاينة (تختفي عند الطباعة) */}
              <div className="print:hidden">
                <PrintConfirmationDocument hotel={hotel} reservation={data.reservation} snapshot={data.snapshot} />
              </div>

              <div className="mt-2 flex flex-col gap-2 print:hidden sm:flex-row-reverse">
                <Button onClick={() => window.print()} className="flex-1">
                  <Printer className="size-4" />
                  طباعة / حفظ PDF
                </Button>
                <Button variant="outline" onClick={() => onOpenChange(false)} className="flex-1">
                  إغلاق
                </Button>
              </div>
            </>
          ) : null}
        </DialogContent>
      </Dialog>
    </>
  )
}

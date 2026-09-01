'use client'

// ─────────────────────────────────────────────────────────────
// GUEST STAY — تبويب إقامتي
// بطاقة الغرفة + خط زمني + بيانات الحجز وجدول الليالي + السياسات + طلباتي
// ─────────────────────────────────────────────────────────────

import { motion } from 'framer-motion'
import {
  ArrowLeftRight,
  BedDouble,
  CalendarDays,
  ConciergeBell,
  DoorOpen,
  Expand,
  Hotel,
  Info,
  Maximize,
  Moon,
  Phone,
  Ruler,
  Sparkles,
  Users,
} from 'lucide-react'
import { useGuest } from './guest-context'
import { DoneMark, EmptyState, RequestStatusBadge, SectionTitle, UrgentMark, pageMotion } from './bits'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion'
import {
  formatDateAr,
  formatDateWithDayAr,
  formatMoney,
  timeAgoAr,
} from '@/lib/format'
import type { SnapshotNight } from './types'

export default function GuestStay() {
  const guest = useGuest()
  const data = guest.stayData

  if (guest.stayLoading && !data) {
    return <StaySkeleton />
  }
  if (!data || !data.hotel) {
    return (
      <EmptyState
        icon={<Hotel className="h-6 w-6" aria-hidden />}
        title="تعذر تحميل تفاصيل الإقامة"
        hint="حدث خطأ في الاتصال — أعد المحاولة"
        action={
          <Button variant="outline" onClick={() => void guest.refreshStay()}>
            إعادة المحاولة
          </Button>
        }
      />
    )
  }

  const { stay, snapshot, hotel } = data
  const image = stay.roomType.images[0] ?? '/images/room-deluxe.png'
  const lastRequests = guest.requests.slice(0, 3)

  return (
    <motion.div {...pageMotion} className="space-y-5">
      {/* ─── بطاقة الغرفة ─── */}
      <section aria-label="غرفة الإقامة">
        <SectionTitle icon={<BedDouble className="h-4.5 w-4.5" />}>غرفتك</SectionTitle>
        <Card className="mt-3 overflow-hidden border-border/70">
          <div className="relative h-44 w-full">
            <img
              src={image}
              alt={`صورة ${stay.roomType.name}`}
              className="h-full w-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" aria-hidden />
            <div className="absolute bottom-3 right-4 left-4 flex items-end justify-between gap-3 text-white">
              <div>
                <p className="text-xs text-white/80">{stay.roomType.name}</p>
                <p className="text-3xl font-extrabold" dir="ltr">
                  {stay.room.number}
                </p>
              </div>
              <Badge className="border-transparent bg-white/20 text-white backdrop-blur">
                الطابق {stay.room.floor}
              </Badge>
            </div>
          </div>
          <CardContent className="space-y-4 p-4">
            <div className="grid grid-cols-2 gap-3">
              <InfoPill icon={<BedDouble className="h-4 w-4" aria-hidden />} label="السرير">
                {stay.roomType.bedConfig}
              </InfoPill>
              <InfoPill icon={<Ruler className="h-4 w-4" aria-hidden />} label="المساحة">
                {stay.roomType.sizeSqm} م²
              </InfoPill>
            </div>
            <div>
              <p className="mb-2 flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
                <Sparkles className="h-3.5 w-3.5 text-gold" aria-hidden />
                مزايا الغرفة
              </p>
              <div className="flex flex-wrap gap-1.5">
                {stay.roomType.amenities.map((a) => (
                  <Badge
                    key={a}
                    variant="secondary"
                    className="rounded-full border-transparent bg-accent text-accent-foreground"
                  >
                    {a}
                  </Badge>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>
      </section>

      {/* ─── الخط الزمني للإقامة ─── */}
      <section aria-label="الخط الزمني للإقامة">
        <SectionTitle icon={<CalendarDays className="h-4.5 w-4.5" />}>خط زمني الإقامة</SectionTitle>
        <Card className="mt-3 border-border/70">
          <CardContent className="p-4">
            <ol className="relative space-y-5 border-r-2 border-border pr-5">
              <TimelineNode
                done
                label="الوصول"
                date={formatDateWithDayAr(stay.checkInAt)}
                icon={<DoorOpen className="h-4 w-4" aria-hidden />}
              />
              <TimelineNode
                current
                label="إقامتك الآن"
                date={`الخروج المتوقع: ${formatDateAr(stay.expectedCheckOutAt)} — حتى ${hotel.checkOutTime}`}
                icon={<Moon className="h-4 w-4" aria-hidden />}
              />
              <TimelineNode
                label="الخروج المتوقع"
                date={`${formatDateWithDayAr(stay.expectedCheckOutAt)} — ${data.remainingNights} ${
                  data.remainingNights === 1 ? 'ليلة متبقية' : 'ليالٍ متبقية'
                }`}
                icon={<ArrowLeftRight className="h-4 w-4" aria-hidden />}
              />
            </ol>
          </CardContent>
        </Card>
      </section>

      {/* ─── بيانات الحجز ─── */}
      <section aria-label="بيانات الحجز">
        <SectionTitle icon={<Info className="h-4.5 w-4.5" />}>بيانات الحجز</SectionTitle>
        <Card className="mt-3 border-border/70">
          <CardContent className="space-y-4 p-4">
            <div className="grid grid-cols-2 gap-3">
              <InfoPill icon={<Hotel className="h-4 w-4" aria-hidden />} label="مرجع الحجز">
                <span dir="ltr" className="font-mono">
                  {stay.reservation.bookingReference}
                </span>
              </InfoPill>
              <InfoPill icon={<Users className="h-4 w-4" aria-hidden />} label="الضيوف">
                {stay.reservation.adults} بالغ
                {stay.reservation.children > 0 ? ` + ${stay.reservation.children} طفل` : ''}
              </InfoPill>
              <InfoPill icon={<Moon className="h-4 w-4" aria-hidden />} label="الليالي">
                {data.nights} {data.nights === 1 ? 'ليلة' : 'ليالٍ'}
              </InfoPill>
              <InfoPill icon={<Expand className="h-4 w-4" aria-hidden />} label="إجمالي الغرفة">
                {formatMoney(stay.reservation.grandTotalCents, stay.reservation.currency)}
              </InfoPill>
            </div>

            {stay.reservation.specialRequests ? (
              <p className="rounded-xl bg-accent/60 p-3 text-xs leading-relaxed text-accent-foreground">
                <span className="font-bold">طلبات خاصة عند الحجز: </span>
                {stay.reservation.specialRequests}
              </p>
            ) : null}

            {/* جدول الليالي من لقطة الحجز */}
            {snapshot && snapshot.nightly.length > 0 ? (
              <div>
                <p className="mb-2 text-xs font-bold text-muted-foreground">
                  تفصيل الليالي (لقطة الحجز)
                </p>
                <div className="overflow-hidden rounded-xl border border-border/70">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-muted/60 text-xs text-muted-foreground">
                        <th scope="col" className="px-3 py-2 text-start font-bold">
                          الليلة
                        </th>
                        <th scope="col" className="px-3 py-2 text-start font-bold">
                          السعر
                        </th>
                        <th scope="col" className="px-3 py-2 text-start font-bold">
                          السعر المعتمد
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {snapshot.nightly.map((n: SnapshotNight) => (
                        <tr key={n.date} className="border-t border-border/60">
                          <td className="px-3 py-2">{formatDateAr(n.date)}</td>
                          <td className="px-3 py-2 font-mono" dir="ltr">
                            {formatMoney(n.priceCents, snapshot.currency)}
                          </td>
                          <td className="px-3 py-2 text-xs text-muted-foreground">{n.rateName}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr className="border-t border-border bg-muted/40">
                        <td className="px-3 py-2 text-xs font-bold">المجموع قبل الضريبة</td>
                        <td className="px-3 py-2 font-mono font-bold" dir="ltr">
                          {formatMoney(snapshot.subtotalCents, snapshot.currency)}
                        </td>
                        <td className="px-3 py-2 text-xs text-muted-foreground">
                          + ضريبة {snapshot.taxPercent}%
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>
            ) : null}
          </CardContent>
        </Card>
      </section>

      {/* ─── معلومات الفندق + السياسات ─── */}
      <section aria-label="معلومات الفندق والسياسات">
        <SectionTitle icon={<Phone className="h-4.5 w-4.5" />}>معلومات الفندق</SectionTitle>
        <Card className="mt-3 border-border/70">
          <CardContent className="space-y-1 p-4 text-sm">
            <p className="font-bold">
              {hotel.name} — {hotel.city}
            </p>
            {hotel.address ? <p className="text-muted-foreground">{hotel.address}</p> : null}
            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
              {hotel.phone ? (
                <a
                  href={`tel:${hotel.phone.replace(/\s/g, '')}`}
                  className="inline-flex items-center gap-1 font-medium text-primary hover:underline"
                  dir="ltr"
                >
                  <Phone className="h-3 w-3" aria-hidden />
                  {hotel.phone}
                </a>
              ) : null}
              <span className="inline-flex items-center gap-1">
                <DoorOpen className="h-3 w-3" aria-hidden />
                الدخول {hotel.checkInTime}
              </span>
              <span className="inline-flex items-center gap-1">
                <Maximize className="h-3 w-3 rotate-45" aria-hidden />
                الخروج {hotel.checkOutTime}
              </span>
            </div>

            <Accordion type="single" collapsible className="mt-3 -mx-2">
              <AccordionItem value="policies" className="border-border/60">
                <AccordionTrigger className="text-sm font-bold py-2.5">
                  سياسات الفندق
                </AccordionTrigger>
                <AccordionContent className="space-y-3 text-xs leading-relaxed text-muted-foreground">
                  <Policy title="الإلغاء" body={hotel.cancellationPolicy} />
                  <Policy title="الدفع" body={hotel.paymentPolicy} />
                  <Policy title="الأطفال" body={hotel.childrenPolicy} />
                  <Policy title="الحيوانات الأليفة" body={hotel.petsPolicy} />
                  <Policy title="التدخين" body={hotel.smokingPolicy} />
                </AccordionContent>
              </AccordionItem>
            </Accordion>
          </CardContent>
        </Card>
      </section>

      {/* ─── طلباتي (آخر 3) ─── */}
      <section aria-label="طلباتي الأخيرة">
        <SectionTitle
          icon={<ConciergeBell className="h-4.5 w-4.5" />}
          action={
            guest.requests.length > 0 ? (
              <button
                onClick={guest.goRequests}
                className="text-xs font-bold text-primary hover:underline"
              >
                كل الطلبات
              </button>
            ) : undefined
          }
        >
          طلباتي
        </SectionTitle>
        <div className="mt-3 space-y-2">
          {guest.requestsLoading && guest.requests.length === 0 ? (
            <>
              <Skeleton className="h-16 rounded-2xl" />
              <Skeleton className="h-16 rounded-2xl" />
            </>
          ) : lastRequests.length === 0 ? (
            <p className="rounded-2xl border border-dashed border-border p-4 text-center text-sm text-muted-foreground">
              لا طلبات بعد — اطلب أي خدمة من تبويب الخدمات
            </p>
          ) : (
            lastRequests.map((r) => (
              <button
                key={r.id}
                onClick={guest.goRequests}
                className="flex w-full items-center justify-between gap-3 rounded-2xl border border-border/70 bg-card p-3.5 text-start shadow-sm transition-colors hover:border-primary/40"
              >
                <div className="min-w-0">
                  <p className="flex items-center gap-2 truncate text-sm font-bold">
                    {r.title}
                    {r.priority === 'URGENT' && <UrgentMark />}
                  </p>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {r.reference} — {timeAgoAr(r.createdAt)}
                  </p>
                </div>
                <RequestStatusBadge status={r.status} />
              </button>
            ))
          )}
        </div>
      </section>
    </motion.div>
  )
}

function InfoPill({
  icon,
  label,
  children,
}: {
  icon: React.ReactNode
  label: string
  children: React.ReactNode
}) {
  return (
    <div className="rounded-xl bg-muted/50 p-3">
      <p className="flex items-center gap-1.5 text-[11px] font-medium text-muted-foreground">
        {icon}
        {label}
      </p>
      <p className="mt-1 truncate text-sm font-bold text-foreground">{children}</p>
    </div>
  )
}

function TimelineNode({
  done,
  current,
  label,
  date,
  icon,
}: {
  done?: boolean
  current?: boolean
  label: string
  date: string
  icon: React.ReactNode
}) {
  return (
    <li className="relative">
      <span
        className={`absolute -right-[1.6875rem] top-0.5 flex h-5.5 w-5.5 items-center justify-center rounded-full ${
          done
            ? 'bg-success/15 text-success'
            : current
              ? 'bg-primary text-primary-foreground shadow-md'
              : 'bg-muted text-muted-foreground'
        }`}
        aria-hidden
      >
        {done ? <DoneMark className="h-3.5 w-3.5" /> : icon}
      </span>
      <p className="flex items-center gap-2 text-sm font-bold">
        {label}
        {current ? (
          <span className="inline-flex items-center gap-1 rounded-full bg-accent px-2 py-0.5 text-[10px] font-bold text-accent-foreground">
            الآن
          </span>
        ) : null}
      </p>
      <p className="mt-0.5 text-xs text-muted-foreground">{date}</p>
    </li>
  )
}

function Policy({ title, body }: { title: string; body: string }) {
  if (!body) return null
  return (
    <div>
      <p className="mb-1 text-sm font-bold text-foreground">{title}</p>
      <p>{body}</p>
    </div>
  )
}

function StaySkeleton() {
  return (
    <div className="space-y-5" aria-busy="true" aria-label="جارٍ تحميل الإقامة">
      <Skeleton className="h-64 w-full rounded-2xl" />
      <Skeleton className="h-36 w-full rounded-2xl" />
      <Skeleton className="h-48 w-full rounded-2xl" />
    </div>
  )
}

'use client'

// ─────────────────────────────────────────────────────────────
// ROOMS SECTION — شبكة بطاقات الغرف + نافذة التفاصيل
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { BedDouble, Users, Maximize, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Separator } from '@/components/ui/separator'
import { Skeleton } from '@/components/ui/skeleton'
import { formatMoney } from '@/lib/format'
import type { HotelPublic, RoomTypePublic } from '@/types'
import { SectionHeading, miniCapacity } from './helpers'

export function RoomsSection({
  hotel,
  roomTypes,
  loading,
  onBook,
}: {
  hotel: HotelPublic | null
  roomTypes: RoomTypePublic[]
  loading: boolean
  onBook: (roomTypeId: string) => void
}) {
  return (
    <section id="rooms" className="scroll-mt-20 bg-muted/40 py-16 sm:py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <SectionHeading
          kicker="الإقامة"
          title="غرف وأجنحة تناسب كل مسافر"
          subtitle="أسعار شفافة تشمل كل التجهيزات — الضريبة ورسوم نهاية الأسبوع تحسب عند الحجز"
        />

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {loading
            ? [1, 2, 3, 4].map((i) => (
                <Card key={i} className="overflow-hidden">
                  <Skeleton className="h-48 w-full rounded-none" />
                  <CardContent className="space-y-3 p-4">
                    <Skeleton className="h-5 w-32" />
                    <Skeleton className="h-4 w-full" />
                    <Skeleton className="h-4 w-2/3" />
                    <Skeleton className="h-8 w-24" />
                  </CardContent>
                </Card>
              ))
            : roomTypes.map((rt) => (
                <RoomCard key={rt.id} roomType={rt} hotel={hotel} onBook={onBook} />
              ))}
        </div>
      </div>
    </section>
  )
}

function RoomCard({
  roomType,
  hotel,
  onBook,
}: {
  roomType: RoomTypePublic
  hotel: HotelPublic | null
  onBook: (roomTypeId: string) => void
}) {
  const [detailsOpen, setDetailsOpen] = useState(false)
  const image = roomType.images[0] ?? '/images/room-double.png'
  const amenities = roomType.amenities
  const shown = amenities.slice(0, 4)
  const extra = amenities.length - shown.length

  return (
    <Card className="group flex flex-col overflow-hidden transition-all duration-300 hover:-translate-y-1.5 hover:shadow-xl">
      <div className="relative h-48 overflow-hidden">
        <img
          src={image}
          alt={`صورة ${roomType.name} — ${roomType.nameEn}`}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
          loading="lazy"
        />
      </div>

      <CardContent className="flex flex-1 flex-col gap-3 p-4">
        <div>
          <h3 className="text-lg font-extrabold text-foreground">{roomType.name}</h3>
          <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{roomType.description}</p>
        </div>

        <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-sm text-muted-foreground">
          <span className="inline-flex items-center gap-1.5">
            <Users className="size-4 text-primary dark:text-gold" />
            {miniCapacity(roomType.capacityAdults, roomType.capacityChildren)}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <BedDouble className="size-4 text-primary dark:text-gold" />
            {roomType.bedConfig}
          </span>
          {roomType.sizeSqm > 0 ? (
            <span className="inline-flex items-center gap-1.5" dir="rtl">
              <Maximize className="size-4 text-primary dark:text-gold" />
              {roomType.sizeSqm} م²
            </span>
          ) : null}
        </div>

        <div className="flex flex-wrap gap-1.5">
          {shown.map((a) => (
            <Badge key={a} variant="secondary" className="text-[11px] font-semibold">
              {a}
            </Badge>
          ))}
          {extra > 0 ? (
            <Badge variant="outline" className="text-[11px] font-semibold">
              +{extra}
            </Badge>
          ) : null}
        </div>

        <div className="mt-auto flex items-baseline gap-1.5 pt-2">
          <span className="text-2xl font-black text-primary dark:text-gold" dir="ltr">
            {formatMoney(roomType.basePriceCents)}
          </span>
          <span className="text-sm text-muted-foreground">/ ليلة — يبدأ من</span>
        </div>
      </CardContent>

      <CardFooter className="flex gap-2 p-4 pt-0">
        <RoomDetailsDialog
          roomType={roomType}
          hotel={hotel}
          open={detailsOpen}
          onOpenChange={setDetailsOpen}
          onBook={(id) => {
            setDetailsOpen(false)
            onBook(id)
          }}
        />
        <Button className="flex-1" onClick={() => onBook(roomType.id)}>
          احجز الآن
        </Button>
      </CardFooter>
    </Card>
  )
}

function RoomDetailsDialog({
  roomType,
  hotel,
  open,
  onOpenChange,
  onBook,
}: {
  roomType: RoomTypePublic
  hotel: HotelPublic | null
  open: boolean
  onOpenChange: (open: boolean) => void
  onBook: (roomTypeId: string) => void
}) {
  const images = roomType.images.length > 0 ? roomType.images : ['/images/room-double.png']

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <Button variant="outline" className="flex-1" asChild>
        <DialogTrigger className="w-full">التفاصيل</DialogTrigger>
      </Button>
      <DialogContent aria-describedby={undefined} className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle className="text-xl font-extrabold">{roomType.name}</DialogTitle>
        </DialogHeader>

        {/* معرض صور النوع */}
        <div className={images.length > 1 ? 'grid grid-cols-2 gap-2' : ''}>
          {images.map((src, i) => (
            <img
              key={src + i}
              src={src}
              alt={`${roomType.name} — صورة ${i + 1}`}
              className={`w-full rounded-lg object-cover ${images.length > 1 ? 'h-40' : 'h-56'}`}
            />
          ))}
        </div>

        <p className="text-sm leading-relaxed text-muted-foreground">{roomType.description}</p>

        <div className="grid grid-cols-1 gap-2 text-sm sm:grid-cols-2">
          <div className="flex items-center gap-2 text-foreground">
            <Users className="size-4 text-primary dark:text-gold" />
            السعة: {miniCapacity(roomType.capacityAdults, roomType.capacityChildren)}
          </div>
          <div className="flex items-center gap-2 text-foreground">
            <BedDouble className="size-4 text-primary dark:text-gold" />
            {roomType.bedConfig}
          </div>
          {roomType.sizeSqm > 0 ? (
            <div className="flex items-center gap-2 text-foreground" dir="rtl">
              <Maximize className="size-4 text-primary dark:text-gold" />
              المساحة: {roomType.sizeSqm} م²
            </div>
          ) : null}
          <div className="flex items-baseline gap-1.5 text-foreground">
            <span className="text-lg font-black text-primary dark:text-gold" dir="ltr">
              {formatMoney(roomType.basePriceCents)}
            </span>
            <span className="text-xs text-muted-foreground">يبدأ من / ليلة</span>
          </div>
        </div>

        <Separator />

        <div>
          <h4 className="mb-2 text-sm font-bold text-foreground">المزايا</h4>
          <ul className="grid grid-cols-1 gap-1.5 sm:grid-cols-2">
            {roomType.amenities.map((a) => (
              <li key={a} className="flex items-center gap-2 text-sm text-muted-foreground">
                <Check className="size-4 shrink-0 text-success" />
                {a}
              </li>
            ))}
          </ul>
        </div>

        <Separator />

        <div className="rounded-lg border bg-muted/50 p-3">
          <h4 className="mb-1 text-sm font-bold text-foreground">سياسة الإلغاء</h4>
          <p className="text-sm leading-relaxed text-muted-foreground">
            {hotel?.cancellationPolicy ?? 'الإلغاء مجاني حتى 24 ساعة قبل موعد الوصول.'}
          </p>
        </div>

        <Button
          size="lg"
          onClick={() => onBook(roomType.id)}
          className="w-full"
        >
          احجز هذه الغرفة
        </Button>
      </DialogContent>
    </Dialog>
  )
}

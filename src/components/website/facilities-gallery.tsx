'use client'

// ─────────────────────────────────────────────────────────────
// FACILITIES + GALLERY — قسم المرافق + المعرض مع Lightbox
// ─────────────────────────────────────────────────────────────
import { useCallback, useEffect, useMemo, useState, Fragment } from 'react'
import { Wifi, SquareParking, Shirt, Clock, Tv, ShieldCheck, ChevronRight, ChevronLeft } from 'lucide-react'
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import type { RoomTypePublic } from '@/types'
import { SectionHeading, Reveal } from './helpers'

const FACILITY_CARDS = [
  {
    src: '/images/facility-lobby.png',
    title: 'الاستقبال واللوبي',
    text: 'لوبي فخم بلمسة عربية أصيلة وخدمة استقبال على مدار الساعة لراحتكم منذ لحظة الوصول.',
  },
  {
    src: '/images/facility-restaurant.png',
    title: 'المطعم',
    text: 'مطعم يقدم أشهى الأطباق المحنية والعالمية بإشراف طهاة محترفين على مدار اليوم.',
  },
  {
    src: '/images/facility-terrace.png',
    title: 'التراس المقصف',
    text: 'تراس مقصف بإطلالة ساحرة على المدينة — قهوتكم الصباحية ومساءاتكم الهادئة.',
  },
  {
    src: '/images/facility-gym.png',
    title: 'النادي الرياضي',
    text: 'نادٍ رياضي مجهز بأحدث الأجهزة للاحتفاظ بنشاطكم خلال الإقامة.',
  },
]

const AMENITY_ICONS = [
  { icon: Wifi, label: 'واي فاي مجاني' },
  { icon: SquareParking, label: 'موقف سيارات' },
  { icon: Shirt, label: 'غسيل ملابس' },
  { icon: Clock, label: 'استقبال 24 ساعة' },
  { icon: Tv, label: 'تلفاز ذكي' },
  { icon: ShieldCheck, label: 'خزنة إلكترونية' },
]

export function FacilitiesSection() {
  return (
    <section id="facilities" className="scroll-mt-20 py-16 sm:py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <SectionHeading
          kicker="المرافق"
          title="مرافق صُممت لراحتكم"
          subtitle="كل ما تحتاجونه لإقامة متكاملة تحت سقف واحد"
        />

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {FACILITY_CARDS.map((f, i) => (
            <Reveal key={f.title} delay={i * 0.08}>
              <div className="group overflow-hidden rounded-2xl border bg-card shadow-sm transition-all duration-300 hover:-translate-y-1.5 hover:shadow-xl">
                <div className="h-44 overflow-hidden">
                  <img
                    src={f.src}
                    alt={`${f.title} — فندق قلب القاهرة`}
                    className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                    loading="lazy"
                  />
                </div>
                <div className="p-4">
                  <h3 className="text-base font-extrabold text-foreground">{f.title}</h3>
                  <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{f.text}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        {/* شبكة مزايا نصية */}
        <Reveal delay={0.15} className="mt-10">
          <div className="grid grid-cols-2 gap-3 rounded-2xl border bg-muted/40 p-5 sm:grid-cols-3 lg:grid-cols-6">
            {AMENITY_ICONS.map((a) => (
              <div
                key={a.label}
                className="flex flex-col items-center gap-2 rounded-xl bg-card p-4 text-center shadow-sm"
              >
                <a.icon className="size-6 text-primary dark:text-gold" />
                <span className="text-xs font-bold text-foreground">{a.label}</span>
              </div>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  )
}

// ─────────────────────────────────────────────────────────────

interface GalleryImage {
  src: string
  title: string
}

export function GallerySection({ roomTypes, loading }: { roomTypes: RoomTypePublic[]; loading: boolean }) {
  const [lightbox, setLightbox] = useState<number | null>(null)

  // صور المعرض: ثابتة + صور الغرف من البيانات (مشتقة بدون تأثير)
  const images: GalleryImage[] = useMemo(() => {
    const roomImages = roomTypes.flatMap((rt) => rt.images.map((src) => ({ src, title: rt.name })))
    return [
      { src: '/images/hero-hotel.png', title: 'واجهة الفندق' },
      ...roomImages,
      { src: '/images/facility-lobby.png', title: 'الاستقبال واللوبي' },
      { src: '/images/facility-restaurant.png', title: 'المطعم' },
      { src: '/images/facility-terrace.png', title: 'التراس المقصف' },
      { src: '/images/facility-gym.png', title: 'النادي الرياضي' },
      { src: '/images/gallery-corridor.png', title: 'ممر الغرف' },
    ]
  }, [roomTypes])

  const next = useCallback(() => {
    setLightbox((i) => (i === null ? null : (i + 1) % images.length))
  }, [images.length])

  const prev = useCallback(() => {
    setLightbox((i) => (i === null ? null : (i - 1 + images.length) % images.length))
  }, [images.length])

  // تنقل بلوحة المفاتيح
  useEffect(() => {
    if (lightbox === null) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') prev() // RTL: يسار = التالي
      if (e.key === 'ArrowRight') next()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [lightbox, next, prev])

  const current = lightbox !== null ? images[lightbox] : null

  return (
    <section id="gallery" className="scroll-mt-20 bg-muted/40 py-16 sm:py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <SectionHeading kicker="المعرض" title="لمحة من الفندق" subtitle="تصفح صور الغرف والمرافق" />

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          {loading
            ? Array.from({ length: 10 }).map((_, i) => <Skeleton key={i} className="aspect-square rounded-xl" />)
            : images.map((img, i) => (
                <Reveal key={img.src + i} delay={(i % 5) * 0.05} y={16}>
                  <button
                    type="button"
                    onClick={() => setLightbox(i)}
                    className="group relative block aspect-square w-full overflow-hidden rounded-xl border focus:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    aria-label={`عرض صورة ${img.title} بحجم كبير`}
                  >
                    <img
                      src={img.src}
                      alt={img.title}
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
                      loading="lazy"
                    />
                    <span className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent p-2 text-right text-xs font-bold text-white opacity-0 transition-opacity group-hover:opacity-100">
                      {img.title}
                    </span>
                  </button>
                </Reveal>
              ))}
        </div>
      </div>

      {/* Lightbox */}
      <Dialog open={lightbox !== null} onOpenChange={(o) => !o && setLightbox(null)}>
        <DialogContent aria-describedby={undefined} className="max-h-[92vh] max-w-4xl overflow-hidden p-0 sm:max-w-4xl [&>button]:z-10 [&>button]:rounded-full [&>button]:bg-background/80 [&>button]:p-1">
          <DialogTitle className="sr-only">عارض صور الفندق</DialogTitle>
          {current ? (
            <Fragment>
              <div className="flex max-h-[80vh] items-center justify-center bg-black/90">
                <img
                  src={current.src}
                  alt={current.title}
                  className="max-h-[80vh] w-full object-contain"
                />
              </div>
              <div className="flex items-center justify-between gap-2 bg-background p-3">
                <Button variant="outline" size="icon" onClick={next} aria-label="الصورة التالية">
                  <ChevronRight className="size-5" />
                </Button>
                <div className="text-center">
                  <div className="text-sm font-bold text-foreground">{current.title}</div>
                  <div className="text-xs text-muted-foreground" dir="ltr">
                    {(lightbox ?? 0) + 1} / {images.length}
                  </div>
                </div>
                <Button variant="outline" size="icon" onClick={prev} aria-label="الصورة السابقة">
                  <ChevronLeft className="size-5" />
                </Button>
              </div>
            </Fragment>
          ) : null}
        </DialogContent>
      </Dialog>
    </section>
  )
}

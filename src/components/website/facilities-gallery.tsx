'use client'

// ─────────────────────────────────────────────────────────────
// FACILITIES + GALLERY — قسم المرافق + المعرض مع Lightbox
// المحتوى (البطاقات/المزايا/عناوين المعرض/صوره) من إدارة المحتوى
// صور المعرض المنتقاة تُتبع بصور الغرف تلقائيًا
// ─────────────────────────────────────────────────────────────
import { useCallback, useEffect, useMemo, useState, Fragment } from 'react'
import { ChevronRight, ChevronLeft } from 'lucide-react'
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import type { RoomTypePublic } from '@/types'
import type { FacilitiesContent, GalleryContent } from '@/lib/site-content'
import { ContentIcon } from './content-icons'
import { SectionHeading, Reveal } from './helpers'

export function FacilitiesSection({ content }: { content: FacilitiesContent }) {
  return (
    <section id="facilities" className="scroll-mt-20 py-16 sm:py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <SectionHeading
          kicker={content.kicker}
          title={content.title}
          subtitle={content.subtitle}
        />

        {content.cards.length > 0 ? (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {content.cards.map((f, i) => (
              <Reveal key={f.title + i} delay={i * 0.08}>
                <div className="group overflow-hidden rounded-2xl border bg-card shadow-sm transition-all duration-300 hover:-translate-y-1.5 hover:shadow-xl">
                  <div className="h-44 overflow-hidden">
                    <img
                      src={f.image}
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
        ) : null}

        {/* شبكة مزايا نصية */}
        {content.amenities.length > 0 ? (
          <Reveal delay={0.15} className="mt-10">
            <div className="grid grid-cols-2 gap-3 rounded-2xl border bg-muted/40 p-5 sm:grid-cols-3 lg:grid-cols-6">
              {content.amenities.map((a, i) => (
                <div
                  key={a.label + i}
                  className="flex flex-col items-center gap-2 rounded-xl bg-card p-4 text-center shadow-sm"
                >
                  <ContentIcon name={a.icon} className="size-6 text-primary dark:text-gold" />
                  <span className="text-xs font-bold text-foreground">{a.label}</span>
                </div>
              ))}
            </div>
          </Reveal>
        ) : null}
      </div>
    </section>
  )
}

// ─────────────────────────────────────────────────────────────

interface GalleryImage {
  src: string
  title: string
}

export function GallerySection({
  content,
  roomTypes,
  loading,
}: {
  content: GalleryContent
  roomTypes: RoomTypePublic[]
  loading: boolean
}) {
  const [lightbox, setLightbox] = useState<number | null>(null)

  // صور المعرض: المنتقاة من إدارة المحتوى + صور الغرف من البيانات (مشتقة بدون تأثير)
  const images: GalleryImage[] = useMemo(() => {
    const curated = content.images.map((img) => ({ src: img.src, title: img.title }))
    const roomImages = roomTypes.flatMap((rt) => rt.images.map((src) => ({ src, title: rt.name })))
    return [...curated, ...roomImages]
  }, [content.images, roomTypes])

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
        <SectionHeading
          kicker={content.kicker}
          title={content.title}
          subtitle={content.subtitle}
        />

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          {loading
            ? Array.from({ length: Math.max(10, images.length) }).map((_, i) => (
                <Skeleton key={i} className="aspect-square rounded-xl" />
              ))
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

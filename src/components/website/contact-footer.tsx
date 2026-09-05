'use client'

// ─────────────────────────────────────────────────────────────
// CONTACT + FOOTER — الموقع والتواصل + السياسات + التذييل اللاصق
// ─────────────────────────────────────────────────────────────
import { MapPin, Phone, Mail, MessageCircle, Clock, LogIn, Navigation, FileText, ShieldCheck } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion'
import { Skeleton } from '@/components/ui/skeleton'
import { useAppStore } from '@/lib/store'
import type { HotelPublic } from '@/types'
import { SectionHeading, Reveal, formatClockAr, waLink } from './helpers'
import { PrivacyDialog } from './privacy-dialog'

export function ContactSection({ hotel }: { hotel: HotelPublic | null }) {
  const mapsUrl = hotel
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${hotel.address}، ${hotel.city}، ${hotel.country}`)}`
    : '#'

  const policies = [
    { title: 'سياسة الإلغاء', body: hotel?.cancellationPolicy },
    { title: 'سياسة الدفع', body: hotel?.paymentPolicy },
    { title: 'سياسة الأطفال', body: hotel?.childrenPolicy },
    { title: 'الحيوانات الأليفة', body: hotel?.petsPolicy },
    { title: 'التدخين', body: hotel?.smokingPolicy },
  ].filter((p) => p.body)

  return (
    <section id="contact" className="scroll-mt-20 py-16 sm:py-20">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <SectionHeading
          kicker="الموقع والتواصل"
          title="نحن في قلب عدن — تواصلوا معنا"
          subtitle="يسعدنا خدمتكم في أي وقت"
        />

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* بطاقة المعلومات */}
          <Reveal>
            <Card className="h-full">
              <CardContent className="space-y-5 p-6">
                <h3 className="text-lg font-extrabold text-foreground">معلومات التواصل</h3>

                <ul className="space-y-4 text-sm">
                  <li className="flex items-start gap-3">
                    <MapPin className="mt-0.5 size-5 shrink-0 text-primary dark:text-gold" />
                    <span className="text-foreground">
                      {hotel ? `${hotel.address}، ${hotel.city}، ${hotel.country}` : 'شارع الجمهورية، كريتر، عدن، اليمن'}
                    </span>
                  </li>
                  <li className="flex items-start gap-3">
                    <Phone className="mt-0.5 size-5 shrink-0 text-primary dark:text-gold" />
                    {hotel?.phone ? (
                      <a
                        href={`tel:${hotel.phone.replace(/\s/g, '')}`}
                        className="font-semibold text-foreground underline-offset-4 hover:underline"
                        dir="ltr"
                      >
                        {hotel.phone}
                      </a>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </li>
                  <li className="flex items-start gap-3">
                    <MessageCircle className="mt-0.5 size-5 shrink-0 text-primary dark:text-gold" />
                    {hotel?.whatsapp ? (
                      <a
                        href={waLink(hotel.whatsapp)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-semibold text-foreground underline-offset-4 hover:underline"
                        dir="ltr"
                      >
                        {hotel.whatsapp}
                      </a>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </li>
                  <li className="flex items-start gap-3">
                    <Mail className="mt-0.5 size-5 shrink-0 text-primary dark:text-gold" />
                    {hotel?.email ? (
                      <a
                        href={`mailto:${hotel.email}`}
                        className="font-semibold text-foreground underline-offset-4 hover:underline"
                        dir="ltr"
                      >
                        {hotel.email}
                      </a>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </li>
                  <li className="flex items-start gap-3">
                    <Clock className="mt-0.5 size-5 shrink-0 text-primary dark:text-gold" />
                    <div className="text-foreground">
                      <div>
                        تسجيل الوصول: <span className="font-bold" dir="ltr">{formatClockAr(hotel?.checkInTime)}</span>
                      </div>
                      <div className="mt-1">
                        تسجيل المغادرة: <span className="font-bold" dir="ltr">{formatClockAr(hotel?.checkOutTime)}</span>
                      </div>
                    </div>
                  </li>
                </ul>

                <Button asChild className="w-full">
                  <a href={mapsUrl} target="_blank" rel="noopener noreferrer">
                    <Navigation className="size-4" />
                    الاتجاهات عبر خرائط جوجل
                  </a>
                </Button>
              </CardContent>
            </Card>
          </Reveal>

          {/* السياسات */}
          <Reveal delay={0.1}>
            <Card className="h-full">
              <CardContent className="p-6">
                <h3 className="mb-4 flex items-center gap-2 text-lg font-extrabold text-foreground">
                  <FileText className="size-5 text-primary dark:text-gold" />
                  سياسات الفندق
                </h3>
                <Accordion type="single" collapsible className="w-full">
                  {policies.map((p, i) => (
                    <AccordionItem key={p.title} value={`policy-${i}`}>
                      <AccordionTrigger className="text-sm font-bold text-foreground">
                        {p.title}
                      </AccordionTrigger>
                      <AccordionContent className="text-sm leading-relaxed text-muted-foreground">
                        {p.body}
                      </AccordionContent>
                    </AccordionItem>
                  ))}
                  <AccordionItem value="policy-privacy">
                    <PrivacyDialog>
                      <button
                        type="button"
                        className="group flex w-full items-center justify-between py-3 text-sm font-bold text-foreground transition-colors"
                        aria-label="عرض سياسة الخصوصية كاملة"
                      >
                        <span className="flex items-center gap-2">
                          <ShieldCheck className="size-4 text-primary dark:text-gold" />
                          سياسة الخصوصية
                        </span>
                        <span className="text-muted-foreground transition-transform group-hover:translate-x-1" aria-hidden>
                          ←
                        </span>
                      </button>
                    </PrivacyDialog>
                  </AccordionItem>
                </Accordion>
              </CardContent>
            </Card>
          </Reveal>
        </div>
      </div>
    </section>
  )
}

// ─────────────────────────────────────────────────────────────

const QUICK_LINKS = [
  { href: '#home', label: 'الرئيسية' },
  { href: '#rooms', label: 'الغرف والأجنحة' },
  { href: '#facilities', label: 'المرافق' },
  { href: '#gallery', label: 'المعرض' },
  { href: '#contact', label: 'الموقع والتواصل' },
]

export function SiteFooter({
  hotel,
  loading,
  onManage,
}: {
  hotel: HotelPublic | null
  loading: boolean
  onManage: () => void
}) {
  const setMode = useAppStore((s) => s.setMode)

  return (
    <footer className="mt-auto bg-[#0C1320] pb-[env(safe-area-inset-bottom)] pt-12 text-white/80">
      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-8 px-4 sm:grid-cols-2 sm:px-6 lg:grid-cols-4">
        {/* معلومات الفندق */}
        <div>
          <div className="flex items-center gap-2.5">
            <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="h-10 w-10" />
            <div>
              <div className="text-base font-extrabold text-white">فندق قلب القاهرة</div>
              <div className="text-xs text-gold">{hotel?.tagline ?? 'ضيافة راقية في قلب عدن'}</div>
            </div>
          </div>
          {loading ? (
            <Skeleton className="mt-4 h-4 w-40 bg-white/10" />
          ) : (
            <p className="mt-4 text-sm leading-relaxed">
              {hotel?.address ?? 'شارع الجمهورية، كريتر'}، {hotel?.city ?? 'عدن'}، {hotel?.country ?? 'اليمن'}
            </p>
          )}
          {hotel?.phone ? (
            <p className="mt-2 text-sm" dir="ltr">
              {hotel.phone}
            </p>
          ) : null}
        </div>

        {/* روابط سريعة */}
        <div>
          <h4 className="mb-4 text-sm font-bold uppercase tracking-wide text-white">روابط سريعة</h4>
          <ul className="space-y-2 text-sm">
            {QUICK_LINKS.map((l) => (
              <li key={l.href}>
                <a href={l.href} className="transition-colors hover:text-gold">
                  {l.label}
                </a>
              </li>
            ))}
            <li>
              <button type="button" onClick={onManage} className="transition-colors hover:text-gold">
                إدارة حجزك
              </button>
            </li>
          </ul>
        </div>

        {/* السياسات */}
        <div>
          <h4 className="mb-4 text-sm font-bold uppercase tracking-wide text-white">السياسات</h4>
          <ul className="space-y-2 text-sm">
            <li>
              <a href="#contact" className="transition-colors hover:text-gold">
                سياسة الإلغاء
              </a>
            </li>
            <li>
              <a href="#contact" className="transition-colors hover:text-gold">
                سياسة الدفع
              </a>
            </li>
            <li>
              <a href="#contact" className="transition-colors hover:text-gold">
                سياسة الأطفال
              </a>
            </li>
            <li>
              <PrivacyDialog>
                <button type="button" className="text-right transition-colors hover:text-gold">
                  سياسة الخصوصية
                </button>
              </PrivacyDialog>
            </li>
            <li>
              <span className="cursor-default">
                تسجيل الوصول <span dir="ltr">{formatClockAr(hotel?.checkInTime)}</span> — المغادرة{' '}
                <span dir="ltr">{formatClockAr(hotel?.checkOutTime)}</span>
              </span>
            </li>
          </ul>
        </div>

        {/* التواصل */}
        <div>
          <h4 className="mb-4 text-sm font-bold uppercase tracking-wide text-white">تواصل معنا</h4>
          <ul className="space-y-2 text-sm">
            {hotel?.phone ? (
              <li dir="ltr" className="text-right">
                {hotel.phone}
              </li>
            ) : null}
            {hotel?.email ? (
              <li dir="ltr" className="text-right">
                {hotel.email}
              </li>
            ) : null}
            {hotel?.whatsapp ? (
              <li>
                <a
                  href={waLink(hotel.whatsapp)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 transition-colors hover:text-gold"
                >
                  <MessageCircle className="size-4" />
                  واتساب مباشر
                </a>
              </li>
            ) : null}
          </ul>
        </div>
      </div>

      <div className="mx-auto mt-10 flex max-w-7xl flex-col items-center gap-3 border-t border-white/10 px-4 py-6 text-center sm:flex-row sm:justify-between sm:px-6 sm:text-right">
        <p className="text-xs">
          © {new Date().getFullYear()} فندق قلب القاهرة — جميع الحقوق محفوظة
        </p>
        <button
          type="button"
          onClick={() => setMode('login')}
          className="inline-flex items-center gap-1.5 rounded-full border border-white/20 px-4 py-1.5 text-xs font-bold text-white/85 transition-colors hover:border-gold/60 hover:text-gold"
        >
          <LogIn className="size-3.5" />
          منصة إدارة الإقامة — دخول التطبيق
        </button>
      </div>
    </footer>
  )
}

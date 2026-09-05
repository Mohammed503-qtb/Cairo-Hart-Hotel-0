'use client'

// ─────────────────────────────────────────────────────────────
// HERO SECTION — الواجهة الرئيسية + شريط الثقة
// المحتوى (الصورة/الشارة/العنوان/الأزرار/الثقة) من إدارة المحتوى
// القيم الفارغة تُسقط لاسم الفندق وشعاره التسويقي
// ─────────────────────────────────────────────────────────────
import { motion } from 'framer-motion'
import { MessageCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import type { HotelPublic } from '@/types'
import type { HeroContent } from '@/lib/site-content'
import { ContentIcon } from './content-icons'
import { SearchWidget } from './search-widget'
import { waLink, type SearchParams } from './helpers'

export function HeroSection({
  hotel,
  content,
  loading,
  search,
  onSearchChange,
  onSearch,
  searchError,
}: {
  hotel: HotelPublic | null
  content: HeroContent
  loading: boolean
  search: SearchParams
  onSearchChange: (v: SearchParams) => void
  onSearch: () => void
  searchError: string | null
}) {
  const image = content.image || '/images/hero-hotel.png'
  const title = content.title || hotel?.name || 'فندق قلب القاهرة'
  const tagline = content.tagline || hotel?.tagline || ''

  return (
    <section id="home" className="relative scroll-mt-20">
      {/* صورة الهيرو */}
      <div className="relative h-[70vh] min-h-[480px] w-full overflow-hidden">
        <img
          src={image}
          alt={`${title} — الواجهة الرئيسية`}
          className="absolute inset-0 h-full w-full object-cover"
        />
        {/* تدرج كحلي داكن */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#0C1320]/95 via-[#0C1320]/55 to-[#0C1320]/25" />

        {/* المحتوى */}
        <div className="relative z-10 mx-auto flex h-full max-w-7xl flex-col justify-center px-4 pb-40 sm:px-6 sm:pb-44">
          {content.badge ? (
            <motion.span
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mb-4 inline-flex w-fit items-center gap-2 rounded-full border border-gold/50 bg-[#0C1320]/60 px-4 py-1.5 text-sm font-bold text-gold backdrop-blur-sm"
            >
              {content.badge}
            </motion.span>
          ) : null}

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="max-w-3xl text-4xl font-black leading-tight text-white drop-shadow-md sm:text-5xl lg:text-6xl"
          >
            {loading ? 'فندق قلب القاهرة' : title}
          </motion.h1>

          {tagline ? (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.3 }}
              className="mt-4 max-w-xl text-lg text-white/85 sm:text-xl"
            >
              {loading ? <Skeleton className="h-6 w-64 bg-white/15" /> : tagline}
            </motion.div>
          ) : null}

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.4 }}
            className="mt-8 flex flex-wrap items-center gap-3"
          >
            <Button size="lg" onClick={onSearch} className="h-12 px-7 text-base">
              {content.checkAvailabilityLabel}
            </Button>
            {hotel?.whatsapp ? (
              <Button
                size="lg"
                variant="outline"
                asChild
                className="h-12 border-white/40 bg-white/10 px-7 text-base text-white hover:bg-white/20 hover:text-white"
              >
                <a href={waLink(hotel.whatsapp)} target="_blank" rel="noopener noreferrer">
                  <MessageCircle className="size-4.5" />
                  {content.whatsappLabel}
                </a>
              </Button>
            ) : null}
          </motion.div>
        </div>
      </div>

      {/* ودجت البحث — بطاقة زجاجية ملاصقة أسفل الهيرو */}
      <div className="relative z-20 mx-auto -mt-24 max-w-5xl px-4 sm:-mt-28 sm:px-6">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.5 }}
        >
          <SearchWidget value={search} onChange={onSearchChange} onSubmit={onSearch} error={searchError} />
        </motion.div>
      </div>

      {/* شريط الثقة */}
      {content.trustItems.length > 0 ? (
        <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {content.trustItems.map((item, i) => (
              <motion.div
                key={item.title + i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-40px' }}
                transition={{ duration: 0.5, delay: i * 0.08 }}
                className="flex items-center gap-4 rounded-xl border bg-card p-4 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"
              >
                <div className="flex size-11 shrink-0 items-center justify-center rounded-full bg-accent text-primary dark:text-gold">
                  <ContentIcon name={item.icon} className="size-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-foreground">{item.title}</div>
                  <div className="text-xs text-muted-foreground">{item.text}</div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      ) : null}
    </section>
  )
}

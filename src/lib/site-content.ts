// ─────────────────────────────────────────────────────────────
// SITE CONTENT — عقد محتوى الموقع القابل للإدارة من لوحة الإدارة
// مصدر الحقيقة: جدول site_content (قيمة JSON لكل قسم) — كل قسم
// يُدمج فوق DEFAULT_CONTENT عند القراءة، فلا يحتاج seed.
// هذا الملف مشترك بين الخادم والعميل (بلا React) — الأيقونات
// تُحوَّل لمكونات في components/website/content-icons.tsx
// ─────────────────────────────────────────────────────────────

// ── الأنواع ──

export type SiteSectionKey =
  | 'header' | 'hero' | 'rooms' | 'facilities' | 'gallery' | 'contact' | 'footer'

export const SITE_SECTION_KEYS: SiteSectionKey[] = [
  'header', 'hero', 'rooms', 'facilities', 'gallery', 'contact', 'footer',
]

export const SITE_SECTION_LABELS: Record<SiteSectionKey, string> = {
  header: 'الترويسة',
  hero: 'الهيرو الرئيسي',
  rooms: 'قسم الغرف',
  facilities: 'قسم المرافق',
  gallery: 'المعرض',
  contact: 'الموقع والتواصل',
  footer: 'التذييل',
}

/** أيقونات مسموحة (مفاتيح lucide — التحويل في content-icons.tsx) */
export type IconKey =
  | 'bed' | 'clock' | 'calendar' | 'wifi' | 'message' | 'parking' | 'laundry'
  | 'tv' | 'safe' | 'star' | 'pool' | 'gym' | 'restaurant' | 'coffee'
  | 'map-pin' | 'phone' | 'mail' | 'sparkles' | 'concierge' | 'luggage'
  | 'car' | 'wind' | 'bell' | 'bath' | 'view' | 'users'

export const ICON_KEYS: IconKey[] = [
  'bed', 'clock', 'calendar', 'wifi', 'message', 'parking', 'laundry',
  'tv', 'safe', 'star', 'pool', 'gym', 'restaurant', 'coffee',
  'map-pin', 'phone', 'mail', 'sparkles', 'concierge', 'luggage',
  'car', 'wind', 'bell', 'bath', 'view', 'users',
]

export const ICON_LABELS: Record<IconKey, string> = {
  bed: 'سرير', clock: 'ساعة / 24 ساعة', calendar: 'تقويم', wifi: 'واي فاي',
  message: 'محادثة', parking: 'موقف سيارات', laundry: 'غسيل', tv: 'تلفاز',
  safe: 'خزنة', star: 'نجمة', pool: 'مسبح', gym: 'نادي رياضي',
  restaurant: 'مطعم', coffee: 'قهوة', 'map-pin': 'موقع', phone: 'هاتف',
  mail: 'بريد', sparkles: 'لمعان', concierge: 'خدمة كونسيرج', luggage: 'أمتعة',
  car: 'سيارة', wind: 'تهوية', bell: 'جرس', bath: 'حمام', view: 'إطلالة', users: 'أشخاص',
}

export interface NavLink { href: string; label: string }
export interface TrustItem { icon: IconKey; title: string; text: string }
export interface FacilityCard { image: string; title: string; text: string }
export interface AmenityItem { icon: IconKey; label: string }
export interface GalleryImage { src: string; title: string }

/** الترويسة — الشعار والاسم والتنقل وأزرار الدخول */
export interface HeaderContent {
  logoUrl: string
  siteName: string // فارغ = اسم الفندق من بياناته
  siteTagline: string // فارغ = الشعار التسويقي للفندق
  navLinks: NavLink[]
  bookButtonLabel: string
  manageButtonLabel: string
}

/** الهيرو — الصورة الكبيرة والشارة والعنوان وشريط الثقة */
export interface HeroContent {
  image: string
  badge: string
  title: string // فارغ = اسم الفندق
  tagline: string // فارغ = الشعار التسويقي للفندق
  checkAvailabilityLabel: string
  whatsappLabel: string
  trustItems: TrustItem[]
}

/** عناوين قسم الغرف (بطاقات الغرف نفسها تُدار من أنواع الغرف) */
export interface RoomsContent {
  kicker: string
  title: string
  subtitle: string
}

/** المرافق — بطاقات الصور + شبكة المزايا */
export interface FacilitiesContent {
  kicker: string
  title: string
  subtitle: string
  cards: FacilityCard[]
  amenities: AmenityItem[]
}

/** المعرض — الصور المنتقاة (صور الغرف تُضاف تلقائيًا بعدها) */
export interface GalleryContent {
  kicker: string
  title: string
  subtitle: string
  images: GalleryImage[]
}

/** عناوين قسم التواصل (المعلومات نفسها من بيانات الفندق) */
export interface ContactContent {
  kicker: string
  title: string
  subtitle: string
}

/** التذييل — الوصف وحقوق النشر وزر دخول التطبيق (روابط سريعة = تنقل الترويسة) */
export interface FooterContent {
  description: string
  copyright: string
  loginButtonLabel: string
}

export interface SiteContentAll {
  header: HeaderContent
  hero: HeroContent
  rooms: RoomsContent
  facilities: FacilitiesContent
  gallery: GalleryContent
  contact: ContactContent
  footer: FooterContent
}

// ── القيم الافتراضية (مطابقة للموقع الحرفي الحالي قبل أي تعديل) ──

export const DEFAULT_CONTENT: SiteContentAll = {
  header: {
    logoUrl: '/logo-hotel.svg',
    siteName: '',
    siteTagline: '',
    navLinks: [
      { href: '#home', label: 'الرئيسية' },
      { href: '#rooms', label: 'الغرف' },
      { href: '#facilities', label: 'المرافق' },
      { href: '#gallery', label: 'المعرض' },
      { href: '#contact', label: 'الموقع والتواصل' },
    ],
    bookButtonLabel: 'احجز الآن',
    manageButtonLabel: 'إدارة حجزك',
  },
  hero: {
    image: '/images/hero-hotel.png',
    badge: 'عدن — اليمن',
    title: '',
    tagline: '',
    checkAvailabilityLabel: 'تحقق من التوفر',
    whatsappLabel: 'تحدث معنا واتساب',
    trustItems: [
      { icon: 'bed', title: 'غرف أنيقة', text: 'تجهيزات عصرية وإطلالة مميزة' },
      { icon: 'clock', title: 'خدمة 24 ساعة', text: 'استقبال وخدمة غرف دائمًا' },
      { icon: 'calendar', title: 'إلغاء مجاني 24 ساعة', text: 'قبل موعد الوصول' },
      { icon: 'wifi', title: 'واي فاي مجاني', text: 'في كل الغرف والمرافق' },
    ],
  },
  rooms: {
    kicker: 'الإقامة',
    title: 'غرف وأجنحة تناسب كل مسافر',
    subtitle: 'أسعار شفافة تشمل كل التجهيزات — الضريبة ورسوم نهاية الأسبوع تحسب عند الحجز',
  },
  facilities: {
    kicker: 'المرافق',
    title: 'مرافق صُممت لراحتكم',
    subtitle: 'كل ما تحتاجونه لإقامة متكاملة تحت سقف واحد',
    cards: [
      {
        image: '/images/facility-lobby.png',
        title: 'الاستقبال واللوبي',
        text: 'لوبي فخم بلمسة عربية أصيلة وخدمة استقبال على مدار الساعة لراحتكم منذ لحظة الوصول.',
      },
      {
        image: '/images/facility-restaurant.png',
        title: 'المطعم',
        text: 'مطعم يقدم أشهى الأطباق المحنية والعالمية بإشراف طهاة محترفين على مدار اليوم.',
      },
      {
        image: '/images/facility-terrace.png',
        title: 'التراس المقصف',
        text: 'تراس مقصف بإطلالة ساحرة على المدينة — قهوتكم الصباحية ومساءاتكم الهادئة.',
      },
      {
        image: '/images/facility-gym.png',
        title: 'النادي الرياضي',
        text: 'نادٍ رياضي مجهز بأحدث الأجهزة للاحتفاظ بنشاطكم خلال الإقامة.',
      },
    ],
    amenities: [
      { icon: 'wifi', label: 'واي فاي مجاني' },
      { icon: 'parking', label: 'موقف سيارات' },
      { icon: 'laundry', label: 'غسيل ملابس' },
      { icon: 'clock', label: 'استقبال 24 ساعة' },
      { icon: 'tv', label: 'تلفاز ذكي' },
      { icon: 'safe', label: 'خزنة إلكترونية' },
    ],
  },
  gallery: {
    kicker: 'المعرض',
    title: 'لمحة من الفندق',
    subtitle: 'تصفح صور الغرف والمرافق',
    images: [
      { src: '/images/hero-hotel.png', title: 'واجهة الفندق' },
      { src: '/images/facility-lobby.png', title: 'الاستقبال واللوبي' },
      { src: '/images/facility-restaurant.png', title: 'المطعم' },
      { src: '/images/facility-terrace.png', title: 'التراس المقصف' },
      { src: '/images/facility-gym.png', title: 'النادي الرياضي' },
      { src: '/images/gallery-corridor.png', title: 'ممر الغرف' },
    ],
  },
  contact: {
    kicker: 'الموقع والتواصل',
    title: 'نحن في قلب عدن — تواصلوا معنا',
    subtitle: 'يسعدنا خدمتكم في أي وقت',
  },
  footer: {
    description: '',
    copyright: 'فندق قلب القاهرة — جميع الحقوق محفوظة',
    loginButtonLabel: 'منصة إدارة الإقامة — دخول التطبيق',
  },
}

/** مكتبة الصور الجاهزة (مع القيم الافتراضية للغرف والمرافق) */
export const IMAGE_LIBRARY: string[] = [
  '/images/hero-hotel.png',
  '/images/room-single.png',
  '/images/room-double.png',
  '/images/room-deluxe.png',
  '/images/room-family.png',
  '/images/facility-lobby.png',
  '/images/facility-restaurant.png',
  '/images/facility-terrace.png',
  '/images/facility-gym.png',
  '/images/gallery-corridor.png',
]

// ── الدمج والتنقية (خادم PATCH + عميل) ──

/** دمج قسم مخزَّن فوق الافتراضي (استبدال سطحي للحقول + المصفوفات) */
export function mergeSection<K extends SiteSectionKey>(
  key: K,
  stored: Partial<SiteContentAll[K]> | null | undefined
): SiteContentAll[K] {
  const base = DEFAULT_CONTENT[key]
  if (!stored || typeof stored !== 'object') return { ...base }
  return { ...base, ...stored } as SiteContentAll[K]
}

// ── مساعدات تنقية داخلية ──

const MAX_URL = 600
const MAX_LINE = 160
const MAX_TEXT = 600

function s(v: unknown, max = MAX_LINE): string {
  return typeof v === 'string' ? v.trim().slice(0, max) : ''
}

function url(v: unknown): string {
  const x = typeof v === 'string' ? v.trim() : ''
  if (x === '') return ''
  // مسار داخلي أو رابط مطلق — وإلا يرفض
  if (x.startsWith('/') || /^https?:\/\//i.test(x)) return x.slice(0, MAX_URL)
  return ''
}

function clamp<T>(arr: T[], min: number, max: number): T[] {
  if (!Array.isArray(arr)) return []
  return arr.slice(0, max)
}

function iconKey(v: unknown): IconKey {
  return typeof v === 'string' && (ICON_KEYS as string[]).includes(v)
    ? (v as IconKey)
    : 'sparkles'
}

/** تنقية كائن مجهول إلى شكل القسم السليم — أو null إن كان غير قابل للإصلاح */
export function sanitizeSection(
  key: SiteSectionKey,
  raw: Record<string, unknown> | null | undefined
): SiteContentAll[typeof key] | null {
  if (!raw || typeof raw !== 'object') return null
  const d = raw as Record<string, unknown>

  switch (key) {
    case 'header': {
      const navLinks = clamp(Array.isArray(d.navLinks) ? d.navLinks : [], 1, 8)
        .map((l) => {
          const o = (l ?? {}) as Record<string, unknown>
          return { href: s(o.href, 200) || '#', label: s(o.label) || 'رابط' }
        })
      if (navLinks.length === 0) return null
      const v: HeaderContent = {
        logoUrl: url(d.logoUrl) || DEFAULT_CONTENT.header.logoUrl,
        siteName: s(d.siteName),
        siteTagline: s(d.siteTagline),
        navLinks,
        bookButtonLabel: s(d.bookButtonLabel, 40) || DEFAULT_CONTENT.header.bookButtonLabel,
        manageButtonLabel: s(d.manageButtonLabel, 40) || DEFAULT_CONTENT.header.manageButtonLabel,
      }
      return v
    }
    case 'hero': {
      const trustItems = clamp(Array.isArray(d.trustItems) ? d.trustItems : [], 0, 8)
        .map((t) => {
          const o = (t ?? {}) as Record<string, unknown>
          return { icon: iconKey(o.icon), title: s(o.title, 60), text: s(o.text, 120) }
        })
        .filter((t) => t.title !== '')
      const v: HeroContent = {
        image: url(d.image) || DEFAULT_CONTENT.hero.image,
        badge: s(d.badge, 60),
        title: s(d.title, 90),
        tagline: s(d.tagline, MAX_TEXT),
        checkAvailabilityLabel: s(d.checkAvailabilityLabel, 40) || DEFAULT_CONTENT.hero.checkAvailabilityLabel,
        whatsappLabel: s(d.whatsappLabel, 40) || DEFAULT_CONTENT.hero.whatsappLabel,
        trustItems,
      }
      return v
    }
    case 'rooms': {
      const v: RoomsContent = {
        kicker: s(d.kicker, 40) || DEFAULT_CONTENT.rooms.kicker,
        title: s(d.title, 100) || DEFAULT_CONTENT.rooms.title,
        subtitle: s(d.subtitle, MAX_TEXT) || DEFAULT_CONTENT.rooms.subtitle,
      }
      return v
    }
    case 'facilities': {
      const cards = clamp(Array.isArray(d.cards) ? d.cards : [], 0, 8)
        .map((c) => {
          const o = (c ?? {}) as Record<string, unknown>
          return { image: url(o.image) || DEFAULT_CONTENT.facilities.cards[0].image, title: s(o.title, 80), text: s(o.text, MAX_TEXT) }
        })
        .filter((c) => c.title !== '')
      const amenities = clamp(Array.isArray(d.amenities) ? d.amenities : [], 0, 12)
        .map((a) => {
          const o = (a ?? {}) as Record<string, unknown>
          return { icon: iconKey(o.icon), label: s(o.label, 40) }
        })
        .filter((a) => a.label !== '')
      const v: FacilitiesContent = {
        kicker: s(d.kicker, 40) || DEFAULT_CONTENT.facilities.kicker,
        title: s(d.title, 100) || DEFAULT_CONTENT.facilities.title,
        subtitle: s(d.subtitle, MAX_TEXT) || DEFAULT_CONTENT.facilities.subtitle,
        cards,
        amenities,
      }
      return v
    }
    case 'gallery': {
      const images = clamp(Array.isArray(d.images) ? d.images : [], 0, 24)
        .map((i) => {
          const o = (i ?? {}) as Record<string, unknown>
          return { src: url(o.src), title: s(o.title, 60) || 'صورة' }
        })
        .filter((i) => i.src !== '')
      const v: GalleryContent = {
        kicker: s(d.kicker, 40) || DEFAULT_CONTENT.gallery.kicker,
        title: s(d.title, 100) || DEFAULT_CONTENT.gallery.title,
        subtitle: s(d.subtitle, MAX_TEXT) || DEFAULT_CONTENT.gallery.subtitle,
        images,
      }
      return v
    }
    case 'contact': {
      const v: ContactContent = {
        kicker: s(d.kicker, 40) || DEFAULT_CONTENT.contact.kicker,
        title: s(d.title, 100) || DEFAULT_CONTENT.contact.title,
        subtitle: s(d.subtitle, MAX_TEXT) || DEFAULT_CONTENT.contact.subtitle,
      }
      return v
    }
    case 'footer': {
      const v: FooterContent = {
        description: s(d.description, MAX_TEXT),
        copyright: s(d.copyright, 120) || DEFAULT_CONTENT.footer.copyright,
        loginButtonLabel: s(d.loginButtonLabel, 60) || DEFAULT_CONTENT.footer.loginButtonLabel,
      }
      return v
    }
  }
}

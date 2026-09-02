// ─────────────────────────────────────────────────────────────
// PRICING ENGINE — محرك تسعير حتمي (SINGLE SOURCE OF TRUTH)
// كل المبالغ بالسنت (Int) — لا أرقام عائمة للمال أبدًا
// السعر الليلي = معدل موسمي مطابق، وإلا السعر الأساسي
// + زيادة نهاية الأسبوع (الجمعة/السبت) إن كانت مفعّلة
// ─────────────────────────────────────────────────────────────

export interface RateLike {
  name: string
  startDate: Date
  endDate: Date
  priceCents: number
}

export interface QuoteInput {
  checkIn: Date
  checkOut: Date
  basePriceCents: number
  rates: RateLike[]
  weekendSurchargePercent: number
  taxPercent: number
  currency: string
  roomsCount?: number
}

export interface Quote {
  nights: number
  roomsCount: number
  currency: string
  taxPercent: number
  nightly: { date: string; priceCents: number; rateName: string }[]
  subtotalCents: number
  discountCents: number
  taxCents: number
  grandTotalCents: number
}

/** مفتاح تاريخ محلي YYYY-MM-DD (بدون انزياح توقيت) */
export function localDateKey(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/** عدد الليالي من حدود الأيام — لا من الطوابع الزمنية */
export function nightsBetween(checkIn: Date, checkOut: Date): number {
  const a = new Date(checkIn); a.setHours(0, 0, 0, 0)
  const b = new Date(checkOut); b.setHours(0, 0, 0, 0)
  return Math.round((b.getTime() - a.getTime()) / 86_400_000)
}

function isWeekend(d: Date): boolean {
  const day = d.getDay() // 5 = الجمعة، 6 = السبت
  return day === 5 || day === 6
}

/** إيجاد المعدل الموسمي المطابق لتاريخ ليلة (الأحدث بدايةً يفوز) */
function rateForNight(date: Date, rates: RateLike[]): RateLike | null {
  const t = date.getTime()
  let best: RateLike | null = null
  for (const r of rates) {
    const start = new Date(r.startDate); start.setHours(0, 0, 0, 0)
    const end = new Date(r.endDate); end.setHours(23, 59, 59, 999)
    if (t >= start.getTime() && t <= end.getTime()) {
      if (!best || new Date(r.startDate) > new Date(best.startDate)) best = r
    }
  }
  return best
}

/** حساب عرض سعر كامل وحتمي — يُستخدم للبحث والمراجعة والإنشاء النهائي */
export function computeQuote(input: QuoteInput): Quote {
  const roomsCount = Math.max(1, input.roomsCount ?? 1)
  const nights = nightsBetween(input.checkIn, input.checkOut)
  const nightly: Quote['nightly'] = []

  const cursor = new Date(input.checkIn); cursor.setHours(0, 0, 0, 0)
  for (let i = 0; i < nights; i++) {
    const rate = rateForNight(cursor, input.rates)
    let price = rate ? rate.priceCents : input.basePriceCents
    if (input.weekendSurchargePercent > 0 && isWeekend(cursor)) {
      price += Math.round((price * input.weekendSurchargePercent) / 100)
    }
    nightly.push({ date: localDateKey(cursor), priceCents: price, rateName: rate?.name ?? 'السعر الأساسي' })
    cursor.setDate(cursor.getDate() + 1)
  }

  const subtotalCents = nightly.reduce((a, n) => a + n.priceCents, 0) * roomsCount
  const taxCents = Math.round((subtotalCents * input.taxPercent) / 100)
  return {
    nights,
    roomsCount,
    currency: input.currency,
    taxPercent: input.taxPercent,
    nightly,
    subtotalCents,
    discountCents: 0,
    taxCents,
    grandTotalCents: subtotalCents + taxCents,
  }
}

/** لقطة السعر التي تُحفظ مع الحجز — غير قابلة لإعادة الكتابة */
export function buildSnapshot(params: {
  quote: Quote
  roomTypeName: string
  cancellationPolicy: string
  checkInTime: string
  checkOutTime: string
  bookedAt: string
}): string {
  return JSON.stringify({
    version: 1,
    roomTypeName: params.roomTypeName,
    nightly: params.quote.nightly,
    subtotalCents: params.quote.subtotalCents,
    discountCents: params.quote.discountCents,
    taxCents: params.quote.taxCents,
    grandTotalCents: params.quote.grandTotalCents,
    currency: params.quote.currency,
    taxPercent: params.quote.taxPercent,
    roomsCount: params.quote.roomsCount,
    cancellationPolicy: params.cancellationPolicy,
    checkInTime: params.checkInTime,
    checkOutTime: params.checkOutTime,
    bookedAt: params.bookedAt,
  })
}

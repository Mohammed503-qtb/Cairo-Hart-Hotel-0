// ═══════════════════════════════════════════════════════════════════
// H2.3 + H2.4 + H2.5 + H2.6 — اختبارات التكامل فوق قاعدة معزولة
// (MASTER_PLAN v2.0 §5 H2 · Task ID: H2-b)
//
// النمط الإلزامي: أول سطر حرفي يضبط DATABASE_URL قبل أي استيراد
// ديناميكي لوحدات src/ (PrismaClient يُبنى لحظة أول استيراد).
// setupTestDb('integration') → migrate deploy + seed بالمسار الرسمي.
//
// الثوابت الموثقة المغطاة هنا (كلها فوق معالجات المسارات مباشرة):
//   I1     : لا حجز مؤكد فوق المخزون (availability + oversell 409)
//   I4     : كود منتهٍ/ملغي لا يعمل (validate بعد الخروج)
//   I7     : لا حجز مزدوج (إعادة فحص التوفر داخل المعاملة + طلبان متزامنان)
//   I8     : لا دفع/حجز مكرر (Idempotency-Key يعيد نفس الحجز)
//   I10    : كل عملية حرجة مُدقَّقة (auditLog للعمليات الحرجة)
//   I11    : كود الضيف يموت عند الخروج (REVOKED + جلسات مبطلة + 401)
//   §12.2  : رصيد الإقامة = grand + Σcharges − Σpayments بالسنت
//   §12.6  : مراجع HTL-YYYY-NNNNNN / ST-YYYY-NNNNNN
//   §12.4  : كود ضيف خام H + 6 أرقام + حرفا تحقق — يُعاد مرة واحدة
//
// كل القيم المالية بالسنت ومحققة ضد المحسوب من prisma/seed.ts
// والثوابت الموثقة فيه (ديلوكس 16000 · ضريبة 15% · نهاية أسبوع 10%).
// ═══════════════════════════════════════════════════════════════════
process.env.DATABASE_URL = 'file:/home/z/my-project/db/test-integration.db'

import { describe, it, expect } from 'bun:test'
import { setupTestDb } from '../helpers/test-db'

setupTestDb('integration')

// ── استيراد ديناميكي للمعالجات بعد ضبط البيئة (إلزامي — لا استيراد ثابت لـ src/) ──
const availabilityRoute = await import('@/app/api/public/availability/route')
const bookingsRoute = await import('@/app/api/public/bookings/route')
const editRoute = await import('@/app/api/public/edit/route')
const validateRoute = await import('@/app/api/auth/validate/route')
const arrivalsRoute = await import('@/app/api/reception/arrivals/route')
const checkInRoute = await import('@/app/api/reception/check-in/route')
const checkOutRoute = await import('@/app/api/reception/check-out/route')
const chargesRoute = await import('@/app/api/reception/charges/route')
const paymentsRoute = await import('@/app/api/reception/payments/route')
const receptionRequestsRoute = await import('@/app/api/reception/requests/route')
const requestStatusRoute = await import('@/app/api/reception/requests/[id]/status/route')
const guestBillRoute = await import('@/app/api/guest/bill/route')
const guestDashboardRoute = await import('@/app/api/guest/dashboard/route')
const guestRequestsRoute = await import('@/app/api/guest/requests/route')
const billingRoute = await import('@/app/api/reception/billing/[stayId]/route')
const { db } = await import('@/lib/db')
const { NextRequest } = await import('next/server')

// ─────────────────────────────────────────────────────────────
// أدوات مساعدة (تواريخ محلية — نفس منطق seed.ts تمامًا)
// ─────────────────────────────────────────────────────────────
const startOfDay = (d: Date): Date => {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x
}
const today = startOfDay(new Date())
const addDays = (base: Date, n: number): Date => {
  const x = new Date(base)
  x.setDate(x.getDate() + n)
  return x
}
const isoDate = (d: Date): string => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/** أقرب تاريخ ≥ from يقع يوم الأحد (بداية نافذة بلا جمعة/سبت) */
const nextSunday = (from: Date): Date => {
  const x = startOfDay(from)
  while (x.getDay() !== 0) x.setDate(x.getDate() + 1)
  return x
}

// ── ثوابت seed الموثقة (prisma/seed.ts — محسوبة من المصدر) ──
const TAX_PERCENT = 15 // hotel.taxPercent
const WEEKEND_PERCENT = 10 // hotel.weekendSurchargePercent (الجمعة/السبت)
const BASE = { single: 8000, double: 12000, deluxe: 16000, family: 22000 } // basePriceCents
const KHALED_GRAND = 55200 // ديلوكس 3 ليالٍ × 16000 + ضريبة 15% (موثق في seed)
const KHALED_PAID = 30000 // SEED-DEP-003
const KHALED_CHARGES = 4500 + 2000 // خدمة الغرف — عشاء + غسيل ملابس
const NORA_GRAND = 41400 // مزدوجة 3 ليالٍ × 12000 + 15%
const NORA_PAID = 36400 // 20000 + 16400
const AHMED_GRAND = 55200
const AHMED_DEPOSIT = 27600 // Math.round(55200 / 2)

/**
 * إعادة حساب عرض السعر من قواعد المال §12.2 وثوابت seed حصرًا
 * (سعر أساسي × ليالي + زيادة نهاية الأسبوع إن أصابت، × الغرف،
 * ضريبة round للسنت) — تحقق مستقل لا يستورد محرك التسعير.
 */
function expectedQuote(checkIn: Date, checkOut: Date, basePriceCents: number, roomsCount = 1) {
  const ci = startOfDay(checkIn)
  const co = startOfDay(checkOut)
  const nights = Math.round((co.getTime() - ci.getTime()) / 86_400_000)
  const nightly: { date: string; priceCents: number; rateName: string }[] = []
  const cursor = new Date(ci)
  for (let i = 0; i < nights; i++) {
    let price = basePriceCents
    const day = cursor.getDay() // 5=الجمعة 6=السبت
    if (day === 5 || day === 6) price += Math.round((basePriceCents * WEEKEND_PERCENT) / 100)
    nightly.push({ date: isoDate(cursor), priceCents: price, rateName: 'السعر الأساسي' })
    cursor.setDate(cursor.getDate() + 1)
  }
  const subtotalCents = nightly.reduce((a, n) => a + n.priceCents, 0) * roomsCount
  const taxCents = Math.round((subtotalCents * TAX_PERCENT) / 100)
  return {
    nights,
    roomsCount,
    currency: 'USD',
    taxPercent: TAX_PERCENT,
    nightly,
    subtotalCents,
    discountCents: 0,
    taxCents,
    grandTotalCents: subtotalCents + taxCents,
  }
}

// ─────────────────────────────────────────────────────────────
// مصنع الطلبات + جلسات (كل نداء IP فريد → لا اصطدام بحدود المعدل
// في الذاكرة: validate 5/دقيقة وbookings 10/ساعة لكل IP)
// ─────────────────────────────────────────────────────────────
let ipCounter = 0
const nextIp = (): string => `198.51.100.${(ipCounter += 1)}`

/** نداء POST لمسار (المعالج يُمرر صراحة — استدعاء مباشر بلا شبكة) */
function postTo(
  handler: (r: Request, ctx?: { params: Promise<Record<string, string>> }) => Promise<Response>,
  url: string,
  body: unknown,
  headers: Record<string, string> = {},
  params?: Record<string, string>
): Promise<Response> {
  return handler(new NextRequest(url, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'content-type': 'application/json', 'x-forwarded-for': nextIp(), ...headers },
  }), params ? { params: Promise.resolve(params) } : undefined)
}

function get(
  handler: (r: Request) => Promise<Response>,
  url: string,
  headers: Record<string, string> = {}
): Promise<Response> {
  return handler(new NextRequest(url, { headers: { 'x-forwarded-for': nextIp(), ...headers } }))
}

async function json<T>(res: Response): Promise<T & { ok: boolean; error?: string }> {
  return (await res.json()) as T & { ok: boolean; error?: string }
}

/** دخول بالكود عبر validate — يرجع التوكن */
async function loginAs(code: string): Promise<{ token: string; role: string; name: string }> {
  const res = await postTo(
    validateRoute.POST as unknown as (r: Request) => Promise<Response>,
    'http://localhost/api/auth/validate',
    { code }
  )
  const j = await json<{ token: string; role: string; name: string }>(res)
  expect(j.ok).toBe(true)
  return j
}
const bearer = (token: string): Record<string, string> => ({ authorization: `Bearer ${token}` })

// ─────────────────────────────────────────────────────────────
// أشكال الاستجابة (مختصرة — الحقول التي نتحقق منها فقط)
// ─────────────────────────────────────────────────────────────
interface QuoteShape {
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
interface AvailabilityItemShape {
  roomType: { id: string; name: string; basePriceCents: number }
  availableCount: number
  quote: QuoteShape
}
interface ReservationPublicShape {
  id: string
  bookingReference: string
  status: string
  nights: number
  roomsCount: number
  currency: string
  subtotalCents: number
  taxCents: number
  grandTotalCents: number
  paidCents: number
  paymentStatus: string
  paymentMethod: string
}
interface BillShape {
  stayId: string
  stayReference: string
  roomNumber: string
  roomNights: number
  roomTotalCents: number
  roomSubtotalCents: number
  roomTaxCents: number
  extraCharges: { description: string; amountCents: number; category: string }[]
  extraTotalCents: number
  payments: { method: string; amountCents: number; recordedBy: string }[]
  totalChargesCents: number
  totalPaidCents: number
  balanceCents: number
  currency: string
}

// ─────────────────────────────────────────────────────────────
// حالة مشتركة بين المجموعات المتسلسلة (الرحلات تتبع بعضها عمدًا)
// ─────────────────────────────────────────────────────────────
let receptionToken = '' // جلسة R492671M3 واحدة تُعاد عبر كل المجموعات
let h23Booking: ReservationPublicShape | null = null // حجز H2.3 (للتحقق من التفرد)
let golden: {
  booking: ReservationPublicShape
  checkInDate: string
  nights: number
  expectedGrand: number
  stayId: string
  stayRef: string
  guestCode: string
  guestToken: string
  roomNumber: string
  requestId: string
  requestRef: string
  chargeCents: number
  paymentCents: number
} | null = null

// ─────────────────────────────────────────────────────────────
// H2.3 — التوفر والحجز (I1 · I7 · I8 · §12.6 · I6 · I9)
// ─────────────────────────────────────────────────────────────
describe('H2.3 — التوفر والحجز (I1, I7, I8)', () => {
  const range = { checkIn: addDays(today, 2), checkOut: addDays(today, 4) }

  it('التوفر بمدى صالح: 4 أنواع فعالة بسعات seed الصحيحة وأسعار محسوبة (I1: المخزون = الغرف − المحجوزات المتداخلة)', async () => {
    const res = await postTo(
      availabilityRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/availability',
      { checkIn: isoDate(range.checkIn), checkOut: isoDate(range.checkOut), adults: 1, children: 0, roomsCount: 1 }
    )
    expect(res.status).toBe(200)
    const j = await json<{ items: AvailabilityItemShape[] }>(res)
    expect(j.ok).toBe(true)

    // مرتبة تصاعديًا بالسعر الأساسي (سلوك المسار)
    expect(j.items.map((i) => i.roomType.name)).toEqual([
      'غرفة مفردة',
      'غرفة مزدوجة',
      'غرفة ديلوكس',
      'الجناح العائلي',
    ])

    // السعات المحسوبة من seed:
    //   مفردة: غرفتا 101+102 بلا حجوزات متداخلة → 2
    //   مزدوجة: 103+104+105+106 (لا OUT_OF_ORDER) بلا تداخل (جون يبدأ اليوم+7) → 4
    //   ديلوكس: 5 غرف − حجز أحمد [اليوم، اليوم+3) يتداخل → 4
    //   عائلي: 301+302 (303 خارج الخدمة) − حجز سارة ينتهي بداية المدى → 2
    const byName = Object.fromEntries(j.items.map((i) => [i.roomType.name, i]))
    expect(byName['غرفة مفردة'].availableCount).toBe(2)
    expect(byName['غرفة مزدوجة'].availableCount).toBe(4)
    expect(byName['غرفة ديلوكس'].availableCount).toBe(4)
    expect(byName['الجناح العائلي'].availableCount).toBe(2)

    // الأسعار محسوبة من قواعد المال §12.2 (شاملة زيادة نهاية الأسبوع إن أصابت المدى)
    // أزواج (الاسم العربي في seed · السعر الأساسي بالسنت)
    const typeBase: Array<[string, number]> = [
      ['غرفة مفردة', BASE.single],
      ['غرفة مزدوجة', BASE.double],
      ['غرفة ديلوكس', BASE.deluxe],
      ['الجناح العائلي', BASE.family],
    ]
    for (const [name, base] of typeBase) {
      expect(byName[name].quote).toEqual(expectedQuote(range.checkIn, range.checkOut, base, 1))
    }
  }, 30_000)

  it('تواريخ معكوسة → 400 بالرسالة العربية الحرفية من الكود', async () => {
    const res = await postTo(
      availabilityRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/availability',
      { checkIn: isoDate(range.checkOut), checkOut: isoDate(range.checkIn), adults: 1, children: 0, roomsCount: 1 }
    )
    expect(res.status).toBe(400)
    const j = await json(res)
    expect(j.error).toBe('تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول')
  })

  it('حجز ناجح PAY_AT_HOTEL → 201 + مرجع HTL-YYYY-NNNNNN (§12.6) + totals مطابقة للمحسوب بالسنت (I6)', async () => {
    const expected = expectedQuote(range.checkIn, range.checkOut, BASE.double, 1)
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: isoDate(range.checkIn),
        checkOut: isoDate(range.checkOut),
        adults: 2,
        children: 0,
        roomsCount: 1,
        roomTypeId: doubleType!.id,
        guest: { fullName: 'حجز تكاملي أول', phone: '+967778111001' },
        paymentMethod: 'PAY_AT_HOTEL',
        idempotencyKey: 'integration-idem-1',
      }
    )
    expect(res.status).toBe(201)
    const j = await json<{ reservation: ReservationPublicShape; replayed?: boolean }>(res)
    expect(j.ok).toBe(true)
    expect(j.replayed).toBeUndefined() // أول نداء — ليس إعادة تشغيل

    // §12.6: صيغة المرجع HTL-YYYY-NNNNNN (6 أرقام — كما في refs.ts والـ seed)
    expect(j.reservation.bookingReference).toMatch(/^HTL-\d{4}-\d{6}$/)
    expect(j.reservation.status).toBe('CONFIRMED')
    expect(j.reservation.paidCents).toBe(0)
    expect(j.reservation.paymentStatus).toBe('UNPAID')
    expect(j.reservation.paymentMethod).toBe('PAY_AT_HOTEL')
    expect(j.reservation.nights).toBe(expected.nights)
    expect(j.reservation.subtotalCents).toBe(expected.subtotalCents)
    expect(j.reservation.taxCents).toBe(expected.taxCents)
    expect(j.reservation.grandTotalCents).toBe(expected.grandTotalCents)
    h23Booking = j.reservation

    // I9: لقطة السعر تُجمد مع الحجز بنفس الأرقام
    const row = await db.reservation.findUnique({ where: { id: j.reservation.id } })
    expect(row).not.toBeNull()
    const snap = JSON.parse(row!.priceSnapshot) as { grandTotalCents: number; subtotalCents: number; taxCents: number; nightly: unknown[] }
    expect(snap.grandTotalCents).toBe(expected.grandTotalCents)
    expect(snap.subtotalCents).toBe(expected.subtotalCents)
    expect(snap.taxCents).toBe(expected.taxCents)
    expect(snap.nightly).toHaveLength(expected.nights)
  }, 30_000)

  it('Idempotency (I8): نفس Idempotency-Key يعيد نفس الحجز — لا حجزًا ثانيًا', async () => {
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const body = {
      checkIn: isoDate(range.checkIn),
      checkOut: isoDate(range.checkOut),
      adults: 2,
      children: 0,
      roomsCount: 1,
      roomTypeId: doubleType!.id,
      guest: { fullName: 'حجز تكاملي أول', phone: '+967778111001' },
      paymentMethod: 'PAY_AT_HOTEL',
      idempotencyKey: 'integration-idem-1',
    }
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      body
    )
    expect(res.status).toBe(200) // إعادة تشغيل — ليست 201
    const j = await json<{ reservation: ReservationPublicShape; replayed: boolean }>(res)
    expect(j.ok).toBe(true)
    expect(j.replayed).toBe(true)
    expect(j.reservation.bookingReference).toBe(h23Booking!.bookingReference)
    expect(j.reservation.id).toBe(h23Booking!.id)

    // ولا يوجد في القاعدة سوى حجز واحد لهذا الضيف (لا ازدواج)
    const count = await db.reservation.count({
      where: { bookingReference: h23Booking!.bookingReference },
    })
    expect(count).toBe(1)
    const guest = await db.guest.findFirst({ where: { phone: { endsWith: '778111001' } } })
    expect(await db.reservation.count({ where: { guestId: guest!.id } })).toBe(1)
  }, 30_000)

  it('الحجز لتاريخ في الماضي → مرفوض برسالة الكود الحرفية', async () => {
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: isoDate(addDays(today, -1)),
        checkOut: isoDate(addDays(today, 1)),
        adults: 1,
        roomTypeId: doubleType!.id,
        guest: { fullName: 'حجز ماضٍ مرفوض', phone: '+967778111002' },
        paymentMethod: 'PAY_AT_HOTEL',
      }
    )
    expect(res.status).toBe(400)
    const j = await json(res)
    expect(j.error).toBe('لا يمكن الحجز لتاريخٍ في الماضي')
  })

  it('الحجز خارج أفق الحجز (365 يومًا) → مرفوض برسالة الكود الحرفية', async () => {
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: isoDate(addDays(today, 366)),
        checkOut: isoDate(addDays(today, 368)),
        adults: 1,
        roomTypeId: doubleType!.id,
        guest: { fullName: 'حجز خارج الأفق', phone: '+967778111003' },
        paymentMethod: 'PAY_AT_HOTEL',
      }
    )
    expect(res.status).toBe(400)
    const j = await json(res)
    expect(j.error).toBe('الحجز متاح حتى 365 يومًا من اليوم فقط')
  })

  it('الحجز فوق الحد الأقصى للإقامة (30 ليلة) → مرفوض برسالة الكود الحرفية', async () => {
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: isoDate(addDays(today, 2)),
        checkOut: isoDate(addDays(today, 33)),
        adults: 1,
        roomTypeId: doubleType!.id,
        guest: { fullName: 'إقامة طويلة مرفوضة', phone: '+967778111004' },
        paymentMethod: 'PAY_AT_HOTEL',
      }
    )
    expect(res.status).toBe(400)
    const j = await json(res)
    expect(j.error).toBe('الحد الأقصى للإقامة 30 ليلة')
  })

  it('I1/I7: حجز كل المخزون (مفردة × غرفتين) ثم محاولة فوق المخزون متزامنة ومتسلسلة → مرفوضة 409 ولا oversell', async () => {
    const singleType = await db.roomType.findFirst({ where: { name: 'غرفة مفردة' } })
    const ci = isoDate(addDays(today, 10))
    const co = isoDate(addDays(today, 12))

    // السعة قبل: غرفتا 101+102 بلا حجوزات متداخلة
    const availBefore = await postTo(
      availabilityRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/availability',
      { checkIn: ci, checkOut: co, adults: 1, children: 0, roomsCount: 1 }
    )
    const before = await json<{ items: AvailabilityItemShape[] }>(availBefore)
    const singleItem = before.items.find((i) => i.roomType.name === 'غرفة مفردة')
    expect(singleItem!.availableCount).toBe(2)

    // طلبان متزامنان يحجزان كل المخزون (roomsCount=2 لكل منهما) — واحد فقط ينجح
    const mkBody = (phone: string) => ({
      checkIn: ci,
      checkOut: co,
      adults: 1,
      children: 0,
      roomsCount: 2,
      roomTypeId: singleType!.id,
      guest: { fullName: 'محاولة حجز متزامنة', phone },
      paymentMethod: 'PAY_AT_HOTEL',
    })
    const handler = bookingsRoute.POST as unknown as (r: Request) => Promise<Response>
    const [r1, r2] = await Promise.all([
      postTo(handler, 'http://localhost/api/public/bookings', mkBody('+967778111011')),
      postTo(handler, 'http://localhost/api/public/bookings', mkBody('+967778111012')),
    ])
    const j1 = await json<{ reservation?: ReservationPublicShape }>(r1)
    const j2 = await json<{ reservation?: ReservationPublicShape }>(r2)
    // I7: إعادة فحص التوفر داخل المعاملة — نجاح واحد بالضبط (201) ورفض واحد (409)
    expect([j1.ok, j2.ok].filter(Boolean)).toHaveLength(1)
    expect([r1.status, r2.status].sort()).toEqual([201, 409])
    const failed = j1.ok ? j2 : j1
    const succeeded = j1.ok ? j1 : j2
    expect(succeeded.reservation!.roomsCount).toBe(2) // حجز كل المخزون (غرفتا المفردة)
    expect(failed.error).toBe('الغرفة لم تعد متاحة لهذه التواريخ. يرجى اختيار خيار آخر أو تغيير المواعيد')

    // I1: النوع اختفى من نتائج التوفر (لا عرض فوق المخزون)
    const availAfter = await postTo(
      availabilityRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/availability',
      { checkIn: ci, checkOut: co, adults: 1, children: 0, roomsCount: 1 }
    )
    const after = await json<{ items: AvailabilityItemShape[] }>(availAfter)
    expect(after.items.find((i) => i.roomType.name === 'غرفة مفردة')).toBeUndefined()

    // محاولة إضافية متسلسلة → 409 نفسها (I1: لا حجز مؤكد فوق المخزون)
    const r3 = await postTo(handler, 'http://localhost/api/public/bookings', mkBody('+967778111013'))
    expect(r3.status).toBe(409)
    const j3 = await json(r3)
    expect(j3.error).toBe('الغرفة لم تعد متاحة لهذه التواريخ. يرجى اختيار خيار آخر أو تغيير المواعيد')

    // برهان قاعدة البيانات: مجموع الغرف المحجوزة لهذا النوع في المدى = 2 بالضبط
    const agg = await db.reservation.aggregate({
      _sum: { roomsCount: true },
      where: {
        roomTypeId: singleType!.id,
        status: { in: ['PENDING', 'CONFIRMED', 'CHECKED_IN'] },
        checkIn: { lt: addDays(today, 12) },
        checkOut: { gt: addDays(today, 10) },
      },
    })
    expect(agg._sum.roomsCount).toBe(2)
  }, 60_000)
})

// ─────────────────────────────────────────────────────────────
// H2.4 — رصيد الفاتورة (§12.2: grand + Σcharges − Σpayments بالسنت)
// ─────────────────────────────────────────────────────────────
describe('H2.4 — رصيد الفاتورة (§12.2)', () => {
  let khaledToken = ''
  let khaledStayId = ''
  const expectedInitial = {
    roomTotal: KHALED_GRAND,
    extraTotal: KHALED_CHARGES,
    totalCharges: KHALED_GRAND + KHALED_CHARGES,
    totalPaid: KHALED_PAID,
    balance: KHALED_GRAND + KHALED_CHARGES - KHALED_PAID, // 55200 + 6500 − 30000 = 31700
  }

  it('دخول خالد (H834729X7) → GET /api/guest/bill: الحساب مطابق لـ seed بالسنت (roomTotal + Σcharges − Σpayments = balance)', async () => {
    khaledToken = (await loginAs('H834729X7')).token
    receptionToken = (await loginAs('R492671M3')).token

    const res = await get(
      guestBillRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/bill',
      bearer(khaledToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ bill: BillShape }>(res)
    const bill = j.bill
    khaledStayId = bill.stayId

    // كلها من seed.ts حرفيًا
    expect(bill.stayReference).toBe('ST-2026-000883')
    expect(bill.roomNumber).toBe('201')
    expect(bill.roomNights).toBe(3)
    expect(bill.roomSubtotalCents).toBe(48000)
    expect(bill.roomTaxCents).toBe(7200)
    expect(bill.roomTotalCents).toBe(expectedInitial.roomTotal) // 55200
    expect(bill.extraCharges).toHaveLength(2)
    expect(bill.extraTotalCents).toBe(expectedInitial.extraTotal) // 6500
    expect(bill.totalChargesCents).toBe(expectedInitial.totalCharges) // 61700
    expect(bill.totalPaidCents).toBe(expectedInitial.totalPaid) // 30000
    expect(bill.payments).toHaveLength(1)
    expect(bill.payments[0].amountCents).toBe(KHALED_PAID)
    expect(bill.currency).toBe('USD')
    // §12.2 — المعادلة بالسنت
    expect(bill.balanceCents).toBe(expectedInitial.balance) // 31700
    expect(bill.roomTotalCents + bill.extraTotalCents - bill.totalPaidCents).toBe(bill.balanceCents)
  }, 30_000)

  it('إضافة رسوم عبر POST /api/reception/charges (R492671M3) → الفاتورة تعكسها فورًا بالزيادة الصحيحة', async () => {
    const CHARGE = 1200
    const res = await postTo(
      chargesRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/charges',
      { stayId: khaledStayId, description: 'بند اختبار تكاملي', amountCents: CHARGE, category: 'SERVICE' },
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ charge: { amountCents: number; category: string }; balanceCents: number }>(res)
    expect(j.charge.amountCents).toBe(CHARGE)
    expect(j.charge.category).toBe('SERVICE')
    // الرصيد الجديد = 55200 + (6500 + 1200) − 30000 = 32900
    expect(j.balanceCents).toBe(expectedInitial.balance + CHARGE)

    // فاتورة الضيف تعكسها فورًا
    const billRes = await get(
      guestBillRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/bill',
      bearer(khaledToken)
    )
    const bill = (await json<{ bill: BillShape }>(billRes)).bill
    expect(bill.extraCharges).toHaveLength(3)
    expect(bill.extraTotalCents).toBe(KHALED_CHARGES + CHARGE) // 7700
    expect(bill.totalChargesCents).toBe(KHALED_GRAND + KHALED_CHARGES + CHARGE) // 62900
    expect(bill.balanceCents).toBe(expectedInitial.balance + CHARGE) // 32900
  }, 30_000)

  it('إضافة دفعة عبر POST /api/reception/payments → الرصيد ينقص بالمقدار الصحيح', async () => {
    const PAYMENT = 10000
    const res = await postTo(
      paymentsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/payments',
      { stayId: khaledStayId, method: 'CASH', amountCents: PAYMENT, note: 'دفعة اختبار تكاملي' },
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ payment: { amountCents: number; method: string }; paidCents: number; paymentStatus: string; balanceCents: number }>(res)
    expect(j.payment.amountCents).toBe(PAYMENT)
    expect(j.payment.method).toBe('CASH')
    expect(j.paidCents).toBe(KHALED_PAID + PAYMENT) // 40000
    expect(j.paymentStatus).toBe('PARTIALLY_PAID') // 40000 < 55200
    // 55200 + 7700 − 40000 = 22900
    expect(j.balanceCents).toBe(KHALED_GRAND + (KHALED_CHARGES + 1200) - (KHALED_PAID + PAYMENT))

    const billRes = await get(
      guestBillRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/bill',
      bearer(khaledToken)
    )
    const bill = (await json<{ bill: BillShape }>(billRes)).bill
    expect(bill.totalPaidCents).toBe(KHALED_PAID + PAYMENT)
    expect(bill.payments).toHaveLength(2)
    expect(bill.balanceCents).toBe(22900)
    // §12.2 مرة أخرى — المعادلة closing
    expect(bill.roomTotalCents + bill.extraTotalCents - bill.totalPaidCents).toBe(bill.balanceCents)
  }, 30_000)

  it('مسار الاستقبال billing/[stayId] يعرض نفس الأرقام تمامًا', async () => {
    // المسار يقرأ stayId من باراميتر المسار — يُمرر بنمط Promise الديناميكي
    const handler = billingRoute.GET as unknown as (
      r: Request,
      ctx: { params: Promise<{ stayId: string }> }
    ) => Promise<Response>
    const res = await handler(
      new NextRequest(`http://localhost/api/reception/billing/${khaledStayId}`, {
        headers: { ...bearer(receptionToken), 'x-forwarded-for': nextIp() },
      }),
      { params: Promise.resolve({ stayId: khaledStayId }) }
    )
    expect(res.status).toBe(200)
    const bill = (await json<{ bill: BillShape }>(res)).bill
    expect(bill.roomTotalCents).toBe(KHALED_GRAND) // 55200
    expect(bill.extraTotalCents).toBe(KHALED_CHARGES + 1200) // 7700
    expect(bill.totalPaidCents).toBe(KHALED_PAID + 10000) // 40000
    expect(bill.totalChargesCents).toBe(62900)
    expect(bill.balanceCents).toBe(22900)
    expect(bill.payments).toHaveLength(2)
  }, 30_000)

  it('خروج برصيد موجب (نورا): يُرفض بلا تأكيد ثم يُقبل مع confirmOutstanding — وbalanceCents بالإيجاب (§12.2)', async () => {
    // نورا: grand 41400 + charges 0 − paid 36400 = رصيد 5000
    const noraStay = await db.stay.findUnique({ where: { reference: 'ST-2026-000871' } })
    expect(noraStay).not.toBeNull()

    // 1) بلا تأكيد → 400 مع الرسالة الحرفية + balanceCents في الجسم
    const r1 = await postTo(
      checkOutRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-out',
      { stayId: noraStay!.id },
      bearer(receptionToken)
    )
    expect(r1.status).toBe(400)
    const j1 = await json<{ balanceCents?: number }>(r1)
    expect(j1.error).toBe('يوجد رصيد غير مسدد $50.00 — سجّل دفعة أو أكّد الخروج مع الرصيد')
    expect(j1.balanceCents).toBe(NORA_GRAND - NORA_PAID) // 5000

    // 2) مع التأكيد → 200 والخروج برصيد موجب
    const r2 = await postTo(
      checkOutRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-out',
      { stayId: noraStay!.id, confirmOutstanding: true },
      bearer(receptionToken)
    )
    expect(r2.status).toBe(200)
    const j2 = await json<{ closed: boolean; balanceCents: number; roomNumber: string }>(r2)
    expect(j2.closed).toBe(true)
    expect(j2.roomNumber).toBe('103')
    expect(j2.balanceCents).toBe(5000)

    // الحالة النهائية في القاعدة (I11 مطبق على نورا أيضًا)
    const stay = await db.stay.findUnique({ where: { id: noraStay!.id } })
    expect(stay!.status).toBe('CLOSED')
    const room103 = await db.room.findUnique({ where: { number: '103' } })
    expect(room103!.status).toBe('DIRTY')
    const noraCode = await db.accessCode.findFirst({ where: { stayId: noraStay!.id, type: 'GUEST' } })
    expect(noraCode!.status).toBe('REVOKED')
  }, 30_000)
})

// ─────────────────────────────────────────────────────────────
// H2.5 — دورة حياة الأكواد (I4 · I11 · §12.4)
// ─────────────────────────────────────────────────────────────
describe('H2.5 — دورة حياة الأكواد (I4, I11)', () => {
  const ahmed = { stayId: '', stayRef: '', guestCode: '', token: '' }

  it('وصول اليوم: arrivals (R492671M3) يحوي HTL-2026-000421 بأرقامه الكاملة', async () => {
    const res = await get(
      arrivalsRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/arrivals',
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ arrivals: Array<{ bookingReference: string; guest: { fullName: string }; grandTotalCents: number; paidCents: number; hasStay: boolean; roomType: { name: string } }> }>(res)
    const target = j.arrivals.find((a) => a.bookingReference === 'HTL-2026-000421')
    expect(target).toBeDefined()
    expect(target!.guest.fullName).toBe('أحمد محمد')
    expect(target!.roomType.name).toBe('غرفة ديلوكس')
    expect(target!.grandTotalCents).toBe(AHMED_GRAND) // 55200
    expect(target!.paidCents).toBe(AHMED_DEPOSIT) // 27600
    expect(target!.hasStay).toBe(false)
  }, 30_000)

  it('check-in بغرفة متاحة (202) → 200 + كود ضيف خام يُعاد مرة واحدة (§12.4)', async () => {
    const res1 = await db.reservation.findUnique({ where: { bookingReference: 'HTL-2026-000421' } })
    const room202 = await db.room.findUnique({ where: { number: '202' } })
    const res = await postTo(
      checkInRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-in',
      { reservationId: res1!.id, roomId: room202!.id, idNumber: 'INT-H2B-1' },
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ stay: { id: string; reference: string }; roomNumber: string; guestCode: string; guestName: string; guestPhone: string }>(res)
    expect(j.stay.reference).toMatch(/^ST-\d{4}-\d{6}$/) // §12.6
    expect(j.roomNumber).toBe('202')
    expect(j.guestName).toBe('أحمد محمد')
    // §12.4: H + 6 أرقام + حرفا تحقق — خام مرة واحدة
    expect(j.guestCode).toMatch(/^H\d{6}[A-Z0-9]{2}$/)
    ahmed.stayId = j.stay.id
    ahmed.stayRef = j.stay.reference
    ahmed.guestCode = j.guestCode

    // القاعدة: إقامة ACTIVE + غرفة OCCUPIED + كود ACTIVE بهاش SHA-256 للكود الخام
    const stay = await db.stay.findUnique({ where: { id: ahmed.stayId } })
    expect(stay!.status).toBe('ACTIVE')
    expect(stay!.reservationId).toBe(res1!.id)
    const room = await db.room.findUnique({ where: { id: room202!.id } })
    expect(room!.status).toBe('OCCUPIED')
    const { hashCode } = await import('@/lib/codes')
    const code = await db.accessCode.findFirst({ where: { stayId: ahmed.stayId, type: 'GUEST' } })
    expect(code!.status).toBe('ACTIVE')
    expect(code!.codeHash).toBe(hashCode(ahmed.guestCode)) // الكود الخام لا يُخزن أبدًا
    expect(code!.codeMasked).toBe(`${ahmed.guestCode.slice(0, 2)}••••${ahmed.guestCode.slice(-2)}`) // قناع §12.4
  }, 30_000)

  it('الكود الجديد: validate به → 200 GUEST ويعمل على مسار محمي', async () => {
    const session = await loginAs(ahmed.guestCode)
    expect(session.role).toBe('GUEST')
    expect(session.name).toBe('أحمد محمد')
    ahmed.token = session.token

    const dash = await get(
      guestDashboardRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/dashboard',
      bearer(ahmed.token)
    )
    expect(dash.status).toBe(200)
    const j = await json<{ stay: { room: { number: string }; reference: string } }>(dash)
    expect(j.stay.room.number).toBe('202')
    expect(j.stay.reference).toBe(ahmed.stayRef)
  }, 30_000)

  it('الخروج: يُرفض مع رصيد → تسوية كاملة → 200 (رصيد صفر)', async () => {
    // رصيد أحمد = 55200 + 0 − 27600 = 27600
    // 1) رفض بلا تسوية
    const r1 = await postTo(
      checkOutRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-out',
      { stayId: ahmed.stayId },
      bearer(receptionToken)
    )
    expect(r1.status).toBe(400)
    const j1 = await json<{ balanceCents?: number }>(r1)
    expect(j1.error).toBe('يوجد رصيد غير مسدد $276.00 — سجّل دفعة أو أكّد الخروج مع الرصيد')
    expect(j1.balanceCents).toBe(AHMED_GRAND - AHMED_DEPOSIT) // 27600

    // 2) تسوية الرصيد بالكامل
    const pay = await postTo(
      paymentsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/payments',
      { stayId: ahmed.stayId, method: 'CARD', amountCents: AHMED_GRAND - AHMED_DEPOSIT },
      bearer(receptionToken)
    )
    expect(pay.status).toBe(200)
    const jpay = await json<{ paidCents: number; paymentStatus: string; balanceCents: number }>(pay)
    expect(jpay.paidCents).toBe(AHMED_GRAND) // 27600 + 27600
    expect(jpay.paymentStatus).toBe('PAID')
    expect(jpay.balanceCents).toBe(0)

    // 3) الخروج ينجح
    const r2 = await postTo(
      checkOutRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-out',
      { stayId: ahmed.stayId },
      bearer(receptionToken)
    )
    expect(r2.status).toBe(200)
    const j2 = await json<{ closed: boolean; roomNumber: string; balanceCents: number }>(r2)
    expect(j2.closed).toBe(true)
    expect(j2.roomNumber).toBe('202')
    expect(j2.balanceCents).toBe(0)
  }, 30_000)

  it('إغلاق الدورة (I11): الكود القديم مرفوض حرفيًا + التوكن القديم 401 + الغرفة DIRTY + الإقامة CLOSED في القاعدة', async () => {
    // I4/I11: الكود أصبح REVOKED → الرسالة الحرفية من فرع REVOKED في validate
    const res = await postTo(
      validateRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/auth/validate',
      { code: ahmed.guestCode }
    )
    expect(res.status).toBe(400)
    const j = await json(res)
    expect(j.error).toBe('تم إلغاء هذا الكود. تواصل مع إدارة الفندق')

    // التوكن القديم مات لحظيًا (الجلسات بُطلت مع الخروج)
    const dash = await get(
      guestDashboardRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/dashboard',
      bearer(ahmed.token)
    )
    expect(dash.status).toBe(401)
    const jdash = await json(dash)
    expect(jdash.error).toBe('جلسة غير صالحة أو منتهية — سجّل الدخول من جديد')

    // التحقق المباشر من القاعدة
    const stay = await db.stay.findUnique({ where: { id: ahmed.stayId } })
    expect(stay!.status).toBe('CLOSED')
    expect(stay!.actualCheckOutAt).not.toBeNull()
    const room202 = await db.room.findUnique({ where: { number: '202' } })
    expect(room202!.status).toBe('DIRTY')
    const codeRow = await db.accessCode.findFirst({ where: { stayId: ahmed.stayId, type: 'GUEST' } })
    expect(codeRow!.status).toBe('REVOKED')
    const sessions = await db.session.findMany({ where: { accessCode: { stayId: ahmed.stayId } } })
    expect(sessions.length).toBeGreaterThan(0)
    expect(sessions.every((s) => s.revoked)).toBe(true)
    const reservation = await db.reservation.findUnique({ where: { id: stay!.reservationId } })
    expect(reservation!.status).toBe('COMPLETED')
  }, 30_000)
})

// ─────────────────────────────────────────────────────────────
// H2.6 — الرحلة الذهبية: التكامل الكامل بأرقام محققة بالسنت
// (I6 · I8 · I10 · I11 · §12.2 · §12.4 · §12.6 — رحلة جديدة كليًا)
// ─────────────────────────────────────────────────────────────
describe('H2.6 — الرحلة الذهبية (التكامل الكامل بأرقام)', () => {
  // نافذة بلا نهاية أسبوع: أقرب أحد ≥ اليوم+1 → ليلتا أحد+اثنين بسعر أساسي صافٍ
  const goldenCheckIn = nextSunday(addDays(today, 1))
  const goldenCheckOut = addDays(goldenCheckIn, 2)
  const ci = isoDate(goldenCheckIn)
  const co = isoDate(goldenCheckOut)
  // مزدوجة ليلتان بلا زيادة نهاية أسبوع: 2 × 12000 = 24000 + 15% = 27600 (رقم بشري قابل للفحص)
  const expectedGolden = expectedQuote(goldenCheckIn, goldenCheckOut, BASE.double, 1)
  const CHARGE = 2500 // رسم إضافي من الاستقبال (خطوة f)

  it('a) availability → المزدوجة متاحة والسعر مطابق للمحسوب (نافذة أحد/اثنين بلا زيادة نهاية أسبوع)', async () => {
    expect(expectedGolden.nightly.every((n) => n.priceCents === BASE.double)).toBe(true) // سلامة النافذة
    expect(expectedGolden.grandTotalCents).toBe(27600)

    const res = await postTo(
      availabilityRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/availability',
      { checkIn: ci, checkOut: co, adults: 2, children: 0, roomsCount: 1 }
    )
    expect(res.status).toBe(200)
    const j = await json<{ items: AvailabilityItemShape[] }>(res)
    const double = j.items.find((i) => i.roomType.name === 'غرفة مزدوجة')
    expect(double).toBeDefined()
    expect(double!.availableCount).toBeGreaterThanOrEqual(1)
    expect(double!.quote).toEqual(expectedGolden)
  }, 30_000)

  it('b) حجز PAY_AT_HOTEL باسم/هاتف جديدين → 201 + مرجع + totals بالسنت (I6)', async () => {
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: ci,
        checkOut: co,
        adults: 2,
        children: 0,
        roomsCount: 1,
        roomTypeId: doubleType!.id,
        guest: { fullName: 'ضيف الرحلة الذهبية', phone: '+967778999001', email: 'golden@example.com' },
        specialRequests: 'اختبار الرحلة الذهبية المتكاملة',
        paymentMethod: 'PAY_AT_HOTEL',
        idempotencyKey: 'integration-golden-1', // I8 يُفعَّل من أول نداء
      }
    )
    expect(res.status).toBe(201)
    const j = await json<{ reservation: ReservationPublicShape }>(res)
    expect(j.reservation.bookingReference).toMatch(/^HTL-\d{4}-\d{6}$/) // §12.6
    expect(j.reservation.grandTotalCents).toBe(expectedGolden.grandTotalCents) // 27600
    expect(j.reservation.subtotalCents).toBe(expectedGolden.subtotalCents) // 24000
    expect(j.reservation.taxCents).toBe(expectedGolden.taxCents) // 3600
    expect(j.reservation.paidCents).toBe(0)
    expect(j.reservation.paymentStatus).toBe('UNPAID')
    golden = {
      booking: j.reservation,
      checkInDate: ci,
      nights: expectedGolden.nights,
      expectedGrand: expectedGolden.grandTotalCents,
      stayId: '',
      stayRef: '',
      guestCode: '',
      guestToken: '',
      roomNumber: '',
      requestId: '',
      requestRef: '',
      chargeCents: CHARGE,
      paymentCents: expectedGolden.grandTotalCents + CHARGE,
    }
  }, 30_000)

  it('c) الاستقبال يرى الحجز في arrivals بتاريخه → check-in بغرفة متاحة → كود ضيف خام', async () => {
    const res = await get(
      arrivalsRoute.GET as unknown as (r: Request) => Promise<Response>,
      `http://localhost/api/reception/arrivals?date=${ci}`,
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ arrivals: Array<{ bookingReference: string; grandTotalCents: number }> }>(res)
    const target = j.arrivals.find((a) => a.bookingReference === golden!.booking.bookingReference)
    expect(target).toBeDefined()
    expect(target!.grandTotalCents).toBe(golden!.expectedGrand)

    // غرفة مزدوجة متاحة: 104 (103 DIRTY بعد خروج نورا · 106 DIRTY من seed)
    const room104 = await db.room.findUnique({ where: { number: '104' } })
    expect(room104!.status).toBe('AVAILABLE')
    const ciRes = await postTo(
      checkInRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-in',
      { reservationId: golden!.booking.id, roomId: room104!.id },
      bearer(receptionToken)
    )
    expect(ciRes.status).toBe(200)
    const ciJ = await json<{ stay: { id: string; reference: string }; roomNumber: string; guestCode: string; guestName: string }>(ciRes)
    expect(ciJ.roomNumber).toBe('104')
    expect(ciJ.guestCode).toMatch(/^H\d{6}[A-Z0-9]{2}$/) // §12.4
    expect(ciJ.guestName).toBe('ضيف الرحلة الذهبية')
    golden!.stayId = ciJ.stay.id
    golden!.stayRef = ciJ.stay.reference
    golden!.guestCode = ciJ.guestCode
    golden!.roomNumber = '104'
  }, 30_000)

  it('d) دخول الضيف بالكود الجديد → dashboard 200 + رقم الغرفة + الرصيد الافتتاحي', async () => {
    const session = await loginAs(golden!.guestCode)
    expect(session.role).toBe('GUEST')
    expect(session.name).toBe('ضيف الرحلة الذهبية')
    golden!.guestToken = session.token

    const res = await get(
      guestDashboardRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/dashboard',
      bearer(golden!.guestToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{
      stay: { id: string; reference: string; room: { number: string }; reservation: { grandTotalCents: number; paidCents: number } }
      balanceCents: number
      chargesCents: number
      currency: string
      activeRequests: number
    }>(res)
    expect(j.stay.id).toBe(golden!.stayId)
    expect(j.stay.room.number).toBe('104')
    expect(j.stay.reservation.grandTotalCents).toBe(golden!.expectedGrand)
    expect(j.stay.reservation.paidCents).toBe(0)
    expect(j.balanceCents).toBe(golden!.expectedGrand) // لا بنود ولا مدفوعات بعد
    expect(j.chargesCents).toBe(0)
    expect(j.currency).toBe('USD')
  }, 30_000)

  it('e) طلب خدمة من الضيف → 201 → الاستقبال يراه ويحوّل حالته ACKNOWLEDGED → IN_PROGRESS → COMPLETE', async () => {
    // الضيف ينشئ الطلب
    const create = await postTo(
      guestRequestsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/requests',
      {
        category: 'GUEST_SERVICES',
        title: 'مناشف إضافية — رحلة ذهبية',
        description: 'طلب اختباري ضمن الرحلة الذهبية',
        priority: 'NORMAL',
      },
      bearer(golden!.guestToken)
    )
    expect(create.status).toBe(201)
    const cj = await json<{ request: { id: string; reference: string; status: string; roomNumber: string; updates: { status: string }[] } }>(create)
    expect(cj.request.status).toBe('NEW')
    expect(cj.request.reference).toMatch(/^REQ-\d+$/) // §12.6
    expect(cj.request.roomNumber).toBe('104')
    expect(cj.request.updates).toHaveLength(1) // NEW فقط
    golden!.requestId = cj.request.id
    golden!.requestRef = cj.request.reference

    // الاستقبال يراه في قائمته
    const list = await get(
      receptionRequestsRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/requests?status=NEW',
      bearer(receptionToken)
    )
    expect(list.status).toBe(200)
    const lj = await json<{ requests: Array<{ id: string; reference: string; status: string; stay: { roomNumber: string; guestName: string } }> }>(list)
    const seen = lj.requests.find((r) => r.id === golden!.requestId)
    expect(seen).toBeDefined()
    expect(seen!.status).toBe('NEW')
    expect(seen!.stay.roomNumber).toBe('104')
    expect(seen!.stay.guestName).toBe('ضيف الرحلة الذهبية')

    // الانتقالات حتى COMPLETE
    const statusHandler = requestStatusRoute.POST as unknown as (
      r: Request,
      ctx: { params: Promise<{ id: string }> }
    ) => Promise<Response>
    const transitions: Array<{ status: string; note: string }> = [
      { status: 'ACKNOWLEDGED', note: 'استلمنا الطلب' },
      { status: 'IN_PROGRESS', note: 'جارٍ التنفيذ' },
      { status: 'COMPLETED', note: 'تم التنفيذ بالكامل' },
    ]
    for (const t of transitions) {
      const r = await postTo(
        statusHandler,
        `http://localhost/api/reception/requests/${golden!.requestId}/status`,
        { status: t.status, note: t.note, assignedTo: 'فريق الاختبار' },
        bearer(receptionToken),
        { id: golden!.requestId }
      )
      expect(r.status).toBe(200)
      const tj = await json<{ request: { status: string; completedAt: string | null } }>(r)
      expect(tj.request.status).toBe(t.status)
      if (t.status === 'COMPLETED') expect(tj.request.completedAt).not.toBeNull()
    }

    // الحالة النهائية في القاعدة + الخط الزمني الكامل (NEW + 3)
    const row = await db.serviceRequest.findUnique({
      where: { id: golden!.requestId },
      include: { updates: true },
    })
    expect(row!.status).toBe('COMPLETED')
    expect(row!.completedAt).not.toBeNull()
    expect(row!.updates.map((u) => u.status)).toEqual(['NEW', 'ACKNOWLEDGED', 'IN_PROGRESS', 'COMPLETED'])

    // الطرفية محمية: تعديل بعد الاكتمال → 400 بالرسالة الحرفية
    const again = await postTo(
      statusHandler,
      `http://localhost/api/reception/requests/${golden!.requestId}/status`,
      { status: 'IN_PROGRESS' },
      bearer(receptionToken),
      { id: golden!.requestId }
    )
    expect(again.status).toBe(400)
    const aj = await json(again)
    expect(aj.error).toBe('لا يمكن تعديل طلب منتهٍ')
  }, 60_000)

  it('f) رسم إضافي + دفعة تغطي الرصيد بالكامل → grand + charge − payments = 0 بالسنت', async () => {
    // رسم من الاستقبال
    const charge = await postTo(
      chargesRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/charges',
      { stayId: golden!.stayId, description: 'خدمة خاصة — رحلة ذهبية', amountCents: CHARGE, category: 'EXTRA' },
      bearer(receptionToken)
    )
    expect(charge.status).toBe(200)
    const chj = await json<{ charge: { amountCents: number }; balanceCents: number }>(charge)
    expect(chj.charge.amountCents).toBe(CHARGE)
    expect(chj.balanceCents).toBe(golden!.expectedGrand + CHARGE) // 27600 + 2500 = 30100

    // دفعة تغطي كل شيء
    const pay = await postTo(
      paymentsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/payments',
      { stayId: golden!.stayId, method: 'TRANSFER', amountCents: golden!.expectedGrand + CHARGE, note: 'تسوية كاملة قبل الخروج' },
      bearer(receptionToken)
    )
    expect(pay.status).toBe(200)
    const pj = await json<{ paidCents: number; paymentStatus: string; balanceCents: number }>(pay)
    expect(pj.paidCents).toBe(golden!.expectedGrand + CHARGE)
    expect(pj.paymentStatus).toBe('PAID')
    expect(pj.balanceCents).toBe(0)

    // فاتورة الضيف بالمعادلة الكاملة §12.2
    const bill = await get(
      guestBillRoute.GET as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/guest/bill',
      bearer(golden!.guestToken)
    )
    const bj = await json<{ bill: BillShape }>(bill)
    expect(bj.bill.roomTotalCents).toBe(golden!.expectedGrand)
    expect(bj.bill.extraTotalCents).toBe(CHARGE)
    expect(bj.bill.totalPaidCents).toBe(golden!.expectedGrand + CHARGE)
    expect(bj.bill.balanceCents).toBe(0)
    expect(bj.bill.roomTotalCents + bj.bill.extraTotalCents - bj.bill.totalPaidCents).toBe(0)
  }, 30_000)

  it('g) الخروج → 200 → تحقق نهائي شامل من القاعدة: CLOSED + DIRTY + REVOKED + جلسات مبطلة + المالية النهائية', async () => {
    const res = await postTo(
      checkOutRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/reception/check-out',
      { stayId: golden!.stayId },
      bearer(receptionToken)
    )
    expect(res.status).toBe(200)
    const j = await json<{ closed: boolean; roomNumber: string; balanceCents: number }>(res)
    expect(j.closed).toBe(true)
    expect(j.roomNumber).toBe('104')
    expect(j.balanceCents).toBe(0)

    // القاعدة مباشرة
    const stay = await db.stay.findUnique({
      where: { id: golden!.stayId },
      include: { reservation: true },
    })
    expect(stay!.status).toBe('CLOSED')
    expect(stay!.actualCheckOutAt).not.toBeNull()
    expect(stay!.reservation.status).toBe('COMPLETED')
    // الحالة المالية النهائية: paid = grand + charges (الدفع غطى كل شيء)
    expect(stay!.reservation.paidCents).toBe(golden!.expectedGrand + CHARGE)
    expect(stay!.reservation.paymentStatus).toBe('PAID')

    const room104 = await db.room.findUnique({ where: { number: '104' } })
    expect(room104!.status).toBe('DIRTY')

    const code = await db.accessCode.findFirst({ where: { stayId: golden!.stayId, type: 'GUEST' } })
    expect(code!.status).toBe('REVOKED') // I11

    const sessions = await db.session.findMany({ where: { accessCode: { stayId: golden!.stayId } } })
    expect(sessions.length).toBeGreaterThan(0)
    expect(sessions.every((s) => s.revoked)).toBe(true) // الجلسات مُبطلة

    // رصيد نهائي صفري من القاعدة مباشرة
    const chargesAgg = await db.charge.aggregate({ _sum: { amountCents: true }, where: { stayId: golden!.stayId } })
    expect(stay!.reservation.grandTotalCents + (chargesAgg._sum.amountCents ?? 0) - stay!.reservation.paidCents).toBe(0)
  }, 30_000)

  it('h) سجل التدقيق (I10): أحداث موثقة للعمليات الحرجة — check-in/check-out/دفع/رسم/كود/طلب', async () => {
    const critical = await db.auditLog.findMany({
      where: {
        action: {
          in: [
            'RESERVATION_CREATED',
            'CHECK_IN',
            'CODE_GENERATED',
            'REQUEST_CREATED',
            'REQUEST_UPDATED',
            'CHARGE_ADDED',
            'PAYMENT_RECORDED',
            'CHECK_OUT',
          ],
        },
        createdAt: { gte: addDays(today, 0) }, // أحداث هذه الجلسة (اليوم)
      },
      orderBy: { createdAt: 'asc' },
    })
    const byAction = (action: string) => critical.filter((l) => l.action === action)

    // كلها تخص رحلتنا الذهبية (المعرفات المرجعية)
    expect(byAction('CHECK_IN').some((l) => l.entityId === golden!.stayId)).toBe(true)
    expect(byAction('CHECK_OUT').some((l) => l.entityId === golden!.stayId)).toBe(true)
    expect(byAction('CODE_GENERATED').some((l) => l.entityId === golden!.stayId)).toBe(true)
    const payment = await db.payment.findFirst({ where: { stayId: golden!.stayId } })
    expect(byAction('PAYMENT_RECORDED').some((l) => l.entityId === payment!.id)).toBe(true)
    const charge = await db.charge.findFirst({ where: { stayId: golden!.stayId } })
    expect(byAction('CHARGE_ADDED').some((l) => l.entityId === charge!.id)).toBe(true)
    expect(byAction('REQUEST_CREATED').some((l) => l.entityId === golden!.requestId)).toBe(true)
    expect(byAction('REQUEST_UPDATED').some((l) => l.entityId === golden!.requestId)).toBe(true)
    const reservationCreated = byAction('RESERVATION_CREATED').find((l) =>
      (l.details ?? '').includes(golden!.booking.bookingReference)
    )
    expect(reservationCreated).toBeDefined()

    // I10: التدقيق يوثق الفاعل والمبلغ للدفع الحرج
    const payAudit = byAction('PAYMENT_RECORDED').find((l) => l.entityId === payment!.id)
    expect(payAudit!.actor).toBe('أحمد الاستقبال') // من جلسة R492671M3
    expect(payAudit!.actorRole).toBe('RECEPTION')
    expect(payAudit!.details).toContain(String(golden!.expectedGrand + CHARGE))
  }, 30_000)
})

// ─────────────────────────────────────────────────────────────
// المسار C — تعديل الحجز المؤهل (REQ-01): POST /api/public/edit
// «المؤهل» = CONFIRMED + قبل (الوصول − 24 ساعة) + بلا إقامة
// الثوابت المغطاة: I1/I7 (توفر مع استثناء الذات داخل المعاملة) ·
// I6 (لقطة سعر جديدة بالسنت) · I10 (تدقيق قبل/بعد) · §12.2 (إعادة
// تسعير خادمية حتمية) · لا كشف وجود الحجز عند فشل التحقق
// ─────────────────────────────────────────────────────────────
describe('المسار C — تعديل الحجز المؤهل (REQ-01)', () => {
  // نطاقات بعيدة عن كل حجوزات seed واختبارات H2.3 (التي تملأ المفردة
  // في [اليوم+10، اليوم+12) والرحلة الذهبية بعد الأحد القادم)
  const D1 = addDays(today, 40) // وصول حجز A
  const D2 = addDays(today, 50) // وصول حجزي B/C (امتلاء المفردة)
  let bookingA: ReservationPublicShape | null = null
  const phoneA = '+967775000111'

  /** إنشاء حجز مؤكد عبر بوابة الموقع (نفس بوابة الإنتاج) */
  async function createBooking(opts: {
    checkIn: Date
    checkOut: Date
    typeName: string
    phone: string
    paymentMethod?: string
    adults?: number
    roomsCount?: number
  }): Promise<ReservationPublicShape> {
    const t = await db.roomType.findFirst({ where: { name: opts.typeName } })
    const res = await postTo(
      bookingsRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/bookings',
      {
        checkIn: isoDate(opts.checkIn),
        checkOut: isoDate(opts.checkOut),
        adults: opts.adults ?? 1,
        children: 0,
        roomsCount: opts.roomsCount ?? 1,
        roomTypeId: t!.id,
        guest: { fullName: `ضيف التعديل ${opts.phone}`, phone: opts.phone },
        paymentMethod: opts.paymentMethod ?? 'PAY_AT_HOTEL',
      }
    )
    expect(res.status).toBe(201)
    const j = await json<{ reservation: ReservationPublicShape }>(res)
    expect(j.ok).toBe(true)
    return j.reservation
  }

  /** نداء تعديل */
  async function callEdit(body: Record<string, unknown>): Promise<Response> {
    return postTo(
      editRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/edit',
      body
    )
  }

  it('c1) تعديل المواعيد (تمديد الليلات): إعادة تسعير خادمية + لقطة جديدة + تدقيق قبل/بعد + إشعار استقبال', async () => {
    bookingA = await createBooking({ checkIn: D1, checkOut: addDays(D1, 2), typeName: 'غرفة مفردة', phone: phoneA })
    const oldGrand = bookingA!.grandTotalCents

    const notifBefore = await db.notification.count({ where: { audience: 'RECEPTION' } })

    // تمديد: ليلتان → ثلاث ليالٍ (نفس النوع)
    const res = await callEdit({
      reference: bookingA!.bookingReference,
      phone: phoneA,
      checkIn: isoDate(D1),
      checkOut: isoDate(addDays(D1, 3)),
      roomTypeId: (await db.roomType.findFirst({ where: { name: 'غرفة مفردة' } }))!.id,
      adults: 1,
      children: 0,
      roomsCount: 1,
      specialRequests: 'طابق مرتفع',
    })
    expect(res.status).toBe(200)
    const j = await json<{ reservation: ReservationPublicShape; snapshot: { nightly: { date: string }[]; grandTotalCents: number } | null; cancellation: { refundable: boolean } }>(res)
    expect(j.ok).toBe(true)

    // §12.2 + I6: الإجمالي الجديد = المحسوب المستقل بالسنت
    const expected = expectedQuote(D1, addDays(D1, 3), BASE.single, 1)
    expect(j.reservation.grandTotalCents).toBe(expected.grandTotalCents)
    expect(j.reservation.subtotalCents).toBe(expected.subtotalCents)
    expect(j.reservation.taxCents).toBe(expected.taxCents)
    expect(j.reservation.nights).toBe(3)
    expect(j.reservation.specialRequests).toBe('طابق مرتفع')
    expect(j.cancellation.refundable).toBe(true)

    // اللقطة الجديدة مبنية على النطاق الجديد
    expect(j.snapshot).not.toBeNull()
    expect(j.snapshot!.nightly).toHaveLength(3)

    // القاعدة: الصف الفعلي بلقطة وأرقام جديدة
    const row = await db.reservation.findUnique({ where: { id: bookingA!.id } })
    expect(row!.grandTotalCents).toBe(expected.grandTotalCents)
    const snap = JSON.parse(row!.priceSnapshot) as { nightly: unknown[]; grandTotalCents: number; roomsCount: number }
    expect(snap.nightly).toHaveLength(3)
    expect(snap.grandTotalCents).toBe(expected.grandTotalCents)
    expect(snap.roomsCount).toBe(1)

    // I10: تدقيق RESERVATION_MODIFIED بقبل/بعد
    const log = await db.auditLog.findFirst({
      where: { action: 'RESERVATION_MODIFIED', entityId: bookingA!.id },
      orderBy: { createdAt: 'desc' },
    })
    expect(log).not.toBeNull()
    expect(log!.actorRole).toBe('WEBSITE')
    const details = JSON.parse(log!.details as string) as {
      reference: string
      before: { grandTotalCents: number; checkIn: string }
      after: { grandTotalCents: number; checkIn: string }
      paidCents: number
    }
    expect(details.reference).toBe(bookingA!.bookingReference)
    expect(details.before.grandTotalCents).toBe(oldGrand)
    expect(details.after.grandTotalCents).toBe(expected.grandTotalCents)
    expect(details.paidCents).toBe(0)

    // إشعار استقبال جديد
    const notifAfter = await db.notification.count({ where: { audience: 'RECEPTION' } })
    expect(notifAfter).toBe(notifBefore + 1)
  }, 30_000)

  it('c2) تعديل نوع الغرفة: نقل الحجز للمفردة→الديلوكس وتحرير المفردة للتوفر العام', async () => {
    // A الآن مفردة [D1, D1+3) — التوفر العام للمفردة = 1 (غرفتان − حجز A)
    const before = await availabilityRoute.POST as unknown as (r: Request) => Promise<Response>
    const availRes = await postTo(before, 'http://localhost/api/public/availability', {
      checkIn: isoDate(D1), checkOut: isoDate(addDays(D1, 3)), adults: 1, children: 0, roomsCount: 1,
    })
    const availJ = await json<{ items: { roomType: { name: string }; availableCount: number }[] }>(availRes)
    const singleBefore = availJ.items.find((i) => i.roomType.name === 'غرفة مفردة')!
    const deluxeBefore = availJ.items.find((i) => i.roomType.name === 'غرفة ديلوكس')!
    expect(singleBefore.availableCount).toBe(1)
    expect(deluxeBefore.availableCount).toBe(5)

    // تعديل A: مفردة → ديلوكس (نفس المواعيد)
    const deluxeType = await db.roomType.findFirst({ where: { name: 'غرفة ديلوكس' } })
    const res = await callEdit({
      reference: bookingA!.bookingReference,
      phone: phoneA,
      checkIn: isoDate(D1),
      checkOut: isoDate(addDays(D1, 3)),
      roomTypeId: deluxeType!.id,
      adults: 2,
      children: 0,
      roomsCount: 1,
      specialRequests: '',
    })
    expect(res.status).toBe(200)
    const j = await json<{ reservation: ReservationPublicShape }>(res)
    expect(j.reservation.roomType.name).toBe('غرفة ديلوكس')
    const expected = expectedQuote(D1, addDays(D1, 3), BASE.deluxe, 1)
    expect(j.reservation.grandTotalCents).toBe(expected.grandTotalCents)

    // بعد النقل: المفردة حرة كاملة (2) والديلوكس نقصت (3)
    const avail2 = await postTo(before, 'http://localhost/api/public/availability', {
      checkIn: isoDate(D1), checkOut: isoDate(addDays(D1, 3)), adults: 1, children: 0, roomsCount: 1,
    })
    const avail2J = await json<{ items: { roomType: { name: string }; availableCount: number }[] }>(avail2)
    expect(avail2J.items.find((i) => i.roomType.name === 'غرفة مفردة')!.availableCount).toBe(2)
    expect(avail2J.items.find((i) => i.roomType.name === 'غرفة ديلوكس')!.availableCount).toBe(4)
  }, 30_000)

  it('c3) معاينة التوفر بالاستثناء الذاتي: reference+phone صحيحان يحرران غرف الحجز نفسه (وفشل التحقق يُتجاهل بصمت)', async () => {
    const handler = availabilityRoute.POST as unknown as (r: Request) => Promise<Response>
    const body = { checkIn: isoDate(D1), checkOut: isoDate(addDays(D1, 3)), adults: 1, children: 0, roomsCount: 1 }

    // بدون مرجع → الديلوكس 4 (حجز A محسوب)
    const plain = await json<{ items: { roomType: { name: string }; availableCount: number }[] }>(
      await postTo(handler, 'http://localhost/api/public/availability', body)
    )
    expect(plain.items.find((i) => i.roomType.name === 'غرفة ديلوكس')!.availableCount).toBe(4)

    // بمرجع + هاتف A → A مستثنى → 5
    const own = await json<{ items: { roomType: { name: string }; availableCount: number }[] }>(
      await postTo(handler, 'http://localhost/api/public/availability', {
        ...body, reference: bookingA!.bookingReference, phone: phoneA,
      })
    )
    expect(own.items.find((i) => i.roomType.name === 'غرفة ديلوكس')!.availableCount).toBe(5)

    // بمرجع A وهاتف خاطئ → لا استثناء ولا كشف (4 كما هي)
    const wrong = await json<{ items: { roomType: { name: string }; availableCount: number }[] }>(
      await postTo(handler, 'http://localhost/api/public/availability', {
        ...body, reference: bookingA!.bookingReference, phone: '+967775000999',
      })
    )
    expect(wrong.items.find((i) => i.roomType.name === 'غرفة ديلوكس')!.availableCount).toBe(4)
  }, 30_000)

  it('c4) I7-مجاور: تعديل «إلى نفس القيم» على مخزون ممتلئ لا يُغلق على نفسه (استثناء الذات داخل المعاملة)', async () => {
    // B و C يملآن المفردة في [D2, D2+2)
    const b = await createBooking({ checkIn: D2, checkOut: addDays(D2, 2), typeName: 'غرفة مفردة', phone: '+967775000222' })
    await createBooking({ checkIn: D2, checkOut: addDays(D2, 2), typeName: 'غرفة مفردة', phone: '+967775000333' })

    // التوفر العام صفر — لكن تعديل B «إلى نفس النطاق/النوع» يجب أن ينجح
    const singleType = await db.roomType.findFirst({ where: { name: 'غرفة مفردة' } })
    const res = await callEdit({
      reference: b.bookingReference,
      phone: '+967775000222',
      checkIn: isoDate(D2),
      checkOut: isoDate(addDays(D2, 2)),
      roomTypeId: singleType!.id,
      adults: 1,
      children: 0,
      roomsCount: 1,
      specialRequests: 'ملاحظة معدلة على مخزون ممتلئ',
    })
    expect(res.status).toBe(200)
    const j = await json<{ reservation: ReservationPublicShape }>(res)
    expect(j.reservation.specialRequests).toBe('ملاحظة معدلة على مخزون ممتلئ')

    // لا يزال بإمكان B الهروب لمواعيد أخرى (المخزون الحر)
    const escape = await callEdit({
      reference: b.bookingReference,
      phone: '+967775000222',
      checkIn: isoDate(addDays(D2, 5)),
      checkOut: isoDate(addDays(D2, 7)),
      roomTypeId: singleType!.id,
      adults: 1,
      children: 0,
      roomsCount: 1,
      specialRequests: '',
    })
    expect(escape.status).toBe(200)
  }, 30_000)

  it('c5) I1: التعديل إلى نطاق ممتلئ فوق المخزون → 409 برسالة التوفر (بلا كتابة)', async () => {
    // B هرب في c4 → C وحده في [D2, D2+2) → المفردة متاحة 1… نملؤها بحجز جديد
    await createBooking({ checkIn: D2, checkOut: addDays(D2, 2), typeName: 'غرفة مفردة', phone: '+967775000444' })
    // الآن [D2, D2+2) ممتلئة تمامًا (C + الجديد = 2/2)

    // حجز A (ديلوكس حاليًا) → محاولة الانتقال للمفردة في النطاق الممتلئ
    const before = await db.reservation.findUnique({ where: { id: bookingA!.id } })
    const singleType = await db.roomType.findFirst({ where: { name: 'غرفة مفردة' } })
    const res = await callEdit({
      reference: bookingA!.bookingReference,
      phone: phoneA,
      checkIn: isoDate(D2),
      checkOut: isoDate(addDays(D2, 2)),
      roomTypeId: singleType!.id,
      adults: 1,
      children: 0,
      roomsCount: 1,
      specialRequests: '',
    })
    expect(res.status).toBe(409)
    const j = await json<{ error?: string }>(res)
    expect(j.error).toContain('لم تعد متاحة')

    // لا كتابة حدثت — الحجز كما كان
    const after = await db.reservation.findUnique({ where: { id: bookingA!.id } })
    expect(after!.roomTypeId).toBe(before!.roomTypeId)
    expect(after!.checkIn.getTime()).toBe(before!.checkIn.getTime())
    expect(after!.grandTotalCents).toBe(before!.grandTotalCents)
  }, 30_000)

  it('c6) المدفوع يُنقل كما هو: حجز CARD بعربون → تعديل أرخص → paidCents ثابت وpaymentStatus محسوب (بلا حركات مالية وهمية)', async () => {
    // عائلي ليلتان بعربون 50% ثم تعديل إلى مفردة أرخص → مدفوع > الإجمالي الجديد
    const g = await createBooking({
      checkIn: D1, checkOut: addDays(D1, 2), typeName: 'الجناح العائلي',
      phone: '+967775000555', paymentMethod: 'CARD', adults: 2,
    })
    const oldGrand = g.grandTotalCents
    expect(g.paidCents).toBe(Math.round(oldGrand / 2))
    expect(g.paymentStatus).toBe('PARTIALLY_PAID')

    const singleType = await db.roomType.findFirst({ where: { name: 'غرفة مفردة' } })
    const res = await callEdit({
      reference: g.bookingReference,
      phone: '+967775000555',
      checkIn: isoDate(D1),
      checkOut: isoDate(addDays(D1, 2)),
      roomTypeId: singleType!.id,
      adults: 1,
      children: 0,
      roomsCount: 1,
      specialRequests: '',
    })
    expect(res.status).toBe(200)
    const j = await json<{ reservation: ReservationPublicShape }>(res)

    // المدفوع كما هو — لا صفوف دفع جديدة (المدفوع = ΣCOMPLETED كما كان)
    expect(j.reservation.paidCents).toBe(Math.round(oldGrand / 2))
    const payments = await db.payment.findMany({ where: { reservationId: g.id } })
    expect(payments).toHaveLength(1) // العربون الأصلي فقط
    expect(payments[0].status).toBe('COMPLETED')

    // الإجمالي الجديد (مفردة أرخص) أقل من المدفوع → الحجز مغطى
    const expected = expectedQuote(D1, addDays(D1, 2), BASE.single, 1)
    expect(j.reservation.grandTotalCents).toBe(expected.grandTotalCents)
    expect(j.reservation.paidCents).toBeGreaterThan(j.reservation.grandTotalCents)
    expect(j.reservation.paymentStatus).toBe('PAID')
  }, 30_000)

  it('c7) حراس الأهلية: خارج نافذة الـ24 ساعة → 400 · هاتف خاطئ → 404 بلا كشف · بلا تغييرات → 400', async () => {
    // حجز وصوله اليوم → نافذة التعديل المجاني فائتة
    const todayBooking = await createBooking({
      checkIn: today, checkOut: addDays(today, 2), typeName: 'غرفة مزدوجة', phone: '+967775000666',
    })
    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const late = await callEdit({
      reference: todayBooking.bookingReference,
      phone: '+967775000666',
      checkIn: isoDate(today),
      checkOut: isoDate(addDays(today, 3)),
      roomTypeId: doubleType!.id,
      adults: 1, children: 0, roomsCount: 1, specialRequests: '',
    })
    expect(late.status).toBe(400)
    expect((await json<{ error?: string }>(late)).error).toContain('مهلة التعديل المجاني')

    // هاتف خاطئ → نفس رسالة عدم العثور (بلا كشف وجود الحجز)
    const wrongPhone = await callEdit({
      reference: bookingA!.bookingReference,
      phone: '+967779999999',
      checkIn: isoDate(D1),
      checkOut: isoDate(addDays(D1, 4)),
      roomTypeId: doubleType!.id,
      adults: 1, children: 0, roomsCount: 1, specialRequests: '',
    })
    expect(wrongPhone.status).toBe(404)
    expect((await json<{ error?: string }>(wrongPhone)).error).toContain('لم نتمكن من التحقق')

    // بلا تغييرات → 400
    const aRow = await db.reservation.findUnique({ where: { id: bookingA!.id }, include: { roomType: true } })
    const noChange = await callEdit({
      reference: bookingA!.bookingReference,
      phone: phoneA,
      checkIn: isoDate(new Date(aRow!.checkIn)),
      checkOut: isoDate(new Date(aRow!.checkOut)),
      roomTypeId: aRow!.roomTypeId,
      adults: aRow!.adults, children: aRow!.children, roomsCount: aRow!.roomsCount,
      specialRequests: aRow!.specialRequests ?? '',
    })
    expect(noChange.status).toBe(400)
    expect((await json<{ error?: string }>(noChange)).error).toContain('لم تقم بأي تعديل')
  }, 30_000)

  it('c8) حجز ملغى/مقيم غير قابل للتعديل → 400 (الحالة)', async () => {
    // إلغاء حجز اليوم (مجاني لأنه فات النافذة؟ الإلغاء يسمح PENDING/CONFIRMED — يلغى برسوم)
    const cancelRoute = await import('@/app/api/public/cancel/route')
    const todayBooking2 = await createBooking({
      checkIn: today, checkOut: addDays(today, 2), typeName: 'غرفة مزدوجة', phone: '+967775000777',
    })
    const cancelled = await postTo(
      cancelRoute.POST as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/public/cancel',
      { reference: todayBooking2.bookingReference, phone: '+967775000777' }
    )
    expect(cancelled.status).toBe(200)

    const doubleType = await db.roomType.findFirst({ where: { name: 'غرفة مزدوجة' } })
    const res = await callEdit({
      reference: todayBooking2.bookingReference,
      phone: '+967775000777',
      checkIn: isoDate(today),
      checkOut: isoDate(addDays(today, 3)),
      roomTypeId: doubleType!.id,
      adults: 1, children: 0, roomsCount: 1, specialRequests: '',
    })
    expect(res.status).toBe(400)
    expect((await json<{ error?: string }>(res)).error).toContain('حالته الحالية')

    // حجز خالد CHECKED_IN (seed) → غير قابل للتعديل
    const khaled = await db.reservation.findFirst({ where: { bookingReference: 'HTL-2026-000415' }, include: { guest: true } })
    const khaledRes = await callEdit({
      reference: 'HTL-2026-000415',
      phone: khaled!.guest.phone,
      checkIn: isoDate(new Date(khaled!.checkIn)),
      checkOut: isoDate(addDays(new Date(khaled!.checkIn), 5)),
      roomTypeId: doubleType!.id,
      adults: 2, children: 0, roomsCount: 1, specialRequests: '',
    })
    expect(khaledRes.status).toBe(400)
    expect((await json<{ error?: string }>(khaledRes)).error).toContain('حالته الحالية')
  }, 30_000)
})

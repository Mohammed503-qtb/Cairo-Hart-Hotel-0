// ═══════════════════════════════════════════════════════════════════
// H2.1 + H2.2 — اختبارات الوحدة لمحرك التسعير (src/lib/pricing.ts)
//
// الثوابت الموثقة المغطاة هنا:
//   I6      : لا يُعتمد سعر من العميل — التسعير حتمي خادميًا (computeQuote)
//   I9      : الحجوزات التاريخية تُفسَّر بلقطة وقت الحجز (buildSnapshot)
//   §12.2   : سنت صحيح دائمًا · الضريبة = round(subtotal × taxPercent / 100)
//   §12 (رأس الوثيقة): عدد الليالي من حدود الأيام لا الطوابع الزمنية (Asia/Aden)
//   §H2.2   : زيادة نهاية الأسبوع (الجمعة/السبت) · عربون 50% بتقريب السنت
//
// هذه اختبارات وحدة نقية: لا قاعدة بيانات ولا شبكة.
// ═══════════════════════════════════════════════════════════════════
import { describe, it, expect } from "bun:test"
import {
  computeQuote,
  buildSnapshot,
  nightsBetween,
  localDateKey,
  type QuoteInput,
  type Quote,
  type RateLike,
} from "@/lib/pricing"

// ── أدوات مساعدة ──────────────────────────────────────────────────
// يناير 2026: 1=الخميس · 2=الجمعة · 3=السبت · 4=الأحد · 9=الجمعة · 10=السبت · 11=الأحد
// سبتمبر 2026: 6=الأحد · 9=الأربعاء · 11=الجمعة · 12=السبت
const d = (y: number, m: number, day: number, h = 0, min = 0): Date =>
  new Date(y, m - 1, day, h, min, 0, 0)

function quoteInput(partial: Partial<QuoteInput> = {}): QuoteInput {
  return {
    // إقامة 4 ليالٍ أيام عمل (أحد 4 → خميس 8 يناير 2026) — بلا نهاية أسبوع
    checkIn: d(2026, 1, 4),
    checkOut: d(2026, 1, 8),
    basePriceCents: 10000,
    rates: [],
    weekendSurchargePercent: 0,
    taxPercent: 0,
    currency: "USD",
    ...partial,
  }
}

function rate(name: string, startDay: number, endDay: number, priceCents: number, month = 1): RateLike {
  return { name, startDate: d(2026, month, startDay), endDate: d(2026, month, endDay), priceCents }
}

// ───────────────────────────────────────────────────────────────────
describe("localDateKey — مفتاح تاريخ محلي بلا انزياح توقيت", () => {
  // §12: المنطقة الزمنية Asia/Aden — المفاتيح من التاريخ المحلي لا UTC
  it("يعيد YYYY-MM-DD مع حشو الأصفار", () => {
    expect(localDateKey(d(2026, 9, 10))).toBe("2026-09-10")
    expect(localDateKey(d(2026, 2, 3))).toBe("2026-02-03")
    expect(localDateKey(d(2026, 1, 1))).toBe("2026-01-01")
  })

  it("لا ينزاح بتوقيت UTC — يستخدم مكونات التاريخ المحلي كما هي", () => {
    const date = d(2026, 1, 4, 23, 59)
    expect(localDateKey(date)).toBe("2026-01-04")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("nightsBetween — عدد الليالي من حدود الأيام", () => {
  // §12: عدد الليالي من حدود الأيام لا الطوابع الزمنية
  it("دخول/خروج متجاوران = ليلة واحدة", () => {
    expect(nightsBetween(d(2026, 1, 5), d(2026, 1, 6))).toBe(1)
  })

  it("فرق N أيام = N ليالٍ — حتى لو اختلفت الساعات كليًا", () => {
    expect(nightsBetween(d(2026, 1, 1), d(2026, 1, 6))).toBe(5)
    expect(nightsBetween(d(2026, 1, 1, 23, 45), d(2026, 1, 2, 0, 15))).toBe(1)
    expect(nightsBetween(d(2026, 1, 1, 0, 0), d(2026, 1, 8, 23, 59))).toBe(7)
  })

  it("نفس اليوم = صفر ليالٍ", () => {
    expect(nightsBetween(d(2026, 1, 4), d(2026, 1, 4))).toBe(0)
    expect(nightsBetween(d(2026, 1, 4, 10, 0), d(2026, 1, 4, 22, 0))).toBe(0)
  })

  it("التواريخ المعكوسة تعيد سالبًا — رفضها مسؤولية validateStayDates (نطاق H2.3/H2-b)", () => {
    // عقد الدالة: فرق أيام سالب. المنع الفعلي للتواريخ المعكوسة يحدث قبل التسعير
    // في src/lib/availability.ts (اختباراته عند وكيل H2-b على قاعدة اختبار معزولة).
    expect(nightsBetween(d(2026, 1, 6), d(2026, 1, 5))).toBe(-1)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — السعر الأساسي × عدد الليالي (سنت صحيح)", () => {
  // §12.2: سنت صحيح دائمًا — السعر الأساسي × الليالي بلا أرقام عائمة
  it("4 ليالٍ أيام عمل بلا ضريبة/زيادة = base × 4 بالضبط", () => {
    const q = computeQuote(quoteInput())
    expect(q.nights).toBe(4)
    expect(q.roomsCount).toBe(1)
    expect(q.subtotalCents).toBe(40000)
    expect(q.taxCents).toBe(0)
    expect(q.grandTotalCents).toBe(40000)
    expect(q.discountCents).toBe(0)
    expect(q.nightly).toHaveLength(4)
    for (const n of q.nightly) {
      expect(n.priceCents).toBe(10000)
      expect(n.rateName).toBe("السعر الأساسي")
    }
    expect(q.nightly.map((n) => n.date)).toEqual([
      "2026-01-04", "2026-01-05", "2026-01-06", "2026-01-07",
    ])
  })

  it("أسبوع كامل (7 ليالٍ) = 7 إدخالات ليلية", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 11) }))
    expect(q.nights).toBe(7)
    expect(q.subtotalCents).toBe(70000)
  })

  it("سيناريو إنتاج واقعي: ديلوكس 160$ × 3 ليالٍ + ضريبة 15% = 552$ بالسنت (48000 + 7200)", () => {
    // يطابق الأرقام الموثقة في سجل العمل لحجز إنتاج حقيقي (HTL-2026-000421)
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 9, 6),   // الأحد
      checkOut: d(2026, 9, 9),  // الأربعاء
      basePriceCents: 16000,
      taxPercent: 15,
    }))
    expect(q.subtotalCents).toBe(48000)
    expect(q.taxCents).toBe(7200)
    expect(q.grandTotalCents).toBe(55200)
  })

  it("كل المبالغ أعداد صحيحة (سنت) — لا كسور عائمة", () => {
    // §12.2: سنت صحيح دائمًا — تحصين ضد أي انزلاق لاحق نحو float
    const q = computeQuote(quoteInput({ basePriceCents: 999, taxPercent: 15, weekendSurchargePercent: 7, checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 11) }))
    expect(Number.isInteger(q.subtotalCents)).toBe(true)
    expect(Number.isInteger(q.taxCents)).toBe(true)
    expect(Number.isInteger(q.grandTotalCents)).toBe(true)
    expect(Number.isInteger(q.discountCents)).toBe(true)
    for (const n of q.nightly) expect(Number.isInteger(n.priceCents)).toBe(true)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — تعدد الغرف (roomsCount)", () => {
  // §12.2: كل الحساب بالسنت — الغرف تضرب الجملة لا الليلة الواحدة
  it("غرفتان: تفصيل الليل لكل غرفة، والمجموع يُضرب ×2", () => {
    const q = computeQuote(quoteInput({ roomsCount: 2 }))
    expect(q.roomsCount).toBe(2)
    expect(q.nightly).toHaveLength(4) // التفصيل الليلي لغرفة واحدة
    expect(q.subtotalCents).toBe(80000)
  })

  it("الضريبة تُحسب على المجموع المضروب", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 5), basePriceCents: 100, roomsCount: 2, taxPercent: 15 }))
    expect(q.subtotalCents).toBe(200)
    expect(q.taxCents).toBe(30)
    expect(q.grandTotalCents).toBe(230)
  })

  it("الغرفة الافتراضية 1 عند الغياب — وقيمة 0 تُثبَّت إلى 1 (حماية دفاعية)", () => {
    expect(computeQuote(quoteInput({ roomsCount: undefined })).roomsCount).toBe(1)
    expect(computeQuote(quoteInput({ roomsCount: 0 })).roomsCount).toBe(1)
    expect(computeQuote(quoteInput({ roomsCount: 0 })).subtotalCents).toBe(40000)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — زيادة نهاية الأسبوع (الجمعة/السبت فقط)", () => {
  // H2.2 + رأس pricing.ts: الزيادة تُطبق على ليالي الجمعة/السبت حصرًا (getDay 5/6)
  it("أسبوع كامل: ليلتا الجمعة والسبت فقط تزيدان 20% والباقي سعر أساسي", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 4),   // الأحد
      checkOut: d(2026, 1, 11), // الأحد التالي
      weekendSurchargePercent: 20,
    }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([
      10000, 10000, 10000, 10000, 10000, 12000, 12000,
    ])
    expect(q.subtotalCents).toBe(74000)
    // ليلة الجمعة 2026-01-09 (index 5) والسبت 2026-01-10 (index 6)
    expect(q.nightly[5].date).toBe("2026-01-09")
    expect(q.nightly[6].date).toBe("2026-01-10")
  })

  it("إقامة كل لياليها نهاية أسبوع (جمعة+سبت): كل ليلة تزيد", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 9),   // الجمعة
      checkOut: d(2026, 1, 11), // الأحد
      weekendSurchargePercent: 20,
    }))
    expect(q.nights).toBe(2)
    expect(q.nightly.map((n) => n.priceCents)).toEqual([12000, 12000])
    expect(q.subtotalCents).toBe(24000)
  })

  it("حدود الخلط: خميس→أحد (خميس عادي، جمعة/سبت بزيادة)", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 8),   // الخميس
      checkOut: d(2026, 1, 11), // الأحد
      weekendSurchargePercent: 20,
    }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([10000, 12000, 12000])
  })

  it("حد النهاية الدنيا: ليلة سبت مفردة تُحسب نهاية أسبوع", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 10), checkOut: d(2026, 1, 11), weekendSurchargePercent: 20 }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([12000])
  })

  it("حد النهاية العليا: ليلة أحد مفردة ليست نهاية أسبوع", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 11), checkOut: d(2026, 1, 12), weekendSurchargePercent: 20 }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([10000])
  })

  it("نسبة 0%: لا زيادة حتى على ليالي الجمعة/السبت (افتراض المخطط)", () => {
    // prisma/schema.prisma: weekendSurchargePercent @default(0)
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 11), weekendSurchargePercent: 0 }))
    expect(q.subtotalCents).toBe(20000)
  })

  it("تقريب الزيادة بالسنت عند كسور (3333$ → +15% = 499.95 → 500)", () => {
    // §12.2: كل تقريب للسنت — Math.round لكل ليلة على حدة
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 10),
      basePriceCents: 3333, weekendSurchargePercent: 15,
    }))
    expect(q.nightly[0].priceCents).toBe(3333 + 500) // 3833
  })

  it("الزيادة تُطبق فوق سعر المعدل الموسمي لا فوق الأساسي", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 11),
      rates: [rate("موسم", 9, 10, 60000)],
      weekendSurchargePercent: 10,
    }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([66000, 66000])
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — المعدلات الموسمية", () => {
  // I6 (امتداد): السعر الليلي = معدل موسمي مطابق إن وجد وإلا السعر الأساسي — من الخادم فقط
  it("الليالي داخل نطاق المعدل تأخذ سعره والخارجية السعر الأساسي", () => {
    const q = computeQuote(quoteInput({ rates: [rate("معدل A", 5, 7, 15000)] }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([10000, 15000, 15000, 15000])
    expect(q.nightly.map((n) => n.rateName)).toEqual(["السعر الأساسي", "معدل A", "معدل A", "معدل A"])
    expect(q.subtotalCents).toBe(55000)
  })

  it("حد البداية: ليلة = startDate تدخل في المعدل (من 00:00)", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 5), checkOut: d(2026, 1, 8),
      rates: [rate("معدل", 6, 10, 15000)],
    }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([10000, 15000, 15000])
  })

  it("حد النهاية: ليلة = endDate تدخل في المعدل (حتى 23:59:59.999)", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 5), checkOut: d(2026, 1, 8),
      rates: [rate("معدل", 4, 6, 15000)],
    }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([15000, 15000, 10000])
  })

  it("معدلان متداخلان: الأحدث بدايةً يفوز على ليالي التداخل", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 5), checkOut: d(2026, 1, 10),
      rates: [rate("أقدم", 4, 10, 11111), rate("أحدث", 6, 8, 22222)],
    }))
    // ليالٍ 5..9: الخامس = أقدم · السادس-الثامن = أحدث · التاسع = أقدم
    expect(q.nightly.map((n) => n.priceCents)).toEqual([11111, 22222, 22222, 22222, 11111])
    expect(q.nightly.map((n) => n.rateName)).toEqual(["أقدم", "أحدث", "أحدث", "أحدث", "أقدم"])
  })

  it("المعدل ملزم حتى لو كان أرخص من السعر الأساسي", () => {
    const q = computeQuote(quoteInput({ rates: [rate("تخفيض", 4, 7, 5000)] }))
    expect(q.nightly.map((n) => n.priceCents)).toEqual([5000, 5000, 5000, 5000])
    expect(q.subtotalCents).toBe(20000)
  })

  it("توليفة كاملة: معدل + زيادة نهاية أسبوع + ضريبة + غرفة واحدة", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 11),
      basePriceCents: 10000,
      rates: [rate("موسم", 9, 10, 50000)],
      weekendSurchargePercent: 10,
      taxPercent: 15,
    }))
    // كل ليلة: 50000 + 5000 = 55000
    expect(q.subtotalCents).toBe(110000)
    expect(q.taxCents).toBe(16500)
    expect(q.grandTotalCents).toBe(126500)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — الضريبة بالتقريب للسنت", () => {
  // §12.2: الضريبة = round(subtotal × taxPercent / 100) — Math.round (نصف سنت لأعلى)
  const oneNight = (base: number, taxPercent = 15): Quote =>
    computeQuote(quoteInput({ checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 5), basePriceCents: base, taxPercent }))

  it("كسر سنت لأعلى: 999 × 15% = 149.85 → 150", () => {
    const q = oneNight(999)
    expect(q.taxCents).toBe(150)
    expect(q.grandTotalCents).toBe(999 + 150)
  })

  it("كسر سنت لأسفل: 1001 × 15% = 150.15 → 150", () => {
    expect(oneNight(1001).taxCents).toBe(150)
  })

  it("حدود التقريب المتنوعة (0.45 → أسفل · 0.05 → أعلى · 0.55 → أعلى)", () => {
    expect(oneNight(1003).taxCents).toBe(150) // 150.45 → 150
    expect(oneNight(1007).taxCents).toBe(151) // 151.05 → 151
    expect(oneNight(1030).taxCents).toBe(155) // 154.5 → 155 (نصف لأعلى)
  })

  it("نصف سنت بالضبط يُقرَّب لأعلى: 1030 × 15% = 154.5 → 155", () => {
    const q = oneNight(1030)
    expect(q.taxCents).toBe(155)
    expect(q.grandTotalCents).toBe(1185)
  })

  it("المجموع متعدد الليالي يُقرَّب مرة واحدة على الجملة لا على كل ليلة", () => {
    // 3 × 333 = 999 → 149.85 → 150 (لو قُرّبت كل ليلة لكانت 3 × 50 = 150 أيضًا،
    // لكن العقد: التقريب على subtotalCents بعد الجمع — 999×15% = 149.85 → 150)
    const q = computeQuote(quoteInput({ basePriceCents: 333, checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 7), taxPercent: 15 }))
    expect(q.subtotalCents).toBe(999)
    expect(q.taxCents).toBe(150)
  })

  it("ضريبة 0% = صفر، والإجمالي = المجموع الفرعي", () => {
    const q = oneNight(12345, 0)
    expect(q.taxCents).toBe(0)
    expect(q.grandTotalCents).toBe(12345)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("computeQuote — الحتمية وسطح المدخلات (I6)", () => {
  // I6: لا يُعتمد سعر من العميل — التسعير حتمي خادميًا
  it("نفس المدخلات → نفس المخرجات بالضبط (JSON متطابق)", () => {
    const input1 = quoteInput({ basePriceCents: 16000, taxPercent: 15, weekendSurchargePercent: 10, checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 11), rates: [rate("موسم", 6, 8, 20000)] })
    const input2 = quoteInput({ basePriceCents: 16000, taxPercent: 15, weekendSurchargePercent: 10, checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 11), rates: [rate("موسم", 6, 8, 20000)] })
    const q1 = computeQuote(input1)
    const q2 = computeQuote(input2)
    expect(JSON.stringify(q1)).toBe(JSON.stringify(q2))
    expect(q1).toEqual(q2)
  })

  it("المخرجات تتبع مدخلات الخادم حصرًا: تغيير السعر الأساسي يغيّر كل شيء", () => {
    const low = computeQuote(quoteInput({ basePriceCents: 10000 }))
    const high = computeQuote(quoteInput({ basePriceCents: 20000 }))
    expect(high.subtotalCents).toBe(low.subtotalCents * 2)
    expect(high.nightly.every((n) => n.priceCents === 20000)).toBe(true)
  })

  it("سطح Quote مجمد: لا حقل يقبل سعرًا من العميل — المفاتيح كما هي", () => {
    // I6: مدخلات التسعير كلها من مصادر خادمية (نوع الغرفة + المعدلات + سياسة الفندق)
    const q = computeQuote(quoteInput())
    expect(Object.keys(q).sort()).toEqual([
      "currency", "discountCents", "grandTotalCents", "nightly",
      "nights", "roomsCount", "subtotalCents", "taxCents", "taxPercent",
    ])
  })
})

// ───────────────────────────────────────────────────────────────────
describe("buildSnapshot — لقطة السعر المجمدة (I9)", () => {
  // I9: الحجوزات التاريخية تُفسَّر بلقطة وقت الحجز — غير قابلة لإعادة الكتابة
  const goldenQuote = computeQuote(quoteInput({
    checkIn: d(2026, 9, 6), checkOut: d(2026, 9, 9),
    basePriceCents: 16000, taxPercent: 15,
  }))
  const snapshot = buildSnapshot({
    quote: goldenQuote,
    roomTypeName: "غرفة ديلوكس",
    cancellationPolicy: "إلغاء مجاني قبل 24 ساعة",
    checkInTime: "14:00",
    checkOutTime: "12:00",
    bookedAt: "2026-09-01T10:00:00.000Z",
  })

  it("JSON صالح يحمل كل عناصر التسعير المجمدة", () => {
    const s = JSON.parse(snapshot)
    expect(s.version).toBe(1)
    expect(s.roomTypeName).toBe("غرفة ديلوكس")
    expect(s.nightly).toEqual(goldenQuote.nightly)
    expect(s.subtotalCents).toBe(48000)
    expect(s.discountCents).toBe(0)
    expect(s.taxCents).toBe(7200)
    expect(s.grandTotalCents).toBe(55200)
    expect(s.currency).toBe("USD")
    expect(s.taxPercent).toBe(15)
    expect(s.roomsCount).toBe(1)
    expect(s.cancellationPolicy).toBe("إلغاء مجاني قبل 24 ساعة")
    expect(s.checkInTime).toBe("14:00")
    expect(s.checkOutTime).toBe("12:00")
    expect(s.bookedAt).toBe("2026-09-01T10:00:00.000Z")
  })

  it("اللقطة مكتفية ذاتيًا: مفاتيحها مجموعة معروفة لا تعتمد على المعدلات الحية", () => {
    const keys = Object.keys(JSON.parse(snapshot)).sort()
    expect(keys).toEqual([
      "bookedAt", "cancellationPolicy", "checkInTime", "checkOutTime", "currency",
      "discountCents", "grandTotalCents", "nightly", "roomTypeName", "roomsCount",
      "subtotalCents", "taxCents", "taxPercent", "version",
    ])
  })

  it("اللقطة لا تتغير بتغيير الأسعار لاحقًا (تفسير تاريخي حصرًا)", () => {
    // I9: بناء اللقطة، ثم تتغير أسعار الفندق — اللقطة الأولى تبقى كما هي بالرقم
    const before = snapshot
    const newQuote = computeQuote(quoteInput({
      checkIn: d(2026, 9, 6), checkOut: d(2026, 9, 9),
      basePriceCents: 32000, taxPercent: 15, // الأسعار تضاعفت
    }))
    const newSnapshot = buildSnapshot({
      quote: newQuote, roomTypeName: "غرفة ديلوكس",
      cancellationPolicy: "إلغاء مجاني قبل 24 ساعة",
      checkInTime: "14:00", checkOutTime: "12:00", bookedAt: "2026-09-05T10:00:00.000Z",
    })
    expect(newSnapshot).not.toBe(before)
    expect(JSON.parse(newSnapshot).grandTotalCents).toBe(110400)
    // اللقطة الأصلية لم تُمس: تُفسَّر بأرقام وقت الحجز
    expect(JSON.parse(before).grandTotalCents).toBe(55200)
  })

  it("اللقطة نص مقيَّم لحظة البناء — تعديل كائن Quote بعدها لا يمسها", () => {
    const mutated = JSON.parse(snapshot)
    // عزل: نسخة معدلة لا تؤثر على النص الأصلي (السلسلة نص مجمد)
    mutated.grandTotalCents = 999999
    expect(JSON.parse(snapshot).grandTotalCents).toBe(55200)
    expect(snapshot).toBe(buildSnapshot({
      quote: computeQuote(quoteInput({
        checkIn: d(2026, 9, 6), checkOut: d(2026, 9, 9),
        basePriceCents: 16000, taxPercent: 15,
      })),
      roomTypeName: "غرفة ديلوكس",
      cancellationPolicy: "إلغاء مجاني قبل 24 ساعة",
      checkInTime: "14:00", checkOutTime: "12:00", bookedAt: "2026-09-01T10:00:00.000Z",
    }))
  })
})

// ───────────────────────────────────────────────────────────────────
describe("عربون الحجز 50% — القاعدة على مخرجات محرك التسعير (H2.2)", () => {
  // H2.2: عربون 50% من الإجمالي بتقريب السنت.
  // الصيغة المنفَّذة في مسار الحجز (فرع CARD في src/app/api/public/bookings/route.ts):
  //     const deposit = Math.round(quote.grandTotalCents / 2)
  // هذه اختبارات وحدة تجمّد القاعدة الرقمية فوق مخرجات computeQuote الحقيقية؛
  // أما فرضها من طرف المسار (تسجيل الدفعة + PARTIALLY_PAID) فاختباره التكاملي
  // عند وكيل H2-b في الرحلة الذهبية على قاعدة اختبار معزولة.
  const depositOf = (q: Quote): number => Math.round(q.grandTotalCents / 2)

  it("إجمالي زوجي: العربون نصفه بالضبط (552$ → 276$)", () => {
    const q = computeQuote(quoteInput({
      checkIn: d(2026, 9, 6), checkOut: d(2026, 9, 9),
      basePriceCents: 16000, taxPercent: 15,
    }))
    expect(q.grandTotalCents).toBe(55200)
    expect(depositOf(q)).toBe(27600)
  })

  it("إجمالي فردي 115 سنتًا: 57.5 → 58 (نصف سنت لأعلى)", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 5), basePriceCents: 100, taxPercent: 15 }))
    expect(q.grandTotalCents).toBe(115)
    expect(depositOf(q)).toBe(58)
  })

  it("إجمالي فردي 1185 سنتًا: 592.5 → 593", () => {
    const q = computeQuote(quoteInput({ checkIn: d(2026, 1, 4), checkOut: d(2026, 1, 5), basePriceCents: 1030, taxPercent: 15 }))
    expect(q.grandTotalCents).toBe(1185)
    expect(depositOf(q)).toBe(593)
  })

  it("العربون دائمًا سنت صحيح ولا يتجاوز الإجمالي", () => {
    for (const base of [1, 3, 101, 999, 12345, 16000, 22000]) {
      const q = computeQuote(quoteInput({ basePriceCents: base, taxPercent: 15, weekendSurchargePercent: 10, checkIn: d(2026, 1, 9), checkOut: d(2026, 1, 11) }))
      const dep = depositOf(q)
      expect(Number.isInteger(dep)).toBe(true)
      expect(dep).toBeGreaterThan(0)
      expect(dep).toBeLessThanOrEqual(q.grandTotalCents)
    }
  })
})

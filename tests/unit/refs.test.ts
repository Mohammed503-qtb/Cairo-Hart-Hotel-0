// ═══════════════════════════════════════════════════════════════════
// H2.1 + H2.2 — اختبارات الوحدة لتوليد المراجع (src/lib/refs.ts)
//
// الثوابت الموثقة المغطاة هنا:
//   §12.6 : اصطلاحات التسمية — مراجع عامة HTL-2026-000NNN / ST-… / REQ-…
//   I5    : مرجع حجز واحد لحجز واحد (unique) — المولِّد يبحث عن خانة حرة
//
// اختبار وحدة نقية: بدل قاعدة البيانات، محاكاة في الذاكرة تنفذ
// نفس عقد استدعاءات Prisma التي يستخدمها refs.ts:
//   reservation.count({ where: { bookingReference: { startsWith } } })
//   reservation.findUnique({ where: { bookingReference } })
// (نفس الشكل لـ stay.reference و serviceRequest.reference)
// لا شبكة ولا قاعدة بيانات حقيقية.
// ═══════════════════════════════════════════════════════════════════
import { describe, it, expect } from "bun:test"
import {
  nextBookingReference,
  nextStayReference,
  nextRequestReference,
} from "@/lib/refs"

// ── محاكاة في الذاكرة بعقد Prisma نفسه ────────────────────────────
interface FakeStore {
  reservations: Set<string>
  stays: Set<string>
  requests: Set<string>
}

const YEAR = new Date().getFullYear()

function fakeTx(store: FakeStore) {
  const countStartsWith = (set: Set<string>, prefix: string) =>
    [...set].filter((r) => r.startsWith(prefix)).length
  return {
    reservation: {
      count: async (args: { where: { bookingReference: { startsWith: string } } }) =>
        countStartsWith(store.reservations, args.where.bookingReference.startsWith),
      findUnique: async (args: { where: { bookingReference: string } }) =>
        store.reservations.has(args.where.bookingReference) ? { bookingReference: args.where.bookingReference } : null,
    },
    stay: {
      count: async (args: { where: { reference: { startsWith: string } } }) =>
        countStartsWith(store.stays, args.where.reference.startsWith),
      findUnique: async (args: { where: { reference: string } }) =>
        store.stays.has(args.where.reference) ? { reference: args.where.reference } : null,
    },
    serviceRequest: {
      count: async () => store.requests.size,
      findUnique: async (args: { where: { reference: string } }) =>
        store.requests.has(args.where.reference) ? { reference: args.where.reference } : null,
    },
  } as unknown as Parameters<typeof nextBookingReference>[0]
}

const emptyStore = (): FakeStore => ({ reservations: new Set(), stays: new Set(), requests: new Set() })

// ───────────────────────────────────────────────────────────────────
describe("nextBookingReference — صيغة HTL-YYYY-NNNNNN", () => {
  // §12.6: مراجع الحجز HTL-2026-000421 — سنة + ترقيم 6 منازل حشوًا
  it("مخزن فارغ → المرجع الأول HTL-{السنة الجارية}-000001", async () => {
    const ref = await nextBookingReference(fakeTx(emptyStore()))
    expect(ref).toBe(`HTL-${YEAR}-000001`)
  })

  it("الصيغة العامة: HTL- + 4 أرقام سنة + 6 أرقام تسلسل", async () => {
    const ref = await nextBookingReference(fakeTx(emptyStore()))
    expect(ref).toMatch(/^HTL-\d{4}-\d{6}$/)
  })

  it("تسلسل متصل: 3 مراجع قائمة → المرجع التالي 000004", async () => {
    const store = emptyStore()
    for (let i = 1; i <= 3; i++) store.reservations.add(`HTL-${YEAR}-${String(i).padStart(6, "0")}`)
    expect(await nextBookingReference(fakeTx(store))).toBe(`HTL-${YEAR}-000004`)
  })

  it("الترقيم يتقدم مع كل حجز جديد (محاكاة الإدراج المتتابع)", async () => {
    const store = emptyStore()
    const seen: string[] = []
    for (let i = 0; i < 3; i++) {
      const ref = await nextBookingReference(fakeTx(store))
      seen.push(ref)
      store.reservations.add(ref) // كما يفعل مسار الإنشاء: يدرج المرجع المخصص
    }
    expect(seen).toEqual([
      `HTL-${YEAR}-000001`, `HTL-${YEAR}-000002`, `HTL-${YEAR}-000003`,
    ])
  })

  it("ثقب في التسلسل: يبحث عن أول خانة حرة ويتخطى المشغولة", async () => {
    // I5: لا مرجع مكرر أبدًا — count يعطي 2 لكن 000003 مشغول → يقفز إلى 000004
    const store = emptyStore()
    store.reservations.add(`HTL-${YEAR}-000001`)
    store.reservations.add(`HTL-${YEAR}-000003`)
    expect(await nextBookingReference(fakeTx(store))).toBe(`HTL-${YEAR}-000004`)
  })

  it("الترقيم يتصفّى بالسنة: مراجع سنة سابقة لا تحرق أرقام السنة الحالية", async () => {
    const store = emptyStore()
    store.reservations.add(`HTL-${YEAR - 1}-000001`)
    store.reservations.add(`HTL-${YEAR - 1}-000999`)
    expect(await nextBookingReference(fakeTx(store))).toBe(`HTL-${YEAR}-000001`)
  })

  it("استنفاد 100 محاولة متتالية مشغولة → خطأ صريح لا مرجع مكرر", async () => {
    // I5: الفشل الصريح أفضل من كسر التفرد
    // كتلة كثيفة: 1..100 (لرفع العدّاد إلى 200) + 201..300 (كلها مشغولة)
    // العدّاد 200 → seq = 201 → يفحص 201..300 كلها مشغولة → 100 محاولة → استنفاد
    const store = emptyStore()
    for (let i = 1; i <= 100; i++) store.reservations.add(`HTL-${YEAR}-${String(i).padStart(6, "0")}`)
    for (let i = 201; i <= 300; i++) store.reservations.add(`HTL-${YEAR}-${String(i).padStart(6, "0")}`)
    await expect(nextBookingReference(fakeTx(store))).rejects.toThrow("failed to allocate booking reference")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("nextStayReference — صيغة ST-YYYY-NNNNNN", () => {
  // §12.6: مراجع الإقامة ST-2026-000883 — نفس منطق الحجز
  it("مخزن فارغ → ST-{السنة}-000001", async () => {
    expect(await nextStayReference(fakeTx(emptyStore()))).toBe(`ST-${YEAR}-000001`)
  })

  it("الصيغة العامة: ST- + سنة + 6 منازل", async () => {
    expect(await nextStayReference(fakeTx(emptyStore()))).toMatch(/^ST-\d{4}-\d{6}$/)
  })

  it("مراجع الحجز لا تؤثر على ترقيم الإقامات (مساران منفصلان)", async () => {
    const store = emptyStore()
    for (let i = 1; i <= 5; i++) store.reservations.add(`HTL-${YEAR}-${String(i).padStart(6, "0")}`)
    expect(await nextStayReference(fakeTx(store))).toBe(`ST-${YEAR}-000001`)
  })

  it("ثقب في التسلسل → أول خانة حرة", async () => {
    const store = emptyStore()
    store.stays.add(`ST-${YEAR}-000001`)
    store.stays.add(`ST-${YEAR}-000003`)
    expect(await nextStayReference(fakeTx(store))).toBe(`ST-${YEAR}-000004`)
  })

  it("استنفاد المحاولات → خطأ صريح", async () => {
    // نفس بنية الاستنفاد في الحجز: عدّاد 200 ثم كتلة 201..300 مشغولة بالكامل
    const store = emptyStore()
    for (let i = 1; i <= 100; i++) store.stays.add(`ST-${YEAR}-${String(i).padStart(6, "0")}`)
    for (let i = 201; i <= 300; i++) store.stays.add(`ST-${YEAR}-${String(i).padStart(6, "0")}`)
    await expect(nextStayReference(fakeTx(store))).rejects.toThrow("failed to allocate stay reference")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("nextRequestReference — صيغة REQ-NNNN", () => {
  // §12.6: مراجع الطلبات REQ-1042 — بلا سنة، ترقيم مطلق يبدأ من 1000
  it("مخزن فارغ → REQ-1000 (البداية الموثقة)", async () => {
    expect(await nextRequestReference(fakeTx(emptyStore()))).toBe("REQ-1000")
  })

  it("42 طلبًا قائمًا → REQ-1042", async () => {
    const store = emptyStore()
    for (let i = 1000; i <= 1041; i++) store.requests.add(`REQ-${i}`)
    expect(await nextRequestReference(fakeTx(store))).toBe("REQ-1042")
  })

  it("الصيغة العامة: REQ- + أرقام فقط", async () => {
    expect(await nextRequestReference(fakeTx(emptyStore()))).toMatch(/^REQ-\d+$/)
  })

  it("يتخطى المرجع المشغول (يدوي الإنشاء) إلى أول حر", async () => {
    const store = emptyStore()
    store.requests.add("REQ-1000")
    store.requests.add("REQ-1001")
    store.requests.add("REQ-1002") // العداد 3 → يتوقع 1003، لكنه مشغول
    store.requests.add("REQ-1003")
    expect(await nextRequestReference(fakeTx(store))).toBe("REQ-1004")
  })

  it("طلبات الحجز/الإقامة لا تؤثر على عدّاد الطلبات (عدّ مطلق لا بادئة)", async () => {
    const store = emptyStore()
    store.reservations.add(`HTL-${YEAR}-000001`)
    store.stays.add(`ST-${YEAR}-000001`)
    expect(await nextRequestReference(fakeTx(store))).toBe("REQ-1000")
  })

  it("استنفاد 200 محاولة متتالية → خطأ صريح", async () => {
    // عدّاد 400 → seq = 1400، والكتلة 1400..1599 (200 مرجع) مشغولة بالكامل
    const store = emptyStore()
    for (let i = 1000; i <= 1199; i++) store.requests.add(`REQ-${i}`)
    for (let i = 1400; i <= 1599; i++) store.requests.add(`REQ-${i}`)
    await expect(nextRequestReference(fakeTx(store))).rejects.toThrow("failed to allocate request reference")
  })
})

// ═══════════════════════════════════════════════════════════════════
// H2.1 + H2.2 — اختبارات الوحدة لأدوات العرض العربية (src/lib/format.ts)
//
// الثوابت الموثقة المغطاة هنا:
//   §12.2 : المال سنت صحيح — formatMoney يحوّل السنت إلى عرض عملة صحيح
//   §12.3 : آلات الحالة — كل حالة لها تسمية عربية موحدة
//   §12.6 : اصطلاحات التسمية والقيم المعروضة
//   §12.7 : عربي أولًا — التواريخ والأوقات والتسميات كلها عربية
//
// هذه اختبارات وحدة نقية: لا قاعدة بيانات ولا شبكة ولا React.
// ═══════════════════════════════════════════════════════════════════
import { describe, it, expect } from "bun:test"
import {
  formatMoney,
  formatDateAr,
  formatDateWithDayAr,
  formatDateTimeAr,
  formatTimeAr,
  timeAgoAr,
  nightsBetweenDates,
  todayInputValue,
  addDaysInput,
  RESERVATION_STATUS_LABELS,
  PAYMENT_STATUS_LABELS,
  PAYMENT_METHOD_LABELS,
  ROOM_STATUS_LABELS,
  REQUEST_STATUS_LABELS,
  PRIORITY_LABELS,
  STAY_STATUS_LABELS,
  SOURCE_LABELS,
  CHARGE_CATEGORY_LABELS,
  EXTENSION_STATUS_LABELS,
} from "@/lib/format"

const d = (y: number, m: number, day: number, h = 0, min = 0): Date =>
  new Date(y, m - 1, day, h, min, 0, 0)

// ───────────────────────────────────────────────────────────────────
describe("formatMoney — سنت صحيح → عرض عملة", () => {
  // §12.2: المال سنت صحيح — العرض يحترم الكسرين دائمًا وفواصل الآلاف
  it("القيم الأساسية: 0 → $0.00 · 1 → $0.01 · 5 → $0.05 · 999 → $9.99", () => {
    expect(formatMoney(0)).toBe("$0.00")
    expect(formatMoney(1)).toBe("$0.01")
    expect(formatMoney(5)).toBe("$0.05")
    expect(formatMoney(999)).toBe("$9.99")
  })

  it("فواصل الآلاف مع كسرين: 123450 → $1,234.50 · 123456 → $1,234.56", () => {
    expect(formatMoney(123450)).toBe("$1,234.50")
    expect(formatMoney(123456)).toBe("$1,234.56")
  })

  it("مليون بالسنت: 100000000 → $1,000,000.00", () => {
    expect(formatMoney(100000000)).toBe("$1,000,000.00")
  })

  it("عملة غير الدولار: الاسم يُلحق بالقيمة", () => {
    expect(formatMoney(123450, "EUR")).toBe("1,234.50 EUR")
    expect(formatMoney(500, "SAR")).toBe("5.00 SAR")
  })

  it("مدخل فارغ (null/undefined) → $0.00 — حماية عرض", () => {
    expect(formatMoney(null as unknown as number)).toBe("$0.00")
    expect(formatMoney(undefined as unknown as number)).toBe("$0.00")
  })

  it("أرقام الإنتاج الموثقة: 55200 سنتًا → $552.00 (حجز الرحلة الذهبية)", () => {
    // يطابق الأرقام الحية الموثقة في سجل العمل: $480 + $72 ضريبة = $552
    expect(formatMoney(55200)).toBe("$552.00")
    expect(formatMoney(27600)).toBe("$276.00") // العربون 50%
  })
})

// ───────────────────────────────────────────────────────────────────
describe("formatDateAr / formatDateWithDayAr — التواريخ العربية", () => {
  // §12.7: عربي أولًا — أسماء أشهر وأيام عربية
  it("10 سبتمبر 2026", () => {
    expect(formatDateAr(d(2026, 9, 10))).toBe("10 سبتمبر 2026")
  })

  it("يعمل مع مدخل نصي (ISO محلي)", () => {
    // بدون Z يُفسَّر النص محليًا — نفس اليوم في أي بيئة
    expect(formatDateAr("2026-09-10T12:00:00")).toBe("10 سبتمبر 2026")
  })

  it("كل الأشهر الـ12 بأسمائها العربية", () => {
    expect(formatDateAr(d(2026, 1, 1))).toBe("1 يناير 2026")
    expect(formatDateAr(d(2026, 2, 1))).toBe("1 فبراير 2026")
    expect(formatDateAr(d(2026, 3, 1))).toBe("1 مارس 2026")
    expect(formatDateAr(d(2026, 4, 1))).toBe("1 أبريل 2026")
    expect(formatDateAr(d(2026, 5, 1))).toBe("1 مايو 2026")
    expect(formatDateAr(d(2026, 6, 1))).toBe("1 يونيو 2026")
    expect(formatDateAr(d(2026, 7, 1))).toBe("1 يوليو 2026")
    expect(formatDateAr(d(2026, 8, 1))).toBe("1 أغسطس 2026")
    expect(formatDateAr(d(2026, 9, 1))).toBe("1 سبتمبر 2026")
    expect(formatDateAr(d(2026, 10, 1))).toBe("1 أكتوبر 2026")
    expect(formatDateAr(d(2026, 11, 1))).toBe("1 نوفمبر 2026")
    expect(formatDateAr(d(2026, 12, 1))).toBe("1 ديسمبر 2026")
  })

  it("الخميس، 10 سبتمبر 2026 (10 سبتمبر 2026 = الخميس)", () => {
    expect(formatDateWithDayAr(d(2026, 9, 10))).toBe("الخميس، 10 سبتمبر 2026")
  })

  it("الجمعة، 2 يناير 2026 — يوم نهاية الأسبوع يظهر باسمه الصحيح", () => {
    // 2 يناير 2026 = الجمعة (حدود زيادة نهاية الأسبوع في التسعير)
    expect(formatDateWithDayAr(d(2026, 1, 2))).toBe("الجمعة، 2 يناير 2026")
    expect(formatDateWithDayAr(d(2026, 1, 3))).toBe("السبت، 3 يناير 2026")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("formatTimeAr / formatDateTimeAr — أوقات 12 ساعة بص/م", () => {
  // §12.7: عربي أولًا — تعليمات الفترة ص/م وحشو الدقائق
  it("بعد الظهر: 14:30 → 2:30 م", () => {
    expect(formatTimeAr(d(2026, 9, 10, 14, 30))).toBe("2:30 م")
  })

  it("قبل الظهر: 00:15 → 12:15 ص", () => {
    expect(formatTimeAr(d(2026, 9, 10, 0, 15))).toBe("12:15 ص")
  })

  it("الظهيرة ومنتصف الليل يتحولان إلى 12 لا 0", () => {
    expect(formatTimeAr(d(2026, 9, 10, 12, 0))).toBe("12:00 م")
    expect(formatTimeAr(d(2026, 9, 10, 23, 59))).toBe("11:59 م")
  })

  it("حشو الدقائق: 11:05 → 11:05 ص (بلا اقتطاع)", () => {
    expect(formatTimeAr(d(2026, 9, 10, 11, 5))).toBe("11:05 ص")
  })

  it("التاريخ مع الوقت: 10 سبتمبر 2026 — 2:30 م", () => {
    expect(formatDateTimeAr(d(2026, 9, 10, 14, 30))).toBe("10 سبتمبر 2026 — 2:30 م")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("timeAgoAr — الزمن النسبي العربي", () => {
  it("الآن: أقل من دقيقة", () => {
    expect(timeAgoAr(new Date())).toBe("الآن")
  })

  it("منذ 5 دقيقة", () => {
    const t = new Date(Date.now() - 5 * 60_000)
    expect(timeAgoAr(t)).toBe("منذ 5 دقيقة")
  })

  it("منذ 3 ساعة", () => {
    const t = new Date(Date.now() - 3 * 3_600_000)
    expect(timeAgoAr(t)).toBe("منذ 3 ساعة")
  })

  it("منذ 1 يوم (47 ساعة → يوم واحد)", () => {
    const t = new Date(Date.now() - 47 * 3_600_000)
    expect(timeAgoAr(t)).toBe("منذ 1 يوم")
  })

  it("أقدم من 30 يومًا → يعود لعرض التاريخ المطلق", () => {
    const t = new Date(Date.now() - 40 * 24 * 3_600_000)
    const result = timeAgoAr(t)
    expect(result).not.toContain("منذ")
    expect(result).toMatch(/^\d{1,2} \S+ \d{4}$/)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("nightsBetweenDates — ليالي حدود الأيام (نسخة العميل الآمنة)", () => {
  // §12: عدد الليالي من حدود الأيام لا الطوابع الزمنية
  it("متجاوران = 1 · فرق 5 أيام = 5", () => {
    expect(nightsBetweenDates(d(2026, 1, 5), d(2026, 1, 6))).toBe(1)
    expect(nightsBetweenDates(d(2026, 1, 1), d(2026, 1, 6))).toBe(5)
  })

  it("يعمل مع مدخلات نصية", () => {
    expect(nightsBetweenDates("2026-01-01T12:00:00", "2026-01-04T12:00:00")).toBe(3)
  })

  it("نفس اليوم = 0 · معكوس = 0 (تثبيت أرضي على العميل — لا سالب)", () => {
    // نسخة العميل تحمي الواجهة من السالب (بخلاف نسخة الخادم التي يحميها
    // validateStayDates في مسار الحجز — نطاق H2-b)
    expect(nightsBetweenDates(d(2026, 1, 4), d(2026, 1, 4))).toBe(0)
    expect(nightsBetweenDates(d(2026, 1, 6), d(2026, 1, 5))).toBe(0)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("todayInputValue / addDaysInput — مفاتيح input[type=date]", () => {
  // §12.6: المفاتيح YYYY-MM-DD (مطابقة لمفاتيح localDateKey في التسعير)
  it("قيمة اليوم بصيغة YYYY-MM-DD", () => {
    expect(todayInputValue()).toMatch(/^\d{4}-\d{2}-\d{2}$/)
    const now = new Date()
    const expected = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
    expect(todayInputValue()).toBe(expected)
  })

  it("إضافة أيام تعبر حدود الشهر: 31 يناير + 1 = 1 فبراير", () => {
    expect(addDaysInput("2026-01-31", 1)).toBe("2026-02-01")
  })

  it("تعبر حدود السنة: 31 ديسمبر + 1 = 1 يناير 2027", () => {
    expect(addDaysInput("2026-12-31", 1)).toBe("2027-01-01")
  })

  it("تحترم السنة الكبيسة: 28 فبراير 2024 + 1 = 29 فبراير (كبيسة) و2026 غير كبيسة", () => {
    expect(addDaysInput("2024-02-28", 1)).toBe("2024-02-29")
    expect(addDaysInput("2026-02-28", 1)).toBe("2026-03-01")
  })

  it("إضافة متعددة أيام وطرح سالب", () => {
    expect(addDaysInput("2026-09-06", 3)).toBe("2026-09-09")
    expect(addDaysInput("2026-03-01", -1)).toBe("2026-02-28")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("خرائط تسميات الحالات العربية — كل حالة معروضة للضيف لها اسم", () => {
  // §12.3: آلات الحالة — كل حالة في كل آلة يجب أن تجد تسميتها العربية
  const ARABIC = /[\u0600-\u06FF]/

  function expectLabels(map: Record<string, string>, states: string[], name: string) {
    it(`${name}: كل حالات الآلة موجودة بتسمية عربية غير فارغة`, () => {
      for (const state of states) {
        expect(map[state]).toBeTruthy()
        expect(ARABIC.test(map[state] ?? "")).toBe(true)
        expect(/[A-Za-z]/.test(map[state] ?? "")).toBe(false)
      }
    })
  }

  // Reservation: PENDING → CONFIRMED → CHECKED_IN → COMPLETED · CANCELLED · NO_SHOW (§12.3)
  expectLabels(RESERVATION_STATUS_LABELS, [
    "PENDING", "CONFIRMED", "CANCELLED", "CHECKED_IN", "COMPLETED", "NO_SHOW",
  ], "Reservation")

  // Stay: ACTIVE → CHECKOUT_REQUESTED → CLOSED (§12.3)
  expectLabels(STAY_STATUS_LABELS, ["ACTIVE", "CHECKOUT_REQUESTED", "CLOSED"], "Stay")

  // Room: AVAILABLE / RESERVED / OCCUPIED / DIRTY / CLEANING / OUT_OF_ORDER (§12.3 + I12)
  expectLabels(ROOM_STATUS_LABELS, [
    "AVAILABLE", "RESERVED", "OCCUPIED", "DIRTY", "CLEANING", "OUT_OF_ORDER",
  ], "Room")

  // ServiceRequest — الآلة كما هي منفذة في الكود (NEW لا SUBMITTED — راجع worklog):
  // NEW → ACKNOWLEDGED → ASSIGNED/IN_PROGRESS/WAITING → COMPLETED/CANCELLED/REJECTED
  expectLabels(REQUEST_STATUS_LABELS, [
    "NEW", "ACKNOWLEDGED", "ASSIGNED", "IN_PROGRESS", "WAITING", "COMPLETED", "CANCELLED", "REJECTED",
  ], "ServiceRequest")

  // Payment: UNPAID → PARTIALLY_PAID → PAID · REFUNDED
  expectLabels(PAYMENT_STATUS_LABELS, ["UNPAID", "PARTIALLY_PAID", "PAID", "REFUNDED"], "Payment")

  // Payment methods (§12.6 قيم معروفة)
  expectLabels(PAYMENT_METHOD_LABELS, ["PAY_AT_HOTEL", "CARD", "CASH", "ONLINE", "TRANSFER"], "PaymentMethod")

  // Priority / Source / ChargeCategory / Extension
  expectLabels(PRIORITY_LABELS, ["NORMAL", "URGENT"], "Priority")
  expectLabels(SOURCE_LABELS, ["WEBSITE", "WHATSAPP", "PHONE", "WALK_IN", "RECEPTION"], "Source")
  expectLabels(CHARGE_CATEGORY_LABELS, ["SERVICE", "EXTRA", "PENALTY", "ROOM_EXTENSION"], "ChargeCategory")
  expectLabels(EXTENSION_STATUS_LABELS, ["PENDING", "APPROVED", "REJECTED"], "ExtensionRequest")

  it("تسميات الحالات الموثقة في العرض الحي مطابقة نصيًا", () => {
    // عينات مطابقة للعرض المُتحقق منه يدويًا في الواجهة (سجل العمل)
    expect(RESERVATION_STATUS_LABELS["CONFIRMED"]).toBe("مؤكد")
    expect(RESERVATION_STATUS_LABELS["CHECKED_IN"]).toBe("مسجّل دخول")
    expect(STAY_STATUS_LABELS["CHECKOUT_REQUESTED"]).toBe("طُلب الخروج")
    expect(STAY_STATUS_LABELS["CLOSED"]).toBe("مغلقة")
    expect(ROOM_STATUS_LABELS["DIRTY"]).toBe("تحتاج تنظيف")
    expect(ROOM_STATUS_LABELS["OUT_OF_ORDER"]).toBe("خارج الخدمة")
    expect(PRIORITY_LABELS["URGENT"]).toBe("عاجل")
    expect(PAYMENT_METHOD_LABELS["PAY_AT_HOTEL"]).toBe("الدفع في الفندق")
    expect(CHARGE_CATEGORY_LABELS["ROOM_EXTENSION"]).toBe("تمديد إقامة")
  })
})

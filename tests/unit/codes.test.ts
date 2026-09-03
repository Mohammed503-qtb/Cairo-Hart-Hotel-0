// ═══════════════════════════════════════════════════════════════════
// H2.1 + H2.2 — اختبارات الوحدة لأكواد الدخول (src/lib/codes.ts)
//
// الثوابت الموثقة المغطاة هنا:
//   §12.4 : الهوية — بادئات H/R/A (حرف + 6 أرقام + حرفا تحقق)
//           توليد وتحقق وهَش SHA-256 وإبطال في src/lib/codes.ts
//           الكود الخام لا يُخزَّن أبدًا — يُخزَّن SHA-256 فقط
//   I4    : كود منتهٍ/ملغي لا يعمل — فحص الصيغة هنا نقي؛
//           اختبارات دورة الحياة (ACTIVE/REVOKED/EXPIRED + I11 موت الكود عند الخروج)
//           تحتاج قاعدة بيانات وهي ملك وكيل H2-b
//
// ملاحظة موثقة: أكواد العرض التجريبية في prisma/seed.ts مختارة يدويًا
// للعرض ولا تحمل حرفي تحقق صالحين — التوليد الفعلي دائمًا يحملهما.
// هذه اختبارات وحدة نقية: لا قاعدة بيانات ولا شبكة.
// ═══════════════════════════════════════════════════════════════════
import { describe, it, expect } from "bun:test"
import {
  generateCode,
  isValidCodeFormat,
  normalizeCode,
  hashCode,
  maskCode,
  type CodeType,
} from "@/lib/codes"

// إعادة تنفيذ خوارزمية حرفي التحقق كما هي في src/lib/codes.ts (checksumChars)
// لمراقبة أن التوليد يلتزم بها (منع انحراف صامت في الحروف)
const PREFIX: Record<CodeType, string> = { GUEST: "H", RECEPTION: "R", ADMIN: "A" }
function expectedChecksum(type: CodeType, digits: string): string {
  const sum = digits.split("").reduce((a, c) => a + Number(c), 0) + PREFIX[type].charCodeAt(0)
  const c1 = (sum % 36).toString(36).toUpperCase()
  const c2 = ((sum * 7 + 13) % 36).toString(36).toUpperCase()
  return c1 + c2
}

const TYPES: CodeType[] = ["GUEST", "RECEPTION", "ADMIN"]

// ───────────────────────────────────────────────────────────────────
describe("generateCode — صيغة H/R/A (بادئة الدور + الطول + الأبجدية)", () => {
  // §12.4: البادئة حسب الدور: GUEST=H · RECEPTION=R · ADMIN=A
  it("البادئة تحترم الدور الممرر في كل توليدة (30 عينة لكل دور)", () => {
    for (const type of TYPES) {
      for (let i = 0; i < 30; i++) {
        const code = generateCode(type)
        expect(code.startsWith(PREFIX[type])).toBe(true)
      }
    }
  })

  it("الطول 9 رموز: بادئة + 6 أرقام + حرفا تحقق", () => {
    // §12.4: حرف + 6 أرقام + حرفا تحقق حتميان
    for (let i = 0; i < 30; i++) {
      for (const type of TYPES) {
        const code = generateCode(type)
        expect(code).toHaveLength(9)
        expect(code.slice(1, 7)).toMatch(/^\d{6}$/)
        expect(code.slice(7)).toMatch(/^[A-Z0-9]{2}$/)
      }
    }
  })

  it("حرفا التحقق حتميان من الأرقام + بادئة النوع (خوارزمية checksumChars)", () => {
    for (let i = 0; i < 30; i++) {
      for (const type of TYPES) {
        const code = generateCode(type)
        const digits = code.slice(1, 7)
        expect(code.slice(7)).toBe(expectedChecksum(type, digits))
      }
    }
  })

  it("المولِّد غير متدهور: عينة 300 توليدة تعطي تنوعًا حقيقيًا", () => {
    // هذا ليس اختبار تفرد (التفرد الحقيقي يفرضه unique في قاعدة البيانات
    // وإعادة المحاولة في مسار الإدارة — ملك H2-b)، بل حراسة من مولِّد ثابت/متدهور.
    const codes = new Set<string>()
    for (let i = 0; i < 300; i++) codes.add(generateCode(TYPES[i % 3]))
    expect(codes.size).toBeGreaterThanOrEqual(150)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("isValidCodeFormat — فحص الصيغة (بوابة الدخول)", () => {
  // §12.4: الصيغة [HRA] + 6 أرقام + حرفا [A-Z0-9] — الفحص يطبع ويكبّر قبل الاختبار
  it("يقبل كل توليدة فعلية من المولِّد", () => {
    for (let i = 0; i < 60; i++) {
      expect(isValidCodeFormat(generateCode(TYPES[i % 3]))).toBe(true)
    }
  })

  it("يقبل الحالة الصغيرة والفراغات الطرفية (تطبيع قبل الفحص)", () => {
    expect(isValidCodeFormat("h123456ab")).toBe(true)
    expect(isValidCodeFormat("  H123456AB  ")).toBe(true)
  })

  it("يرفض البادئات غير المسموحة", () => {
    expect(isValidCodeFormat("X123456AB")).toBe(false)
    expect(isValidCodeFormat("B123456AB")).toBe(false)
    expect(isValidCodeFormat("123456AB")).toBe(false)
    expect(isValidCodeFormat("hR123456AB")).toBe(false)
  })

  it("يرفض الأطوال الخاطئة", () => {
    expect(isValidCodeFormat("")).toBe(false)
    expect(isValidCodeFormat("H12345")).toBe(false)      // قصير جدًا
    expect(isValidCodeFormat("H123456")).toBe(false)     // 8 — بلا حرفي التحقق
    expect(isValidCodeFormat("H123456A")).toBe(false)    // حرف تحقق واحد
    expect(isValidCodeFormat("H123456ABC")).toBe(false)  // 10 — طويل
  })

  it("يرفض عدد الأرقام الخاطئ أو رموزًا غير مسموحة في مواضعها", () => {
    expect(isValidCodeFormat("H12345AB")).toBe(false)   // 5 أرقام
    expect(isValidCodeFormat("H1234567AB")).toBe(false) // 7 أرقام
    expect(isValidCodeFormat("H12A456AB")).toBe(false)  // حرف في موضع رقم
    expect(isValidCodeFormat("H123456A-")).toBe(false)  // رمز ممنوع
    expect(isValidCodeFormat("H123456A!")).toBe(false)
  })

  it("يرفض الفراغ الداخلي (التطبيع يزيله لكن الفحص الخام لا)", () => {
    // isValidCodeFormat لا يزيل الفراغ الداخلي — trim يشيل الأطراف فقط
    expect(isValidCodeFormat("H123 456AB")).toBe(false)
  })
})

// ───────────────────────────────────────────────────────────────────
describe("normalizeCode — التطبيع", () => {
  // §12.4: قبل الهش/الفحص — trim + uppercase + إزالة كل الفراغات
  it("يزيل الفراغات الطرفية ويكبّر", () => {
    expect(normalizeCode("  H834729X7  ")).toBe("H834729X7")
    expect(normalizeCode("r492671m3")).toBe("R492671M3")
  })

  it("يزيل الفراغات الداخلية وأسطر جديدة", () => {
    expect(normalizeCode("h8347 29x7")).toBe("H834729X7")
    expect(normalizeCode("\n\ta371849l9")).toBe("A371849L9")
  })
})

// ───────────────────────────────────────────────────────────────────
describe("hashCode — هش SHA-256 أحادي الاتجاه", () => {
  // §12.4: الكود الخام لا يُخزَّن أبدًا — يُخزَّن SHA-256 فقط
  it("حتمي: نفس الخام → نفس الهش بالضبط", () => {
    expect(hashCode("H834729X7")).toBe(hashCode("H834729X7"))
    expect(hashCode("R492671M3")).toBe(hashCode("R492671M3"))
  })

  it("هش SHA-256 معروف (تجميد الخوارزمية ضد أي تبديل صامت)", () => {
    // sha256("H834729X7") = cb73e0bd... — متجه مرجعي محسوب مسبقًا
    expect(hashCode("H834729X7")).toBe("cb73e0bdd12402380e4f42c00fd35fa2bc3cb8cfb34859ba2d30724fffd635f4")
    expect(hashCode("R492671M3")).toBe("8ab09965723cb258a120d65e93d298e70aa3fdf640ad5fe0ac7c260bd034f69d")
  })

  it("شكل hex صغير بطول 64", () => {
    expect(hashCode("A371849L9")).toMatch(/^[0-9a-f]{64}$/)
    expect(hashCode(generateCode("GUEST"))).toMatch(/^[0-9a-f]{64}$/)
  })

  it("أحادي الاتجاه: الهش ليس الكود ولا يحتويه", () => {
    const h = hashCode("H834729X7")
    expect(h).not.toBe("H834729X7")
    expect(h.includes("H834729")).toBe(false)
  })

  it("خام مختلف → هاش مختلف", () => {
    expect(hashCode("H111111AA")).not.toBe(hashCode("H111111AB"))
    expect(hashCode("H834729X7")).not.toBe(hashCode("R492671M3"))
  })

  it("الهش على الصيغة المطبَّعة: حروف صغيرة/فراغات تعطي نفس هش الكود النظيف", () => {
    // real behavior: hashCode يطبّع داخليًا — ضيف يكتب الكود بصيغة غلط يمر
    expect(hashCode("h8347 29x7")).toBe(hashCode("H834729X7"))
    expect(hashCode("  r492671m3 ")).toBe(hashCode("R492671M3"))
  })
})

// ───────────────────────────────────────────────────────────────────
describe("maskCode — قناع العرض (البادئة مرئية والباقي مموّه)", () => {
  // §12.4 + حماية العرض: الكود لا يُعرض كاملًا في الواجهات اللاحقة
  it("يعرض أول حرفين وآخر حرفين مع تمويه الوسط", () => {
    expect(maskCode("H834729X7")).toBe("H8••••X7")
    expect(maskCode("R492671M3")).toBe("R4••••M3")
    expect(maskCode("A371849L9")).toBe("A3••••L9")
  })

  it("يطبّع المدخل قبل التمويه (حروف صغيرة/فراغات)", () => {
    expect(maskCode(" h834729x7 ")).toBe("H8••••X7")
    expect(maskCode("h8347 29x7")).toBe("H8••••X7")
  })

  it("مدخل أقصر من 6 رموز → قناع كامل مغلق", () => {
    expect(maskCode("H123")).toBe("••••••••")
    expect(maskCode("")).toBe("••••••••")
  })

  it("القناع لا يكشف أكثر من 4 رموز من الكود", () => {
    const masked = maskCode(generateCode("GUEST"))
    expect(masked).toHaveLength(8)
    expect(masked.slice(2, 6)).toBe("••••")
  })
})

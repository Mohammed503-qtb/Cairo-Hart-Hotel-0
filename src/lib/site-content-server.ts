// ─────────────────────────────────────────────────────────────
// SITE CONTENT SERVER — قراءة محتوى الموقع المدمج من القاعدة
// (خادم فقط — يدمج المخزَّن فوق DEFAULT_CONTENT لكل قسم)
// ─────────────────────────────────────────────────────────────
import { db } from '@/lib/db'
import { SITE_SECTION_KEYS, mergeSection, type SiteContentAll, type SiteSectionKey } from '@/lib/site-content'

/** المحتوى الكامل: المخزَّن مدموجًا فوق الافتراضي — الأقسام غير المحفوظة تُرجع الافتراضي */
export async function loadSiteContent(): Promise<SiteContentAll> {
  const rows = await db.siteContent.findMany({
    select: { key: true, value: true },
  })
  const stored = new Map<string, string>(rows.map((r) => [r.key, r.value]))

  const content = {} as SiteContentAll
  for (const key of SITE_SECTION_KEYS as SiteSectionKey[]) {
    let parsed: unknown = null
    try {
      const raw = stored.get(key)
      parsed = raw ? JSON.parse(raw) : null
    } catch {
      parsed = null
    }
    const storedObj =
      parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : null
    // مفتاح ديناميكي — القسم منقّى الأنواع عبر mergeSection، فالتحويل الآمن هنا ضروري فقط لـ TS
    ;(content as Record<SiteSectionKey, unknown>)[key] = mergeSection(key, storedObj as Parameters<typeof mergeSection>[1])
  }
  return content
}

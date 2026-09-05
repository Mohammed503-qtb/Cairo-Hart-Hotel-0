// ─────────────────────────────────────────────────────────────
// GET /api/public/site-content — محتوى الموقع العام (المدموج)
// عام بلا مصادقة — يستهلكه موقع الفندق عند التحميل
// ─────────────────────────────────────────────────────────────
import { ok, fail } from '@/lib/api'
import { loadSiteContent } from '@/lib/site-content-server'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const content = await loadSiteContent()
    return ok({ content })
  } catch {
    return fail('تعذر تحميل محتوى الموقع', 500)
  }
}

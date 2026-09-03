// ─────────────────────────────────────────────────────────────
// GET /api/public/app-config — سياسة إصدار تطبيق الضيف (F6)
// نقطة عامة بلا مصادقة: يفحصها التطبيق عند الإطلاق فقط (حارس minAppVersion).
// الفشل هنا متسامح (fail-open): أي خلل يُعاد كقيمة فارغة = لا فرض —
// التطبيق يُكمل تشغيله وأخطاء الاتصال الحقيقية تظهر عند الدخول.
// ─────────────────────────────────────────────────────────────
import { db } from '@/lib/db'
import { ok } from '@/lib/api'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const hotel = await db.hotel.findFirst()
    // فارغ = لا فرض · غياب صف الفندق يعامل كلا فرض
    return ok({ minAppVersion: hotel?.minAppVersion ?? '' })
  } catch {
    return ok({ minAppVersion: '' })
  }
}

// ─────────────────────────────────────────────────────────────
// GET /api/guest/services — كتالوج الخدمات
// الأقسام بترتيب العرض مع خدماتها النشطة فقط
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)

  try {
    const categories = await db.serviceCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      include: {
        services: {
          where: { active: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    })

    // أقسام ذات خدمات نشطة فقط — كتالوج نظيف
    const visible = categories.filter((c) => c.services.length > 0)

    return ok({
      categories: visible.map((c) => ({
        id: c.id,
        name: c.name,
        key: c.key,
        icon: c.icon,
        services: c.services.map((s) => ({
          id: s.id,
          name: s.name,
          description: s.description,
          priceCents: s.priceCents,
          categoryKey: c.key,
        })),
      })),
    })
  } catch (e) {
    console.error('guest services failed', e)
    return fail('حدث خطأ أثناء تحميل الخدمات — أعد المحاولة', 500)
  }
}

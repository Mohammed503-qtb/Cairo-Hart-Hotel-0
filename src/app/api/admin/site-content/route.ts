// ─────────────────────────────────────────────────────────────
// GET/PATCH /api/admin/site-content — إدارة محتوى الموقع
// PATCH: { section: SiteSectionKey, data: { ... } } → تنقية →
// upsert → audit CONTENT_UPDATED → إرجاع المحتوى الكامل المدموج
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'
import { loadSiteContent } from '@/lib/site-content-server'
import {
  SITE_SECTION_KEYS,
  SITE_SECTION_LABELS,
  sanitizeSection,
  type SiteSectionKey,
} from '@/lib/site-content'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  try {
    const content = await loadSiteContent()
    return ok({ content })
  } catch {
    return fail('تعذر تحميل محتوى الموقع', 500)
  }
}

export async function PATCH(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  const body = await readBody<{ section?: string; data?: Record<string, unknown> }>(req)
  if (!body) return fail('طلب غير صالح')

  const section = body.section
  if (!section || !(SITE_SECTION_KEYS as string[]).includes(section)) {
    return fail('قسم محتوى غير معروف')
  }
  const key = section as SiteSectionKey
  if (!body.data || typeof body.data !== 'object' || Array.isArray(body.data)) {
    return fail('بيانات القسم غير صالحة')
  }

  // التنقية (القيم المفقودة تُحفظ من المخزَّن الحالي وليس الافتراضي — تعديل جزئي آمن)
  const current = await loadSiteContent()
  const mergedInput = { ...current[key], ...body.data }
  const sanitized = sanitizeSection(key, mergedInput as Record<string, unknown>)
  if (!sanitized) return fail('بيانات القسم غير صالحة — تحقق من الحقول المطلوبة')

  const value = JSON.stringify(sanitized)
  const existing = await db.siteContent.findUnique({ where: { key } })
  const changed = existing
    ? existing.value !== value
    : JSON.stringify(current[key]) !== value

  if (!changed) {
    return ok({ content: current, changedFields: [], note: 'لا توجد تغييرات' })
  }

  const saved = await db.siteContent.upsert({
    where: { key },
    update: { value },
    create: { key, value },
  })

  const content = await loadSiteContent()

  await audit(db, {
    action: 'CONTENT_UPDATED',
    entityType: 'SiteContent',
    entityId: saved.id,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { section: key, sectionLabel: SITE_SECTION_LABELS[key] },
  })

  return ok({ content, changedFields: [key], note: 'تم حفظ المحتوى — يظهر على الموقع فورًا' })
}

// ═══════════════════════════════════════════════════════════════════
// F6-minAppVersion — اختبارات تكامل على قاعدة معزولة (appversion)
// (MASTER_PLAN v2.2 §6.7 · Task ID: 18)
//
// يغطي:
//   PUB-07 : GET /api/public/app-config — نقطة عامة بلا مصادقة (fail-open)
//   A-03   : PATCH /api/admin/hotel — حقل minAppVersion (x.y.z أو فارغ)
//            + رسالة الـ 400 الحرفية + التدقيق SETTINGS_UPDATED
//            + حارس الدور (غير الأدمن يُرفض)
//
// قواعد حارس الاختبار (tests/helpers/test-db.ts) مُتبعة حرفيًا:
// أول سطر يضبط DATABASE_URL → setupTestDb → استيراد ديناميكي فقط.
// ═══════════════════════════════════════════════════════════════════
process.env.DATABASE_URL = 'file:/home/z/my-project/db/test-appversion.db'

import { describe, it, expect } from 'bun:test'
import { setupTestDb } from '../helpers/test-db'

setupTestDb('appversion')

// ── استيراد ديناميكي للمعالجات بعد ضبط البيئة (إلزامي) ──
const appConfigRoute = await import('@/app/api/public/app-config/route')
const hotelRoute = await import('@/app/api/admin/hotel/route')
const validateRoute = await import('@/app/api/auth/validate/route')
const { db } = await import('@/lib/db')
const { NextRequest } = await import('next/server')

// ── أدوات مساعدة (نمط flows.test.ts نفسه) ──
let ipCounter = 0
const nextIp = (): string => `198.51.100.${(ipCounter += 1)}`

function request(
  handler: (r: Request) => Promise<Response>,
  url: string,
  init: { method?: string; body?: unknown; headers?: Record<string, string> } = {}
): Promise<Response> {
  return handler(new NextRequest(url, {
    method: init.method ?? 'GET',
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
    headers: { 'content-type': 'application/json', 'x-forwarded-for': nextIp(), ...(init.headers ?? {}) },
  }) as unknown as Request)
}

async function json<T>(res: Response): Promise<T & { ok: boolean; error?: string }> {
  return (await res.json()) as T & { ok: boolean; error?: string }
}

/** دخول بالكود عبر validate — يرجع التوكن */
async function loginAs(code: string): Promise<string> {
  const res = await request(
    validateRoute.POST as unknown as (r: Request) => Promise<Response>,
    'http://localhost/api/auth/validate',
    { method: 'POST', body: { code } }
  )
  const j = await json<{ token: string }>(res)
  expect(j.ok).toBe(true)
  return j.token
}

const bearer = (token: string): Record<string, string> => ({ authorization: `Bearer ${token}` })

const ADMIN = 'A371849L9' // سالم المدير (seed)
const GUEST = 'H834729X7' // خالد (seed)

// ═══════════════════════════════════════════════════════════════════
describe('F6-minAppVersion — PUB-07 · GET /api/public/app-config (عام)', () => {
  it('بلا مصادقة → 200 مع minAppVersion فارغة (افتراض seed = لا فرض)', async () => {
    const res = await request(appConfigRoute.GET as unknown as (r: Request) => Promise<Response>, 'http://localhost/api/public/app-config')
    expect(res.status).toBe(200)
    const j = await json<{ minAppVersion: string }>(res)
    expect(j.ok).toBe(true)
    expect(j.minAppVersion).toBe('')
  })
})

// ═══════════════════════════════════════════════════════════════════
describe('F6-minAppVersion — A-03 · PATCH /api/admin/hotel (حقل الإصدار)', () => {
  it('تعيين 2.0.0 (أدمن) → 200 + changedFields يشمل الحقل + الفندق محدَّث + PUB-07 يعكسه فورًا', async () => {
    const token = await loginAs(ADMIN)
    const res = await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '2.0.0' }, headers: bearer(token) }
    )
    expect(res.status).toBe(200)
    const j = await json<{ hotel: { minAppVersion: string }; changedFields: string[] }>(res)
    expect(j.ok).toBe(true)
    expect(j.changedFields).toContain('minAppVersion')
    expect(j.hotel.minAppVersion).toBe('2.0.0')

    // النقطة العامة تعكس القيمة الجديدة بلا توكن
    const pub = await request(appConfigRoute.GET as unknown as (r: Request) => Promise<Response>, 'http://localhost/api/public/app-config')
    const pj = await json<{ minAppVersion: string }>(pub)
    expect(pj.minAppVersion).toBe('2.0.0')
  }, 30_000)

  it('قيمة بفراغات محيطية تُنظَّف قبل الحفظ (سلوك الخادم: trim)', async () => {
    const token = await loginAs(ADMIN)
    const res = await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: ' 2.0.1 ' }, headers: bearer(token) }
    )
    expect(res.status).toBe(200)
    const j = await json<{ hotel: { minAppVersion: string } }>(res)
    expect(j.hotel.minAppVersion).toBe('2.0.1')
  })

  it('صيغة غير ثلاثية (abc / 1.2 / 1.2.3.4) → 400 برسالة حرفية واحدة', async () => {
    const token = await loginAs(ADMIN)
    for (const bad of ['abc', '1.2', '1.2.3.4']) {
      const res = await request(
        hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
        'http://localhost/api/admin/hotel',
        { method: 'PATCH', body: { minAppVersion: bad }, headers: bearer(token) }
      )
      expect(res.status).toBe(400)
      const j = await json<Record<string, unknown>>(res)
      expect(j.error).toBe('صيغة إصدار التطبيق يجب أن تكون ثلاثية رقمية (مثال: 1.2.0)')
      // لم يتغير شيء في القاعدة
      const hotel = await db.hotel.findFirst()
      expect(hotel!.minAppVersion).toBe('2.0.1')
    }
  })

  it('تفريغ الحقل (إلغاء الفرض) → 200 + PUB-07 تعود فارغة', async () => {
    const token = await loginAs(ADMIN)
    const res = await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '' }, headers: bearer(token) }
    )
    expect(res.status).toBe(200)
    const pub = await request(appConfigRoute.GET as unknown as (r: Request) => Promise<Response>, 'http://localhost/api/public/app-config')
    const pj = await json<{ minAppVersion: string }>(pub)
    expect(pj.minAppVersion).toBe('')
  })

  it('نفس القيمة الحالية → لا تغييرات (changedFields فارغة)', async () => {
    const token = await loginAs(ADMIN)
    await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '1.0.0' }, headers: bearer(token) }
    )
    const res = await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '1.0.0' }, headers: bearer(token) }
    )
    const j = await json<{ changedFields: string[] }>(res)
    expect(j.changedFields).not.toContain('minAppVersion')
  })

  it('ضيف (ليس أدمن) → مرفوض بحارس الدور — لا مساس بالإعداد', async () => {
    const token = await loginAs(GUEST)
    const res = await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '9.9.9' }, headers: bearer(token) }
    )
    expect([401, 403]).toContain(res.status)
    const hotel = await db.hotel.findFirst()
    expect(hotel!.minAppVersion).toBe('1.0.0')
  })

  it('التدقيق (I10): SETTINGS_UPDATED يوثق الحقل المتغير ضمن details', async () => {
    const token = await loginAs(ADMIN)
    const before = await db.auditLog.count({ where: { action: 'SETTINGS_UPDATED' } })
    await request(
      hotelRoute.PATCH as unknown as (r: Request) => Promise<Response>,
      'http://localhost/api/admin/hotel',
      { method: 'PATCH', body: { minAppVersion: '1.1.0' }, headers: bearer(token) }
    )
    const after = await db.auditLog.count({ where: { action: 'SETTINGS_UPDATED' } })
    expect(after).toBeGreaterThan(before)
    const last = await db.auditLog.findFirst({
      where: { action: 'SETTINGS_UPDATED' },
      orderBy: { createdAt: 'desc' },
    })
    const details = JSON.parse(last!.details as string) as { changed: Record<string, unknown> }
    expect(details.changed.minAppVersion).toBe('1.1.0')
    expect(last!.actorRole).toBe('ADMIN')
  })
})

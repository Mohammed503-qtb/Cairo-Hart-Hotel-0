// ═══════════════════════════════════════════════════════════════════
// H3 — اختبارات عقد المصادقة للعميل الثاني (Mobile-ready Auth)
// المسار: إصدار → نداء محمي → تجديد → إبطال/انتهاء/كود ملغي → بلا توكن
//
// بنية الاختبار المشتركة (tests/helpers/test-db.ts — لا تُعدَّل):
//   أول سطر حرفي يضبط DATABASE_URL على قاعدة اختبار معزولة (auth)
//   قبل أي استيراد لوحدات src/ (PrismaClient يُبنى لحظة أول
//   استيراد ويقرأ DATABASE_URL وقتها) — ثم setupTestDb('auth')
//   (حذف + migrate deploy + seed بالمسار الرسمي) ثم استيراد
//   ديناميكي فقط لوحدات src/. الاستيراد الثابت لحامل الاختبار آمن.
//
// الثوابت الموثقة المغطاة هنا:
//   H3    : التجديد (POST /api/auth/renew) يمديد نفس التوكن بعمر
//           min(12 ساعة، صلاحية الكود) — لا يصدر توكنًا جديدًا
//   I4    : كود غير ACTIVE لا يعمل — getAuth يفحص الكود مع كل طلب
//   I11   : الجلسة تموت مع الكود/الخروج — هنا عبر إبطال الجلسة
//           يدويًا أو إبطال الكود (نفس ما يفعله check-out/codes-revoke)
//   §1.2  : 401 الحرفي «جلسة غير صالحة أو منتهية — سجّل الدخول من جديد»
//
// تحذير rate-limit موثق: الـ limiter في الذاكرة داخل العملية —
//   validate محدود 5/دقيقة وrenew 10/دقيقة لكل IP → كل نداء إصدار/تجديد
//   يمرر ترويسة x-forwarded-for مستقلة (clientIp في src/lib/rate-limit.ts
//   يقرؤها) — إجمالي نداءات validate هنا 3 وrenew 5، كلها تحت السقف.
// ═══════════════════════════════════════════════════════════════════
process.env.DATABASE_URL = 'file:/home/z/my-project/db/test-auth.db'

import { describe, it, expect } from 'bun:test'
import { setupTestDb } from '../helpers/test-db'

setupTestDb('auth')

// ── استيراد ديناميكي بعد ضبط البيئة (توقيعات مطبَّعة كـ Request) ──
const { POST: validate } = (await import('@/app/api/auth/validate/route')) as {
  POST: (req: Request) => Promise<Response>
}
const { POST: renew } = (await import('@/app/api/auth/renew/route')) as {
  POST: (req: Request) => Promise<Response>
}
const { GET: guestDashboard } = (await import('@/app/api/guest/dashboard/route')) as {
  GET: (req: Request) => Promise<Response>
}
const { db } = await import('@/lib/db')

// ── أدوات النداء المباشر (لا شبكة — استدعاء دوال المسار كما هي) ──
const GUEST_KHALED = 'H834729X7'
const INVALID_SESSION_MSG = 'جلسة غير صالحة أو منتهية — سجّل الدخول من جديد'

function postJson(path: string, body: unknown, headers: Record<string, string> = {}): Request {
  return new Request(`http://localhost${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  })
}

function postRenew(ip: string, token?: string): Request {
  const headers: Record<string, string> = { 'x-forwarded-for': ip }
  if (token) headers.authorization = `Bearer ${token}`
  return new Request('http://localhost/api/auth/renew', { method: 'POST', headers })
}

function getWithToken(path: string, token: string): Request {
  return new Request(`http://localhost${path}`, {
    headers: { authorization: `Bearer ${token}` },
  })
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

// حالة تتقاسمها السيناريوهات المتسلسلة (bun:test يشغّل it بالترتيب)
let token1 = ''
let issuedExpiresAt = ''

describe('H3 — عقد المصادقة: إصدار → استخدام → تجديد → موت الجلسة', () => {
  it('a) دخول بكود ضيف H834729X7 → 200 + توكن GUEST (استجابة مسطحة)', async () => {
    const res = await validate(
      postJson('/api/auth/validate', { code: GUEST_KHALED }, { 'x-forwarded-for': '10.9.0.1' })
    )
    expect(res.status).toBe(200)
    const body = await res.json()
    // شكل validate الفعلي: { ok, token, role, name, expiresAt } — مسطح بلا غلاف data
    expect(body.ok).toBe(true)
    expect(typeof body.token).toBe('string')
    expect(body.token.length).toBeGreaterThan(0)
    expect(body.role).toBe('GUEST')
    expect(body.name).toBe('خالد يوسف')
    expect(typeof body.expiresAt).toBe('string')
    token1 = body.token
    issuedExpiresAt = body.expiresAt
  })

  it('b) نداء محمي بالتوكن (GET /api/guest/dashboard عبر ترويسة authorization) → 200', async () => {
    const res = await guestDashboard(getWithToken('/api/guest/dashboard', token1))
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.ok).toBe(true)
    // عزل البيانات: إقامة خالد فقط (stayId من الجلسة لا من الطلب)
    expect(body.stay.reference).toBe('ST-2026-000883')
    expect(body.stay.guestName).toBe('خالد يوسف')
  })

  it('c) renew بالتوكن → 200 + expiresAt جديدة لاحقة للقديمة — ونفس التوكن يُمدَّد لا يُستبدل', async () => {
    // فاصل زمني مضمون بين لحظة الإصدار ولحظة التجديد (العمر = الآن+12س
    // في الحالتين لأن صلاحية الكود أبعد) حتى تكون الجديدة لاحقة بدقة
    await sleep(50)

    const res = await renew(postRenew('10.9.1.1', token1))
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.ok).toBe(true)
    expect(typeof body.expiresAt).toBe('string')
    expect(new Date(body.expiresAt).getTime()).toBeGreaterThan(new Date(issuedExpiresAt).getTime())
    // العقد: لا يُصدر توكنًا جديدًا — الاستجابة بلا حقل token
    expect(body.token).toBeUndefined()

    // التوكن المخزَّن لدى العميل يبقى صالحًا بعد التجديد (نفس التوكن)
    const dash = await guestDashboard(getWithToken('/api/guest/dashboard', token1))
    expect(dash.status).toBe(200)
    expect((await dash.json()).ok).toBe(true)

    // القاعدة فعلًا امتُدت في نفس سجل الجلسة (نفس التوكن لا سجل جديد)
    const sess = await db.session.findUnique({ where: { token: token1 } })
    expect(sess).not.toBeNull()
    expect(sess!.revoked).toBe(false)
    expect(sess!.expiresAt.toISOString()).toBe(body.expiresAt)
    expect(sess!.lastSeenAt).not.toBeNull()
  })

  it('d) renew بعد إبطال الجلسة يدويًا في قاعدة الاختبار (revoked=true) → 401', async () => {
    await db.session.update({ where: { token: token1 }, data: { revoked: true } })
    const res = await renew(postRenew('10.9.2.1', token1))
    expect(res.status).toBe(401)
    const body = await res.json()
    expect(body.ok).toBe(false)
    expect(body.error).toBe(INVALID_SESSION_MSG)
  })

  it('e) renew بعد انتهاء الجلسة (expiresAt في الماضي) → 401', async () => {
    // جلسة جديدة (توكن ثانٍ) ثم إنهاؤها في القاعدة مباشرة
    const login = await validate(
      postJson('/api/auth/validate', { code: GUEST_KHALED }, { 'x-forwarded-for': '10.9.0.2' })
    )
    expect(login.status).toBe(200)
    const { token: token2 } = await login.json()

    await db.session.update({
      where: { token: token2 },
      data: { expiresAt: new Date(Date.now() - 3600_000) },
    })

    const res = await renew(postRenew('10.9.3.1', token2))
    expect(res.status).toBe(401)
    const body = await res.json()
    expect(body.ok).toBe(false)
    expect(body.error).toBe(INVALID_SESSION_MSG)
  })

  it('f) نداء محمي بعد إبطال الكود (accessCode.status=REVOKED) → 401 (I4)', async () => {
    // توكن ثالث سليم أولًا — يثبت أن 401 سببه الكود لا شيء آخر
    const login = await validate(
      postJson('/api/auth/validate', { code: GUEST_KHALED }, { 'x-forwarded-for': '10.9.0.3' })
    )
    expect(login.status).toBe(200)
    const { token: token3 } = await login.json()

    const before = await guestDashboard(getWithToken('/api/guest/dashboard', token3))
    expect(before.status).toBe(200)

    const sess = await db.session.findUnique({ where: { token: token3 } })
    expect(sess).not.toBeNull()
    await db.accessCode.update({
      where: { id: sess!.accessCodeId },
      data: { status: 'REVOKED' },
    })

    // getAuth يفحص الكود مع كل طلب → الجلسة ماتت مع الكود (I11)
    const after = await guestDashboard(getWithToken('/api/guest/dashboard', token3))
    expect(after.status).toBe(401)
    const body = await after.json()
    expect(body.ok).toBe(false)
    expect(body.error).toBe(INVALID_SESSION_MSG)
  })

  it('g) renew بلا ترويسة Authorization / بتوكن ملفق → 401', async () => {
    // بلا ترويسة إطلاقًا
    const noHeader = await renew(postRenew('10.9.4.1'))
    expect(noHeader.status).toBe(401)
    const noHeaderBody = await noHeader.json()
    expect(noHeaderBody.ok).toBe(false)
    expect(noHeaderBody.error).toBe(INVALID_SESSION_MSG)

    // توكن ملفق غير موجود في القاعدة
    const forged = await renew(postRenew('10.9.5.1', 'forge-00000000-0000-0000-0000-000000000000'))
    expect(forged.status).toBe(401)
    const forgedBody = await forged.json()
    expect(forgedBody.ok).toBe(false)
    expect(forgedBody.error).toBe(INVALID_SESSION_MSG)
  })
})

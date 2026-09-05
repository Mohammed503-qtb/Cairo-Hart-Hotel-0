// ─────────────────────────────────────────────────────────────
// SMOKE — الفحص اليومي الآلي للمسار الذهبي (F7 · P3 — Task 24-d)
//
//رحلة كاملة عبر HTTP حي ضد الخادم الجاري (BASE_URL افتراضيًا
// http://localhost:3000): صحة → فندق → توفر → حجز PAY_AT_HOTEL →
// إعادة تشغيل Idempotency (I8) → دخول أدمن → إنشاء موظف استقبال
// حقيقي + توليد كوده (يُختبر فورًا) → وصول الضيف (كود الضيف مرة
// واحدة I11-track) → طلب خدمة → محادثة → بند فاتورة → دفعة →
// تسوية الرصيد صفر (§12.2) → خروج → موت كود الضيف (I11) →
// خدمة Realtime حية.
//
// لا يعتمد على أرقام seed: الأرقام المالية تُحسب من عرض التوفر
// نفسه (المصدر الوحيد للحقيقة = استجابة الخادم).
//
// الاستخدام:
//   bun run scripts/smoke.ts
//   ADMIN_CODE=A123456Z9 bun run scripts/smoke.ts
//
// ملاحظة حدود المعدل: الدخول 5/دقيقة لكل IP — لا تكرر السكربت
// خلال دقيقة واحدة وإلا رأيت 429 (وهو بحد ذاته دليل أن الحارس
// يعمل — لكنه سيفشل هذه الرحلة).
// ─────────────────────────────────────────────────────────────

const BASE = process.env.BASE_URL ?? 'http://localhost:3000'
const RT_URL = process.env.RT_URL ?? 'http://localhost:3002'
const ADMIN_CODE = process.env.ADMIN_CODE ?? 'A371849L9' // كود seed الافتراضي — أو مرر ADMIN_CODE=

/** حالة إنشاء مقبولة (200 في بعض المسارات و201 في أخرى — كلاهما نجاح) */
const created = (status: number): boolean => status === 200 || status === 201

// ── أدوات ──
let stepCount = 0
let failures = 0
const t0 = Date.now()

function log(step: string, pass: boolean, detail = '') {
  stepCount += 1
  const mark = pass ? '✅' : '❌'
  if (!pass) failures += 1
  console.log(`${mark} ${String(stepCount).padStart(2, '0')} · ${step}${detail ? ` — ${detail}` : ''}`)
}

function isoDay(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}
const inDays = (n: number): string => {
  const d = new Date()
  d.setDate(d.getDate() + n)
  return isoDay(d)
}

async function call(
  method: string,
  path: string,
  body?: unknown,
  token?: string
): Promise<{ status: number; j: any }> {
  const headers: Record<string, string> = { 'content-type': 'application/json' }
  if (token) headers.authorization = `Bearer ${token}`
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  let j: any = null
  try {
    j = await res.json()
  } catch {
    /* استجابة غير JSON */
  }
  return { status: res.status, j }
}

async function login(code: string): Promise<{ token: string; role: string; name: string }> {
  const { j } = await call('POST', '/api/auth/validate', { code })
  if (!j?.ok) throw new Error(`فشل الدخول بالكود — ${j?.error ?? 'استجابة غير متوقعة'}`)
  return j
}

// ── الرحلة ──
async function main() {
  console.log('═'.repeat(64))
  console.log(`SMOKE — المسار الذهبي ضد ${BASE}`)
  console.log('═'.repeat(64))

  // 1) الصحة
  const health = await call('GET', '/api/health')
  log('GET /api/health', health.status === 200 && health.j?.ok === true && health.j?.db === true,
    `db=${health.j?.db} · took ${health.j?.tookMs}ms`)

  // 2) الفندق العام
  const hotel = await call('GET', '/api/public/hotel')
  log('GET /api/public/hotel', hotel.status === 200 && !!hotel.j?.hotel?.name, hotel.j?.hotel?.name ?? '')

  // 3) التوفر
  const checkIn = inDays(7)
  const checkOut = inDays(9)
  const avail = await call('POST', '/api/public/availability', {
    checkIn, checkOut, adults: 2, children: 0, roomsCount: 1,
  })
  const items: any[] = avail.j?.items ?? []
  log('POST /api/public/availability', avail.status === 200 && items.length >= 1 && items.some((i) => i.availableCount > 0), `${items.length} أنواع · ${checkIn}→${checkOut}`)

  // اختيار النوع الأول المتاح + اعتماد عرضه مرجعًا للمال
  const chosen = items.find((i) => i.availableCount > 0)
  if (!chosen) {
    log('اختيار نوع غرفة متاح', false, 'لا توفر — لا يمكن إكمال الرحلة')
    return finish()
  }
  log('اختيار نوع غرفة متاح', true, `${chosen.roomType.name} · متاح ${chosen.availableCount}`)

  const idem = `smoke-${Date.now()}`
  const guestPhone = `+9677${String(Math.floor(10000000 + Math.random() * 89999999))}`

  // 4) الحجز
  const booking = await call('POST', '/api/public/bookings', {
    checkIn, checkOut, adults: 2, children: 0, roomsCount: 1,
    roomTypeId: chosen.roomType.id,
    guest: { fullName: 'فحص يومي آلي', phone: guestPhone },
    paymentMethod: 'PAY_AT_HOTEL',
    idempotencyKey: idem,
  })
  const r: any = booking.j?.reservation
  const refOk = typeof r?.bookingReference === 'string' && /^HTL-\d{4}-\d{6}$/.test(r.bookingReference)
  log('POST /api/public/bookings (201)', booking.status === 201 && !!r && refOk, r?.bookingReference ?? booking.j?.error ?? '')

  // 5) تطابق المجاميع مع عرض التوفر (I6)
  const totalsOk = r && chosen.quote.grandTotalCents === r.grandTotalCents
  log('المجاميع من التوفر = المجاميع من الحجز (I6)', totalsOk === true,
    `quote=${chosen.quote.grandTotalCents} · booked=${r?.grandTotalCents}`)

  // 6) إعادة التشغيل بنفس المفتاح (I8)
  const replay = await call('POST', '/api/public/bookings', {
    checkIn, checkOut, adults: 2, children: 0, roomsCount: 1,
    roomTypeId: chosen.roomType.id,
    guest: { fullName: 'فحص يومي آلي', phone: guestPhone },
    paymentMethod: 'PAY_AT_HOTEL',
    idempotencyKey: idem,
  })
  log('إعادة Idempotency نفس الحجز (I8)', replay.j?.replayed === true && replay.j?.reservation?.id === r?.id,
    replay.j?.replayed === true ? 'replayed' : String(replay.j?.replayed))

  // 7) دخول الأدمن
  let admin: { token: string; role: string; name: string } | null = null
  try {
    admin = await login(ADMIN_CODE)
    log('دخول الأدمن', admin.role === 'ADMIN', `${admin.name} (${admin.role})`)
  } catch (e: any) {
    log('دخول الأدمن', false, e?.message ?? '')
    return finish()
  }

  // 8) إنشاء موظف استقبال حقيقي (اختبار مسار الطاقم)
  const staffRes = await call('POST', '/api/admin/staff', {
    fullName: 'استقبال الفحص اليومي', role: 'RECEPTION', phone: '+967700000019',
  }, admin.token)
  const staffId = staffRes.j?.staffMember?.id
  log('POST /api/admin/staff (RECEPTION)', created(staffRes.status) && !!staffId, staffRes.j?.staffMember?.fullName ?? staffRes.j?.error ?? '')

  // 9) توليد كود استقبال — الكود الخام مرة واحدة
  const genRes = await call('POST', '/api/admin/codes', {
    type: 'RECEPTION', staffId, days: 7,
  }, admin.token)
  const receptionCode: string | undefined = genRes.j?.code
  log('توليد كود استقبال (خام مرة واحدة)', created(genRes.status) && !!receptionCode, genRes.j?.codeMasked ?? genRes.j?.error ?? '')

  // 10) الكود المولَّد يعمل فورًا
  let reception: { token: string; role: string; name: string } | null = null
  try {
    reception = receptionCode ? await login(receptionCode) : null
    log('دخول بالكود المولَّد حديثًا', !!reception && reception.role === 'RECEPTION', reception?.name ?? '')
  } catch (e: any) {
    log('دخول بالكود المولَّد حديثًا', false, e?.message ?? '')
    return finish()
  }

  // 11) لوحة الاستقبال
  const rd = await call('GET', '/api/reception/dashboard', undefined, reception!.token)
  log('GET /api/reception/dashboard', rd.status === 200 && rd.j?.ok === true)

  // 12) الغرف — اختر غرفة متاحة من نفس النوع
  const roomsRes = await call('GET', '/api/reception/rooms', undefined, reception!.token)
  const rooms: any[] = roomsRes.j?.rooms ?? []
  const room = rooms.find((x: any) => x.roomTypeId === chosen.roomType.id && x.status === 'AVAILABLE')
  log('GET /api/reception/rooms (اختيار غرفة)', roomsRes.status === 200 && !!room, room ? `غرفة ${room.number}` : 'لا غرفة متاحة من النوع')

  if (!r || !room) return finish()

  // 13) تسجيل الوصول (كود الضيف يُصدر مرة واحدة)
  const ci = await call('POST', '/api/reception/check-in', {
    reservationId: r.id, roomId: room.id,
  }, reception!.token)
  const guestCode: string | undefined = ci.j?.guestCode
  const stayId: string | undefined = ci.j?.stay?.id
  const stayRefOk = typeof ci.j?.stay?.reference === 'string' && /^ST-\d{4}-\d{6}$/.test(ci.j.stay.reference)
  log('POST /api/reception/check-in', created(ci.status) && !!guestCode && !!stayId && stayRefOk,
    `${ci.j?.stay?.reference ?? ''} · غرفة ${ci.j?.roomNumber ?? ''} · كود ${ci.j?.guestCode ?? '—'}`)

  if (!guestCode || !stayId) return finish()

  // 14) دخول الضيف بكوده
  let guest: { token: string; role: string; name: string } | null = null
  try {
    guest = await login(guestCode)
    log('دخول الضيف بكود الوصول', guest.role === 'GUEST', guest.name)
  } catch (e: any) {
    log('دخول الضيف بكود الوصول', false, e?.message ?? '')
    return finish()
  }

  // 15) لوحة الضيف
  const gd = await call('GET', '/api/guest/dashboard', undefined, guest.token)
  log('GET /api/guest/dashboard', gd.status === 200 && gd.j?.ok === true)

  // 16) طلب خدمة
  const req = await call('POST', '/api/guest/requests', {
    title: 'فحص آلي — منشفة إضافية', description: 'طلب مولَّد من الفحص اليومي الآلي',
    category: 'HOUSEKEEPING', priority: 'NORMAL',
  }, guest.token)
  const reqRef: string | undefined = req.j?.request?.reference
  const reqRefOk = typeof reqRef === 'string' && /^REQ-\d{4,6}$/.test(reqRef) // REQ-1042 (refs.ts)
  log('POST /api/guest/requests', created(req.status) && reqRefOk, reqRef ?? req.j?.error ?? '')

  // 17) رسالة محادثة من الضيف
  const msg = await call('POST', '/api/guest/messages', {
    body: 'رسالة فحص آلي — شكرًا',
  }, guest.token)
  log('POST /api/guest/messages', created(msg.status) && msg.j?.ok === true, msg.j?.error ?? '')

  // 18) رد الاستقبال
  const rmsg = await call('POST', '/api/reception/messages', {
    stayId, body: 'رد فحص آلي — على الفور',
  }, reception!.token)
  log('POST /api/reception/messages (رد)', created(rmsg.status) && rmsg.j?.ok === true, rmsg.j?.error ?? '')

  // 19) بند فاتورة
  const CHARGE = 5000
  const ch = await call('POST', '/api/reception/charges', {
    stayId, description: 'فحص آلي — بند فاتورة', amountCents: CHARGE, category: 'SERVICE',
  }, reception!.token)
  log('POST /api/reception/charges', created(ch.status) && ch.j?.charge?.amountCents === CHARGE,
    `رصيد بعده ${ch.j?.balanceCents ?? '—'} سنت`)

  // 20) دفعة تسوية كاملة
  const PAY = r.grandTotalCents + CHARGE
  const pay = await call('POST', '/api/reception/payments', {
    stayId, method: 'CASH', amountCents: PAY, note: 'تسوية فحص آلي',
  }, reception!.token)
  log('POST /api/reception/payments', created(pay.status) && pay.j?.balanceCents === 0,
    `مدفوع ${pay.j?.paidCents ?? '—'} · رصيد ${pay.j?.balanceCents ?? '—'}`)

  // 21) فاتورة الضيف — رصيد صفر (§12.2)
  const bill = await call('GET', '/api/guest/bill', undefined, guest.token)
  log('GET /api/guest/bill رصيد=0 (§12.2)', bill.status === 200 && bill.j?.bill?.balanceCents === 0,
    `grand+charges−paid = ${bill.j?.bill?.balanceCents ?? '—'}`)

  // 22) الخروج
  const co = await call('POST', '/api/reception/check-out', { stayId }, reception!.token)
  log('POST /api/reception/check-out', co.status === 200 && co.j?.ok === true && co.j?.closed === true, co.j?.error ?? `رصيد ختامي ${co.j?.balanceCents ?? '—'}`)

  // 23) كود الضيف مات بعد الخروج (I11)
  const dead = await call('GET', '/api/guest/dashboard', undefined, guest.token)
  log('كود الضيف مات بعد الخروج (I11)', dead.status === 401, `HTTP ${dead.status}`)

  // 24) Realtime حي (polling socket.io)
  let rtOk = false
  let rtDetail = ''
  try {
    const rt = await fetch(`${RT_URL}/socket.io/?EIO=4&transport=polling`)
    const text = await rt.text()
    rtOk = rt.status === 200 && text.includes('"sid"')
    rtDetail = rtOk ? 'sid' : text.slice(0, 40)
  } catch (e: any) {
    rtDetail = e?.message ?? ''
  }
  log('Realtime 3002 (polling)', rtOk, rtDetail)

  await finish()
}

async function finish() {
  console.log('─'.repeat(64))
  const secs = ((Date.now() - t0) / 1000).toFixed(1)
  if (failures === 0) {
    console.log(`🟢 SMOKE PASSED — ${stepCount} فحصًا في ${secs}s`)
  } else {
    console.log(`🔴 SMOKE FAILED — ${failures} من ${stepCount} فشلت (في ${secs}s)`)
    process.exitCode = 1
  }
}

main().catch((e) => {
  console.error('خطأ غير متوقع في الفحص:', e)
  process.exitCode = 1
})

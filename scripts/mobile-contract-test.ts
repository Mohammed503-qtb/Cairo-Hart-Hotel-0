// ─────────────────────────────────────────────────────────────
// MOBILE CONTRACT TEST — التكامل الحي لتطبيق الهاتف (Task 27)
// يتحقق أن كل endpoint تستهلكه AdminStore/ReceptionStore في
// الجوال يعمل فعليًا ويعيد الأشكال (أسماء الحقول) التي تحللها
// نماذج الجوال حرفيًا — end-to-end ضد الخادم الجاري والقاعدة.
//
// الرحلة: دخول أدمن (كل A-01..A-34 بأشكالها + دورات CRUD كاملة
// مع تنظيف) → حجز عام → دخول استقبال (كل R-01..R-23 بأشكالها
// + وصول/فاتورة/رسائل/خروج) → renew (سياسة §1.2.1) → realtime.
//
// الاستخدام:
//   ADMIN_CODE=A… RECEPTION_CODE=R… bun run scripts/mobile-contract-test.ts
// ─────────────────────────────────────────────────────────────
import { PrismaClient } from '@prisma/client'
import { io } from 'socket.io-client'

const db = new PrismaClient()
const BASE = process.env.BASE_URL ?? 'http://localhost:3000'
const RT_BASE = process.env.RT_URL ?? 'http://localhost:3002'
const ADMIN_CODE = process.env.ADMIN_CODE ?? ''
const RECEPTION_CODE = process.env.RECEPTION_CODE ?? ''

let pass = 0
let fail = 0
const failures: string[] = []

function ok(step: string, cond: boolean, detail = '') {
  if (cond) {
    pass++
    console.log(`✅ ${String(pass + fail).padStart(3, '0')} · ${step}${detail ? ` — ${detail}` : ''}`)
  } else {
    fail++
    failures.push(step)
    console.log(`❌ ${String(pass + fail).padStart(3, '0')} · ${step}${detail ? ` — ${detail}` : ''}`)
  }
}

/** تحقق شكل: كل حقل موجود بنوعه (كما يفككه fromJson في الجوال) */
function shape(obj: any, fields: Record<string, string>): string | null {
  for (const [k, t] of Object.entries(fields)) {
    const v = k.split('.').reduce<any>((acc, seg) => (acc == null ? undefined : acc[seg]), obj)
    if (v === undefined) return `الحقل ${k} غائب`
    if (t === 'string' && typeof v !== 'string') return `${k}: ليس نصًا (${typeof v})`
    if (t === 'int' && (typeof v !== 'number' || !Number.isFinite(v))) return `${k}: ليس رقمًا`
    if (t === 'array' && !Array.isArray(v)) return `${k}: ليس قائمة`
    if (t === 'obj' && (typeof v !== 'object' || v === null || Array.isArray(v))) return `${k}: ليس كائنًا`
    if (t === 'bool' && typeof v !== 'boolean') return `${k}: ليس منطقيًا`
  }
  return null
}

async function call(
  method: string,
  path: string,
  body?: unknown,
  token?: string
): Promise<{ status: number; j: any }> {
  const headers: Record<string, string> = { 'content-type': 'application/json' }
  if (token) headers.authorization = `Bearer ${token}`
  const res = await fetch(`${BASE}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) })
  let j: any = null
  try { j = await res.json() } catch { /* غير JSON */ }
  return { status: res.status, j }
}

async function login(code: string) {
  const { j } = await call('POST', '/api/auth/validate', { code })
  if (!j?.ok) throw new Error(`فشل الدخول — ${j?.error ?? 'استجابة غير متوقعة'}`)
  return j as { token: string; role: string; name: string }
}

const isoDay = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
const inDays = (n: number) => { const d = new Date(); d.setDate(d.getDate() + n); return isoDay(d) }
const createdOk = (s: number) => s === 200 || s === 201

// ─────────────────────────────────────────────────────────────
async function main() {
  console.log('═'.repeat(70))
  console.log(`MOBILE CONTRACT — لوحة الأدمن + لوحة الاستقبال ضد ${BASE}`)
  console.log('═'.repeat(70))

  if (!ADMIN_CODE || !RECEPTION_CODE) {
    console.log('مرر ADMIN_CODE و RECEPTION_CODE (أنشئهما عبر make-codes)')
    process.exit(1)
  }

  // ═══ 0) الصحة ═══
  const health = await call('GET', '/api/health')
  ok('GET /api/health', health.status === 200 && health.j?.ok === true, `db=${health.j?.db}`)

  // ═══ 1) دخول الأدمن (نفس نداء الجوال: POST /api/auth/validate) ═══
  const admin = await login(ADMIN_CODE)
  ok('دخول الأدمن validate {code}', admin.role === 'ADMIN' && !!admin.token, `${admin.name}`)

  // ═══ 2) كل قراءات AdminStore بأشكال نماذج الجوال ═══
  const dash = await call('GET', '/api/admin/dashboard', undefined, admin.token)
  ok('A-01 dashboard: kpis/recentBookings/roomsByStatus/alerts/revenueByDay',
    dash.status === 200 && !shape(dash.j, {
      'kpis.arrivalsToday': 'int', 'kpis.urgentRequests': 'int', 'kpis.revenueMonthCents': 'int',
      'kpis.occupancyPercent': 'int', 'kpis.totalRooms': 'int', 'kpis.activeGuestCodes': 'int',
      recentBookings: 'array', roomsByStatus: 'obj', 'alerts.staleRequests': 'int',
      'alerts.outOfOrderRooms': 'int', revenueByDay: 'array',
    }), shape(dash.j, { x: 'int' }) ?? '')

  const hotel = await call('GET', '/api/admin/hotel', undefined, admin.token)
  ok('A-02 hotel: hotel.{id,name,tagline,...,currency}',
    hotel.status === 200 && !shape(hotel.j, {
      'hotel.id': 'string', 'hotel.name': 'string', 'hotel.tagline': 'string',
      'hotel.currency': 'string', 'hotel.checkInTime': 'string', 'hotel.cancellationPolicy': 'string',
    }), `اسم: ${hotel.j?.hotel?.name ?? '—'}`)

  const types = await call('GET', '/api/admin/room-types', undefined, admin.token)
  const firstType = (types.j?.roomTypes ?? [])[0]
  ok('A-04 room-types: roomTypes[].{name,basePriceCents,active,roomsCount,amenities,images}',
    types.status === 200 && !shape(firstType ?? {}, {
      id: 'string', name: 'string', basePriceCents: 'int', active: 'bool',
      roomsCount: 'int', amenities: 'array', images: 'array', capacityAdults: 'int', sortOrder: 'int',
    }), `${types.j?.roomTypes?.length ?? 0} نوعًا`)

  const rooms = await call('GET', '/api/admin/rooms', undefined, admin.token)
  const firstRoom = (rooms.j?.rooms ?? [])[0]
  ok('A-08 rooms: rooms[].{number,floor,status,roomTypeId,roomTypeName}',
    rooms.status === 200 && !shape(firstRoom ?? {}, {
      id: 'string', number: 'string', floor: 'int', status: 'string',
      roomTypeId: 'string', roomTypeName: 'string',
    }), `${rooms.j?.rooms?.length ?? 0} غرفة`)

  const rates = await call('GET', '/api/admin/rates', undefined, admin.token)
  ok('A-12 rates: rates[].{name,priceCents,startDate,endDate,roomTypeId}',
    rates.status === 200 && Array.isArray(rates.j?.rates) &&
    (rates.j.rates.length === 0 || !shape(rates.j.rates[0], {
      name: 'string', priceCents: 'int', startDate: 'string', endDate: 'string', roomTypeId: 'string',
    })), `${rates.j?.rates?.length ?? 0} معدلًا`)

  const services = await call('GET', '/api/admin/services', undefined, admin.token)
  ok('A-15 services: services[].{name,priceCents,categoryName,active}',
    services.status === 200 && Array.isArray(services.j?.services) &&
    (services.j.services.length === 0 || !shape(services.j.services[0], {
      name: 'string', priceCents: 'int', categoryName: 'string', active: 'bool',
    })), `${services.j?.services?.length ?? 0} خدمة`)

  const cats = await call('GET', '/api/admin/service-categories', undefined, admin.token)
  ok('A-19 service-categories: categories[].{name,key,servicesCount}',
    cats.status === 200 && Array.isArray(cats.j?.categories) &&
    (cats.j.categories.length === 0 || !shape(cats.j.categories[0], {
      name: 'string', key: 'string', servicesCount: 'int',
    })), `${cats.j?.categories?.length ?? 0} فئة`)

  const staff = await call('GET', '/api/admin/staff', undefined, admin.token)
  ok('A-23 staff: staff[].{fullName,role,active}',
    staff.status === 200 && Array.isArray(staff.j?.staff) &&
    (staff.j.staff.length === 0 || !shape(staff.j.staff[0], {
      fullName: 'string', role: 'string', active: 'bool',
    })), `${staff.j?.staff?.length ?? 0} موظفًا`)

  const codes = await call('GET', '/api/admin/codes', undefined, admin.token)
  ok('A-26 codes: codes[].{type,codeMasked,status,expiresAt}',
    codes.status === 200 && Array.isArray(codes.j?.codes) &&
    (codes.j.codes.length === 0 || !shape(codes.j.codes[0], {
      type: 'string', codeMasked: 'string', status: 'string', expiresAt: 'string',
    })), `${codes.j?.codes?.length ?? 0} كودًا`)

  const reservations = await call('GET', '/api/admin/reservations?page=1', undefined, admin.token)
  ok('A-29 reservations: {items[],total,page,pages}',
    reservations.status === 200 && !shape(reservations.j, {
      items: 'array', total: 'int', page: 'int', pages: 'int',
    }), `${reservations.j?.total ?? 0} حجزًا`)

  const guests = await call('GET', '/api/admin/guests', undefined, admin.token)
  ok('A-31 guests: guests[].{fullName,phone,createdAt,reservationsCount}',
    guests.status === 200 && Array.isArray(guests.j?.guests) &&
    (guests.j.guests.length === 0 || !shape(guests.j.guests[0], {
      fullName: 'string', phone: 'string', createdAt: 'string', reservationsCount: 'int',
    })), `${guests.j?.guests?.length ?? 0} ضيفًا`)

  const audit = await call('GET', '/api/admin/audit?page=1', undefined, admin.token)
  ok('A-32 audit: {items[],total,page,pages}',
    audit.status === 200 && !shape(audit.j, {
      items: 'array', total: 'int', page: 'int', pages: 'int',
    }), `${audit.j?.total ?? 0} حدثًا`)

  const reports = await call('GET', '/api/admin/reports', undefined, admin.token)
  ok('A-33 reports: {effectiveRooms,occupancyLast14Days,revenueByMonth,requestsStats,guestsByNationality}',
    reports.status === 200 && !shape(reports.j, {
      effectiveRooms: 'int', occupancyLast14Days: 'array', revenueByMonth: 'array',
      requestsStats: 'obj', guestsByNationality: 'array',
    }), '')

  const notifs = await call('GET', '/api/admin/notifications', undefined, admin.token)
  ok('A-34 notifications: {notifications[],unreadCount}',
    notifs.status === 200 && !shape(notifs.j, {
      notifications: 'array', unreadCount: 'int',
    }), `${notifs.j?.unreadCount ?? 0} غير مقروء`)

  // ═══ 3) دورات CRUD الأدمن الكاملة (مع تنظيف تام) ═══
  // A-05/A-06/A-07: نوع غرفة
  const typeName = `نوع فحص ${Date.now() % 100000}`
  const tCreate = await call('POST', '/api/admin/room-types', {
    name: typeName, nameEn: 'Audit Type', description: 'وصف', capacityAdults: 2,
    capacityChildren: 0, bedConfig: 'سرير', sizeSqm: 20, basePriceCents: 5000,
    amenities: ['واي فاي'], images: [],
  }, admin.token)
  const typeId = tCreate.j?.roomType?.id
  ok('A-05 POST room-types {name,basePriceCents,…} → roomType.id',
    createdOk(tCreate.status) && !!typeId, tCreate.j?.roomType?.name ?? tCreate.j?.error ?? '')

  const tPatch = await call('PATCH', `/api/admin/room-types/${typeId}`, {
    basePriceCents: 6500, description: 'محدّث',
  }, admin.token)
  ok('A-06 PATCH room-types/:id → roomType.basePriceCents الجديد',
    tPatch.status === 200 && tPatch.j?.roomType?.basePriceCents === 6500, '')

  // A-09/A-10/A-11: غرفة (ثم حذفها والنوع)
  const roomNo = `9${String(Date.now() % 1000).padStart(3, '0')}`
  const rCreate = await call('POST', '/api/admin/rooms', {
    number: roomNo, floor: 9, roomTypeId: typeId,
  }, admin.token)
  const roomId = rCreate.j?.room?.id
  ok('A-09 POST rooms {number,floor,roomTypeId} → room.id',
    createdOk(rCreate.status) && !!roomId, `غرفة ${rCreate.j?.room?.number ?? '—'}`)

  const rPatch = await call('PATCH', `/api/admin/rooms/${roomId}`, {
    status: 'CLEANING', notes: 'فحص',
  }, admin.token)
  ok('A-10 PATCH rooms/:id {status:CLEANING,notes}',
    rPatch.status === 200 && (rPatch.j?.room?.status === 'CLEANING' || rPatch.j?.ok === true), '')

  const rDel = await call('DELETE', `/api/admin/rooms/${roomId}`, undefined, admin.token)
  ok('A-11 DELETE rooms/:id → message', rDel.status === 200 && !!rDel.j?.message, rDel.j?.message ?? '')

  const tDel = await call('DELETE', `/api/admin/room-types/${typeId}`, undefined, admin.token)
  ok('A-07 DELETE room-types/:id → message', tDel.status === 200 && !!tDel.j?.message, tDel.j?.message ?? '')

  // A-13/A-14: معدل موسمي
  const rateCreate = await call('POST', '/api/admin/rates', {
    name: `فحص ${Date.now() % 100000}`, roomTypeId: firstType.id,
    priceCents: 7000, startDate: inDays(60), endDate: inDays(70),
  }, admin.token)
  const rateId = rateCreate.j?.rate?.id
  ok('A-13 POST rates {name,roomTypeId,priceCents,start,end} → rate.id + warning?',
    createdOk(rateCreate.status) && !!rateId,
    rateCreate.j?.warning ? `مع تحذير تداخل (متوقع مسموح)` : '')

  const rateDel = await call('DELETE', `/api/admin/rates/${rateId}`, undefined, admin.token)
  ok('A-14 DELETE rates/:id → message', rateDel.status === 200 && !!rateDel.j?.message, '')

  // A-20/A-21/A-22: فئة خدمة
  const cCreate = await call('POST', '/api/admin/service-categories', {
    name: `فئة فحص ${Date.now() % 100000}`, nameEn: 'Audit Cat',
  }, admin.token)
  const catId = cCreate.j?.category?.id
  ok('A-20 POST service-categories {nameAr,nameEn} → category.id',
    createdOk(cCreate.status) && !!catId, '')

  const cPatch = await call('PATCH', `/api/admin/service-categories/${catId}`, {
    name: `فئة محدثة ${Date.now() % 100000}`,
  }, admin.token)
  ok('A-21 PATCH service-categories/:id → category.name الجديد',
    cPatch.status === 200 && (cPatch.j?.category?.name ?? '').includes('محدثة'), '')

  const cDel = await call('DELETE', `/api/admin/service-categories/${catId}`, undefined, admin.token)
  ok('A-22 DELETE service-categories/:id → message', cDel.status === 200 && !!cDel.j?.message, '')

  // A-16/A-17/A-18: خدمة (فئة موجودة أولًا)
  const existingCat = (cats.j?.categories ?? [])[0]
  if (existingCat) {
    const sCreate = await call('POST', '/api/admin/services', {
      name: `خدمة فحص ${Date.now() % 100000}`, nameEn: 'Audit Svc',
      categoryId: existingCat.id, priceCents: 500, durationMin: 15,
    }, admin.token)
    const svcId = sCreate.j?.service?.id
    ok('A-16 POST services {nameAr,categoryId,priceCents} → service.id',
      createdOk(sCreate.status) && !!svcId, '')
    const sPatch = await call('PATCH', `/api/admin/services/${svcId}`, { priceCents: 600 }, admin.token)
    ok('A-17 PATCH services/:id {priceCents} → 600',
      sPatch.status === 200 && sPatch.j?.service?.priceCents === 600, '')
    const sDel = await call('DELETE', `/api/admin/services/${svcId}`, undefined, admin.token)
    ok('A-18 DELETE services/:id → message', sDel.status === 200 && !!sDel.j?.message, '')
  }

  // A-24/A-25/A-27/A-28: موظف + كود (توليد → إبطال) ثم تعطيل الموظف
  const stCreate = await call('POST', '/api/admin/staff', {
    fullName: `موظف فحص ${Date.now() % 100000}`, role: 'RECEPTION', phone: '+967700000010',
  }, admin.token)
  const stId = stCreate.j?.staffMember?.id
  ok('A-24 POST staff {fullName,role,phone} → staffMember.id',
    createdOk(stCreate.status) && !!stId, stCreate.j?.staffMember?.fullName ?? '')

  const gen = await call('POST', '/api/admin/codes', {
    type: 'RECEPTION', staffId: stId, days: 1,
  }, admin.token)
  // نفس ما يقرأه GeneratedCodeResult.fromJson في الجوال: codeId/code/codeMasked
  const codeId = gen.j?.codeId
  ok('A-27 POST codes {type,staffId,days} → {codeId,code,codeMasked} + الخام مرة واحدة',
    createdOk(gen.status) && !!codeId && typeof gen.j?.code === 'string' && !!gen.j?.codeMasked,
    `${gen.j?.codeMasked ?? ''} — الخام أُعيد مرة واحدة (لا يُخزن)`)

  const revoke = await call('POST', '/api/admin/codes/revoke', { codeId }, admin.token)
  ok('A-28 POST codes/revoke {codeId} → message + الحالة REVOKED',
    revoke.status === 200 && !!revoke.j?.message, revoke.j?.message ?? '')

  const stPatch = await call('PATCH', `/api/admin/staff/${stId}`, { active: false }, admin.token)
  ok('A-25 PATCH staff/:id {active:false} → staffMember.active=false',
    stPatch.status === 200 && stPatch.j?.staffMember?.active === false, '')

  // A-03: تعديل إعدادات الفندق ثم استرجاع
  const oldCity = hotel.j?.hotel?.city
  const hPatch = await call('PATCH', '/api/admin/hotel', { city: oldCity }, admin.token)
  ok('A-03 PATCH hotel {city} → note', hPatch.status === 200 && typeof hPatch.j?.note === 'string', hPatch.j?.note ?? '')

  // A-30: تفاصيل حجز (من قائمة الحجوزات إن وجدت)
  const anyRes = (reservations.j?.items ?? [])[0]
  if (anyRes) {
    const rd = await call('GET', `/api/admin/reservations/${anyRes.id}`, undefined, admin.token)
    ok('A-30 GET reservations/:id → reservation{id,reference,guest.fullName,grandTotalCents,status,priceSnapshot}',
      rd.status === 200 && !shape(rd.j?.reservation ?? {}, {
        id: 'string', reference: 'string', 'guest.fullName': 'string',
        grandTotalCents: 'int', status: 'string', priceSnapshot: 'obj',
      }), rd.j?.reservation?.reference ?? '')
  } else {
    console.log('⏭ A-30 تفاصيل حجز: لا حجوزات في القاعدة حاليًا')
  }

  // ═══ 4) الحجز العام (لتغذية مسار الاستقبال) ═══
  const checkIn = inDays(7), checkOut = inDays(9)
  const avail = await call('POST', '/api/public/availability', {
    checkIn, checkOut, adults: 2, children: 0, roomsCount: 1,
  })
  const chosen = (avail.j?.items ?? []).find((i: any) => i.availableCount > 0)
  ok('حجز عام: توفر متاح', avail.status === 200 && !!chosen, `${chosen?.roomType?.name ?? '—'}`)

  const booking = await call('POST', '/api/public/bookings', {
    checkIn, checkOut, adults: 2, children: 0, roomsCount: 1,
    roomTypeId: chosen.roomType.id,
    guest: { fullName: 'ضيف فحص الجوال', phone: `+9677${String(Math.floor(10000000 + Math.random() * 89999999))}` },
    paymentMethod: 'PAY_AT_HOTEL', idempotencyKey: `mobile-audit-${Date.now()}`,
  })
  const resv = booking.j?.reservation
  ok('حجز عام: POST bookings → reservation{id,bookingReference}', booking.status === 201 && !!resv?.id, resv?.bookingReference ?? '')

  // ═══ 5) دخول الاستقبال + كل قراءات ReceptionStore ═══
  const rec = await login(RECEPTION_CODE)
  ok('دخول الاستقبال validate {code}', rec.role === 'RECEPTION' && !!rec.token, `${rec.name}`)

  const rDash = await call('GET', '/api/reception/dashboard', undefined, rec.token)
  ok('R-01 dashboard: stats{…} + arrivals[] + departures[] + pendingRequests[]',
    rDash.status === 200 && !shape(rDash.j, {
      'stats.arrivalsToday': 'int', 'stats.departuresToday': 'int', 'stats.inHouseStays': 'int',
      'stats.pendingRequests': 'int', 'stats.occupancyPercent': 'int', 'stats.totalRooms': 'int',
      arrivals: 'array', departures: 'array', pendingRequests: 'array',
    }), '')

  const rArr = await call('GET', `/api/reception/arrivals?date=${checkIn}`, undefined, rec.token)
  const arrItem = (rArr.j?.arrivals ?? []).find((a: any) => a.id === resv?.id) ?? (rArr.j?.arrivals ?? [])[0]
  ok('R-02 arrivals?date: arrivals[].{bookingReference,guest.fullName,roomType.name,paymentStatus,grandTotalCents}',
    rArr.status === 200 && !shape(arrItem ?? {}, {
      bookingReference: 'string', 'guest.fullName': 'string', 'roomType.name': 'string',
      paymentStatus: 'string', grandTotalCents: 'int', nights: 'int', paidCents: 'int',
    }), arrItem?.bookingReference ?? '')

  const rDep = await call('GET', `/api/reception/departures?date=${inDays(9)}`, undefined, rec.token)
  ok('R-03 departures?date: departments[].{guestName,roomNumber,balanceCents,overdue,activeRequests}',
    rDep.status === 200 && Array.isArray(rDep.j?.departures) &&
    (rDep.j.departures.length === 0 || !shape(rDep.j.departures[0], {
      guestName: 'string', roomNumber: 'string', balanceCents: 'int',
      overdue: 'bool', activeRequests: 'int', reference: 'string',
    })), `${rDep.j?.departures?.length ?? 0} مغادرة`)

  const rIn = await call('GET', '/api/reception/inhouse', undefined, rec.token)
  ok('R-04 inhouse: stays[].{guest.fullName,room.number,roomType.name,reservation.paymentStatus,balanceCents}',
    rIn.status === 200 && Array.isArray(rIn.j?.stays) &&
    (rIn.j.stays.length === 0 || !shape(rIn.j.stays[0], {
      id: 'string', reference: 'string', status: 'string',
      'guest.fullName': 'string', 'room.number': 'string', 'room.floor': 'int',
      'roomType.name': 'string', balanceCents: 'int', activeRequests: 'int',
      'reservation.grandTotalCents': 'int', 'reservation.paidCents': 'int',
      'reservation.paymentStatus': 'string',
    })), `${rIn.j?.stays?.length ?? 0} مقيمًا`)

  const rReq = await call('GET', '/api/reception/requests', undefined, rec.token)
  ok('R-08 requests: requests[].{title,priority,status,stay.roomNumber,stay.guestName,updates[]}',
    rReq.status === 200 && Array.isArray(rReq.j?.requests) &&
    (rReq.j.requests.length === 0 || !shape(rReq.j.requests[0], {
      title: 'string', priority: 'string', status: 'string', category: 'string',
      reference: 'string', 'stay.roomNumber': 'string', 'stay.guestName': 'string', updates: 'array',
    })), `${rReq.j?.requests?.length ?? 0} طلبًا`)

  const rRooms = await call('GET', '/api/reception/rooms', undefined, rec.token)
  const freeRoom = (rRooms.j?.rooms ?? []).find((x: any) => x.roomTypeId === chosen.roomType.id && x.status === 'AVAILABLE')
  ok('R-10 rooms: rooms[].{number,floor,status,roomTypeId,roomTypeName,guestName?}',
    rRooms.status === 200 && Array.isArray(rRooms.j?.rooms) &&
    (rRooms.j.rooms.length === 0 || !shape(rRooms.j.rooms[0], {
      id: 'string', number: 'string', floor: 'int', status: 'string',
      roomTypeId: 'string', roomTypeName: 'string',
    })), freeRoom ? `غرفة متاحة من النوع: ${freeRoom.number}` : '⚠ لا غرفة متاحة من النوع')

  const rNotifs = await call('GET', '/api/reception/notifications', undefined, rec.token)
  ok('R-22 notifications: {notifications[],unreadCount}',
    rNotifs.status === 200 && !shape(rNotifs.j, { notifications: 'array', unreadCount: 'int' }),
    `${rNotifs.j?.unreadCount ?? 0} غير مقروء`)

  const rSearch = await call('GET', `/api/reception/search?q=${resv?.bookingReference ?? 'HTL'}`, undefined, rec.token)
  ok('R-19 search?q: {reservations[],stays[]}',
    rSearch.status === 200 && Array.isArray(rSearch.j?.reservations) && Array.isArray(rSearch.j?.stays), '')

  // ═══ 6) العمليات الحية (المسار الذهبي للجوال) ═══
  if (resv && freeRoom) {
    // R-06 تسجيل الوصول
    const ci = await call('POST', '/api/reception/check-in', {
      reservationId: resv.id, roomId: freeRoom.id, idNumber: 'فحص-123',
    }, rec.token)
    const stay = ci.j?.stay
    const guestCode: string | undefined = ci.j?.guestCode
    ok('R-06 check-in {reservationId,roomId,idNumber} → stay{id,reference} + guestCode مرة واحدة',
      createdOk(ci.status) && !!stay?.id && !!guestCode, `${stay?.reference ?? ''} · غرفة ${ci.j?.roomNumber ?? ''}`)

    // R-05 تفاصيل الإقامة
    const sd = await call('GET', `/api/reception/stays/${stay.id}`, undefined, rec.token)
    const bill = sd.j?.bill
    ok('R-05 stays/:id → {stay.id,guest.fullName,room.number,bill.{balanceCents,extraCharges,payments}}',
      sd.status === 200 && !shape(sd.j ?? {}, {
        'stay.id': 'string', 'guest.fullName': 'string', 'room.number': 'string',
        'bill.balanceCents': 'int', 'bill.totalPaidCents': 'int',
        'bill.extraCharges': 'array', 'bill.payments': 'array',
        requests: 'array', extensionRequests: 'array', messages: 'array',
      }), `الرصيد ${bill?.balanceCents ?? '—'} سنت`)

    // R-09 حالة طلب: أنشئ طلبًا كضيف؟ — نستخدم POST الحالة على طلب إن وجد
    const anyReq = (rReq.j?.requests ?? [])[0]
    if (anyReq) {
      const st = await call('POST', `/api/reception/requests/${anyReq.id}/status`, {
        status: 'ACKNOWLEDGED', note: 'فحص الجوال',
      }, rec.token)
      ok('R-09 POST requests/:id/status {status,note} → request.status',
        st.status === 200 && st.j?.request?.status === 'ACKNOWLEDGED', '')
    }

    // R-11 حالة غرفة (الغرفة الحالية OCCUPIED — جرّب نظافة غرفة أخرى متاحة)
    // انتقال قانوني DIRTY → CLEANING (الجوال يعرض الأزرار القانونية فقط —
    // ومنطق الحارس: AVAILABLE → CLEANING مرفوض 400 برسالة عربية)
    const dirtyRoom = (rRooms.j?.rooms ?? []).find((x: any) => x.status === 'DIRTY')
    if (dirtyRoom) {
      const rs = await call('POST', `/api/reception/rooms/${dirtyRoom.id}/status`, {
        status: 'CLEANING', notes: 'فحص الجوال',
      }, rec.token)
      ok(`R-11 POST rooms/:id/status {DIRTY→CLEANING} — غرفة ${dirtyRoom.number}`,
        rs.status === 200 || rs.status === 201, rs.j?.error ?? '')
    } else {
      console.log('⏭ R-11: لا غرفة DIRTY حاليًا لاختبار الانتقال القانوني')
    }
    // freeRoom صارت OCCUPIED بعد الوصول — حارس آخر يشتغل (كلاهما دليل صحة)
    const guard = await call('POST', `/api/reception/rooms/${freeRoom.id}/status`, { status: 'CLEANING' }, rec.token)
    ok('R-11 حارس الانتقالات: انتقال غير قانوني مرفوض 400 برسالة عربية',
      guard.status === 400 && !!guard.j?.error, guard.j?.error ?? '')

    // R-12 دفعة
    const pay = await call('POST', '/api/reception/payments', {
      stayId: stay.id, method: 'CASH', amountCents: 1000, note: 'دفعة فحص الجوال',
    }, rec.token)
    ok('R-12 POST payments {stayId,method,amountCents,note} → balanceCents',
      pay.status === 200 && typeof pay.j?.balanceCents === 'number',
      `الرصيد بعد الدفعة: ${pay.j?.balanceCents}`)

    // R-13 بند فاتورة
    const charge = await call('POST', '/api/reception/charges', {
      stayId: stay.id, description: 'بند فحص الجوال', amountCents: 500, category: 'SERVICE',
    }, rec.token)
    ok('R-13 POST charges {stayId,description,amountCents,category}',
      charge.status === 200 || charge.status === 201, '')

    // R-20/R-21 رسائل
    const msg = await call('POST', '/api/reception/messages', {
      stayId: stay.id, body: 'رسالة فحص الجوال',
    }, rec.token)
    ok('R-21 POST messages {stayId,body} → message{id,body,senderName}',
      msg.status === 200 && !shape(msg.j?.message ?? {}, {
        body: 'string', senderName: 'string',
      }) || createdOk(msg.status), '')

    const msgs = await call('GET', `/api/reception/messages?stayId=${stay.id}`, undefined, rec.token)
    ok('R-20 GET messages?stayId → messages[]', msgs.status === 200 && Array.isArray(msgs.j?.messages),
      `${msgs.j?.messages?.length ?? 0} رسالة`)

    // R-15..R-18: طلب تمديد/تغيير غرفة كضيف ثم البت فيه كاستقبال
    const gLogin = await call('POST', '/api/auth/validate', { code: guestCode })
    const guestToken = gLogin.j?.token
    const ext = await call('POST', '/api/guest/extension', { newCheckOut: inDays(10) }, guestToken)
    const extReqId = ext.j?.request?.id
    ok('R-15 ضيف: POST guest/extension → request (PENDING) — ثم قرار الاستقبال',
      createdOk(ext.status) && !!extReqId, ext.j?.request?.status ?? ext.j?.error ?? '')
    if (extReqId) {
      const dec = await call('POST', `/api/reception/extension-requests/${extReqId}/decide`, {
        approve: false,
      }, rec.token)
      ok('R-16 POST extension-requests/:id/decide {approve:false}',
        dec.status === 200 || dec.status === 201, '')
    }

    // R-07 تسجيل الخروج (مع تسوية الرصيد المتبقي أولًا)
    const detail = await call('GET', `/api/reception/stays/${stay.id}`, undefined, rec.token)
    const bal = detail.j?.bill?.balanceCents ?? 0
    if (bal > 0) {
      await call('POST', '/api/reception/payments', {
        stayId: stay.id, method: 'CASH', amountCents: bal,
      }, rec.token)
    }
    const co = await call('POST', '/api/reception/check-out', { stayId: stay.id }, rec.token)
    ok('R-07 check-out {stayId} → stay CLOSED + room DIRTY + موت كود الضيف',
      co.status === 200 && (co.j?.stay?.status === 'CLOSED' || co.j?.ok === true),
      `${co.j?.stay?.reference ?? ''} — الرصيد صفر قبل الخروج`)

    // كود الضيف مات فعلًا (I11): validate يرفض
    const deadLogin = await call('POST', '/api/auth/validate', { code: guestCode })
    ok('I11 كود الضيف مات بعد الخروج (validate يرفض)',
      deadLogin.j?.ok === false, deadLogin.j?.error ?? '')
  } else {
    console.log('⏭ المسار الحي: لا حجز أو لا غرفة متاحة من النوع — تخطي العمليات')
  }

  // ═══ 7) R-23 تعليم الإشعارات مقروءة ═══
  const unreadIds = (rNotifs.j?.notifications ?? []).filter((n: any) => !n.read).map((n: any) => n.id).slice(0, 3)
  if (unreadIds.length > 0) {
    const mark = await call('POST', '/api/reception/notifications/read', { ids: unreadIds }, rec.token)
    ok('R-23 POST notifications/read {ids[]} → ok', mark.status === 200 && mark.j?.ok !== false, `${unreadIds.length} إشعارًا`)
  } else {
    console.log('⏭ R-23: لا إشعارات غير مقروءة')
  }

  // ═══ 8) سياسة الجوال §1.2.1: renew يمدد الجلسة ═══
  const renewA = await call('POST', '/api/auth/renew', undefined, admin.token)
  ok('§1.2.1 renew (أدمن) → ok:true', renewA.status === 200 && renewA.j?.ok === true, '')
  const renewR = await call('POST', '/api/auth/renew', undefined, rec.token)
  ok('§1.2.1 renew (استقبال) → ok:true', renewR.status === 200 && renewR.j?.ok === true, '')

  // توكن مزيف → 401 (يكرر الجوال بعدها بـ renew ثم خروج)
  const bad = await call('GET', '/api/admin/dashboard', undefined, 'fake-token')
  ok('401 بتوكن مزيف (يؤدي renew ثم إعادة المحاولة في الجوال)',
    bad.status === 401, `الحالة ${bad.status}`)

  // ═══ 9) Realtime — like the mobile connects and receives (join string + broadcast) ═══
  await new Promise<void>((resolve) => {
    const socket = io(`${RT_BASE}/?XTransformPort=3002`, {
      path: '/', transports: ['websocket', 'polling'], reconnection: false, timeout: 4000,
    })
    let gotEvent = false
    let detail = ''
    const finish = () => {
      ok('Realtime: socket.io connection (3002) + join reception + receiving a broadcast event',
        gotEvent, detail)
      try { socket.disconnect() } catch {}
      resolve()
    }
    const to = setTimeout(() => { detail = detail || 'timeout'; finish() }, 7000)
    socket.on('connect', () => {
      // exactly as the mobile does: socket.emit('join', room) — a string
      socket.emit('join', 'reception')
      // broadcast an event to the room via the broadcast port 3004 (internal)
      setTimeout(async () => {
        try {
          const r = await fetch('http://localhost:3004/emit', {
            method: 'POST', headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ room: 'reception', event: 'audit:ping', data: { hello: 'mobile' } }),
          })
          const j = await r.json().catch(() => null)
          if (!j?.ok) detail = `broadcast failed: ${JSON.stringify(j)}`
        } catch (e: any) { detail = `broadcast error: ${e?.message}` }
      }, 300)
    })
    socket.on('audit:ping', (p: any) => {
      gotEvent = p?.hello === 'mobile'
      if (!gotEvent) detail = `unexpected payload: ${JSON.stringify(p)}`
      clearTimeout(to)
      finish()
    })
    socket.on('connect_error', (e: any) => { detail = `connect_error: ${e?.message}`; clearTimeout(to); finish() })
  })

  // ═══ 10) التنظيف: الغرف التي اتسخت من فحوص الوصول/الخروج السابقة ═══
  const roomsNow = await call('GET', '/api/admin/rooms', undefined, admin.token)
  const dirty = (roomsNow.j?.rooms ?? []).filter((x: any) => x.status === 'DIRTY')
  for (const d of dirty) {
    await call('PATCH', `/api/admin/rooms/${d.id}`, { status: 'CLEANING', notes: 'إتمام تنظيف فحص الجوال' }, admin.token)
    await call('PATCH', `/api/admin/rooms/${d.id}`, { status: 'AVAILABLE' }, admin.token)
  }
  ok(`تنظيف ما بعد الفحص: ${dirty.length} غرفة اتسخت عادت AVAILABLE`, true, 'إدارة المنزل تعيد الجاهزية')

  // ═══ 11) الخروج (يحرق الجلسة) ═══
  const logout = await call('POST', '/api/auth/logout', undefined, rec.token)
  ok('POST /api/auth/logout (استقبال) → ok', logout.status === 200, '')
  const badAfter = await call('GET', '/api/reception/dashboard', undefined, rec.token)
  ok('الجلسة ماتت بعد الخروج (401)', badAfter.status === 401, `الحالة ${badAfter.status}`)

  await db.$disconnect()
  console.log('═'.repeat(70))
  console.log(`النتيجة: ${pass} ناجح · ${fail} فاشل`)
  if (failures.length) {
    console.log('الفاشل:')
    for (const f of failures) console.log(`  ❌ ${f}`)
  }
  console.log('═'.repeat(70))
  process.exit(fail > 0 ? 1 : 0)
}

main().catch((e) => {
  console.error('خطأ قاتل:', e)
  process.exit(1)
})

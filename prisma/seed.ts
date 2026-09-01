// ─────────────────────────────────────────────────────────────
// SEED — بيانات فندق قلب القاهرة — عدن
// بيانات حقيقية قابلة للتجربة: حجوزات اليوم، إقامات نشطة
// بأكواد ضيف، طلبات، محادثات، مدفوعات
// تشغيل: bun prisma/seed.ts
// ─────────────────────────────────────────────────────────────
import { PrismaClient } from '@prisma/client'
import { hashCode, maskCode } from '../src/lib/codes'

const db = new PrismaClient()

const startOfDay = (d: Date) => {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x
}
const addDays = (base: Date, n: number) => {
  const x = new Date(base)
  x.setDate(x.getDate() + n)
  return x
}
const endOfDay = (d: Date) => {
  const x = new Date(d)
  x.setHours(23, 59, 59, 999)
  return x
}
const atTime = (base: Date, h: number, m = 0) => {
  const x = new Date(base)
  x.setHours(h, m, 0, 0)
  return x
}

async function main() {
  console.log('🧹 مسح البيانات القديمة...')
  await db.$transaction([
    db.auditLog.deleteMany(),
    db.notification.deleteMany(),
    db.message.deleteMany(),
    db.requestUpdate.deleteMany(),
    db.serviceRequest.deleteMany(),
    db.roomChangeRequest.deleteMany(),
    db.extensionRequest.deleteMany(),
    db.feedback.deleteMany(),
    db.payment.deleteMany(),
    db.charge.deleteMany(),
    db.session.deleteMany(),
    db.accessCode.deleteMany(),
    db.stay.deleteMany(),
    db.reservation.deleteMany(),
    db.guest.deleteMany(),
    db.staff.deleteMany(),
    db.service.deleteMany(),
    db.serviceCategory.deleteMany(),
    db.rate.deleteMany(),
    db.room.deleteMany(),
    db.roomType.deleteMany(),
    db.hotel.deleteMany(),
  ])

  console.log('🏨 إنشاء الفندق...')
  const hotel = await db.hotel.create({
    data: {
      name: 'فندق قلب القاهرة',
      tagline: 'ضيافة راقية في قلب عدن',
      description:
        'فندق قلب القاهرة — عدن وجهة مثالية للمسافرين الباحثين عن الراحة والأناقة. غرف عصرية مجهزة بأحدث وسائل الراحة، مطعم يقدم أشهى الأطباق، وخدمة ضيافة على مدار الساعة تجعل إقامتك تجربة لا تُنسى في قلب المدينة الساحرة عدن.',
      phone: '+967 2 232 000',
      whatsapp: '+967771230000',
      email: 'info@qalbcairo-hotel.com',
      address: 'شارع الجمهورية، كريتر',
      city: 'عدن',
      country: 'اليمن',
      currency: 'USD',
      taxPercent: 15,
      weekendSurchargePercent: 10,
      checkInTime: '14:00',
      checkOutTime: '12:00',
      minStayNights: 1,
      maxStayNights: 30,
      bookingHorizonDays: 365,
      cancellationPolicy:
        'الإلغاء مجاني حتى 24 ساعة قبل موعد الوصول. الإلغاء خلال 24 ساعة من الوصول يترتب عليه رسوم ليلة واحدة.',
      paymentPolicy: 'يمكن الدفع إلكترونيًا عند الحجز أو نقدًا/بالبطاقة في الفندق عند الوصول.',
      childrenPolicy: 'الإقامة مجانية للأطفال تحت 6 سنوات. الأطفال من 6-12 سنة بنسبة 50% من سعر السرير الإضافي.',
      petsPolicy: 'لا يُسمح بالحيوانات الأليفة داخل الفندق.',
      smokingPolicy: 'جميع الغرف لغير المدخنين. يوجد مكان مخصص للتدخين في الطابق الأرضي.',
      logoUrl: '/logo-hotel.svg',
    },
  })

  console.log('🛏 إنشاء أنواع الغرف...')
  const single = await db.roomType.create({
    data: {
      hotelId: hotel.id,
      name: 'غرفة مفردة',
      nameEn: 'Single Room',
      description: 'غرفة مريحة مثالية لمسافر الأعمال، بسرير ملكي أنيق ومكتب عمل وإضاءة دافئة.',
      capacityAdults: 1,
      capacityChildren: 0,
      bedConfig: 'سرير ملكي واحد',
      sizeSqm: 22,
      basePriceCents: 8000,
      amenities: JSON.stringify(['واي فاي مجاني', 'تكييف', 'تلفاز 43 بوصة', 'خزنة إلكترونية', 'ثلاجة صغيرة', 'مكتب عمل']),
      images: JSON.stringify(['/images/room-single.png']),
      sortOrder: 1,
    },
  })
  const double = await db.roomType.create({
    data: {
      hotelId: hotel.id,
      name: 'غرفة مزدوجة',
      nameEn: 'Double Room',
      description: 'غرفة واسعة بسرير ملكي كبير وزاوية جلوس مريحة، مثالية لإقامة رومانسية أو عمل هادئ.',
      capacityAdults: 2,
      capacityChildren: 1,
      bedConfig: 'سرير ملكي كبير',
      sizeSqm: 30,
      basePriceCents: 12000,
      amenities: JSON.stringify(['واي فاي مجاني', 'تكييف', 'تلفاز 50 بوصة', 'خزنة إلكترونية', 'ثلاجة صغيرة', 'زاوية جلوس', 'ماكينة قهوة']),
      images: JSON.stringify(['/images/room-double.png']),
      sortOrder: 2,
    },
  })
  const deluxe = await db.roomType.create({
    data: {
      hotelId: hotel.id,
      name: 'غرفة ديلوكس',
      nameEn: 'Deluxe Room',
      description: 'غرفة ديلوكس فاخرة بإطلالة بانورامية على المدينة، بأثاث خشبي فاخر وتجهيزات راقية.',
      capacityAdults: 2,
      capacityChildren: 2,
      bedConfig: 'سرير ملكي + أريكة سرير',
      sizeSqm: 45,
      basePriceCents: 16000,
      amenities: JSON.stringify(['واي فاي فائق السرعة', 'تكييف مركزي', 'تلفاز ذكي 55 بوصة', 'خزنة إلكترونية', 'ميني بار', 'ماكينة قهوة', 'إطلالة بانورامية', 'خزانة ملابس واسعة']),
      images: JSON.stringify(['/images/room-deluxe.png']),
      sortOrder: 3,
    },
  })
  const family = await db.roomType.create({
    data: {
      hotelId: hotel.id,
      name: 'الجناح العائلي',
      nameEn: 'Family Suite',
      description: 'جناح عائلي رحب بغرفتي نوم وركن للأطفال، مثالي للعائلات الباحثة عن الخصوصية والراحة.',
      capacityAdults: 4,
      capacityChildren: 2,
      bedConfig: 'سريران ملكيان',
      sizeSqm: 65,
      basePriceCents: 22000,
      amenities: JSON.stringify(['واي فاي فائق السرعة', 'تكييف مركزي', 'تلفازان ذكيان', 'مطبخ صغير', 'ميني بار', 'ركن للأطفال', 'غرفتا نوم', 'خزانة ملابس واسعة']),
      images: JSON.stringify(['/images/room-family.png']),
      sortOrder: 4,
    },
  })

  console.log('🚪 إنشاء الغرف الفعلية...')
  const roomDefs: Array<{ number: string; floor: number; type: string }> = [
    { number: '101', floor: 1, type: single.id },
    { number: '102', floor: 1, type: single.id },
    { number: '103', floor: 1, type: double.id },
    { number: '104', floor: 1, type: double.id },
    { number: '105', floor: 1, type: double.id },
    { number: '106', floor: 1, type: double.id },
    { number: '201', floor: 2, type: deluxe.id },
    { number: '202', floor: 2, type: deluxe.id },
    { number: '203', floor: 2, type: deluxe.id },
    { number: '204', floor: 2, type: deluxe.id },
    { number: '205', floor: 2, type: deluxe.id },
    { number: '301', floor: 3, type: family.id },
    { number: '302', floor: 3, type: family.id },
    { number: '303', floor: 3, type: family.id },
  ]
  const rooms: Record<string, { id: string }> = {}
  for (const def of roomDefs) {
    const room = await db.room.create({
      data: { number: def.number, floor: def.floor, roomTypeId: def.type, status: 'AVAILABLE' },
    })
    rooms[def.number] = room
  }

  console.log('📅 إنشاء معدل موسمي...')
  const thisYear = new Date().getFullYear()
  await db.rate.create({
    data: {
      roomTypeId: family.id,
      name: 'الموسم الشتوي',
      startDate: new Date(`${thisYear}-12-01T00:00:00`),
      endDate: new Date(`${thisYear + 1}-01-15T23:59:59`),
      priceCents: 25000,
    },
  })

  console.log('🛎 إنشاء كتالوج الخدمات...')
  const catHouse = await db.serviceCategory.create({
    data: { name: 'خدمات التنظيف', nameEn: 'Housekeeping', key: 'HOUSEKEEPING', icon: 'sparkles', sortOrder: 1 },
  })
  const catMaint = await db.serviceCategory.create({
    data: { name: 'الصيانة', nameEn: 'Maintenance', key: 'MAINTENANCE', icon: 'wrench', sortOrder: 2 },
  })
  const catGuest = await db.serviceCategory.create({
    data: { name: 'خدمات الضيافة', nameEn: 'Guest Services', key: 'GUEST_SERVICES', icon: 'concierge-bell', sortOrder: 3 },
  })

  const serviceDefs = [
    { cat: catHouse.id, name: 'تنظيف الغرفة', nameEn: 'Clean Room', price: 0 },
    { cat: catHouse.id, name: 'مناشف إضافية', nameEn: 'Extra Towels', price: 0 },
    { cat: catHouse.id, name: 'مستلزمات عناية', nameEn: 'Toiletries', price: 0 },
    { cat: catHouse.id, name: 'فراش إضافي', nameEn: 'Extra Bedding', price: 1500 },
    { cat: catMaint.id, name: 'مشكلة تكييف', nameEn: 'AC Issue', price: 0 },
    { cat: catMaint.id, name: 'مشكلة مياه', nameEn: 'Water Issue', price: 0 },
    { cat: catMaint.id, name: 'مشكلة تلفاز', nameEn: 'TV Issue', price: 0 },
    { cat: catMaint.id, name: 'مشكلة واي فاي', nameEn: 'Wi-Fi Issue', price: 0 },
    { cat: catGuest.id, name: 'مساعدة عامة', nameEn: 'General Assistance', price: 0 },
    { cat: catGuest.id, name: 'إفطار بالغرفة', nameEn: 'Breakfast in Room', price: 800 },
    { cat: catGuest.id, name: 'خدمة الغرف (عشاء)', nameEn: 'Room Service (Dinner)', price: 4500 },
    { cat: catGuest.id, name: 'غسيل ملابس', nameEn: 'Laundry', price: 2000 },
  ]
  let sOrder = 0
  for (const s of serviceDefs) {
    await db.service.create({
      data: {
        categoryId: s.cat,
        name: s.name,
        nameEn: s.nameEn,
        priceCents: s.price,
        sortOrder: sOrder++,
      },
    })
  }

  console.log('👥 إنشاء الطاقم والأكواد...')
  const ahmedStaff = await db.staff.create({
    data: { fullName: 'أحمد الاستقبال', role: 'RECEPTION', phone: '+967771111111' },
  })
  const salimAdmin = await db.staff.create({
    data: { fullName: 'سالم المدير', role: 'ADMIN', phone: '+967772222222' },
  })

  const RECEPTION_DEMO = 'R492671M3'
  const ADMIN_DEMO = 'A371849L9'
  const GUEST_KHALED = 'H834729X7'
  const GUEST_NORA = 'H119922K4'

  const today = startOfDay(new Date())

  console.log('🙋 إنشاء الضيوف...')
  const ahmed = await db.guest.create({
    data: { fullName: 'أحمد محمد', phone: '+967771234567', whatsapp: '+967771234567', email: 'ahmed@example.com', nationality: 'يمني' },
  })
  const sara = await db.guest.create({
    data: { fullName: 'سارة علي', phone: '+967772345678', whatsapp: '+967772345678', email: 'sara@example.com', nationality: 'يمنية' },
  })
  const khaled = await db.guest.create({
    data: { fullName: 'خالد يوسف', phone: '+967773456789', whatsapp: '+967773456789', email: 'khaled@example.com', nationality: 'يمني' },
  })
  const nora = await db.guest.create({
    data: { fullName: 'نورا يوسف', phone: '+967774567890', whatsapp: '+967774567890', email: 'nora@example.com', nationality: 'يمنية' },
  })
  const john = await db.guest.create({
    data: { fullName: 'جون سميث', phone: '+967775678901', email: 'john@example.com', nationality: 'أمريكي' },
  })

  console.log('📋 إنشاء الحجوزات...')

  // ── حجز 1: أحمد — وصول اليوم (ديلوكس 3 ليالٍ، عربون مدفوع)
  const r1CheckIn = today
  const r1CheckOut = addDays(today, 3)
  const r1Subtotal = 16000 * 3
  const r1Tax = Math.round((r1Subtotal * 15) / 100)
  const r1Total = r1Subtotal + r1Tax
  const r1Paid = Math.round(r1Total / 2) // عربون 50%
  const res1 = await db.reservation.create({
    data: {
      bookingReference: 'HTL-2026-000421',
      guestId: ahmed.id,
      roomTypeId: deluxe.id,
      status: 'CONFIRMED',
      source: 'WEBSITE',
      checkIn: r1CheckIn,
      checkOut: r1CheckOut,
      adults: 2,
      children: 0,
      roomsCount: 1,
      subtotalCents: r1Subtotal,
      taxCents: r1Tax,
      grandTotalCents: r1Total,
      paidCents: r1Paid,
      paymentStatus: 'PARTIALLY_PAID',
      paymentMethod: 'CARD',
      specialRequests: 'أرجو غرفة بإطلالة إن أمكن',
      priceSnapshot: JSON.stringify({
        version: 1,
        roomTypeName: 'غرفة ديلوكس',
        nightly: [0, 1, 2].map((i) => ({ date: addDays(today, i).toISOString().slice(0, 10), priceCents: 16000, rateName: 'السعر الأساسي' })),
        subtotalCents: r1Subtotal,
        taxCents: r1Tax,
        grandTotalCents: r1Total,
        currency: 'USD',
        taxPercent: 15,
        roomsCount: 1,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: new Date().toISOString(),
      }),
      confirmedAt: addDays(today, -2),
    },
  })
  await db.payment.create({
    data: {
      reservationId: res1.id,
      method: 'ONLINE',
      amountCents: r1Paid,
      status: 'COMPLETED',
      reference: 'SEED-DEP-001',
      recordedBy: 'ONLINE',
      note: 'عربون حجز إلكتروني 50%',
    },
  })

  // ── حجز 2: سارة — وصول اليوم (جناح عائلي ليلتان، الدفع بالفندق)
  const res2 = await db.reservation.create({
    data: {
      bookingReference: 'HTL-2026-000422',
      guestId: sara.id,
      roomTypeId: family.id,
      status: 'CONFIRMED',
      source: 'WHATSAPP',
      checkIn: today,
      checkOut: addDays(today, 2),
      adults: 2,
      children: 1,
      roomsCount: 1,
      subtotalCents: 22000 * 2,
      taxCents: Math.round((22000 * 2 * 15) / 100),
      grandTotalCents: 22000 * 2 + Math.round((22000 * 2 * 15) / 100),
      paidCents: 0,
      paymentStatus: 'UNPAID',
      paymentMethod: 'PAY_AT_HOTEL',
      specialRequests: 'سرير أطفال إن توفر',
      priceSnapshot: JSON.stringify({
        version: 1,
        roomTypeName: 'الجناح العائلي',
        nightly: [0, 1].map((i) => ({ date: addDays(today, i).toISOString().slice(0, 10), priceCents: 22000, rateName: 'السعر الأساسي' })),
        subtotalCents: 22000 * 2,
        taxCents: Math.round((22000 * 2 * 15) / 100),
        grandTotalCents: 22000 * 2 + Math.round((22000 * 2 * 15) / 100),
        currency: 'USD',
        taxPercent: 15,
        roomsCount: 1,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: new Date().toISOString(),
      }),
      confirmedAt: addDays(today, -1),
    },
  })

  // ── حجز 3: خالد — مقيم حاليًا (ديلوكس، خروج غدًا) + كود ضيف H834729X7
  const r3CheckIn = addDays(today, -2)
  const r3CheckOut = addDays(today, 1)
  const r3Subtotal = 16000 * 3
  const r3Tax = Math.round((r3Subtotal * 15) / 100)
  const r3Total = r3Subtotal + r3Tax
  const res3 = await db.reservation.create({
    data: {
      bookingReference: 'HTL-2026-000415',
      guestId: khaled.id,
      roomTypeId: deluxe.id,
      status: 'CHECKED_IN',
      source: 'WEBSITE',
      checkIn: r3CheckIn,
      checkOut: r3CheckOut,
      adults: 2,
      children: 0,
      roomsCount: 1,
      subtotalCents: r3Subtotal,
      taxCents: r3Tax,
      grandTotalCents: r3Total,
      paidCents: 30000,
      paymentStatus: 'PARTIALLY_PAID',
      paymentMethod: 'CARD',
      priceSnapshot: JSON.stringify({
        version: 1,
        roomTypeName: 'غرفة ديلوكس',
        nightly: [0, 1, 2].map((i) => ({ date: addDays(r3CheckIn, i).toISOString().slice(0, 10), priceCents: 16000, rateName: 'السعر الأساسي' })),
        subtotalCents: r3Subtotal,
        taxCents: r3Tax,
        grandTotalCents: r3Total,
        currency: 'USD',
        taxPercent: 15,
        roomsCount: 1,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: addDays(r3CheckIn, -5).toISOString(),
      }),
      confirmedAt: addDays(r3CheckIn, -5),
    },
  })
  await db.payment.create({
    data: {
      reservationId: res3.id,
      method: 'ONLINE',
      amountCents: 30000,
      status: 'COMPLETED',
      reference: 'SEED-DEP-003',
      recordedBy: 'ONLINE',
      note: 'عربون حجز إلكتروني',
    },
  })
  const stayKhaled = await db.stay.create({
    data: {
      reference: 'ST-2026-000883',
      reservationId: res3.id,
      guestId: khaled.id,
      roomId: rooms['201'].id,
      checkInAt: atTime(r3CheckIn, 14, 30),
      expectedCheckOutAt: endOfDay(r3CheckOut),
      status: 'ACTIVE',
    },
  })
  await db.room.update({ where: { id: rooms['201'].id }, data: { status: 'OCCUPIED' } })

  // ── حجز 4: نورا — مقيمة، خروج اليوم (غرفة مزدوجة) + كود ضيف H119922K4
  const r4CheckIn = addDays(today, -3)
  const r4CheckOut = today
  const r4Subtotal = 12000 * 3
  const r4Tax = Math.round((r4Subtotal * 15) / 100)
  const r4Total = r4Subtotal + r4Tax
  const res4 = await db.reservation.create({
    data: {
      bookingReference: 'HTL-2026-000410',
      guestId: nora.id,
      roomTypeId: double.id,
      status: 'CHECKED_IN',
      source: 'PHONE',
      checkIn: r4CheckIn,
      checkOut: r4CheckOut,
      adults: 1,
      children: 0,
      roomsCount: 1,
      subtotalCents: r4Subtotal,
      taxCents: r4Tax,
      grandTotalCents: r4Total,
      paidCents: 36400,
      paymentStatus: 'PARTIALLY_PAID',
      paymentMethod: 'PAY_AT_HOTEL',
      priceSnapshot: JSON.stringify({
        version: 1,
        roomTypeName: 'غرفة مزدوجة',
        nightly: [0, 1, 2].map((i) => ({ date: addDays(r4CheckIn, i).toISOString().slice(0, 10), priceCents: 12000, rateName: 'السعر الأساسي' })),
        subtotalCents: r4Subtotal,
        taxCents: r4Tax,
        grandTotalCents: r4Total,
        currency: 'USD',
        taxPercent: 15,
        roomsCount: 1,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: addDays(r4CheckIn, -2).toISOString(),
      }),
      confirmedAt: addDays(r4CheckIn, -2),
    },
  })
  await db.payment.create({
    data: { reservationId: res4.id, method: 'CASH', amountCents: 20000, status: 'COMPLETED', recordedBy: 'أحمد الاستقبال', note: 'دفعة أولى نقدًا' },
  })
  await db.payment.create({
    data: { reservationId: res4.id, method: 'CARD', amountCents: 16400, status: 'COMPLETED', recordedBy: 'أحمد الاستقبال', note: 'دفعة ثانية بطاقة' },
  })
  const stayNora = await db.stay.create({
    data: {
      reference: 'ST-2026-000871',
      reservationId: res4.id,
      guestId: nora.id,
      roomId: rooms['103'].id,
      checkInAt: atTime(r4CheckIn, 15, 0),
      expectedCheckOutAt: endOfDay(r4CheckOut),
      status: 'ACTIVE',
    },
  })
  await db.room.update({ where: { id: rooms['103'].id }, data: { status: 'OCCUPIED' } })

  // ── حجز 5: جون — الأسبوع القادم (مزدوجة)
  await db.reservation.create({
    data: {
      bookingReference: 'HTL-2026-000430',
      guestId: john.id,
      roomTypeId: double.id,
      status: 'CONFIRMED',
      source: 'WEBSITE',
      checkIn: addDays(today, 7),
      checkOut: addDays(today, 10),
      adults: 2,
      children: 0,
      roomsCount: 1,
      subtotalCents: 12000 * 3,
      taxCents: Math.round((12000 * 3 * 15) / 100),
      grandTotalCents: 12000 * 3 + Math.round((12000 * 3 * 15) / 100),
      paidCents: 0,
      paymentStatus: 'UNPAID',
      paymentMethod: 'PAY_AT_HOTEL',
      priceSnapshot: JSON.stringify({
        version: 1,
        roomTypeName: 'غرفة مزدوجة',
        nightly: [7, 8, 9].map((i) => ({ date: addDays(today, i).toISOString().slice(0, 10), priceCents: 12000, rateName: 'السعر الأساسي' })),
        subtotalCents: 12000 * 3,
        taxCents: Math.round((12000 * 3 * 15) / 100),
        grandTotalCents: 12000 * 3 + Math.round((12000 * 3 * 15) / 100),
        currency: 'USD',
        taxPercent: 15,
        roomsCount: 1,
        cancellationPolicy: hotel.cancellationPolicy,
        checkInTime: hotel.checkInTime,
        checkOutTime: hotel.checkOutTime,
        bookedAt: new Date().toISOString(),
      }),
      confirmedAt: today,
    },
  })

  console.log('🔑 إنشاء الأكواد...')
  await db.accessCode.create({
    data: {
      codeHash: hashCode(RECEPTION_DEMO),
      codeMasked: maskCode(RECEPTION_DEMO),
      type: 'RECEPTION',
      staffId: ahmedStaff.id,
      expiresAt: addDays(today, 7),
      status: 'ACTIVE',
    },
  })
  await db.accessCode.create({
    data: {
      codeHash: hashCode(ADMIN_DEMO),
      codeMasked: maskCode(ADMIN_DEMO),
      type: 'ADMIN',
      staffId: salimAdmin.id,
      expiresAt: addDays(today, 7),
      status: 'ACTIVE',
    },
  })
  await db.accessCode.create({
    data: {
      codeHash: hashCode(GUEST_KHALED),
      codeMasked: maskCode(GUEST_KHALED),
      type: 'GUEST',
      stayId: stayKhaled.id,
      expiresAt: endOfDay(r3CheckOut),
      status: 'ACTIVE',
    },
  })
  await db.accessCode.create({
    data: {
      codeHash: hashCode(GUEST_NORA),
      codeMasked: maskCode(GUEST_NORA),
      type: 'GUEST',
      stayId: stayNora.id,
      expiresAt: endOfDay(r4CheckOut),
      status: 'ACTIVE',
    },
  })

  console.log('🧹 غرفة إضافية تحتاج تنظيف + غرفة خارج الخدمة...')
  await db.room.update({ where: { number: '106' }, data: { status: 'DIRTY' } })
  await db.room.update({ where: { number: '303' }, data: { status: 'OUT_OF_ORDER', notes: 'صيانة تكييف مركزي' } })

  console.log('📝 طلبات خالد...')
  const req1 = await db.serviceRequest.create({
    data: {
      reference: 'REQ-1001',
      stayId: stayKhaled.id,
      category: 'HOUSEKEEPING',
      title: 'تنظيف الغرفة',
      description: 'أرجو تنظيف الغرفة اليوم',
      priority: 'NORMAL',
      status: 'COMPLETED',
      createdAt: atTime(addDays(today, -1), 10, 30),
      updatedAt: atTime(addDays(today, -1), 11, 15),
      completedAt: atTime(addDays(today, -1), 11, 15),
    },
  })
  await db.requestUpdate.createMany({
    data: [
      { requestId: req1.id, status: 'ACKNOWLEDGED', note: 'تم استلام طلبك', byName: 'أحمد الاستقبال', byRole: 'RECEPTION', createdAt: atTime(addDays(today, -1), 10, 35) },
      { requestId: req1.id, status: 'COMPLETED', note: 'تم تنظيف الغرفة بالكامل', byName: 'فريق التنظيف', byRole: 'RECEPTION', createdAt: atTime(addDays(today, -1), 11, 15) },
    ],
  })
  const req2 = await db.serviceRequest.create({
    data: {
      reference: 'REQ-1002',
      stayId: stayKhaled.id,
      category: 'MAINTENANCE',
      title: 'المكيف لا يبرد',
      description: 'المكيف يعمل لكن لا يبرد الغرفة. الجو حار وغير مريح.',
      priority: 'URGENT',
      status: 'IN_PROGRESS',
      createdAt: atTime(today, 9, 0),
      updatedAt: atTime(today, 9, 45),
    },
  })
  await db.requestUpdate.createMany({
    data: [
      { requestId: req2.id, status: 'ACKNOWLEDGED', note: 'استلمنا طلبك وسنرسل فنيًا فورًا', byName: 'أحمد الاستقبال', byRole: 'RECEPTION', createdAt: atTime(today, 9, 10) },
      { requestId: req2.id, status: 'IN_PROGRESS', note: 'الفني في الطريق وسيفحص المكيف خلال دقائق', byName: 'فريق الصيانة', byRole: 'RECEPTION', createdAt: atTime(today, 9, 45) },
    ],
  })

  console.log('💰 بنود إضافية على فاتورة خالد...')
  await db.charge.createMany({
    data: [
      { stayId: stayKhaled.id, category: 'SERVICE', description: 'خدمة الغرف — عشاء', amountCents: 4500, createdAt: atTime(addDays(today, -1), 20, 0) },
      { stayId: stayKhaled.id, category: 'SERVICE', description: 'غسيل ملابس', amountCents: 2000, createdAt: atTime(today, 8, 0) },
    ],
  })

  console.log('📅 طلب تمديد معلّق لخالد...')
  await db.extensionRequest.create({
    data: {
      stayId: stayKhaled.id,
      newCheckOut: endOfDay(addDays(today, 2)),
      nights: 1,
      priceCents: 16000 + Math.round((16000 * 15) / 100),
      note: 'تمديد لظروف عمل',
      status: 'PENDING',
      createdAt: atTime(today, 10, 0),
    },
  })

  console.log('💬 محادثة خالد مع الاستقبال...')
  await db.message.createMany({
    data: [
      { stayId: stayKhaled.id, sender: 'RECEPTION', senderName: 'الاستقبال', body: 'أهلًا بك في فندق قلب القاهرة! غرفتك 201 جاهزة. نسعد بخدمتك في أي وقت.', createdAt: atTime(r3CheckIn, 14, 35) },
      { stayId: stayKhaled.id, sender: 'GUEST', senderName: 'خالد يوسف', body: 'شكرًا لكم! هل الإفطار متاح الآن؟', createdAt: atTime(addDays(today, -1), 8, 10) },
      { stayId: stayKhaled.id, sender: 'RECEPTION', senderName: 'الاستقبال', body: 'نعم، الإفطار متاح في المطعم من 6:30 صباحًا حتى 10:30.', createdAt: atTime(addDays(today, -1), 8, 12) },
    ],
  })

  console.log('🔔 إشعارات...')
  await db.notification.createMany({
    data: [
      { audience: 'GUEST', stayId: stayKhaled.id, type: 'WELCOME', title: 'أهلًا بك في فندق قلب القاهرة', body: 'إقامتك في الغرفة 201 سعيدة! تصفح الخدمات من التطبيق.', createdAt: atTime(r3CheckIn, 14, 35) },
      { audience: 'GUEST', stayId: stayKhaled.id, type: 'REQUEST', title: 'تحديث طلب: المكيف لا يبرد', body: 'الفني في الطريق وسيفحص المكيف خلال دقائق.', createdAt: atTime(today, 9, 45) },
      { audience: 'RECEPTION', stayId: stayKhaled.id, type: 'REQUEST', title: 'طلب عاجل — الغرفة 201', body: 'خالد يوسف: المكيف لا يبرد.', createdAt: atTime(today, 9, 0) },
      { audience: 'RECEPTION', stayId: stayKhaled.id, type: 'EXTENSION', title: 'طلب تمديد إقامة', body: 'خالد يوسف يطلب تمديد إقامته ليلة إضافية.', createdAt: atTime(today, 10, 0) },
      { audience: 'RECEPTION', stayId: null, type: 'RESERVATION', title: 'حجز جديد من الموقع', body: 'حجز مؤكد HTL-2026-000421 — أحمد محمد، وصول اليوم.', createdAt: addDays(today, -2) },
    ],
  })

  console.log('📜 سجل التدقيق...')
  await db.auditLog.createMany({
    data: [
      { action: 'RESERVATION_CREATED', entityType: 'Reservation', entityId: res1.id, actor: 'الموقع', actorRole: 'WEBSITE', details: JSON.stringify({ reference: 'HTL-2026-000421' }), createdAt: addDays(today, -2) },
      { action: 'RESERVATION_CONFIRMED', entityType: 'Reservation', entityId: res1.id, actor: 'النظام', actorRole: 'SYSTEM', details: JSON.stringify({ reference: 'HTL-2026-000421' }), createdAt: addDays(today, -2) },
      { action: 'PAYMENT_RECORDED', entityType: 'Payment', entityId: res1.id, actor: 'بوابة الدفع', actorRole: 'SYSTEM', details: JSON.stringify({ amountCents: r1Paid }), createdAt: addDays(today, -2) },
      { action: 'CODE_GENERATED', entityType: 'AccessCode', entityId: 'reception-demo', actor: 'سالم المدير', actorRole: 'ADMIN', details: JSON.stringify({ type: 'RECEPTION' }), createdAt: addDays(today, -1) },
      { action: 'CHECK_IN', entityType: 'Stay', entityId: stayKhaled.id, actor: 'أحمد الاستقبال', actorRole: 'RECEPTION', details: JSON.stringify({ room: '201', reference: 'ST-2026-000883' }), createdAt: atTime(r3CheckIn, 14, 30) },
      { action: 'ROOM_ASSIGNED', entityType: 'Room', entityId: rooms['201'].id, actor: 'أحمد الاستقبال', actorRole: 'RECEPTION', details: JSON.stringify({ room: '201' }), createdAt: atTime(r3CheckIn, 14, 28) },
      { action: 'CHECK_IN', entityType: 'Stay', entityId: stayNora.id, actor: 'أحمد الاستقبال', actorRole: 'RECEPTION', details: JSON.stringify({ room: '103', reference: 'ST-2026-000871' }), createdAt: atTime(r4CheckIn, 15, 0) },
      { action: 'REQUEST_CREATED', entityType: 'ServiceRequest', entityId: req2.id, actor: 'خالد يوسف', actorRole: 'GUEST', details: JSON.stringify({ title: 'المكيف لا يبرد', priority: 'URGENT' }), createdAt: atTime(today, 9, 0) },
    ],
  })

  console.log('')
  console.log('✅ اكتملت تهيئة البيانات')
  console.log('─────────────────────────────────────')
  console.log(`🏨 ${hotel.name} — ${hotel.city}`)
  console.log(`🛏 ${roomDefs.length} غرفة | ${4} أنواع غرف`)
  console.log('🔑 أكواد الدخول التجريبية:')
  console.log(`   • الاستقبال: ${RECEPTION_DEMO}`)
  console.log(`   • الإدارة:    ${ADMIN_DEMO}`)
  console.log(`   • ضيف (خالد، غرفة 201): ${GUEST_KHALED}`)
  console.log(`   • ضيفة (نورا، غرفة 103): ${GUEST_NORA}`)
  console.log('─────────────────────────────────────')
}

main()
  .catch((e) => {
    console.error('❌ فشل التهيئة:', e)
    process.exit(1)
  })
  .finally(() => db.$disconnect())

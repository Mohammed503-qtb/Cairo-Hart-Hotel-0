// ─────────────────────────────────────────────────────────────
// PURGE-DEMO — مسح بيانات العرض التجريبية (AD-10 · F7/P2 — Task 24-d)
//
// الغرض: قبل أول ضيف حقيقي (بوابة الإطلاق P2) يجب أن تموت كل
// بيانات seed التجريبية (حجوزات/ضيوف/إقامات/أكواد عرض/جلسات).
// «لا يُسمح بقيام دائم لأي كود تجريبي في بيئة الإنتاج» — AD-10.
//
// ما يُمسح: كل البيانات التشغيلية + الطاقم + الأكواد + الجلسات + التدقيق.
// ما يُبقى (إعداد الفندق القابل للتعديل من لوحة الإدارة):
//   Hotel · RoomType · Room (المشغولة تعود AVAILABLE) · Rate
//   ServiceCategory · Service
//
// بعد المسح يُنشئ السكربت «كود إقلاع أدمن» واحدًا خامًا (يُطبع مرة
// واحدة فقط — لا يُخزَّن) لتسجيل الدخول الأول وإنشاء الطاقم الحقيقي.
//
// الاستخدام:
//   bun run scripts/purge-demo.ts              → جرد فقط (dry-run)
//   bun run scripts/purge-demo.ts --confirm    → مسح فعلي + كود إقلاع
//   bun run scripts/purge-demo.ts --confirm --days 7 --admin-name "فلان"
// ─────────────────────────────────────────────────────────────
import { PrismaClient } from '@prisma/client'
import { generateCode, hashCode, maskCode } from '../src/lib/codes'

const db = new PrismaClient()

const args = process.argv.slice(2)
const CONFIRM = args.includes('--confirm')
const nameIdx = args.indexOf('--admin-name')
const ADMIN_NAME = nameIdx >= 0 && args[nameIdx + 1] ? args[nameIdx + 1] : 'مالك التشغيل'
const daysIdx = args.indexOf('--days')
const daysRaw = daysIdx >= 0 ? Number(args[daysIdx + 1]) : 30
const DAYS = Number.isFinite(daysRaw) && daysRaw >= 1 && daysRaw <= 30 ? Math.floor(daysRaw) : 30

async function counts() {
  return {
    sessions: await db.session.count(),
    requestUpdates: await db.requestUpdate.count(),
    messages: await db.message.count(),
    notifications: await db.notification.count(),
    serviceRequests: await db.serviceRequest.count(),
    charges: await db.charge.count(),
    payments: await db.payment.count(),
    extensionRequests: await db.extensionRequest.count(),
    roomChangeRequests: await db.roomChangeRequest.count(),
    feedback: await db.feedback.count(),
    accessCodes: await db.accessCode.count(),
    stays: await db.stay.count(),
    reservations: await db.reservation.count(),
    guests: await db.guest.count(),
    auditLogs: await db.auditLog.count(),
    staff: await db.staff.count(),
  }
}

async function main() {
  const before = await counts()
  const total = Object.values(before).reduce((a, b) => a + b, 0)

  console.log('═'.repeat(64))
  console.log('مسح بيانات العرض التجريبية (AD-10) — فندق قلب القاهرة (عدن)')
  console.log('═'.repeat(64))
  console.log(`وضع التشغيل: ${CONFIRM ? '🔴 مسح فعلي (--confirm)' : '🟡 جرد فقط (dry-run — أضف --confirm للمسح)'}`)
  console.log(`القاعدة: ${process.env.DATABASE_URL ?? '(من .env)'}`)
  console.log('')

  console.log('البيانات التشغيلية التي ' + (CONFIRM ? 'ستمسح' : 'ستُمسح لو أكدت') + ':')
  for (const [k, v] of Object.entries(before)) {
    if (v > 0) console.log(`  · ${k.padEnd(22)} ${v}`)
  }
  if (total === 0) {
    console.log('  (لا توجد بيانات تشغيلية — القاعدة نظيفة أصلًا)')
  }
  const roomsOccupied = await db.room.count({ where: { status: 'OCCUPIED' } })
  if (roomsOccupied > 0) {
    console.log(`  · الغرف المشغولة ستعود AVAILABLE: ${roomsOccupied}`)
  }
  console.log('')

  const kept = [
    'Hotel', 'RoomType', 'Room (مع الحالة)', 'Rate',
    'ServiceCategory', 'Service',
  ]
  console.log(`ما يُبقى (الإعداد): ${kept.join(' · ')}`)
  console.log('')

  if (!CONFIRM) {
    console.log('➜ لم يُمسح شيء. أعد التشغيل بـ --confirm للمسح الفعلي.')
    return
  }

  // مسح فعلي — بترتيب العلاقات (الأبناء قبل الآباء)
  await db.session.deleteMany({})
  await db.requestUpdate.deleteMany({})
  await db.message.deleteMany({})
  await db.notification.deleteMany({})
  await db.serviceRequest.deleteMany({})
  await db.charge.deleteMany({})
  await db.payment.deleteMany({})
  await db.extensionRequest.deleteMany({})
  await db.roomChangeRequest.deleteMany({})
  await db.feedback.deleteMany({})
  await db.accessCode.deleteMany({})
  await db.stay.deleteMany({})
  await db.reservation.deleteMany({})
  await db.guest.deleteMany({})
  await db.auditLog.deleteMany({})
  await db.staff.deleteMany({})

  // الغرف المشغولة تعود متاحة (إقاماتها مُسحت) — DIRTY/OUT_OF_SERVICE تبقى
  const freed = await db.room.updateMany({
    where: { status: 'OCCUPIED' },
    data: { status: 'AVAILABLE' },
  })

  // الجرد النهائي قبل إنشاء كيانات الإقلاع (يجب أن يكون صفرًا تامًا)
  const after = await counts()
  const afterTotal = Object.values(after).reduce((a, b) => a + b, 0)

  console.log('─'.repeat(64))
  console.log('✅ تم المسح. الجرد بعد (قبل الإقلاع):')
  const leftovers = Object.entries(after).filter(([, v]) => v > 0)
  if (leftovers.length === 0) {
    console.log('  (صفر تام — كل البيانات التشغيلية مُحيت)')
  } else {
    for (const [k, v] of leftovers) console.log(`  · ${k.padEnd(22)} ${v}`)
    console.error(`❌ بقيت ${afterTotal} صفوف — راجع العلاقات الجديدة`)
    process.exitCode = 1
  }
  console.log(`  (محيت ${total} صفًا تشغيليًا)`)
  console.log('')

  // ── كود الإقلاع: أول أدمن حقيقي ──
  const staff = await db.staff.create({
    data: { fullName: ADMIN_NAME, role: 'ADMIN', phone: null },
  })
  const raw = generateCode('ADMIN')
  const expiresAt = new Date(Date.now() + DAYS * 24 * 60 * 60 * 1000)
  const code = await db.accessCode.create({
    data: {
      codeHash: hashCode(raw),
      codeMasked: maskCode(raw),
      type: 'ADMIN',
      staffId: staff.id,
      expiresAt,
      status: 'ACTIVE',
    },
  })
  await db.auditLog.create({
    data: {
      action: 'DATA_PURGED',
      entityType: 'System',
      entityId: 'purge-demo',
      actor: 'SYSTEM',
      actorRole: 'SYSTEM',
      details: JSON.stringify({
        purged: before,
        freedRooms: freed.count,
        bootstrapStaff: staff.fullName,
        bootstrapCodeMasked: code.codeMasked,
        bootstrapDays: DAYS,
      }),
    },
  })

  console.log('═'.repeat(64))
  console.log('🔑 كود إقلاع الأدمن (يُعرض مرة واحدة الآن فقط — لا يُخزَّن):')
  console.log('')
  console.log(`      ${raw}`)
  console.log('')
  console.log(`   صالح ${DAYS} يومًا للموظف: ${ADMIN_NAME}`)
  console.log('   انسخه الآن، سجّل الدخول به، ثم أنشئ أكواد الطاقم الحقيقية')
  console.log('   من (الإدارة ← الطاقم والأكواد) وأبطله بعد تسليمك المفاتيح.')
  console.log('═'.repeat(64))
}

main()
  .catch((e) => {
    console.error('فشل المسح:', e)
    process.exitCode = 1
  })
  .finally(() => db.$disconnect())

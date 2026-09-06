// ─────────────────────────────────────────────────────────────
// MAKE-CODES — إنشاء أكواد فحص حية (أدمن/استقبال) لتشغيل
// mobile-contract-test.ts — مثل purge-demo تمامًا (توليد + هاش).
// الاستخدام: bun run scripts/make-codes.ts
// (الأكواد الخام تُطبع مرة واحدة — أعد تشغيل السكربت لإنشاء جديدة)
// ─────────────────────────────────────────────────────────────
import { PrismaClient } from '@prisma/client'
import { generateCode, hashCode, maskCode } from '../src/lib/codes'
const db = new PrismaClient()

async function mk(type: 'ADMIN' | 'RECEPTION', name: string, role: string) {
  let staff = await db.staff.findFirst({ where: { fullName: name, role } })
  if (!staff) staff = await db.staff.create({ data: { fullName: name, role } })
  const raw = generateCode(type)
  await db.accessCode.create({
    data: {
      type,
      codeHash: hashCode(raw),
      codeMasked: maskCode(raw),
      status: 'ACTIVE',
      expiresAt: new Date(Date.now() + 2 * 24 * 3600 * 1000),
      staffId: staff.id,
    },
  })
  console.log(`${type}_CODE=${raw}`)
}

await mk('ADMIN', 'مدقق الجوال', 'ADMIN')
await mk('RECEPTION', 'مختبر الاستقبال', 'RECEPTION')
await db.$disconnect()

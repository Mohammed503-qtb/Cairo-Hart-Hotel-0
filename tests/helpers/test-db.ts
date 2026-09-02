// ─────────────────────────────────────────────────────────────
// TEST DB HARNESS — قاعدة اختبار معزولة عبر migrations الرسمية
// (H2-b و H3 يشتركان في هذه البنية بالتوازي — لا تعدّل هذا الملف)
//
// القواعد الصارمة للاستخدام:
// 1) أول سطر حرفي في ملف الاختبار (قبل أي import ثابت لوحدات src/):
//      process.env.DATABASE_URL = 'file:/home/z/my-project/db/test-<name>.db'
//    ثم استدعاء setupTestDb('<name>') ثم الاستيراد الديناميكي لوحدات التطبيق.
//    <name> مختلف لكل وكيل/مجموعة (مثل integration و auth) — وكيلان
//    متوازيان لا يتشاركان ملف القاعدة أبدًا.
// 2) ممنوع الاستيراد الثابت (static import) لأي وحدة من src/ في ملفات
//    اختبار قاعدة البيانات — PrismaClient يُبنى لحظة أول استيراد ويقرأ
//    DATABASE_URL وقتها. الاستيراد الديناميكي (await import) بعد ضبط
//    البيئة فقط. استيراد هذا الملف ثابتًا آمن (لا يستورد من src/).
// 3) bun test يشغّل كل الملفات في عملية واحدة — حارس __TEST_DB_READY_<name>__
//    يضمن أن التهيئة تجري مرة واحدة لكل عملية لكل اسم. الأفضل عمليًا:
//    اختبارات كل مجموعة في ملف واحد متسلسل.
// 4) لا يجوز أبدًا توجيه الاختبارات إلى db/custom.db (قاعدة التطوير الحية).
// 5) شغّل الاختبارات محددة النطاق: bun test tests/<مجموعتك>/ — لا تشغّل
//    bun test عاريًا بينما وكيل آخر يكتب ملفات اختبار في مجلد آخر.
// ─────────────────────────────────────────────────────────────
import { spawnSync } from 'node:child_process'
import { existsSync, rmSync } from 'node:fs'

const ROOT = '/home/z/my-project'

export function testDbUrl(name = 'test'): string {
  return `file:${ROOT}/db/test-${name}.db`
}

const g = globalThis as unknown as Record<string, boolean | undefined>

/**
 * يهيئ قاعدة اختبار نظيفة باسم مستقل (حذف + migrate deploy + seed)
 * عبر المسار الرسمي — مرة واحدة لكل عملية لكل اسم. يضبط DATABASE_URL
 * أيضًا. استدعِها في بداية الملف قبل أول استيراد ديناميكي لوحدات src/.
 */
export function setupTestDb(name = 'test'): void {
  const dbPath = `${ROOT}/db/test-${name}.db`
  const dbUrl = `file:${dbPath}`
  process.env.DATABASE_URL = dbUrl

  const guardKey = `__TEST_DB_READY_${name}__`
  if (g[guardKey]) return
  g[guardKey] = true

  for (const f of [dbPath, `${dbPath}-journal`, `${dbPath}-wal`, `${dbPath}-shm`]) {
    if (existsSync(f)) rmSync(f)
  }

  const env = { ...process.env, DATABASE_URL: dbUrl }

  const deploy = spawnSync('bunx', ['prisma', 'migrate', 'deploy'], {
    cwd: ROOT,
    env,
    encoding: 'utf8',
  })
  if (deploy.status !== 0) {
    throw new Error(`migrate deploy فشل على قاعدة الاختبار (${name}):\n${deploy.stdout}\n${deploy.stderr}`)
  }

  const seed = spawnSync('bun', ['prisma/seed.ts'], { cwd: ROOT, env, encoding: 'utf8' })
  if (seed.status !== 0) {
    throw new Error(`seed فشل على قاعدة الاختبار (${name}):\n${seed.stdout}\n${seed.stderr}`)
  }
}

/** يحذف ملفات قاعدة اختبار بالاسم (للتنظيف اليدوري عند الحاجة). */
export function dropTestDb(name = 'test'): void {
  const dbPath = `${ROOT}/db/test-${name}.db`
  for (const f of [dbPath, `${dbPath}-journal`, `${dbPath}-wal`, `${dbPath}-shm`]) {
    if (existsSync(f)) rmSync(f)
  }
  g[`__TEST_DB_READY_${name}__`] = false
}

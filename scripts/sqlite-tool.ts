// ─────────────────────────────────────────────────────────────
// SQLITE-TOOL — أداة نسخ/فحص/استعادة موحدة لقاعدة SQLite (P2)
//
// لا تعتمد على ثنائي sqlite3 المثبت — تستخدم bun:sqlite المدمج،
// فتعمل في الرملة وعلى الخادم بنفس السلوك.
//
// الأوامر:
//   bun scripts/sqlite-tool.ts backup <db> <dest>   → نسخة متناسقة (VACUUM INTO) + فحص
//   bun scripts/sqlite-tool.ts check  <db>           → PRAGMA quick_check + جرد الجداول
//   bun scripts/sqlite-tool.ts restore <src> <db>    → تحقق من المصدر ثم استبدال القاعدة
//                                                      (مع نسخة أمان من الحالية أولًا)
// ─────────────────────────────────────────────────────────────
import { Database } from 'bun:sqlite'
import { copyFileSync, existsSync, mkdirSync, renameSync } from 'node:fs'
import { dirname } from 'node:path'

const [cmd, a, b] = process.argv.slice(2)

function open(dbPath: string, readonly = true): Database {
  return new Database(dbPath, { readonly, create: false })
}

function quickCheck(dbPath: string): { ok: boolean; result: string } {
  if (!existsSync(dbPath)) return { ok: false, result: 'الملف غير موجود' }
  const db = open(dbPath, true)
  try {
    const row = db.query('PRAGMA quick_check;').get() as { quick_check: string } | null
    const result = row?.quick_check ?? 'no-result'
    return { ok: result === 'ok', result }
  } finally {
    db.close()
  }
}

switch (cmd) {
  case 'backup': {
    const dbPath = a ?? ''
    const dest = b ?? ''
    if (!dbPath || !dest) {
      console.error('الاستخدام: sqlite-tool.ts backup <db> <dest>')
      process.exit(2)
    }
    if (!existsSync(dbPath)) {
      console.error(`❌ القاعدة غير موجودة: ${dbPath}`)
      process.exit(1)
    }
    mkdirSync(dirname(dest), { recursive: true })
    // 1) نقطة تحقق WAL (best-effort — قد يفشل مع كتاب متزامن، لا يضر)
    try {
      const live = open(dbPath, false)
      live.exec('PRAGMA wal_checkpoint(PASSIVE);')
      live.close()
    } catch {
      /* الخادم يكتب الآن — VACUUM INTO متسقة رغم ذلك */
    }
    // 2) اللقطة المتناسقة
    const db = open(dbPath, true)
    try {
      db.exec(`VACUUM INTO '${dest.replaceAll("'", "''")}';`)
    } finally {
      db.close()
    }
    // 3) فحص فوري للنسخة
    const check = quickCheck(dest)
    if (!check.ok) {
      console.error(`❌ النسخة ${dest} فشلت في quick_check (${check.result}) — لا تُعتدّ بها`)
      process.exit(1)
    }
    console.log(`✅ نسخة متناسقة: ${dest} (quick_check: ok)`)
    break
  }

  case 'check': {
    const dbPath = a ?? ''
    if (!dbPath) {
      console.error('الاستخدام: sqlite-tool.ts check <db>')
      process.exit(2)
    }
    const check = quickCheck(dbPath)
    if (!check.ok) {
      console.error(`❌ quick_check: ${check.result}`)
      process.exit(1)
    }
    console.log('✅ quick_check: ok')
    // جرد الجداول التشغيلية (أسماء الجداول من @@map في prisma/schema.prisma)
    const db = open(dbPath, true)
    try {
      const tables = (db
        .query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_prisma%'")
        .all() as { name: string }[]).map((r) => r.name)
      for (const t of tables.sort()) {
        const c = (db.query(`SELECT COUNT(*) AS c FROM "${t}";`).get() as { c: number }).c
        console.log(`  · ${t.padEnd(22)} ${c}`)
      }
    } finally {
      db.close()
    }
    break
  }

  case 'restore': {
    const src = a ?? ''
    const dbPath = b ?? ''
    if (!src || !dbPath) {
      console.error('الاستخدام: sqlite-tool.ts restore <src> <db>')
      process.exit(2)
    }
    // 1) تحقق من سلامة النسخة المصدر أولًا — لا استعادة من نسخة تالفة
    const check = quickCheck(src)
    if (!check.ok) {
      console.error(`❌ النسخة المصدر فاسدة (quick_check: ${check.result}) — رفض الاستعادة`)
      process.exit(1)
    }
    // 2) نسخة أمان من الحالية قبل الاستبدال
    if (existsSync(dbPath)) {
      const safety = `${dbPath}.pre-restore.${Date.now()}`
      copyFileSync(dbPath, dbPath + '.safety-tmp')
      renameSync(dbPath + '.safety-tmp', safety)
      console.log(`🛡️ نسخة أمان من الحالية: ${safety}`)
    }
    // 3) الاستبدال + التحقق
    copyFileSync(src, dbPath)
    const after = quickCheck(dbPath)
    if (!after.ok) {
      console.error(`❌ القاعدة المستعادة فشلت في quick_check (${after.result})`)
      process.exit(1)
    }
    console.log(`✅ استُعيدت القاعدة من ${src} (quick_check: ok)`)
    console.log(`   أعد تشغيل الخدمتين الآن: systemctl restart cairo-hart-web cairo-hart-realtime`)
    break
  }

  default: {
    console.error('الأوامر: backup <db> <dest> · check <db> · restore <src> <db>')
    process.exit(2)
  }
}

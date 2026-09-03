# Task H1 — خط أساس Prisma Migrations

## الوكيل
full-stack-developer

## العمل
تنفيذ البند H1 من MASTER_PLAN v2.0 (المرحلة H — التحصين): إنشاء migration تأسيسي يمثل المخطط الحالي كما هو بالضبط (صفر تغيير تصميمي)، تعليم قاعدة التطوير الحية بأنها على هذا الخط الأساس، إثبات المسار النظيف قابل لإعادة الإنتاج من الصفر، وتحويل migrations إلى المسار الرسمي الوحيد بدل db:push.

### الخطوات المنفذة (بالأوامر ونتائجها)
1. **جرد الحالة**: `.env` = `file:/home/z/my-project/db/custom.db`، لا يوجد `prisma/migrations` إطلاقًا، الخادم حي (200)، المخطط **22 نموذجًا فعليًا** (الوصف التاريخي «20» تقريبي).
2. **التوليد**: `bunx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script > /tmp/baseline.sql` → 374 سطرًا: **22 CREATE TABLE** + **14 CREATE INDEX** (9 منها UNIQUE) + كل قيود FOREIGN KEY. راجعتُ الملف سطرًا سطرًا مقابل المخطط: كل جدول/فهرس/UNIQUE حاضر.
3. **الإنشاء**: `prisma/migrations/20260901000000_baseline/migration.sql` (نسخة مطابقة للـ diff — تحقق `diff` لاحقًا: مطابق 100%) + `prisma/migration_lock.toml` (`provider = "sqlite"`).
4. **التعليم**: `bunx prisma migrate resolve --applied 20260901000000_baseline` → نجح من أول محاولة (لا قفل SQLite رغم عمل الخادم). سجل `_prisma_migrations`: finished=1, rolled_back=0.
5. **الحالة**: `bunx prisma migrate status` → «1 migration found in prisma/migrations / Database schema is up to date!».
6. **اختبار أمان (قبل المسار النظيف)**: أثبتّ أن `DATABASE_URL` الصريح في البيئة **يتقدم على .env** في CLI والعميل معًا (تجربة على `/tmp/prec-test.db`: الـ CLI طبع مسار الـ scratch، والعميل أخفق بـ «table main.Hotel does not exist») — أي أن فحص الـ scratch لا يمكنه لمس custom.db بصمت.
7. **المسار النظيف**: على `db/migrate-check.db`:
   - `DATABASE_URL="file:/home/z/my-project/db/migrate-check.db" bunx prisma migrate deploy` → «SQLite database created + Applying 20260901000000_baseline + All migrations have been successfully applied»
   - `DATABASE_URL="file:/home/z/my-project/db/migrate-check.db" bun prisma/seed.ts` → اكتمل بلا أخطاء
   - العدّ: **hotel=1, rooms=14, reservations=5, stays=2, guests=5, serviceRequests=2**
   - `migrate status` على الـ scratch: up to date
   - ثم `rm -f db/migrate-check.db db/migrate-check.db-journal` — حُذفت نهائيًا
8. **التوثيق**: README.md قسم «التشغيل محليًا» → الخطوة 3 أصبحت `bunx prisma migrate deploy` (+ إشارة `bun run db:deploy`) + الملاحظة الصريحة المطلوبة عن حظر db:push على القواعد الحقيقية؛ package.json → `"db:deploy": "prisma migrate deploy"` مع إبقاء كل السكربتات.

### مفاجأة مكتشفة (موثقة بشفافية — سابقة لعملي)
- **قاعدة custom.db كانت فارغة من البيانات عند بدئي**: ملف القاعدة وُلد `2026-09-02 00:24` مع تهيئة بيئة هذه الجلسة (كل الجداول بلا صفوف، ولا `_prisma_migrations` قبل resolve)، وخادم dev (بدأ 00:24) كان يرجع **503** على `/api/public/hotel` و`/api/public/room-types` منذ ذلك الحين.
- أوامري (diff/resolve/status + قراءات count) لا تحذف بيانات — الحالة سابقة لعملي (الأرجح: إعادة تهيئة البيئة شغّلت مسار إنشاء المخطط القديم `db:push` دون seed).
- **الاستعادة**: `bun prisma/seed.ts` (المسار الرسمي، بلا db:push وبلا لمس يدوي) → تحقق: `/api/public/hotel` = 200 بالبيانات، `/api/public/room-types` = 200 (4 أنواع)، `H834729X7` يرجع جلسة GUEST (خالد يوسف).
- ملاحظة جانبية: وكلاء متوازيون نشطون (tests/unit ظهر 02:17 ثم أُخلي؛ محاولة dev ثانية فشلت بـ EADDRINUSE وبترت بداية dev.log).

### التحقق النهائي
- `curl /` → **HTTP 200**
- `bunx prisma migrate status` → **Database schema is up to date!**
- `bun run lint` → **exit 0 نظيف**
- `git status --short` → فقط: `M README.md`، `M package.json`، `?? prisma/migration_lock.toml`، `?? prisma/migrations/20260901000000_baseline/migration.sql`
- آخر أسطر `dev.log` → 200 على room-types و auth/validate، لا أخطاء runtime
- بعد الاستعادة: custom.db → hotel=1, rooms=14, reservations=5, stays=2, accessCodes=4 + سجل `_prisma_migrations` سليم

### الملفات (ملكيتي)
- **منشأة**: `prisma/migrations/20260901000000_baseline/migration.sql`، `prisma/migration_lock.toml`
- **معدلة**: `README.md` (قسم التشغيل محليًا فقط)، `package.json` (إضافة db:deploy فقط)
- **لم تُلمس**: `prisma/schema.prisma`، `db/custom.db` يدويًا، `src/`، `tests/`، `docs/CONTRACTS.md`؛ لم يُشغَّل `db:push` ولا `bun run build`

## النتائج
- H1.1–H1.4 مقفلة بمعايير القبول كلها: استنساخ نظيف يعمل بمسار migrations فقط، `migrate status` صفر انحراف، والمسار الرسمي موثق في README + سكربت db:deploy.
- من الآن كل تغيير مخطط = migration جديد عبر `bunx prisma migrate dev --name <وصف>` (أول مستخدم متوقع: H3.1 — توكن bearer للجلسات).

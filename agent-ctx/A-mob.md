# A-mob — الفحص الساكن للجوال (المستوى C) — تطبيق Flutter «فندق قلب القاهرة — عدن»

- **Task ID:** A-mob
- **Agent:** general-purpose (وكيل تدقيق — ساكن بالكامل، قراءة فقط)
- **التاريخ:** 2026-09-05 (02:00–02:45 UTC تقريبًا)
- **نقطة الفحص:** شجرة العمل المحلية `2e3897b` مع تحقق أن `mobile/` مطابقة حرفيًا لما اختبرته CI (`git diff --stat fb9edf2 e722325 -- mobile/` فارغ — لا فرق في mobile بين fb9edf2 و e722325 و HEAD المحلي) والبعيد `main = e722325`.
- **المستوى المُتبع:** **C** (لا محاكي/لا جهاز/لا Flutter SDK — انظر §6 حدود البيئة).

---

## 1) حدود البيئة الصريحة (قبل كل شيء — تصريح المستوى C)

| البند | الحالة | الدليل |
|---|---|---|
| Flutter SDK | **غير مثبت** | `which flutter dart` → لا مخرجات؛ PATH لا يحوي أي مسار Flutter (`/home/z/.venv/bin:/home/z/.npm-global/bin:/home/z/.bun/bin:/usr/local/sbin:...`)؛ فحص المسارات الشائعة `/usr/lib/flutter, /opt/flutter, /home/z/flutter, /home/z/snap/flutter, /root/flutter, /usr/local/flutter, /snap/bin/flutter` → لا شيء موجود |
| **S4 (`flutter analyze`)** | **غير قابل للتنفيذ محليًا** | تعويض موثق: سجل وظيفة CI «Flutter analyze + test» للجولة الخضراء 1a0b0d2 (مخرج حرفي من logs API — أدناه §2.2) |
| **S5 (`flutter test`)** | **غير قابل للتنفيذ محليًا** | تعويض موثق: نفس السجل يحوي `🎉 169 tests passed.` |
| محاكي/جهاز Android | غير متوفر (لا Android SDK) | المستوى A/B مستحيل — المتبع C حصرًا |
| `apksigner` | غير متوفر | التعويض: `unzip -l` لملفات `META-INF/*.RSA|*.SF` + فحص كتلة توقيع APK v2 (magic `APK Sig Block 42`) + `keytool -printcert` |
| `db/custom.db` | **لم يُمس** | المهمة ساكنة — لا تشغيل، لا كتابة بيانات |

> **إقرار:** «تم فحص X» في هذا التقرير تعني حصريًا: قراءة كود موثقة بـ`ملف:سطر`، أو نداء GitHub API حرفي (قراءة فقط)، أو تنزيل أصل من Releases، أو فحص ثنائي للـ APK. لا شيء شُغّل من Flutter محليًا.

---

## 2) الجزء 1 — GitHub API (قراءة فقط)

كل النداءات `curl -s -H "Authorization: Bearer <token>"` على `api.github.com/repos/Mohammed503-qtb/Cairo-Hart-Hotel-0`. لا POST ولا تشغيل workflows ولا تعديل أي شيء. الأدلة الخام محفوظة في `audit-evidence/mobile/gh-*.json`.

### 2.1 الجولات — `GET /actions/runs?per_page=20` (+page 2)

- `total_count: 27` جولة (كل التاريخ). تفصيلها: **Mobile CI 23** (منها جولتان أوليان معطوبتان ظهرتا باسم مسار الملف `.github/workflows/mobile-ci.yml` — نفس ظاهرة YAML المكسور الموثقة في Task 18)، **Web CI 3** (كلها خضراء: b693bbc #1 · addce53 #2 · 3429cba #3)، **Mobile Release 2** (b693bbc #1 فشل ثم 308db82 #2 نجح وأنشأ الإصدار).

**آخر 8 جولات (الأحدث أولًا):**

| workflow | head_sha | status | conclusion | created_at | run# | html_url |
|---|---|---|---|---|---|---|
| Mobile CI | fb9edf2 | completed | **success** | 2026-09-04T02:12:02Z | 21 | …/actions/runs/33828621131 |
| Mobile CI | 1a0b0d2 | completed | **success** | 2026-09-04T02:03:05Z | 20 | …/actions/runs/33828056973 |
| Mobile CI | 9803f81 | completed | failure | 2026-09-04T01:52:44Z | 19 | …/actions/runs/33827415900 |
| Mobile CI | edd5895 | completed | failure | 2026-09-04T01:46:40Z | 18 | …/actions/runs/33827038754 |
| Mobile CI | 4f867de | completed | failure | 2026-09-04T01:38:27Z | 17 | …/actions/runs/33826534569 |
| Mobile CI | d83625f | completed | success | 2026-09-03T23:25:10Z | 16 | …/actions/runs/33817516410 |
| Mobile CI | c2694ae | completed | failure | 2026-09-03T23:18:36Z | 15 | …/actions/runs/33817032342 |
| Mobile CI | a7aada4 | completed | failure | 2026-09-03T23:09:57Z | 14 | …/actions/runs/33816379259 |

### 2.2 التحقق من ادعاء العمل السابق — ✅ **مؤكَّد كلاهما**

**الادعاء 1: «CI خضراء بالكامل عند 1a0b0d2 (mobile: analyze + 169 اختبارًا + build smoke)»** — **مؤكد**:
- الجولة 20 (run 33828056973) عند `1a0b0d2` → `completed/success`.
- `GET …/actions/runs/33828056973/jobs` → وظيفتان كلتاهما success:
  - `Flutter analyze + test`: كل الخطوات خضراء، منها `Analyze → success` و `Test → success`.
  - `Android build smoke (dev flavor)`: `Build debug APK (dev flavor) → success` + `Upload APK artifact → success`.
- تنزيل سجل وظيفة الاختبار (`GET …/actions/jobs/<id>/logs` — 92,513 بايت، محفوظ في `audit-evidence/mobile/gh-run20-analyze-test-log.txt`):
  - سطر حرفي: **`🎉 169 tests passed.`** → عدد 169 مؤكد حرفيًا.
  - سطر حرفي: `flutter analyze --no-fatal-infos` ثم **`59 issues found. (ran in 13.0s)`** — كلها **info فقط** (صفر warning/error — تصنيفها: 47 prefer_const_constructors · 6 prefer_const_literals_to_create_immutables · 3 unnecessary_const · 1 unnecessary_brace_in_string_interps · 1 no_leading_underscores_for_local_identifiers · 1 dangling_library_doc_comments). *(انظر MOB-03: معيار S4 «صفر إشكالات» في AUDIT_BRIEF غير محقق حرفيًا — CI يمر بسبب `--no-fatal-infos` بتصميمه).*
- جولة 21 (fb9edf2 — docs تمس `mobile/README.md` فأطلقت mobile-ci بمسار paths): success أيضًا.

**الادعاء 2: «أربع جولات CI موثقة» (جولات F5)** — **مؤكد بالتطابق الحرفي مع worklog Task 21**:
- الجولة 1 = run 17 عند `4f867de` (failure — 6 أخطاء تجميع) · الجولة 2 = run 18 عند `edd5895` (failure — 5 تحذيرات analyzer) · الجولة 3 = run 19 عند `9803f81` (failure — 7 اختبارات) · الجولة 4 = run 20 عند `1a0b0d2` (**success**) — أربع جولات بالضبط وبنفس تسلسل SHAs الموثق في worklog.

### 2.3 خطوط CI — `GET /actions/workflows` → `total_count: 3`

| name | path | state | id |
|---|---|---|---|
| Mobile CI | .github/workflows/mobile-ci.yml | active | 348124692 |
| Mobile Release | .github/workflows/mobile-release.yml | active | 348124693 |
| Web CI | .github/workflows/web-ci.yml | active | 348124694 |

**ملفاتها محليًا (قراءة كاملة — ماذا تفعل بالضبط):**

1. **`mobile-ci.yml`** (79 سطرًا): مشغّل push/PR بفلتر مسارات `mobile/**` + `mobile-ci.yml` + `workflow_dispatch`. وظيفتان متوازيتان (working-directory: mobile، Flutter 3.29.2 stable عبر subosito/flutter-action@v2 مع cache):
   - **analyze-test**: `flutter pub get` → استخراج APP_VERSION من `pubspec.yaml` (`grep -m1 '^version:' | sed | cut -d+ -f1` إلى GITHUB_ENV) → `flutter analyze --no-fatal-infos` → `flutter test --dart-define=APP_VERSION=${APP_VERSION}`.
   - **build-smoke**: Java 17 temurin → نفس خطوات الإصدار → `flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_VERSION=…` → رفع الأثر `app-dev-debug.apk` (retention 7 أيام).
2. **`mobile-release.yml`** (117 سطرًا): مشغّل `workflow_dispatch` بمدخلين (`api_base_url` اختياري، `build_dev` منطقي افتراضي true) + push على tags `v*`. صلاحية `contents: write`. الخطوات: استرجاع مفتاح التوقيع من **Secrets** (`ANDROID_KEYSTORE_BASE64` → يفك إلى `upload-keystore.jks` + يولد `key.properties`؛ عند غيابه تحذير ويوقّع بمفتاح debug) → بناء **prod APK release flavor** (مع `API_BASE_URL` الاختياري عبر dart-define) → بناء dev APK → إعادة تسمية إلى `dist/CairoHeartGuest-v<version>-{prod,dev}.apk` → حساب وسم `v<VERSION>+<run_number>` → **ncipollo/release-action@v1** ينشئ GitHub Release بعنوان «تطبيق الضيف — فندق قلب القاهرة …» وجسم عربي يشرح النسختين وشاشة «إعدادات الخادم»، مع `allowUpdates/replacesArtifacts`.
3. **`web-ci.yml`** (48 سطرًا): مشغّل push/PR بفلتر `src/**, prisma/**, tests/**, package.json, bun.lock, eslint.config.mjs` + dispatch. وظيفة واحدة: checkout → oven-sh/setup-bun → **ربط مسار ثابت** (`sudo ln -sfn $GITHUB_WORKSPACE /home/z/my-project` — حامل الاختبارات يصلب هذا المسار) → `bun install --frozen-lockfile` → `bunx prisma generate` → `bun run lint` → `bun run test`.

### 2.4 Releases — `GET /releases` → **إصدار واحد موجود**

- **الوسم:** `v1.0.0+1+2` · **العنوان:** «تطبيق الضيف — فندق قلب القاهرة v1.0.0+1+2» · نُشر 2026-09-02T05:53:51Z · أنشأه `github-actions[bot]` (من الجولة Mobile Release #2 عند **308db82** — حدث workflow_dispatch).
- **الأصول:**
  - `CairoHeartGuest-v1.0.0+1-prod.apk` — 52,939,895 بايت (6 تنزيلات)
  - `CairoHeartGuest-v1.0.0+1-dev.apk` — 52,939,896 بايت (صفر تنزيلات)
- الجسم: شرح عربي (prod موقّعة = وضع الضيف F1 · dev بsuffix حزمة .dev · عند غياب العنوان المدمج: شاشة الدخول → «إعدادات الخادم»).

### 2.5 تنزيل APK الموقّع وتوثيقه — ✅ تم

- حمّلت **prod** عبر `Accept: application/octet-stream` (asset id 540700166) إلى `audit-evidence/mobile/CairoHeartGuest-v1.0.0+1-prod.apk` (HTTP 200 · 52,939,895 بايت · 7.2 ثانية). المجلد `audit-evidence/` **غير متتبع في git** (تحقق: `git ls-files audit-evidence/` فارغ) — مطابق للمطلوب.
- **الحجم/الهاش:** `52,939,895` بايت · `sha256 = 7907161f130e70089656508f664ebb3568cf895f5db6c6888c5e66cdafcc5a12`
- **`file`:** «Android package (APK), with gradle app-metadata.properties».
- **التوقيع (v1 JAR):** `unzip -l` يظهر `META-INF/CERT.RSA` (1,376 بايت) + `META-INF/CERT.SF` (34,942) + `META-INF/MANIFEST.MF` (34,868) — و`CERT.SF` يحوي `X-Android-APK-Signed: 2` و`Created-By: Android Gradle 8.7.3` و`Built-By: Signflinger` (380 مدخلًا مهضومًا).
- **التوقيع (v2/v3):** فحص ثنائي لآخر 3MB وجد magic **`APK Sig Block 42`** → كتلة توقيع APK v2 موجودة.
- **الشهادة (`keytool -printcert -file META-INF/CERT.RSA`):**
  - Owner/Issuer (ذاتية التوقيع): `CN=Cairo Heart Hotel Aden, OU=Mobile, O=Cairo Heart Hotel, L=Aden, C=YE`
  - الصلاحية: 2026-09-02 → 2056-08-25 (30 سنة) · SHA384withRSA · RSA 2048
  - SHA256 fingerprint: `88:51:36:43:CE:B1:A1:BE:FD:A5:2C:9B:66:DF:1D:B3:54:1F:2D:D6:89:C4:88:2F:FA:AD:FF:94:7C:3D:D8:B2`
  - SHA1: `E8:14:A4:B2:D6:EB:0F:EE:71:E8:F5:28:A8:3D:B3:06:75:2A:CB:92`
- **`apksigner`: غير موجود في البيئة** (صرّحت بذلك كما هو متوقع) — التحقق أعلاه بديل كافٍ لوجود التوقيع، لكنه **لا يعادل** تحقق `apksigner verify` الكامل (هوية مخططات v2/v3 داخل الكتلة غير مفحوصة — حد بيئي موثق).

### 2.6 فحص ثانوي لصلب APK (سلاسل AOT في `lib/arm64-v8a/libapp.so`)

| سلسلة (UTF-16LE للعربية) | النتيجة | الدلالة |
|---|---|---|
| `فندق قلب القاهرة` / `الاستقبال` / `الفاتورة` / `إقامتي` | **موجودة** | وضع الضيف F1/F2 داخل البناء |
| `XTransformPort` / `3002` / `chat:message` / `join` / `/api/auth/validate` / `/api/guest/` | **موجودة** | عميل realtime وعقود الضيف |
| `يتوفر تحديث مطلوب` / `نسخ رابط الإصدارات` / `minAppVersion` / `app-config` | **غائبة** | **حارس F6 غير موجود في هذا البناء** |
| `الوصولون` / `المغادرون` / `حالة الغرف` / `تأكيد تسجيل الوصول` | **غائبة** | **وضع الاستقبال F4 غير موجود** |
| `سجل التدقيق` / `أنواع الغرف` / `الطاقم والأكواد` | **غائبة** | **وضع الإدارة F5 غير موجود** |

→ الإصدار المنشور بُني من `308db82` (2026-09-02) — **قبل** F4-a (3429cba، 2026-09-03) وF5 وF6. هذا متسق مع worklog Task 21 («لا إصدار APK جديد — القرار للمالك»)، لكنه يعني أن **حارس minAppVersion لا يحمي الـ APK المنشور فعليًا** (انظر MOB-01).

---

## 3) الجزء 2 — تكافؤ النقل AD-03 (مقارنة كود بلا تشغيل)

### 3.1 الألوان — القيم الحرفية

**الهوية المقررة: كحلي `#1A3C6E` + ذهبي `#D4A843`**

| القيمة | الجوال (`mobile/lib/ui/theme.dart`) | الويب (`src/app/globals.css`) | الحكم |
|---|---|---|---|
| الكحلي (نهاري) | `AppColors.navy = Color(0xFF1A3C6E)` — theme.dart:10، مستخدم `primary:` — :29 | `--primary: #1A3C6E` — globals.css:62 (أيضًا :69,:73,:78,:85,:88,:90) | **مطابق حرفيًا** |
| الذهبي (نهاري) | `AppColors.gold = Color(0xFFD4A843)` — theme.dart:13، مستخدم `secondary:` — :33 | `--secondary: #D4A843` — globals.css:64 و`--gold: #D4A843` — :74 (أيضًا :79,:102,:112,:117) | **مطابق حرفيًا** |
| الذهبي (ليلي) | `secondary: AppColors.gold` — theme.dart:59 | `--secondary: #D4A843` / `--gold: #D4A843` — globals.css:102,112 | **مطابق** |
| **الكحلي المعدَّل (ليلي)** | `primary: Color(0xFFA8C2E8)` — theme.dart:55 | `--primary: #8FB3E3` — globals.css:100 | **انحراف قيمة** (MOB-02) |
| خلفية Scaffold نهاري | `#F6F8FB` — theme.dart:49 | `--background: #FAF8F5` — globals.css:56 | انحراف (MOB-02) |
| خلفية Scaffold ليلي | `#0E1726` — theme.dart:75 | `--background: #0C1320` — globals.css:94 | انحراف (MOB-02) |
| نص فوق الذهبي | `onSecondary: #3A2E07` — theme.dart:34,60 | `--secondary-foreground: #2A2110` — globals.css:65,103 | انحراف (MOB-02) |

**ملاحظة بنية الويب:** المشروع **Tailwind 4 CSS-first**: الألوان الفعلية تُعرَّف في `@theme inline` بـ globals.css:6-43 (مثل `--color-primary: var(--primary)`) — أي أن `#1A3C6E` هو القيمة النافذة. ملف `tailwind.config.ts` (14-53) القديم بغلاف `hsl(var(--primary))` **موروث/أجوف** (سيُنتج لونًا غير صالح لو اعتُمد) — لا أثر تشغيليًا، لكنه بقايا تلتبس (MOB-04).

### 3.2 التسميات العربية — 24 تسمية (المطلوب ≥12) — **صفر انحراف تسمية**

| # | التسمية | الجوال (ملف:سطر) | الويب (ملف:سطر) | الحكم |
|---|---|---|---|---|
| 1 | لوحة التحكم (تبويب استقبال) | reception_shell.dart:50 | reception-app.tsx:44 | مطابق |
| 2 | الوصولون | reception_shell.dart:51 | reception-app.tsx:45 | مطابق |
| 3 | المقيمون | reception_shell.dart:52 | reception-app.tsx:46 | مطابق |
| 4 | الطلبات | reception_shell.dart:53 | reception-app.tsx:47 | مطابق |
| 5 | المغادرون | reception_shell.dart:54 | reception-app.tsx:48 | مطابق |
| 6 | حالة الغرف | reception_shell.dart:55 | reception-app.tsx:49 | مطابق |
| 7 | تسجيل وصول (عنوان المعالج) | check_in_wizard.dart:233 | check-in-wizard.tsx:169 | مطابق |
| 8 | تأكيد تسجيل الوصول | check_in_wizard.dart:672 | check-in-wizard.tsx:342 | مطابق |
| 9 | متابعة (زر الخطوات) | check_in_wizard.dart:476,551 | check-in-wizard.tsx:263,311 | مطابق |
| 10 | رجوع | check_in_wizard.dart:545,661 | check-in-wizard.tsx:310,339 | مطابق |
| 11 | نسخ الكود | check_in_wizard.dart:796 | check-in-wizard.tsx:396 | مطابق |
| 12 | إرسال واتساب | check_in_wizard.dart:806 | check-in-wizard.tsx:401 | مطابق |
| 13 | تأكيد الخروج مع رصيد غير مسدد؟ | check_out_wizard.dart:163 | check-out-wizard.tsx:274 | مطابق |
| 14 | نعم، أكّد الخروج | check_out_wizard.dart:184 | check-out-wizard.tsx:281 | مطابق |
| 15 | تراجع | check_out_wizard.dart:172 | check-out-wizard.tsx:280 | مطابق |
| 16 | تسجيل الوصول (زر بطاقة الوصول) | arrivals_screen.dart:198,447 | arrivals-view.tsx:124,216 | مطابق |
| 17 | تسجيل الخروج (زر المغادرة) | departures_screen.dart:287 | departures-view.tsx:154 | مطابق |
| 18 | حالات الغرف الخمس (متاحة/محجوزة/تنظيف جارٍ/تحتاج تنظيف/خارج الخدمة) | admin/rooms_screen.dart:19-34 | admin/sections/rooms.tsx:34-45 | مطابق (QUICK+EDITABLE حرفيًا) |
| 19 | تسميات حالات الحجز السبع (قيد الانتظار/مؤكد/ملغي/مسجّل دخول/مكتمل/لم يحضر/منتهي) | core/format.dart:101-109 | src/lib/format.ts:92-99 | مطابق حرفيًا |
| 20 | أقسام الإدارة الأحد عشر (لوحة التحكم/إعدادات الفندق/أنواع الغرف/الغرف/الأسعار/الخدمات/الطاقم والأكواد/الحجوزات/الضيوف/التقارير/سجل التدقيق) | admin_shell.dart:31-43 | admin-app.tsx:39-50 | مطابق (وMOBILE_PRIMARY نفس الأربعة: dashboard/rooms/reservations/staff) |
| 21 | فندق قلب القاهرة (عنوان الدخول) | login_screen.dart:114 | code-login.tsx:70 | مطابق |
| 22 | أدخل كود الدخول | login_screen.dart:144 | code-login.tsx:36,78 | مطابق |
| 23 | دخول (زر) | login_screen.dart:191 | code-login.tsx:98 | مطابق |
| 24 | أقل إصدار مسموح للتطبيق (حقل الإدارة) | hotel_settings_screen.dart:478 | hotel-settings.tsx:219 | مطابق |

إضافات موثقة: تبويبات الضيف الأربعة (الرئيسية/إقامتي/الخدمات/الفاتورة — guest_shell.dart:42-47 مقابل guest-app.tsx:50-53) مطابقة · حالة فراغ الوصولات «لا وصولات في … 🎉» (arrivals_screen.dart:79 مقابل arrivals-view.tsx:79) مطابقة حرفيًا · وصف حوار رصيد الخروج مطابق نصًا («سيتم إغلاق إقامة … مع بقاء رصيد مستحق … لا يمكن تسجيل دفعات على الإقامة بعد إغلاقها» — check_out_wizard.dart:164-168 مقابل check-out-wizard.tsx:275-278).
رسالة «يتوفر تحديث مطلوب» (update_required_screen.dart:56) — **شاشة خاصة بالتطبيق** بلا نظير ويب (ب التصميم — الحارس جانب العميل) — ليست انحرافًا.

### 3.3 RTL

- **`MaterialApp`** في `mobile/lib/app.dart:130` مع:
  - `locale: const Locale('ar')` — **app.dart:136**
  - `supportedLocales: const [Locale('ar')]` — **app.dart:137**
  - المندوبون `GlobalMaterialLocalizations/GlobalWidgetsLocalizations/GlobalCupertinoLocalizations` — **app.dart:138-142**
- لا يوجد عنصر `Directionality` صريح في main.dart (سطره الوحيد: runApp عند main.dart:14) — الاتجاه **مشتق من اللغة العربية عبر مندوبي التوطين** (النمط الأصيل في Flutter: locale `ar` ⇒ TextDirection.rtl على الجذر). `main.dart` كامل 15 سطرًا (تهيئة AppConfig → SessionController → runApp).
- **جزر LTR**: 96 موضع `textDirection: TextDirection.ltr` في `mobile/lib/` (أكواد/هواتف/مراجع/مبالغ — كنمط `dir="ltr"` في الويب) — أعدادها: audit_log (2) · reservations (8) · room_types (6) · services (…) وغيرها.

### 3.4 الاتصال — ApiClient حصريًا + Socket عبر البوابة

- **`mobile/lib/core/api_client.dart`** (188 سطرًا): كل النداءات GET/POST/PATCH/DELETE عبر `_send` (api_client.dart:53-62) بغلاف ok/fail الموحد، ترويسة Bearer (47)، **401 → tryRenew مرة واحدة → إعادة المحاولة → وإلا SessionExpiredError** (89-100)، و`postRaw` للدخول (141-176).
- **imports مباشرة لـ http في mobile/lib/: ملفان فقط**:
  1. `core/api_client.dart:8` — العميل نفسه (متوقع).
  2. `core/app_version.dart:12` — **استثناء موثق ومقصود**: حارس PUB-07 يفحص نقطة عامة قبل وجود جلسة/توكن، فيستعمل http.Client مباشرة (app_version.dart:62-85).
  - **صفر dio · صفر dart:io HttpClient** في mobile/lib (grep `package:dio/|import 'dart:io'|HttpClient`).
- **بناء عنوان Socket** (`services/socket_service.dart:92-101`):
  ```dart
  io.io(AppConfig.baseUrl, io.OptionBuilder()
      .setPath('/')
      .setQuery({'XTransformPort': AppConfig.realtimePort})   // ← البوابة
      .setTransports(['websocket', 'polling']) ...)
  ```
  و`AppConfig.realtimePort = '3002'` ثابتًا — **config.dart:77** — مع تعليق «وفق العقد: socket.io على المسار "/" مع XTransformPort=3002». **⇒ مطابق لعقد الويب `io("/?XTransformPort=3002")` ولا منفذ مباشر في عنوان.** الأحداث المستمعة (socket_service.dart:55-63) هي نفسها §1.5: chat:message · request:new/updated · notification:new · stay:updated · room:status · reservation:new، والغرف stay:{id}/reception/admin (66-87) كما في الويب.

---

## 4) الجزء 3 — جودة كود الجوال (ساكن)

| الفحص | الأمر | النتيجة | المواضع |
|---|---|---|---|
| `print(` | grep في `mobile/lib/` (و`test/` للمعلومة) | **صفر مطابقات** في lib وtest معًا | — (و`avoid_print: true` مفعل في analysis_options.yaml:5) |
| `withOpacity(` | grep في `mobile/lib/` | **صفر مطابقات** | بدلها **106 نداء `withValues(alpha:)`** (API الحديثة) |
| `debugPrint`/`developer.log` | grep | صفر | — |
| import http خارج api_client | grep `package:http/` | **2 فقط**: api_client.dart:8 (العميل) + app_version.dart:12 (حارس PUB-07 — استثناء مقصود موثق أعلاه) | موثق |
| حجم الشجرة | `find lib -name '*.dart'` | **67 ملفًا · 32,411 سطرًا** · 31 ملف اختبار | — |

---

## 5) الجزء 4 — حارس minAppVersion (F6) — الآلية حرفيًا

**الخادم:**
- `prisma/schema.prisma:44-45` — `minAppVersion String @default("")` على نموذج Hotel (تعليق: «فارغ = لا فرض»).
- `src/app/api/public/app-config/route.ts:12-19` — `GET /api/public/app-config` نقطة عامة بلا مصادقة: تعيد `ok({ minAppVersion: hotel?.minAppVersion ?? '' })`، وأي استثناء يعاد كقيمة فارغة (fail-open — سطر 17-18)، `force-dynamic` (سطر 10).
- يُضبط من وضع الإدارة: حقل «أقل إصدار مسموح للتطبيق» — web hotel-settings.tsx:219-223 · mobile hotel_settings_screen.dart:478 (يُرسل ضمن PATCH كـ `'minAppVersion'` — hotel_settings_screen.dart:41,117,157).

**العميل (mobile):**
- `core/app_version.dart:15-18` — `kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0')` (يُدمج وقت البناء؛ CI يستخرجه من pubspec — mobile-ci.yml:33-35 ثم يمرره 41 و71). الافتراضي 0.0.0 = «أقدم إصدار» (اتجاه fail-closed تجاه القيمة: أي فرض يحجب بناءً بلا إصدار مدمج).
- `compareSemver` (29-37): مقارنة ثلاثية رقمية، غير الرقمي = 0. `needsUpdate` (55-58): `minVersion` فارغ ⇒ false؛ وإلا `compareSemver(app, min) < 0`.
- `fetchMinAppVersion` (62-85): GET `$baseUrl/api/public/app-config` بمهلة 10 ثوان — null عند أي فشل/غير 200/شكل غير متوقع (كل الفشلات متسامحة).
- `app.dart:109-118` — `_checkMinAppVersion()` عند الإطلاق (initState — app.dart:59): **يُتخطى إذا لا يوجد عنوان خادم مضبوط** (110 — شاشة الدخول تطلبه أولًا)؛ يخزن `_lastMinVersion` ويضبط `_updateRequired = min != null && needsUpdate(min)`.
- `app.dart:149-158` — **حجب كامل**: `_updateRequired` ⇒ `UpdateRequiredScreen(minVersion: _lastMinVersion, onRetry: _recheckMinAppVersion)` تحل محل الشاشة الرئيسية (قبل الدخول وبعده على السواء — تبديل home). «إعادة المحاولة» (120-123) تعيد الفحص (SplashGate أثناءها — :151) — يفك الحجب بعد رفع الأدمن للحد.
- `screens/update_required_screen.dart` — ماذا تعرض: العنوان **«يتوفر تحديث مطلوب»** (:56) · النص «هذا الإصدار من التطبيق لم يعد مدعومًا. حدّث التطبيق إلى أحدث إصدار من صفحة الإصدارات ثم عد وافتحه من جديد.» (:65) · بطاقة: «إصدارك الحالي» = kAppVersion (:78-80) و«الحد الأدنى المطلوب» = minVersion (:82-84) و«حمّل أحدث نسخة (APK) من:» + رابط قابل للتحديد (:87-101) · زر «نسخ رابط الإصدارات» (:106) عبر Clipboard · زر «إعادة المحاولة» (:115). الرابط: `kReleasesUrl = https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-0/releases` (app_version.dart:21-22).
- الاختبار موجود في CI: `mobile/test/screens/update_required_test.dart` («تعرض العنوان والحد المطلوب ورابط الإصدارات» — ظاهر في سجل الجولة 20).

**⚠️ فجوة تنفيذية موثقة:** الـ APK المنشور في Releases (308db82) **لا يحوي الحارس أصلًا** (§2.6) — الحارس يحمي البناءات المستقبلية فقط. أي فرض minAppVersion اليوم لن يحجب النسخة المنشورة.

---

## 6) سجل ملاحظات التدقيق (بترتيب الخطورة)

| ID | الخطورة | البُعد | المنصة | الموضع | العنوان | المتوقع | الفعلي | الدليل | سبب جذر مُرجَّح | إصلاح مقترح (بلا تنفيذ) |
|---|---|---|---|---|---|---|---|---|---|---|
| MOB-01 | **MAJOR** (تعملقي بنشر التطبيق؛ INFO من زاوية الكود) | الشاشات/الأقسام + المنطق | mobile | GitHub Release `v1.0.0+1+2` (من `308db82` 2026-09-02) | الـ APK المنشور نسخة «وضع الضيف فقط» سابقة لـ F4/F5/F6 | AUDIT_BRIEF §7-C: «تحقق من وجود APK موقّع في GitHub Releases» + §1: الجوال «flavors dev/prod» بأوضاعه الثلاثة | موجود وموقّع، لكنه بُني قبل F4/F5/F6: لا استقبال ولا إدارة ولا حارس تحديث — والتنزيلات 6 | فحص سلاسل libapp.so (§2.6) + تاريخ الجولات | قرار موثق بعدم إصدار جديد بعد F4/F5 (worklog Task 21) | قبل أي فرض minAppVersion: أطلق Mobile Release من main الحالي (قرار مالك — التشغيل خارج نطاق التدقيق) |
| MOB-02 | COSMETIC | الألوان/الثيم | cross | theme.dart:49,55,75,34,60 ↔ globals.css:56,100,94,65,103 | انحراف قيم ألوان ثانوية بين المنصتين (بلا مساس بهوية الكحلي/الذهبي) | AD-03: ألوان الثيم متكافئة | الكحلي الليلي: mobile `#A8C2E8` ≠ web `#8FB3E3`؛ خلفيات: `#F6F8FB`≠`#FAF8F5` و`#0E1726`≠`#0C1320`؛ onSecondary `#3A2E07`≠`#2A2110` | §3.1 جدول | نقل يدوي للقيم دون توحيد مصدر | توحيد القيم الخمس (أو اعتماد مصدر مشترك) — توصية فقط |
| MOB-03 | INFO | الاعتمادات/جودة | mobile | mobile-ci.yml:38 + سجل الجولة 20 | `flutter analyze` = 59 ملاحظة info (CI خضراء بسبب `--no-fatal-infos`) | S4: «صفر إشكالات» | 59 info (47 prefer_const_constructors…) — صفر warning/error | السطر الحرفي `59 issues found. (ran in 13.0s)` | تراكم info lints مع توسع F4/F5 | تشغيل `dart fix --apply` وتفعيل `prefer_const_constructors` — توصية |
| MOB-04 | INFO | الاعتمادات | web | tailwind.config.ts:14-53 | ملف tailwind.config.ts موروث أجوف (hsl(var(--primary)) على قيم hex) — المشروع Tailwind 4 CSS-first عبر `@theme inline` (globals.css:6-43) | لا أثر تشغيلي | بقايا قالب أولي تلبس القارئ | §3.1 | ترقية Tailwind 4 أبقت الملف القديم | حذف الملف أو تحديث تعليقه — توصية |

**عناصر مؤكدة سليمة (أدلة §2-§5):** ادعاءا CI (1a0b0d2 خضراء بـ169 اختبارًا + أربع جولات) — مؤكدان حرفيًا · خطوط CI الثلاثة موجودة وفاعلة وموثقة · APK موقّع v1+v2 بشهادة Cairo Heart Hotel Aden · تكافؤ تسميات 24/24 بلا انحراف · حالات الغرف/الحجز حرفية · RTL عربي بجزر LTR (96) · socket عبر `?XTransformPort=3002` بلا منفذ مباشر · صفر print/withOpacity وhttp حصري عبر ApiClient (باستثناء الحارس المقصود).

---

## 7) إقرار النزاهة

- **ما نُفّذ:** قراءة كود موثقة (كل موضع `ملف:سطر` أعلاه مقروء فعليًا) · 6 نداءات GitHub API قراءة فقط + تنزيل سجل وظيفة + تنزيل أصل APK · فحص توقيع بـ unzip/keytool/فحص ثنائي · grep ساكن للجودة · مقارنات حرفية للتكافؤ.
- **ما لم يمكن التحقق منه ولماذا:** S4/S5 محليًا (لا Flutter SDK — §1) — عُوّض بسجلات CI الحرفية · تشغيل حي للتطبيق (لا محاكي/جهاز — المستوى C بالتعريف) · تحقق apksigner الكامل (الأداة غير مثبتة — عُوّض بفحص v1+v2 الثنائي) · هوية مخطط v3 داخل كتلة التوقيع.
- **لا مساس بشيء:** لا تعديل ملفات كود، لا commit، لا push، لا إطلاق Actions، لا إنشاء/تعديل Releases، لا لمس `db/custom.db`. الملفات التي أنشأتها: `agent-ctx/A-mob.md` + إضافات في `audit-evidence/mobile/` (غير متتبعة في git) + إلحاق بـ `worklog.md` (المطلوب بالمهمة).

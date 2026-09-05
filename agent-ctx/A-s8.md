# تقرير الوكيل A-s8 — الفحص الساكن S8: مراجعة الاعتماديات (package.json · pubspec.yaml · realtime)

**المهمة:** AUDIT_BRIEF.md §5 جدول S8 — «راجع `package.json` و`mobile/pubspec.yaml`: تناقضات إصدارات، حزم بلا استخدام ظاهر، مخاطر أمنية معروفة» · بُعد الفحص #6 (الاعتمادات) من مصفوفة الأبعاد.
**الطبيعة:** ساكنة بالكامل (قراءة فقط — صفر تعديل على ملفات الكود، صفر commit/push، لا تثبيت حزم، لا مساس db/custom.db).
**نقطة الوقوف:** HEAD المحلي `2e3897b` (فروقات توثيقية فقط عن `fb9edf2` المذكور في بطاقة AUDIT_BRIEF — آخر 3 commits: 9248a30/e722325/2e3897b كلها docs؛ ملفات الاعتماديات لم تتغير) · تاريخ الفحص: 2026-09-05.
**نطاق المسح:** `src/` + `tests/` + `examples/` + `prisma/` + `mini-services/` (بلا node_modules) + `.github/workflows/` + ملفات إعداد الجذر (next.config.ts, tailwind.config.ts, postcss.config.mjs, eslint.config.mjs, tsconfig.json, components.json, package.json) — استُبعدت مجلدات عمل التدقيق (repo-cairo-hart/, audit-evidence/).

---

## 1) المنهجية (كل نتيجة بمسح برمجي لا بقراءة عينية)

| الخطوة | الطريقة | الناتج |
|---|---|---|
| الاستخدام الفعلي (الجذر) | مسح برمجي لكل ملفات الكود (امتدادات ts/tsx/js/jsx/mjs/css/json/yaml/sh/prisma) بريجكس استيراد: `(from\s+\|import(\s*require()\s*['"]حزمة(/مسار فرعي)?['"]` — 76 حزمة معلنة | تصنيف ثلاثي: مستوردة / ذكر نصي فقط / لا شيء |
| التحقق المستقل من «اللا استخدام» | بحث Grep (ripgrep) مستقل عن أسماء الحزم المشكوك فيها في `src/` و`tests/` | تأكيد صفر نتائج (انظر §4) |
| سلسلة مكوّنات shadcn (المستوى الثاني) | لكل ملف في `src/components/ui/*.tsx` (58 ملفًا): هل يستورده أي ملف خارج `ui/`؟ | 22 مكوّنًا حيًّا / 36 ميتًا — حزم radix التي تغذّي الميتات = «سلسلة ميتة» |
| النسخ المحجوزة | تحليل `bun.lock` برمجيًا (JSONC نُظّفت فواصله اللاحقة) واستخراج كل `packages["name"][0]` | 76 نسخة محجوزة (§3) |
| الثغرات المنشورة | **مصدر حي:** استعلامات POST فعلية إلى `https://api.osv.dev/v1/query` بتاريخ 2026-09-05 لـ 34 حزمة npm + 6 حزم Pub + 6 تبعيات مباشرة لخدمة realtime (engine.io/ws/cors/cookie/…) | §5 |
| أحدث ما تحلّه الجوال | **مصدر حي:** استعلامات إلى `pub.dev/api/packages/<name>` (لا يوجد pubspec.lock في المستودع — انظر §7) | §6 |
| التوافق البيني | مقارنة أزواج: next↔react · prisma↔@prisma/client · socket.io↔socket.io-client (JS+Dart) · tailwindcss↔@tailwindcss/postcss↔tailwind-merge | §8 |

> **ملاحظة أمانة:** لا يتوفر لي مهارة بحث ويب عام (Web-Search) في هذه البيئة، لكن الشبكة متاحة فاستُعملت واجهتا **OSV.dev** و**pub.dev** مباشرة كمصدرين حيين بتاريخ الفحص — كل بند أمني في هذا التقرير موسوم بمصدره، وما لم يُذكر مصدر حي فهو «غير متحقق من مصدر حي» صراحة.

---

## 2) الجدول أ — الحزم المستخدمة فعليًا في الجذر (32 من 68 dependencies + 8 من 9 devDependencies)

| الحزمة | المعلنة | المحجوزة (bun.lock) | مستخدمة؟ | ملاحظات/مخاطر |
|---|---|---|---|---|
| next | ^16.1.1 | **16.1.3** | نعم — 68 ملفًا | ⚠️ **32 تحذيرًا أمنيًا منشورًا على 16.1.3** (§5.1) — الإصلاح ≥16.2.11 داخل نطاق caret |
| react | ^19.0.0 | 19.2.3 | نعم — 98 ملفًا | نظيفة في OSV · انجراف minor (19.0→19.2.3) |
| react-dom | ^19.0.0 | 19.2.3 | ضمنيًا (متطلب تشغيل Next) | نظيفة · لا استيراد مباشر في src — طبيعي في App Router |
| @prisma/client | ^6.11.1 | **6.19.2** | نعم — 10 ملفات (src/lib/db.ts, audit.ts, refs.ts, availability.ts, api/guest/_lib, api/public/_lib…) | نظيفة · انجراف 8 minors (6.11.1→6.19.2) |
| prisma | ^6.11.1 | 6.19.2 | نعم — CLI فقط عبر سكربتات `db:*` (package.json:11-15) + أوامر CI/التدقيق | **موضعها الأدق devDependencies** (الإنتاج standalone لا يحتاج CLI) — §9.2 · متطابقة مع @prisma/client ✓ |
| socket.io-client | ^4.8.3 | 4.8.3 | نعم — `src/hooks/use-socket.ts:8` + `examples/websocket/frontend.tsx` | نظيفة · مطابقة لنسخة الخادم 4.8.3 (§8) |
| framer-motion | ^12.23.2 | 12.26.2 | نعم — 13 ملفًا (guest/* أساسًا) | نظيفة |
| lucide-react | ^0.525.0 | 0.525.0 | نعم — 74 ملفًا | نظيفة |
| zustand | ^5.0.6 | 5.0.10 | نعم — `src/lib/store.ts` | نظيفة |
| recharts | ^2.15.4 | 2.15.4 | نعم — `admin/sections/dashboard.tsx` + `admin/sections/reports.tsx` مباشرة | نظيفة · ملاحظة: `ui/chart.tsx` (wrapper) نفسه ميت لكن الحزمة حية بالاستيراد المباشر |
| next-themes | ^0.4.6 | 0.4.6 | نعم — theme-provider.tsx + site-header.tsx + ui/sonner.tsx(ميت) | نظيفة |
| uuid | ^11.1.0 | 11.1.0 | نعم — `src/app/api/auth/validate/route.ts:11` (`v4` فقط عند السطر 98) | ⚠️ GHSA-w5hq-g745-h8pq (§5.6) — **لا تنطبق** على نمط الاستخدام (v4 بلا buf) |
| class-variance-authority | ^0.7.1 | 0.7.1 | نعم — 8 ملفات ui حية | نظيفة |
| clsx | ^2.1.1 | 2.1.1 | نعم — `src/lib/utils.ts` (cn) | نظيفة |
| tailwind-merge | ^3.3.1 | 3.4.0 | نعم — `src/lib/utils.ts` | نظيفة · الجيل 3.x الصحيح لـ Tailwind 4 |
| @radix-ui/react-dialog | ^1.1.14 | 1.1.15 | نعم — dialog.tsx (28 مستهلكًا) + sheet.tsx (4 مستهلكين) | نظيفة |
| @radix-ui/react-label | ^2.1.7 | 2.1.8 | نعم — label.tsx (16 مستهلكًا) + form.tsx(ميت) | نظيفة |
| @radix-ui/react-select | ^2.2.5 | 2.2.6 | نعم — 13 مستهلكًا | نظيفة |
| @radix-ui/react-alert-dialog | ^1.1.14 | 1.1.15 | نعم — 9 مستهلكين | نظيفة |
| @radix-ui/react-slot | ^1.2.3 | 1.2.4 | نعم — button.tsx(49) + badge.tsx(24) [+ form/breadcrumb/sidebar ميوت] | نظيفة |
| @radix-ui/react-tabs | ^1.1.12 | 1.1.13 | نعم — 4 مستهلكين | نظيفة |
| @radix-ui/react-toast | ^1.2.14 | 1.2.15 | نعم — toaster.tsx المستهلك من `src/app/layout.tsx` | نظيفة |
| @radix-ui/react-switch | ^1.2.5 | 1.2.6 | نعم — 4 مستهلكين | نظيفة |
| @radix-ui/react-progress | ^1.1.7 | 1.1.8 | نعم — 6 مستهلكين | نظيفة |
| @radix-ui/react-separator | ^1.1.7 | 1.1.8 | نعم — 4 مستهلكين | نظيفة |
| @radix-ui/react-checkbox | ^1.3.2 | 1.3.3 | نعم — مستهلكان | نظيفة |
| @radix-ui/react-scroll-area | ^1.2.9 | 1.2.10 | نعم — admin-app.tsx | نظيفة |
| @radix-ui/react-accordion | ^1.2.11 | 1.2.12 | نعم — مستهلكان (guest-stay + contact-footer) | نظيفة |
| @radix-ui/react-tooltip | ^1.2.7 | 1.2.8 | نعم — reception-app + admin-app | نظيفة |
| @radix-ui/react-dropdown-menu | ^2.1.15 | 2.1.16 | نعم — admin/rooms.tsx | نظيفة |
| @radix-ui/react-popover | ^1.1.14 | 1.1.15 | نعم — admin/audit-log.tsx | نظيفة |
| @radix-ui/react-radio-group | ^1.3.7 | 1.3.8 | نعم — booking-dialog.tsx | نظيفة |
| **devDeps المستخدمة** | | | | |
| @tailwindcss/postcss | ^4 | 4.1.18 | نعم — postcss.config.mjs | مطابقة لإصدار tailwindcss نفسه ✓ |
| tailwindcss | ^4 | 4.1.18 | نعم — `@import "tailwindcss"` (globals.css:1) + البناء | نظيفة |
| tw-animate-css | ^1.3.5 | 1.4.0 | نعم — `@import "tw-animate-css"` (globals.css:2) | هو المفعّل الفعلي للحركات في Tailwind 4 (انظر §9.1) |
| eslint | ^9 | 9.39.2 | نعم — eslint.config.mjs + `bun run lint` | نظيفة |
| eslint-config-next | ^16.1.1 | 16.1.3 | نعم — eslint.config.mjs | مطابقة لنسخة next ✓ |
| typescript | ^5 | 5.9.3 | نعم — toolchain Next | نظيفة · ملاحظة مجاورة: `next.config.ts:7` يطفئ فحص البناء `ignoreBuildErrors:true` (يخص S1) |
| @types/react | ^19 | 19.2.8 | ضمنيًا (tsc/Next) | — |
| @types/react-dom | ^19 | 19.2.3 | ضمنيًا (tsc/Next) | — |

---

## 3) الجدول ب — «السلسلة الميتة»: حزم مستوردة فقط داخل مكونات ui/ ميتة (لا يستهلكها التطبيق) — 19 حزمة

> الحكم: الحزمة مستوردة في `src/components/ui/xxx.tsx`، لكن لا ملف واحد خارج `ui/` يستورد `ui/xxx` — أي أن المكون ميت وبالتالي الحزمة بلا أثر تشغيلي. (المستوردون داخل ui/ أنفسها = صفر لكل ما يلي.)

| الحزمة | المعلنة | المحجوزة | مستوردة فقط في | ملاحظات |
|---|---|---|---|---|
| cmdk | ^1.1.1 | 1.1.1 | ui/command.tsx (ميت) | نظيفة أمنيًا |
| embla-carousel-react | ^8.6.0 | 8.6.0 | ui/carousel.tsx (ميت) | نظيفة |
| input-otp | ^1.4.2 | 1.4.2 | ui/input-otp.tsx (ميت) | نظيفة |
| react-day-picker | ^9.8.0 | 9.13.0 | ui/calendar.tsx (ميت) | انجراف 5 minors — بلا أثر لأن المكون ميت |
| react-hook-form | ^7.60.0 | 7.71.1 | ui/form.tsx (ميت) | انجراف 11 minors — بلا أثر |
| react-resizable-panels | ^3.0.3 | 3.0.6 | ui/resizable.tsx (ميت) | — |
| sonner | ^2.0.6 | 2.0.7 | ui/sonner.tsx (ميت) | التطبيق يستخدم Toaster الرادكس (toaster.tsx من layout.tsx) — سونر بديل غير مستهلك |
| vaul | ^1.1.2 | 1.1.2 | ui/drawer.tsx (ميت) | نظيفة |
| tailwindcss-animate | ^1.0.7 | 1.0.7 | tailwind.config.ts:2 (ملف **غير محمَّل**) | **ميت فعليًا رغم «الاستيراد»**: Tailwind 4 لا يقرأ JS config إلا بتوجيه `@config` في CSS — وglobals.css لا يحويه؛ ازدواج غرض مع tw-animate-css (§9.1) |
| @radix-ui/react-aspect-ratio | ^1.1.7 | 1.1.8 | ui/aspect-ratio.tsx (ميت) | — |
| @radix-ui/react-avatar | ^1.1.10 | 1.1.11 | ui/avatar.tsx (ميت) | — |
| @radix-ui/react-collapsible | ^1.1.11 | 1.2.12 | ui/collapsible.tsx (ميت) | — |
| @radix-ui/react-context-menu | ^2.2.15 | 2.2.16 | ui/context-menu.tsx (ميت) | — |
| @radix-ui/react-hover-card | ^1.1.14 | 1.1.15 | ui/hover-card.tsx (ميت) | — |
| @radix-ui/react-menubar | ^1.1.15 | 1.1.16 | ui/menubar.tsx (ميت) | — |
| @radix-ui/react-navigation-menu | ^1.2.13 | 1.2.14 | ui/navigation-menu.tsx (ميت) | — |
| @radix-ui/react-slider | ^1.3.5 | 1.3.6 | ui/slider.tsx (ميت) | — |
| @radix-ui/react-toggle | ^1.1.9 | 1.1.10 | ui/toggle.tsx (ميت) | — |
| @radix-ui/react-toggle-group | ^1.1.10 | 1.1.11 | ui/toggle-group.tsx (ميت) | — |

(ملفات ui إضافية ميتة بلا حزم خارجية: pagination, table, alert, breadcrumb, sidebar, chart — تخص جرد المكونات لا الاعتماديات.)

## 3-مكرر) الجدول ج — حزم بلا أي استيراد في كود المشروع كله — 17 حزمة dependencies + 1 devDependency

> **ما بحثت عنه:** ريجكس استيراد على كل الملفات المذكورة في §1، ثم تحقق Grep مستقل بالاسم الحرفي لكل حزمة على `src/` و`tests/` (و`examples/` و`mini-services/` في المسح الشامل) — كل النتائج: **صفر**. لا يوجد أي `import/require/dynamic-import` لهذه الأسماء في أي ملف كود.

| الحزمة | المعلنة | المحجوزة | ملاحظات/مخاطر |
|---|---|---|---|
| @dnd-kit/core | ^6.3.1 | 6.3.1 | بقايا قالب — نظيفة أمنيًا |
| @dnd-kit/sortable | ^10.0.0 | 10.0.0 | بقايا قالب |
| @dnd-kit/utilities | ^3.2.2 | 3.2.2 | بقايا قالب |
| @hookform/resolvers | ^5.1.1 | 5.2.2 | رفيق react-hook-form الميت — انجراف بلا أثر |
| @mdxeditor/editor | ^3.39.1 | 3.52.3 | بقايا قالب — انجراف 13 minors بلا أثر |
| @reactuses/core | ^6.0.5 | 6.1.9 | بقايا قالب |
| @tanstack/react-query | ^5.82.0 | 5.90.19 | بقايا قالب — ازدواج غرض مع zustand (§9.1) |
| @tanstack/react-table | ^8.21.3 | 8.21.3 | بقايا قالب |
| next-auth | ^4.24.11 | 4.24.13 | ⚠️ **3 ثغرات منشورة في 4.24.13** (§5.2) + غير متوافق بنيويًا مع Next 16 لو استُورد يومًا (جيل 4.x مبني لـ Next ≤14) — **لا مسار استغلال حاليًا لأنها غير مستوردة إطلاقًا** |
| next-intl | ^4.3.4 | 4.7.0 | ⚠️ ثغرتان منشورتان في 4.7.0 (§5.3) — كامنة (غير مستوردة) · المشروع عربي مبني يدويًا بلا i18n framework |
| date-fns | ^4.1.0 | 4.1.0 | لا استيراد واحد (التواريخ تُدار يدويًا في src/lib) |
| react-markdown | ^10.1.0 | 10.1.0 | بقايا قالب — منظومة markdown الرباعية غير المستخدمة (§9.1) |
| react-syntax-highlighter | ^15.6.1 | 15.6.6 | بقايا قالب |
| remark-gfm | ^4.0.1 | 4.0.1 | بقايا قالب |
| sharp | ^0.34.3 | 0.34.5 | ⚠️ ثغرة libvips منشورة (§5.4) — كامنة: لا استخدام `next/image` في src إطلاقًا (Grep: صفر) فلا مُحسِّن صور أصلًا |
| z-ai-web-dev-sdk | ^0.0.18 | 0.0.18 | بقايا قالب z.ai |
| zod | ^4.0.2 | 4.3.5 | **لا استيراد واحد في src/tests** — كل تحقق المدخلات يدوي في مسارات API (دلالة معمارية، لا خلل) · نظيفة في OSV |
| **devDeps** | | | |
| bun-types | ^1.3.4 | 1.3.6 | معلنة لكن **غير موصولة**: tsconfig.json بلا حقل `"types"` وبلا إشارة إليها (tsconfig.json:1-42)، ولا `Bun.` في src (Grep: صفر)، ولا مرجع في next-env.d.ts — توصيتها الوصل أو الإزالة |

**الحصيلة الرقمية للجذر:** 68 dependencies معلنة → **32 مستخدمة (47%)** · **36 بلا أثر استخدام (53%)**: 17 بلا استيراد + 19 سلسلة ميتة. ومن 9 devDependencies: 8 مستخدمة + bun-types غير موصولة. كل النسخ المحجوزة تقع داخل نطاقات caret المعلنة (لا خرق semver واحد) — تفصيل الانجرافات في §7.

---

## 4) mobile/pubspec.yaml — الجدول الكامل (المسح على mobile/lib/ وmobile/test/)

> لا يوجد `pubspec.lock` في المستودع (Glob: غير موجود) — لذا عمود «المحجوزة» = ما تحلّه `flutter pub get` طازجًا اليوم (استعلام حي pub.dev 2026-09-05)، وهو نفسه ما يثبته CI في كل تشغيل (mobile-ci.yml: flutter-version 3.29.2).

| الحزمة | المعلنة | ما تحله pub اليوم (حي) | مستخدمة؟ | ملاحظات/مخاطر |
|---|---|---|---|---|
| flutter (sdk) | >=3.24.0 | 3.29.2 (CI) | نعم | القيد sdk >=3.5.0 <4.0.0 متوافق مع Dart 3.7 (الخاص بـ3.29.2) ✓ |
| flutter_localizations (sdk) | sdk | — | نعم — `lib/app.dart` (مرجعان: localizationsDelegates) | — |
| cupertino_icons | ^1.0.8 | 1.0.9 | **لا** — Grep `CupertinoIcons` في lib/ وtest/: **صفر** (الذكر الوحيد في pubspec.yaml نفسه) | بقايا قالب Flutter الافتراضي — إزالة مقترحة |
| http | ^1.2.2 | 1.6.0 | نعم — `lib/core/api_client.dart` + `lib/core/app_version.dart` | نظيفة في OSV-Pub |
| shared_preferences | ^2.3.2 | 2.5.5 | نعم — `lib/config.dart` | نظيفة |
| socket_io_client | ^3.0.0 | 3.1.6 | نعم — `lib/services/socket_service.dart:9` | نظيفة في OSV-Pub (تغطية Pub في OSV محدودة أصلًا) · توافق بروتوكول مع الخادم 4.8.3: §8 |
| url_launcher | ^6.3.0 | 6.3.2 | نعم — `lib/screens/reception/wizards/check_in_wizard.dart` (روابط wa.me — قرار W0) | نظيفة |
| flutter_test (sdk) | sdk | — | نعم — 169 اختبارًا (مرجعية CI) | — |
| flutter_lints | ^4.0.0 | 4.x (الأحدث العام 6.0.0) | نعم — `analysis_options.yaml:1` (`include: package:flutter_lints/flutter.yaml`) | جيل 4 يعمل؛ جيل 6 متاح كتحسين INFO |

**حصيلة الجوال:** 5 حزم runtime معلنة → 4 مستخدمة + **cupertino_icons غير مستخدمة** · صفر ثغرات معروفة في OSV-Pub للحزم السبع (مع تحفظ تغطية) · **لا pubspec.lock مؤرشف** — قابلية الاستنساخ غير مضمونة (انظر §7.3).

---

## 5) mini-services/realtime/package.json + المخاطر الأمنية (مصدر حي: OSV.dev — استعلامات 2026-09-05)

### 5.1 جدول realtime

| الحزمة | المعلنة | المحجوزة (bun.lock خاص بها) | مستخدمة؟ | ملاحظات |
|---|---|---|---|---|
| socket.io | ^4.8.1 | **4.8.3** | نعم — `index.ts:9` (`new Server`) | نظيفة في OSV · مطابقة للعميل JS |
| (تبعية) engine.io | — | 6.6.9 | ضمنيًا | نظيفة في OSV |
| (تبعية) ws | — | 8.21.3 | ضمنيًا | نظيفة (أحدث من إصلاح CVE-2024-37890 القديم) |
| (تبعية) cors/cookie | — | 2.8.6 / 0.7.2 | ضمنيًا | نظيفة · ملاحظة مجاورة: `cors: origin:'*'` بتصميم البوابة (index.ts:17) — ليست ضمن نطاق الاعتماديات |

### 5.2 سجل المخاطر الأمنية المنشورة (كلها من استعلام حي إلى api.osv.dev بتاريخ 2026-09-05)

| # | الحزمة@النسخة | التحذيرات | التفاصيل (المعرّفات) | الإصلاح | قابلية التطبيق على هذا المشروع |
|---|---|---|---|---|---|
| 1 | **next@16.1.3** (مستخدمة — عمود فقري) | **32 تحذيرًا** | **Bypass مجموعة Middleware/Proxy:** GHSA-267c-6grr-h53f (CVE-2026-44575) · GHSA-26hh-7cqf-hhc6 (CVE-2026-45109) · GHSA-36qx-fr4f-26g5 (CVE-2026-44573) · GHSA-492v-c6pp-mqqv (CVE-2026-44574) · GHSA-6gpp-xcg3-4w24 (CVE-2026-64642) · **تسميم كاش:** GHSA-vfv6-92ff-j949 (CVE-2026-44582) · GHSA-wfc6-r584-vfw7 (CVE-2026-44576) · GHSA-4633-3j49-mh5q (CVE-2026-64647) · GHSA-68g3-v927-f742 (CVE-2026-64648) · **SSRF:** GHSA-c4j6-fc7j-m34r (CVE-2026-44578) · GHSA-89xv-2m56-2m9x (CVE-2026-64649) · GHSA-p9j2-gv94-2wf4 (CVE-2026-64645) · **DoS:** GHSA-8h8q-6873-q5fj · GHSA-q4gf-8mx6-v5v3 · GHSA-h25m-26qc-wcjf · GHSA-m99w-x7hq-7vfj (CVE-2026-64641) · GHSA-4c39-4ccg-62r3 (CVE-2026-64646) · GHSA-h64f-5h5j-jqjh (CVE-2026-44577) · GHSA-q8wf-6r8g-63ch (CVE-2026-64644) · GHSA-mg66-mrh9-m8jx (CVE-2026-44579) · GHSA-5f7q-jpqc-wp7h (CVE-2025-59472) · GHSA-9g9p-9gw9-jx7f (CVE-2025-59471) · GHSA-h27x-g6w4-24gq (CVE-2026-27979) · GHSA-3x4c-7xq6-9pq8 (CVE-2026-27980) · **XSS:** GHSA-ffhc-5mcf-pf4q (CVE-2026-44581) · GHSA-gx5p-jg67-6x7h (CVE-2026-44580) · **تهريب/إعادة توجيه:** GHSA-ggv3-7p47-pfv8 (CVE-2026-29057) · **إفصاح:** GHSA-955p-x3mx-jcvp (CVE-2026-64643) · **CSRF بيئة التطوير:** GHSA-jcc7-9wpm-mj36 (CVE-2026-27977) · GHSA-mq59-m269-xvcx (CVE-2026-27978) | أقدم إصلاح داخل 16.1.5/16.1.7 · الأشمل **16.2.11** (كلها داخل نطاق ^16.1.1) | **منخفضة نسبيًا الآن لكنها حقيقية كدين أمني:** لا middleware.ts في المشروع (Glob: صفر) فمتجهات الـBypass غير مفتوحة · لا next/image (صفر) · لا Server Actions (`use server`: صفر) · لا rewrites في next.config.ts · لا PPR/Cache Components · لكن نشر الإنتاج standalone (`next.config.ts:4` + سكربت start) هو النمط الذي تصفه عدة تحذيرات DoS/كاش — **الترقية إلى ≥16.2.11 واجبة وقابلة بلا كسر** |
| 2 | next-auth@4.24.13 (**غير مستخدمة**) | 3 | GHSA-7rqj-j65f-68wh (CVE-2026-73420) تجاوز homoglyph للتطبيع · GHSA-x445-f3h2-j279 (CVE-2026-73419) ربط state/nonce/PKCE · GHSA-xmf8-cvqr-rfgj (CVE-2026-73418) استثناء غير معالج في getToken | 4.24.15 | **كامنة — لا مسار حالي** (صفر استيراد في المشروع) · إزالة الحزمة تُصفّر الخطر |
| 3 | next-intl@4.7.0 (**غير مستخدمة**) | 2 | GHSA-4c35-wcg5-mm9h تلوث prototype عبر precompile · GHSA-8f24-v5vv-gm5j (CVE-2026-40299) إعادة توجيه مفتوحة | 4.9.1 / 4.9.2 | كامنة — صفر استيراد |
| 4 | sharp@0.34.5 (**غير مستخدمة**) | 1 | GHSA-f88m-g3jw-g9cj — ثغرات libvips موروثة (CVE-2026-33327/33328/35590/35591) | 0.35.0 | كامنة — لا next/image في المشروع |
| 5 | uuid@11.1.0 (مستخدمة) | 1 | GHSA-w5hq-g745-h8pq (CVE-2026-41907/41988) — غياب فحص حدود buffer في v3/v5/v6 عند تمرير buf | 11.1.1 | **لا تنطبق على الاستخدام الفعلي:** الكود يستدعي `v4()` بلا buf (validate/route.ts:11,98) — الترقية داخل caret بسيطة كتحصين |
| 6 | البقية كلها | 0 | react 19.2.3 · react-dom · @prisma/client 6.19.2 · prisma · socket.io 4.8.3 · socket.io-client 4.8.3 · engine.io 6.6.9 · ws 8.21.3 · framer-motion 12.26.2 · zustand · zod · lucide-react · recharts · sonner · next-themes · tailwindcss · tw-animate-css · react-hook-form · @tanstack/react-query · date-fns · vaul · cmdk · clsx · cva · typescript · eslint · كل حزم Pub السبع | — | **«لا ثغرات معروفة»** بمخرج OSV الحرفي بتاريخ الاستعلام |

> تحفظ إقرار: OSV يجمّع GitHub advisories وCVE — الحزم «النظيفة» نظيفة **بحد علم قاعدة OSV في 2026-09-05**؛ وحزم Pub تغطيتها في OSV محدودة تاريخيًا. ما لم يُستعلم حيًّا (حزم الـ«سلسلة الميتة» غير المدرجة في §5.2 سطر 6) بقي معلنًا فقط — والحاسم أنها غير مستوردة أصلًا فخطرها الصفري تشغيليًا هو خطر وزن لا خطر ثغرة.

---

## 6) تناقضات الإصدارات والتوافق البيني

| الثنائية | الحالة | الدليل/الحكم |
|---|---|---|
| next 16.1.3 ↔ react 19.2.3 | ✅ متوافقة | Next 16 مبني على React 19.2 — المقيد 19.2.3 محجوز فعلاً |
| prisma 6.19.2 ↔ @prisma/client 6.19.2 | ✅ متطابقتان حرفيًا | الزوج الإلزامي (CLI+Client) بنفس الإصدار في bun.lock |
| socket.io (خادم realtime) 4.8.3 ↔ socket.io-client (ويب) 4.8.3 | ✅ تطابق تام | نفس الإصدار في القفلين (الجذر + realtime) |
| socket.io 4.8.3 ↔ socket_io_client (Dart) ^3.0.0→3.1.6 | ✅ متوافقة بروتوكولًا | جيل 3.x من عميل Dart يطبق بروتوكول Socket.IO v4/Engine.IO v4 — والدليل التشغيلي: الاختبارات الثنائية الموثقة حية في worklog (Task 20/21: ضيف↔استقبال لحظيًا عبر البوابة) |
| tailwindcss 4.1.18 ↔ @tailwindcss/postcss 4.1.18 ↔ tailwind-merge 3.4.0 | ✅ ثلاثي متسق | الجيل الصحيح لبعضه (tailwind-merge 3.x مصمم لـ Tailwind 4) |
| eslint-config-next 16.1.3 ↔ next 16.1.3 | ✅ متطابقتان | — |
| radix 27 حزمة ↔ react 19.2.3 | ✅ متوافقة | إصدارات 2025+ من Radix تدعم React 19 في peerDeps |
| **تناقض حاد (خارج النطاق المرن)** | **صفر** | كل نسخة محجوزة تقع داخل نطاق caret المعلن — لا خرق semver واحد في bun.lock |

---

## 7) الانجراف (declared vs locked) وخطر caret

1. **انجرافات داخل caret (طبيعية، موثقة):** next 16.1.1→16.1.3 · prisma/@prisma/client 6.11.1→**6.19.2** (8 minors) · react/react-dom 19.0.0→19.2.3 · framer-motion 12.23.2→12.26.2 · zod 4.0.2→4.3.5 · react-hook-form 7.60.0→7.71.1 · next-intl 4.3.4→4.7.0 · react-day-picker 9.8.0→9.13.0 · @mdxeditor 3.39.1→3.52.3 · @tanstack/react-query 5.82.0→5.90.19 · @hookform/resolvers 5.1.1→5.2.2 · @reactuses 6.0.5→6.1.9 · uuid/sonner/… طفيفة. الحكم: bun.lock يجمّد الواقع فلا مفاجآت في التثبيت؛ الخطر يظهر فقط عند `bun update`.
2. **هل يجلب caret نسخة كاسرة؟** لا كسر متوقعًا: كل النطاقات major-مقيدة (next ^16 يبقى <17؛ prisma ^6 يبقى <7). **لكن** المفارقة العملية: تحديث واحد داخل النطاق (^16.1.1 → 16.2.11) هو نفسه **إصلاح الثغرات الـ32** — أي أن الترقية الأمنية لا تكسر caret بل تنفذ من داخله (توصية إيجابية). المخاطرة الكاسرة الأعلى في المشروع ليست caret بل: **bun-version: latest في web-ci.yml:29** (أداة CI غير مثبتة) — تحديث أداة Bun الكبير قد يغير سلوك التثبيت/الاختبار بين ليلة وضحاها.
3. **الجوال بلا قفل:** غياب `pubspec.lock` من المستودع يجعل `^` تُحل طازجة كل CI (اليوم: socket_io_client 3.1.6 · http 1.6.0 · shared_preferences 2.5.5 · url_launcher 6.3.2) — فرق النسخ بين جهاز المطوّر وCI ممكن بلا ضابط. Flutter توصي بأرشفة lock لتطبيقات (وليس لحزم منشورة) — MINOR.

---

## 8) ازدواج الغرض، سوء الموضع، وملاحظات إضافية

### 8.1 حزمان لنفس الغرض (أو أكثر)
1. **tailwindcss-animate ↔ tw-animate-css** — كلاهما إضافات حركات Tailwind؛ الأولى «مستوردة» في tailwind.config.ts لكن الملف **غير محمَّل أصلًا** في Tailwind 4 (لا `@config` في globals.css — والأدلة: components.json:7 يصرح `tailwind.config: ""` أي CSS-first) → tw-animate-css هو الفعال. دليل إضافي على موت config: أنماط content فيه تشير إلى `./pages` و`./components` و`./app` — مسارات غير موجودة في بنية src/. **خطر عملي:** من يظن أن تعديل tailwind.config.ts يؤثر سيضيع وقته.
2. **@tanstack/react-query ↔ zustand** — إدارة حالة/جلب؛ react-query صفر استخدام وzustand هي المستخدمة.
3. **next-auth ↔ المصادقة الداخلية** (src/lib/auth.ts + أكواد H/R/A المخزنة SHA-256) — next-auth بقايا قالب بلا أي دور.
4. **منظومة markdown الرباعية** — react-markdown + remark-gfm + react-syntax-highlighter + @mdxeditor/editor: كلها صفر استخدام.
5. **uuid ↔ crypto.randomUUID المدمج** (Bun/Node ≥19) — يمكن الاستغناء عن الحزمة كليًا (استخدام واحد v4).

### 8.2 dependencies في devDependencies أو العكس
- **prisma (CLI) في dependencies** والموضع الأدق devDependencies — الإنتاج standalone (`next.config.ts:4`) يشغّل server.js بـ@prisma/client فقط؛ CLI يحتاجه التطوير/الترحيل. (MINOR — ليس خللًا تشغيليًا.)
- **sharp في dependencies** وهو غير مستخدم أصلًا (لا next/image) — إزالة لا نقل.
- **العكس (runtime في dev): صفر** — كل حزم runtime المستخدمة (next, react, @prisma/client, socket.io-client, uuid, zustand, framer-motion…) في dependencies موضعها الصحيح.
- bun-types في devDependencies معلنة بلا توصيل (tsconfig بلا `"types": ["bun-types"]`) — توصيل أو إزالة (INFO).

### 8.3 ملاحظات إضافية (INFO)
- `examples/websocket/server.ts:2` يستورد `socket.io` — **غير معلنة في package.json الجذر** وغير مثبتة في node_modules الجذر (تحقق مباشر: node_modules/socket.io غائب؛ هي معلنة فقط في mini-services/realtime) → المثال غير قابل للتشغيل من الجذر — بقايا قالب (MINOR).
- هوية package.json: `name: "nextjs_tailwind_shadcn_ts"` v0.2.1 — اسم القالب الأصلي لم يُعرَّب/يُخصص لهوية المشروع (INFO).
- لا حقل `engines` في package.json (INFO).

---

## 9) الحصيلة والتوصيات (توصيات فقط — لا تنفيذ؛ النطاق قراءة)

| البند | العدد/الحكم | الخطورة (بمقياس AUDIT_BRIEF §11) |
|---|---|---|
| حزم الجذر بلا أثر استخدام | **36/68 dependencies (53%)** + bun-types من dev | MINOR (وزن تثبيت + سطح هجوم بالعرض — أربع منها عليها تحذيرات منشورة لكن كامنة) |
| دين أمني فعلي | next 16.1.3 عليها **32 تحذيرًا منشورًا** والحزمة العمود الفقري للمشروع | **MAJOR** (تطبيق المباشر منخفض لغياب middleware/image/actions — لكن اللازم الترقية إلى ≥16.2.11 داخل caret بلا كسر) |
| ثغرات كامنة | next-auth 3 · next-intl 2 · sharp 1 — كلها بحزم غير مستوردة | INFO/كامن — الإزالة تصفّرها |
| ثغرة مشروطة | uuid 11.1.0 (GHSA-w5hq-g745-h8pq) — لا تنطبق على v4() المستخدمة | INFO — ترقية إلى 11.1.1 كتحصين |
| تناقضات إصدارات حادة | **صفر** (كل المحجوز داخل caret) · زعم AUDIT_BRIEF «next 16.1.3» مطابق للقفل ✓ | — |
| الجوال | cupertino_icons غير مستخدمة · لا pubspec.lock | MINOR |
| realtime | 1/1 مستخدمة ونظيفة + تبعياتها (engine.io/ws) نظيفة | — |

**التوصيات المرتبة (بلا تنفيذ):**
1. ترقية `next` إلى ≥16.2.11 (داخل ^16.1.1) وتشغيل الاختبارات الـ165 — سد الدين الأمني الأكبر.
2. إزالة الحزم الـ17 غير المستوردة (أولاها next-auth وnext-intl وsharp — عليها تحذيرات؛ ثم dnd-kit×3، tanstack×2، markdown×4، reactuse، z-ai-web-dev-sdk، date-fns، zod إن لم يكن مخططًا لاستخدامها) + رفع uuid إلى 11.1.1.
3. حذف ملفات ui الميتة الـ36 ومَعها حزم «السلسلة الميتة» الـ19 — أو إبقاؤها كمكتبة shadcn جاهزة بقرار واعٍ موثق (الإبقاء الحالي غير موثق كقرار).
4. إزالة tailwind.config.ts وtailwindcss-animate (الملف غير محمّل) بعد تأكيد أن كل الثيم يعتمد globals.css — وتوثيق ذلك.
5. نقل prisma CLI إلى devDependencies + توصيل bun-types أو إزالتها.
6. أرشفة mobile/pubspec.lock + تثبيت bun-version في web-ci.yml بدل latest.
7. إصلاح/حذف examples/websocket/server.ts (يستورد socket.io غير المتوفرة في الجذر).

---

## 10) إقرار النزاهة
- نُفّذ: مسح برمجي كامل للاستخدام (76+9+9 حزم) · تحليل سلسلة ui بمستويين · قراءة bun.lock للجذر وrealtime · استعلامات حية إلى OSV.dev (46 استعلامًا: 34 npm + 6 Pub + 6 تبعيات realtime) وpub.dev (6 حزم) بتاريخ 2026-09-05 · تحقق Grep مستقل لكل ادعاء «لا استخدام».
- لم يمكن/لم يُنفّذ: تشغيل `bun audit` (لا يوجد ضمن bun 1.3 سكربت مكافئ موثوق — اكتفيت بـOSV كمصدر حي أدق) · فحص npm registry الثانوي (OSV يغطي advisories المنشورة). كل ما في هذا التقرير إما بمصدر حي مذكور أو بموضع ملف:سطر.
- صفر تعديل على أي ملف كود (المخرجان الوحيدان: هذا التقرير + سجل worklog).

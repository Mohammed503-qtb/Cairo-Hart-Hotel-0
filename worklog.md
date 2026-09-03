# Hotel Platform — Work Log

> ملف سجل العمل المشترك لجميع الوكلاء. كل وكيل يقرأه قبل البدء ويضيف قسمه في النهاية (Append فقط، لا يتم الكتابة فوق المحتوى).

---
Task ID: 1
Agent: Main Agent (Z.ai Code)
Task: تحويل HOTEL PLATFORM — MASTER PLAN (Website + Mobile + Backend) إلى وثيقة MASTER_PLAN.md تنفيذية صارمة، وبناء عارض تفاعلي لها في صفحة /

Work Log:
- قراءة الملفين المرفوعين بالكامل: upload/PLAN_WEBSITE.md (3425 سطرًا) و upload/PLAN_ MOBILE-APK.md (2071 سطرًا)
- تحديد البنية الموحدة: 15 قسمًا رئيسيًا (دليل القراءة، ADR، Domain Model، State Machines، Database، Identity/Codes، RBAC، API، Events، Screens/Routes، Structures، Security/Testing، Phases، DoD، ملاحق)
- كتابة /home/z/my-project/MASTER_PLAN.md على دفعات (Task 2-b → 2-g)
- إطلاق Subagent (Task 2-a) لبناء عارض الوثيقة في src/app/page.tsx + src/app/api/plan/route.ts

Stage Summary:
- قيد التنفيذ: الوثيقة تُكتب على مراحل، العارض يُبنى بالتوازي

---
Task ID: 2-3-4
Agent: Main Agent (Z.ai Code)
Task: بناء أساس المنصة المركزية — قاعدة البيانات + مكتبات الخادم + الهوية البصرية + خدمة Realtime

Work Log:
- كتابة مخطط Prisma كامل (20 نموذجًا): Hotel, RoomType, Room, Rate, Guest, Reservation, Stay, Charge, Payment, Staff, AccessCode, Session, ServiceCategory, Service, ServiceRequest, RequestUpdate, Message, Notification, ExtensionRequest, RoomChangeRequest, Feedback, AuditLog — المبالغ بالسنت (Int)، بدون enums (SQLite) مع قيم موثقة
- bun run db:push + توليد 9 صور فندقية حقيقية (hero + 4 أنواع غرف + lobby/مطعم/تراس/ممر) في public/images/
- مكتبات الخادم: codes.ts (توليد/هاش/قناع الأكواد H/R/A) — refs.ts (HTL/ST/REQ) — pricing.ts (محرك تسعير حتمي + snapshot) — availability.ts (توفر + تحقق تواريخ) — audit.ts — rate-limit.ts — auth.ts (جلسات + requireRole) — events.ts (بث socket.io) — api.ts (ok/fail)
- مكتبات العميل: format.ts (عملة/تواريخ/تسميات حالات عربية) — store.ts (zustand+persist) — api-client.ts — use-socket.ts
- خدمة Realtime: mini-services/realtime (socket.io منفذ 3002 عبر البوابة + HTTP emit داخلي 3004) — تعمل الآن
- seed.ts: فندق + 14 غرفة + 4 أنواع + خدمات + طاقم + 5 حجوزات (وصولان اليوم، مقيمان بكودي ضيف، مستقبلي) + طلبات + محادثة + مدفوعات + تدقيق
- الهوية: globals.css بلوحة ألوان الفندق (كحلي #1A3C6E + ذهبي #D4A843) فاتح/داكن، خط Cairo، layout.tsx عربي RTL، شعار SVG
- صفحة / = SPA بتبديل أوضاع (website/login/guest/reception/admin) + شاشة دخول الكود + زر عائم "دخول التطبيق"
- API المصادقة: POST /api/auth/validate (rate limit + hash + جلسة) و /api/auth/logout — مختبرة بنجاح

Stage Summary:
- الأساس مكتمل ومختبر: كود الضيف H834729X7 يعيد جلسة GUEST، كود خاطئ يرجع رسالة عربية
- أكواد تجريبية: ضيف H834729X7 (خالد غرفة 201) / ضيفة H119922K4 (نورا غرفة 103 خروج اليوم) / استقبال R492671M3 / إدارة A371849L9
- جاري إطلاق الوكلاء: 5-a موقع+حجز، 5-b ضيف، 5-c استقبال، 5-d إدارة

---
Task ID: 5-a
Agent: full-stack-developer
Task: موقع الفندق العام + محرك الحجز

Work Log:
- استلام عمل سابق شبه مكتمل (API عام + مكونات موقع) بلا تحقق؛ قراءة كل الملفات والملكيات
- إصلاح خطأ Hydration في hero-section.tsx: motion.p يحوي Skeleton (div) → تحويله motion.div — صفر أخطاء console بعدها
- إعادة تشغيل خادم dev:3000 (كان قُتل بـ OOM) بطريقة تعبر الجلسات `(setsid bun run dev &)` + تسخين كل المسارات
- تحقق API عبر curl: availability (فلترة سعة + فرز سعر + ضريبة/زيادة نهاية أسبوع)، bookings (PAY_AT_HOTEL/CARD + idempotency replay يعيد نفس الحجز + 201)، lookup (هاتف خاطئ = رسالة موحدة 404)، cancel (مزدوج = 400)، والتدقيق/الإشعارات/الدفعات مكتوبة في DB
- تحقق browser (agent-browser): RTL عربي + 21 صورة سليمة + وضع ليلي؛ ودجت البحث (اليوم→+2) يعطي 3 أنواع بأسعار صحيحة؛ حجز كامل PAY_AT_HOTEL → HTL-2026-000008 مع طباعة التأكيد ونسخ المرجع؛ حجز CARD → HTL-2026-000009 (عربون 50% + زيادة نهاية أسبوع $132)؛ إدارة الحجز + إلغاء مجاني له؛ موبايل 390×844 بدون overflow؛ Lightbox بأسهم الكيبورد؛ dev.log بلا أخطاء runtime
- bun run lint: 0 أخطاء/تحذيرات في ملفاتي (التحذير الوحيد في use-socket.ts ملف مشترك خارج ملكيتي)
- كتابة سجل العمل: agent-ctx/5-a-full-stack-developer.md

Stage Summary:
- الملفات: src/app/api/public/{_lib,hotel,room-types,availability,bookings,lookup,cancel} + src/components/website/{website-view,site-header,hero-section,search-widget,rooms-section,facilities-gallery,contact-footer,booking-dialog,manage-booking-dialog,print-confirmation,helpers}
- النتائج: lint نظيف لملفاتي؛ كل مسارات API 200/201 (السلبية مقصودة)؛ تدفق حجز/إدارة/إلغاء كامل يعمل من الواجهة؛ HTL-2026-000008 (فندق) وHTL-2026-000009 (بطاقة، أُلغي) شهادات اختبار
- ملاحظة للوكلاء التاليين: خادم dev قد يُقتل بـ OOM أثناء تجميع مسارات كثيرة + كروم — أعد تشغيله بـ `(setsid bun run dev &)` من مجلد المشروع إن وجدت 3000 مغلقًا؛ حجوزات الاختبار الحية: HTL-2026-000006/0008 مؤكدة

---
Task ID: 5-b
Agent: full-stack-developer (قُطع الاتصال قبل التحقق — أكمل الوكيل الرئيسي التحقق نيابةً عنه)
Task: تطبيق الضيف (Guest Mode)

Work Log:
- بناء 15 مسار API كاملة تحت src/app/api/guest/ (dashboard, stay, services, requests + cancel, messages, bill, extension, room-options, room-change, checkout-request, notifications + read, feedback) مع _lib.ts مشتركة
- بناء مكونات الواجهة: guest-app (هيكل + تنقل سفلي)، guest-home، guest-stay، guest-services، guest-bill، chat-dialog، request-dialog، request-detail-dialog، extension-dialog، room-change-dialog، checkout-dialog، feedback-dialog، notifications-sheet، guest-context
- التحقق (بواسطة الوكيل الرئيسي بعد استعادة الخادم): دخول H834729X7 → لوحة خالد يوسف غرفة 201 ✓، إنشاء طلب تنظيف عاجل REQ-1003 من الواجهة ✓، الفاتورة بأرقام صحيحة ($552 غرفة + $65 إضافي + المدفوعات + الرصيد $317) ✓، المحادثة بفواصل أيام وإرسال فوري ✓، الإشعارات مع عداد غير مقروء ✓، lint نظيف، صفر أخطاء console
- استعادة حالة العرض التجريبية بعد اختبارات الوكيل (stay ACTIVE، حذف طلبات/رسائل الاختبار)

Stage Summary:
- تطبيق الضيف كامل ومتحقق منه: إقامة، خدمات، طلبات، محادثة فورية (socket + polling)، فاتورة، تمديد، تغيير غرفة، طلب خروج، ملاحظات
- عزل البيانات مضمون: كل مسار يتحقق من الجلسة ويعيد بيانات إقامة الضيف فقط

---
Task ID: 5-c
Agent: full-stack-developer
Task: وضع الاستقبال

Work Log:
- وجدت API الاستقبال (17 مسارًا) + الواجهة (19 مكونًا) مكتملين من وكيل سابق انقطع قبل التحقق — قرأت كل شيء ثم تحققت وعمّقت
- إصلاح bug حرج في /api/reception/search: صيغة Prisma غير صالحة (OR كقيمة حقل contains) كانت ترجع 500 — أُعيد بناء الشروط بمصفوفة OR مسطحة لكل تنويع حالة، واختُبر بعربي/مرجع/غرفة/lowercase
- إصلاح dashboard: inHouseStays أصبح يشمل CHECKOUT_REQUESTED حسب المواصفة
- إصلاح Hydration errors: زر «إدارة» داخل بطاقة-زر (dashboard-view → div[role=button])، وشريط خطوات div داخل DialogDescription/p (check-in + check-out wizards → span flex)
- إصلاح تحديث لوحة الغرف: تغيير حالة الغرفة لم يكن يُعاد عرضه إلا عبر socket → أضفت onChanged→bump في RoomDialog (تحديث فوري دائمًا) + أوصاف حوارات دائمة (إزالة تحذير aria-describedby)
- إصلاح صغير: تعطيل «متابعة» في معالج الوصول إن لم يكن الحجز CONFIRMED
- تحقق المتصفح (agent-browser) الكامل: دخول R492671M3 → وصول أحمد محمد HTL-2026-000421 بمعالج 4 خطوات → غرفة 202 → كود ضيف H334469T0 (تحقق بـ validate + دخول به في تبويب جديد)؛ إكمال طلب «المكيف لا يبرد» العاجل؛ خروج نورا بدفعة نقدية $50 ثم إغلاق → 103 تحتاج تنظيف → تنظيفها حتى متاحة؛ 303 خارج الخدمة و106 تحتاج تنظيف ✓؛ موافقة تمديد خالد $184 → تاريخ الخروج 3 سبتمبر + بند ROOM_EXTENSION؛ الإشعارات والـ KPIs تتحدث؛ البحث الفوري؛ سلبية: خروج برصيد 400+balanceCents، غرفة مشغولة مرفوضة، نوع غرفة خاطئ مرفوض
- خادم dev قُتل بـ OOM أثناء الاختبار → أُعيد بـ (setsid bun run dev &) وعاد سريعًا
- Realtime مُتحقق عبر بوابة Caddy (المنفذ 81): emit → delivered:true، وطلب ضيف جديد ظهر في لوحة الاستقبال لحظيًا بلا تحديث — عبر localhost:3000 مباشرة لا يمر websocket بالبوابة (قيد بيئة الاختبار فقط، الـ preview يمر بالبوابة)
- lint نظيف لكل ملفات الاستقبال (الوحدي في المشروع: use-socket.ts ملف مشترك خارج ملكيتي)؛ صفر أخطاء console؛ dev.log نظيف
- استعادة بيانات العرض بعد الاختبارات بـ bun prisma/seed.ts وتحققت منها: الوصولان/المغادرة $50/خالد مع التمديد المعلق والطلب العاجل قيد التنفيذ/106 و303 كما كانت

Stage Summary:
- الملفات (ملكيتي): src/app/api/reception/{_helpers, dashboard, arrivals, departures, inhouse, stays/[id], check-in, check-out, requests, requests/[id]/status, rooms, rooms/[id]/status, payments, charges, billing/[stayId], extension-requests + [id]/decide, room-change-requests + [id]/decide, search, messages, notifications + read} + src/components/reception/{reception-app, dashboard-view, arrivals-view, departures-view, inhouse-view, requests-view, rooms-view, check-in-wizard, check-out-wizard, stay-detail-dialog, request-detail-dialog, room-dialog, payment-dialog, charge-dialog, search-dialog, notifications-sheet, bits, context, types}
- النتائج: كل المسارات 200/السلبية مقصودة؛ تدفقات الوصول/الخروج/الطلبات/الغرف/الفواتير/التمديد تعمل من الواجهة؛ lint نظيف؛ صفر أخطاء console
- كود الضيف المولّد في الاختبار: H334469T0 (مات مع إعادة التهيئة — الكود الخام لا يُخزن)
- ملاحظة للوكلاء التاليين: خادم dev حساس لـ OOM عند تجميع مسارات كثيرة + كروم — أعد تشغيله بـ (setsid bun run dev &)؛ ولأي اختبار websocket محلي استخدم المنفذ 81 (بوابة Caddy) لأن 3000 مباشر لا يمر بالبوابة

---
Task ID: 5-d
Agent: full-stack-developer
Task: وضع الإدارة

Work Log:
- استلمت عملًا سابقًا مكتمل البنية (17 مسار API + 12 مكون واجهة) بلا أي تحقق؛ قرأت كل شيء ثم تحققت بعمق
- اكتشفت وأصلحت أخطاء حرجة: GET services + service-categories كانا 500 (orderBy على createdAt غير موجود في النموذجين)، DELETE خدمة يستخدم علاقة serviceRequests غير معرفة في المخطط (العدّ الآن عبر serviceRequest.count بـ serviceId)، حذف قسم يتحقق من الطلبات عبر IN على معرفات خدماته، وأضفت RESERVED إلى roomsByStatus في لوحة التحكم
- وحّدت استخراج staffName في كل المسارات بنمط الاستقبال (Extract<AuthContext, role ADMIN>) — أصلح 22 خطأ TypeScript؛ tsc نظيف لملفاتي
- إصلاح تحذيرات aria في admin-app (SheetDescription للجرس وقائمة الأقسام) — صفر تحذيرات console الآن
- تحقق curl شامل: 13 مسار GET بأرقام حقيقية + كل السلبيات (OCCUPIED يدويًا، رقم مكرر، نسب خارج النطاق، تواريخ معكوسة، كود بديل خاطئ) برسائل عربية، وتحذير تداخل المعدلات يعاد مع السماح بالإنشاء
- تحقق browser كامل بدخول A371849L9: لوحة تحكم بأرقام حقيقية (إشغال، مقيمون 3، إيراد $940، مخططات تُعرض)؛ تغيير tagline → toast + ثبت بعد التحديث؛ إضافة «غرفة اقتصادية» $50 مع صورة؛ إضافة غرفة 107؛ تحويل 106 إلى متاحة (أُعيدت لاحقًا لحالة Seed: تحتاج تنظيف)؛ إضافة معدل «موسم رأس السنة» للديلوكس بنطاق مستقبلي؛ إضافة خدمة «توصيل مطعم» $5؛ **توليد كود استقبال لأحمد 3 أيام من الواجهة — الكود الخام R695693CP يظهر كبيرًا monospace بحدود ذهبية + «انسخه الآن» + زر نسخ، تحقق به عبر validate (جلسة RECEPTION)، ثم إبطاله بتأكيد → validate يرفض**؛ فتح HTL-2026-000421 → لقطة السعر كاملة (3 ليالٍ بالسعر الأساسي، $480 فرعي + $72 ضريبة 15% = $552، سياسة الإلغاء وقت الحجز، دفعة عربون $276)؛ التقارير وسجل التدقيق يعرضان كل أفعالي الجديدة؛ الجرس فيه إشعار توليد الكود للاستقبال؛ موبايل 390×844: صفر أفقي overflow في كل الأقسام؛ الوضع الداكن يعمل؛ lint نظيف لملفاتي (الوحدي بالمشروع: use-socket.ts مشترك خارج ملكيتي)
- ملاحظة للوكيل الرئيسي: Hydration error قابل للاسترجاع في src/app/page.tsx (فرع typeof window في BootScreen) يظهر مع الجلسات المحفوظة — خارج ملكيتي
- إدارة بيانات العرض بعد الاختبارات: أُعيدت 106 إلى «تحتاج تنظيف» وأعيدت خدمة «تنظيف الغرفة» (حذفها الاختباري كان حذفًا صلبًا صحيحًا لعدم ارتباطها بطلبات)؛ أُبقي وتُسجَّل: النوع الاقتصادي + غرفة 107، معدل موسم رأس السنة، خدمة توصيل مطعم، tagline الجديد، وكودان REVOKED في سجل الأكواد (تاريخ تشغيلي سليم)

Stage Summary:
- الملفات (ملكيتي): src/app/api/admin/{_shared, dashboard, hotel, room-types + [id], rooms + [id], rates + [id], services + [id], service-categories + [id], staff + [id], codes + revoke, reservations + [id], guests, audit, reports, notifications} + src/components/admin/{admin-app, shared, types, sections/{dashboard, hotel-settings, room-types, rooms, rates, services, staff-codes, reservations, guests, reports, audit-log}}
- النتائج: كل المسارات 200/السلبية مقصودة برسائل عربية؛ تدفقات كاملة تعمل من الواجهة (إعدادات، أنواع، غرف، معدلات، خدمات، طاقم، أكواد بخام الكود مرة واحدة، حجوزات بلقطة السعر، ضيوف، تقارير، تدقيق)؛ lint + tsc نظيفان لملفاتي؛ صفر أخطاء runtime
- حالة العرض: بذرة Seed محفوظة جوهريًا (وصولان اليوم، نورا تُغادر اليوم، خالد بتمديد معلق، 106 تحتاج تنظيف، 303 خارج الخدمة) + إضافات إدارية موثقة أعلاه

---
Task ID: 6-7-8
Agent: Main Agent (Z.ai Code)
Task: إكمال MASTER_PLAN.md + الفحص الشامل E2E + التسليم النهائي

Work Log:
- إصلاح خطأ Hydration في page.tsx (نمط useSyncExternalStore الصحيح) وتصحيح use-socket.ts (تحديث ref داخل effect) — lint الآن صفر أخطاء وصفر تحذيرات
- إكمال MASTER_PLAN.md كاملة (639 سطرًا): PART II الدومين والثوابت I1-I12، PART III آلات الحالة السبع، PART IV قاعدة البيانات المنفذة، PART V الأكواد، PART VI RBAC، PART VII عقود API، PART VIII الأحداث، PART IX شاشات، PART X الهيكل، PART XI الأمان، PART XII المراحل بحالتها (P0-P12 منجزة)، PART XIII DoD
- الفحص الشامل E2E بالمتصفح — الرحلة الذهبية كاملة:
  1) زائر: بحث توفر ← ديلوكس ← بيانات ← مراجعة بسعر شفاف ← الدفع بالفندق ← HTL-2026-000006 مؤكد
  2) استقبال R492671M3: وصول محمد عبدالله الشمري ← معالج 4 خطوات ← غرفة 204 ← كود ضيف H314065J2 ظهر مرة واحدة
  3) ضيف بالكود الجديد: لوحة الغرفة 204 + إشعار ترحيب ← طلب صيانة عاجل REQ-1003
  4) استقبال: استلام ← بدء تنفيذ ← إكمال بملاحظة
  5) خروج: دفعة نقدية $184 ← تأكيد الخروج ← ST-2026-000003 CLOSED + غرفة 204 DIRTY + كود H314065J2 REVOKED
  6) الكود الميت مرفوض: «تم إلغاء هذا الكود. تواصل مع إدارة الفندق»
  7) إدارة A371849L9: لوحة بأرقام حقيقية + موبايل 390px بلا overflow
- إعادة بيانات العرض التجريبية النظيفة (seed) وتصفية الجلسات

Stage Summary:
- المنصة مكتملة ومتحقق منها: موقع + محرك حجز + ضيف + استقبال + إدارة + فوري (socket.io عبر البوابة) + فواتير + أكواد هاش + تدقيق — فوق DB مركزية واحدة
- lint نظيف، dev.log نظيف، صفر أخطاء console، الخدمات الثلاث تعمل (3000 تطبيق، 3002 سوكت، 3004 بث)
- أكواد العرض: H834729X7 / H119922K4 / R492671M3 / A371849L9

---
Task ID: 9
Agent: Main Agent (Z.ai Code)
Task: رفع المشروع بالكامل إلى GitHub (مستودع Cairo-Hart-Hotel-0)

Work Log:
- التحقق من المستودع البعيد بـ git ls-remote: فارغ تمامًا (لا فروع) — رفع مباشر بلا تعارضات
- تنظيف الفهرس قبل الرفع: git rm --cached لـ .env و db/custom.db و db/hotel.db و tool-results/ و download/ (كلها بقيت على القرص المحلي، لم تُرفع)
- تحديث .gitignore: استثناء db/*.db بكل امتداداتها + /tool-results/ + /download/ + السماح بـ !.env.example
- إنشاء .env.example (DATABASE_URL نموذجي بمسار نسبي مع شرح) وإنشاء README.md شامل بالعربية: نظرة عامة على القنوات الأربع، المفاهيم الجوهرية (Reservation مقابل Stay، كود الضيف مقابل مرجع الحجز)، التقنيات، خطوات التشغيل المحلي، أكواد الدخول التجريبية، بنية المشروع، أبرز نقاط الأمان، روابط الوثائق
- فحص أمني للملفات المؤرشفة (ghp_/sk-/api_key/password): لا أسرار حقيقية
- commit جديد (5f4cb98) برسالة وافية تصف كل قنوات المنصة ثم git remote add origin بالتوكن و git push -u origin main
- تحقق بعد الرفع: HEAD البعيد = main = 5f4cb98، 256 ملفًا على البعيد، الشجرة تحوي كل الملفات المفتاحية (README.md، .env.example، MASTER_PLAN.md، prisma/schema.prisma، src/app/page.tsx، mini-services/realtime/index.ts، public/images/*)، working tree محلي نظيف (0 تغييرات = مزامنة كاملة)
- فحص صحة الخادم بعد العملية: HTTP 200 على / و dev.log نظيف — المنصة تعمل بلا أي تأثر

Stage Summary:
- المشروع مرفوع بالكامل بنجاح إلى https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-0 (فرع main، 256 ملفًا)
- التوكن مخزن في .git/config محليًا فقط (غير مؤرشف، لا يظهر في أي ملف مرفوع)
- الكود المصدر + الوثائق (MASTER_PLAN.md + خطتا الأصل) + سجل العمل + الصور مرفوعة؛ ملفات .env و .db غير مرفوعة عمدًا (تُولّد بـ db:push + seed حسب README)
- الحالة: بانتظار أوامر المالك لبدء تنفيذ الخطط اللاحقة (المرحلة التالية بحسب MASTER_PLAN)

---
Task ID: 10
Agent: Main Agent (Z.ai Code)
Task: جلسات قرار هندسية (اتجاه المشروع + بوابة Flutter) ثم إعادة بناء MASTER_PLAN.md كخط سير حي v2.0 بحسب ما اتُّفق

Work Log:
- جلسة قرار 1 (اتجاه المشروع): تحليل صريح — الترتيب الذي بُني به صحيح (دومين أولًا ثم نظام يعمل) لكن التحقق كله بالعين البشرية لا آليًا؛ ما بُني نموذج أولي مكتمل للمنتج وليس منتج إنتاج؛ القرار: لا rewrite ولا قفزة لـ Flutter، تحصين قصير مغلق ثم Flutter فوق عقد مستقر، وتأجيل NestJS/PostgreSQL لمحفز واقعي (strangler عند الحاجة)
- جلسة قرار 2 (بوابة Flutter): تحديد القائمة المغلقة الأربعة (Migrations · اختبارات المال · عقد التوكن · وثيقة العقد المستقر) + المجموعات الثلاث (قبل/موازٍ/بعد) + نقطة الثقة + القوائم المجمدة + تحليل عدم تماثل الخطأ (A مرئي قابل للكبح / B مخفي يظهر كحادثة) → اختيار A بسقف أسبوع
- المالك اعتمد الخيار A وطلب إعادة بناء الماستر بلان «بحسب ما نوقش وبحسب الحالة الحالية» بخط سير كامل إلى ما بعد الإنتاج
- أرشفة v1.0 إلى docs/archive/MASTER_PLAN_v1.md (للتوثيق التاريخي — git يحتفظ بها أيضًا)
- كتابة MASTER_PLAN.md v2.0 (خط السير الحي): أسبقية القرارات وقواعد الانضباط (قائمة مغلقة، سقف أسبوع، حظر «بينما نحن هنا») · جرد الواقع المنفَّذ وحدود الثقة الحالية (تحقق بالعين فقط) · ADR v2 عشرة قرارات (Next.js backend رسمي للـ v1 · SQLite للإنتاج الأحادي · Flutter نقل تصميم مثبت · قائمة التحصين المغلقة · واتساب مسار أعمال · لا فتح للمنطق المثبت · محفزات الاستخراج الموثقة · الخيار A · الاختبار الآلي يحل محل العين · فصل بيانات العرض) · خريطة المسار H→F→W→P→O بثلاث بوابات (الثقة/المتجر/الإطلاق) · كل خطوة محسوبة (قبول/اعتمد/جهد/خطر الإيجاز) · القوائم المجمدة (ما لا يُلمس) · سجل مخاطر 7 · الملحق المرجعي (I1-I12، آلات الحالة، الأكواد، سطح API 57 مسارًا، التسميات، الهوية البصرية) · أكواد العرض التجريبية مع قاعدة مسحها قبل الإنتاج
- الترقيم الجديد H/F/W/P/O مع إعلان صريح أن مراحل v1 القديمة P0-P13 منجزة ومُبتلعة في الجرد — منعًا للالتباس

Stage Summary:
- MASTER_PLAN.md v2.0 جاهز ومرفوع: وثيقة خط سير تنفيذية واحدة من نقطة الوقوف الحالية إلى ما بعد الإنتاج (إيقاعات التشغيل + محفزات التوسع) بأربعة قرارات حاكمة: لا rewrite، قائمة تحصين مغلقة من 4 بسقف أسبوع، Flutter كنقل، الاستخراج بمحفز واقعي فقط
- بوابة بدء التنفيذ التالية بحسب الخطة: المرحلة H (التحصين) H1..H4 ثم بوابة الثقة ثم F — **بانتظار إشارة المالك لبدء تنفيذ H**

---
Task ID: H1
Agent: full-stack-developer
Task: خط أساس Prisma Migrations (البند الأول من المرحلة H في MASTER_PLAN v2.0): migration تأسيسي يمثل المخطط الحالي كما هو بلا أي تغيير تصميمي + تعليم قاعدة التطوير + إثبات المسار النظيف + تحويل migrations إلى المسار الرسمي الوحيد

Work Log:
- قراءة worklog.md بالكامل والقسم 5 (H1) من MASTER_PLAN.md؛ التحقق من الحالة الابتدائية: .env = file:/home/z/my-project/db/custom.db، لا مجلد prisma/migrations، الخادم حي (200)، المخطط فعليًا 22 نموذجًا (الوصف التاريخي «20 نموذجًا» في الوثائق تقريبي — النصاب الحقيقي: 22 جدولًا)
- bunx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script > /tmp/baseline.sql → 374 سطرًا: 22 CREATE TABLE لكل جداول المخطط (Hotel و21 جدولًا بـ @@map) + 14 CREATE INDEX (منها 9 UNIQUE: rooms.number، guests.phone، reservations.bookingReference، stays.reference، stays.reservationId، access_codes.codeHash، sessions.token، service_requests.reference، feedback.stayId) + 5 فهارس مركبة/عادية + كل قيود FOREIGN KEY — صفر تغيير تصميمي
- إنشاء prisma/migrations/20260901000000_baseline/migration.sql بمحتوى المخرجات (تحقق لاحقًا بـ diff: مطابق 100%) + prisma/migration_lock.toml بمحتوى provider = "sqlite" كما في التعليمات
- bunx prisma migrate resolve --applied 20260901000000_baseline → نجح من أول محاولة (لم يحدث قفل SQLite رغم عمل الخادم) — أنشأ جدول _prisma_migrations وسجّل الخط الأساس (finished_at=1، rolled_back=0) دون أي مساس بالبيانات
- bunx prisma migrate status → «1 migration found in prisma/migrations / Database schema is up to date!» — صفر معلّقة
- اختبار أمان قبل المسار النظيف: أثبتّ أن متغير البيئة الصريح يتقدّم على .env في Prisma CLI والعميل معًا (DATABASE_URL=file:/tmp/prec-test.db → الـ CLI طبع «Datasource: prec-test.db at file:/tmp/prec-test.db» والعميل أخفق بـ «table main.Hotel does not exist» في الملف الجديد) — أي أن فحص scratch لا يمكنه أن يلمس custom.db بصمت
- المسار النظيف (محاكاة استنساخ جديد من الصفر) على قاعدة scratch منفصلة: DATABASE_URL="file:/home/z/my-project/db/migrate-check.db" bunx prisma migrate deploy → «SQLite database migrate-check.db created + Applying 20260901000000_baseline + All migrations have been successfully applied»؛ ثم DATABASE_URL="file:...migrate-check.db" bun prisma/seed.ts → اكتمل بلا أي أخطاء (فندق + 14 غرفة + 4 أنواع + أكواد)؛ العدّ: hotel=1, rooms=14, reservations=5, stays=2, guests=5, serviceRequests=2؛ وmigrate status على الـ scratch أيضًا up to date؛ ثم rm -f db/migrate-check.db db/migrate-check.db-journal (تحقق: db/ يحوي custom.db فقط)
- مفاجأة مكتشفة (حالة سابقة لعملي، موثقة بشفافية): قاعدة custom.db كانت فارغة تمامًا من البيانات عند بدئي — ملف القاعدة وُلد 2026-09-02 00:24 مع تهيئة بيئة هذه الجلسة (كل الجداول موجودة بصفر صفوف، ولا _prisma_migrations قبل resolve) وخادم dev (بدأ 00:24) كان يرجع 503 على /api/public/hotel و/api/public/room-types منذ ذلك الحين (كل نافذة dev.log الحالية 503 قبل الاستعادة). أوامري كلها (diff/resolve/status + قراءات count) لا تحذف بيانات — المسح سابق لعملي بالكامل (على الأرجح إعادة تهيئة البيئة شغّلت مسار إنشاء المخطط القديم دون seed)
- الاستعادة بالمسار الرسمي: bun prisma/seed.ts على custom.db (بلا db:push وبلا لمس يدوي — السكربت الرسمي نفسه الذي يستخدمه الوكلاء لاستعادة بيانات العرض) → تحقق بعدها مباشرة: /api/public/hotel = 200 بالبيانات الكاملة، /api/public/room-types = 200 بأربعة أنواع، وكود الضيف H834729X7 يرجع جلسة GUEST لخالد يوسف
- README.md قسم «التشغيل محليًا»: استبدال خطوة bun run db:push بالمسار الرسمي bunx prisma migrate deploy (مع الإشارة للأمر المختصر bun run db:deploy) + ملاحظة صريحة بالنص المطلوب: «db:push مسموح فقط على قواعد scratch تجريبية وممنوع منعًا باتًا على أي قاعدة تحمل بيانات حقيقية — كل تغيير مخطط مستقبلي يجتاز ملف migration جديد» مع إرشاد إنشاء migration عبر migrate dev --name
- package.json: إضافة "db:deploy": "prisma migrate deploy" ضمن scripts مع إبقاء كل السكربتات القائمة كما هي (لم يُحذف db:push — القيد توثيقي في README)
- التحقق النهائي الشامل: curl / → HTTP 200؛ bun run lint → exit 0 نظيف؛ git status --short → فقط: M README.md، M package.json، ?? prisma/migration_lock.toml، ?? prisma/migrations/؛ آخر أسطر dev.log: 200 على room-types و auth/validate بلا أي خطأ runtime
- كتابة سجل الوكيل في agent-ctx/H1-full-stack-developer.md

Stage Summary:
- الملفات المنشأة: prisma/migrations/20260901000000_baseline/migration.sql (374 سطرًا: 22 جدولًا + 14 فهرسًا + القيود) وprisma/migration_lock.toml؛ المعدلة: README.md (قسم التشغيل محليًا) وpackage.json (سكربت db:deploy)
- المنجز: H1.1 (التأسيس) + H1.2 (التعليم) + H1.3 (المسار النظيف مجرَّب فعليًا من الصفر على scratch ثم حُذفت) + H1.4 (تحديث التدفق والسكربتات) — البند مقفل بمعايير قبوله كلها
- لم يُلمس: prisma/schema.prisma، db/custom.db يدويًا، src/، tests/، docs/CONTRACTS.md؛ لم يُشغَّل db:push ولا bun run build إطلاقًا
- من الآن: كل تغيير مخطط مستقبلي يجتاز migration جديدًا (أول مستخدم متوقع H3.1 — توسيع الجلسة إلى توكن bearer عبر migration لا push)
- تنبيه للوكيل الرئيسي: بيانات قاعدة التطوير كانت ممسوحة منذ تهيئة بيئة هذه الجلسة (وليست نتيجة عملي) — استُعادت بالـ seed الرسمي والمنصة سليمة الآن (أكواد العرض: H834729X7 / H119922K4 / R492671M3 / A371849L9). إن مُسحت البيانات مجددًا بعد إعادة تهيئة بيئة مستقبلية فالمسار الصحيح هو migrate deploy ثم seed كما في README الآن — ولإزالة الالتباس مستقبلًا يُستحسن تصحيح وصف «20 نموذجًا» في الوثائق إلى 22
- وكلاء متوازيون نشطون أثناء عملي (tests/unit ظهر 02:17 ثم أُخلي؛ ومحاولة تشغيل dev ثانية فشلت بـ EADDRINUSE وبترت بداية dev.log) — لم يؤثروا على H1 ولم ألمس ملكياتهم

---
Task ID: H2-a
Agent: full-stack-developer
Task: حامل الاختبارات + اختبارات الوحدة لمسارات المال (H2.1 + H2.2 من MASTER_PLAN v2.0) — tests/unit فقط، نقية بلا DB/شبكة

Work Log:
- قراءة worklog.md كاملًا + MASTER_PLAN.md §5 (H2) و§12 (I1-I12 وقواعد المال §12.2 وآلات الحالة §12.3)
- قراءة عميقة قبل الكتابة للتوقيعات الفعلية: src/lib/{pricing,codes,refs,format}.ts + مواضع استدعائها (bookings/availability/extension) + قيم seed الواقعية (tax 15% · weekend 10% · ديلوكس 16000)
- تحقق أن bun (1.3.14) يقرأ paths من tsconfig تلقائيًا — alias @/lib/* يعمل في bun test — لم يلزم bunfig.toml
- إنشاء tests/unit/ بأربعة ملفات *.test.ts (bun:test): pricing (44 اختبارًا) · codes (23) · refs (18) · format (31) = 124 اختبارًا / 25 مجموعة، كل مجموعة معلقة بثابت موثق (I5/I6/I9/§12.2/§12.3/§12.4/§12.6/§12.7/H2.2)
- refs اختُبرت بمحاكاة في الذاكرة تنفذ عقد Prisma نفسه (count startsWith + findUnique) — بلا قاعدة بيانات؛ أرقام إنتاج حقيقية مجمّدة (55200 سنتًا وعربون 27600 = HTL-2026-000421)؛ متجهات sha256 مرجعية مثبتة نصيًا
- العربون 50%: الصيغة Math.round(grandTotalCents/2) مضمّنة في فرع CARD من api/public/bookings (ليست دالة مصدّرة) → جمّدت القاعدة الرقمية فوق مخرجات computeQuote الحقيقية (زوجي/فردي/نصف سنت لأعلى) والفرض من طرف المسار موثق لـ H2-b
- صفر تعديلات تحت src/ أو prisma/ أو README أو package.json أو docs/ — AD-06 مطاعة بلا استثناءات (لا خللًا حقيقيًا في المنطق المالي اكتُشف)
- bun test tests/unit → 124 pass / 0 fail؛ bun test (أمر واحد من الجذر — H2.7 متحقق الآن) → نفس النتيجة؛ bun run lint → صفر أخطاء وتحذيرات؛ خادم dev:3000 حي (200) وdev.log نظيف
- كتابة agent-ctx/H2-a-full-stack-developer.md

Stage Summary:
- H2.1 + H2.2 منجزة: حامل الاختبارات مفعل (bun test أخضر بأمر واحد، 124/124) ومحرك التسعير والأكواد والمراجع والعرض المالي تحت شبكة أمان آلية — الدومين المالي مثبت بالاختبار لا بالعين
- انحراف توثيقي يُعرض على H4-a (لا يعد خلل كود): §12.3 تذكر ServiceRequest بـ SUBMITTED بينما المنفَّذ NEW → ACKNOWLEDGED → ASSIGNED/IN_PROGRESS/WAITING → COMPLETED/CANCELLED/REJECTED (schema + routes + REQUEST_STATUS_LABELS متسقة داخليًا) — تصويب صياغة في docs/CONTRACTS.md يكفي
- المتبقي من H2 للوكيل التالي (H2-b — يحتاج قاعدة اختبار معزولة عبر migrations لا قاعدة التطوير أبدًا): H2.3 التوفر (سعة/معكوسة/أفق/ذرية لا-oversell) · H2.4 رصيد الفاتورة (grand + Σcharges − Σpaid، خروج برصيد موجب/صفر، تمديد/تغيير غرفة) · H2.5 دورة الأكواد (منتهٍ/ملغي، I11 موت كود الضيف عند الخروج) · H2.6 الرحلة الذهبية بتأكيد مالي في كل محطة (وفيها فرض عربون 50% من طرف المسار) · دمجها كلها تحت bun test واحد
- إرشادات مفصلة للوكيل التالي في agent-ctx/H2-a-full-stack-developer.md (نمط محاكاة refs، ملاحظات الحدود الموثقة، انحراف التوثيق)

---
Task ID: H4-a
Agent: full-stack-developer
Task: جرد العقود الكامل — docs/CONTRACTS.md v0.9 (H4.1 من MASTER_PLAN v2.0): توثيق كل مسارات API المنفَّذة كما هي في الكود (العقد المستقر المرجعي لتطبيق Flutter)

Work Log:
- قراءة worklog.md كاملًا وMASTER_PLAN.md (§5 H4 وقاعدة الاستقرار، §12.5) قبل أي كتابة
- قراءة سطرية لكل ملفات المسارات تحت src/app/api (67 ملفًا: 6 public + 2 auth + 14 guest + 22 reception + 22 admin + 1 جذر) + _lib/_shared/_helpers + src/lib/{api,auth,rate-limit,audit,events,pricing,availability,codes}.ts
- عدّ فعلي بالأدوات: 67 ملف مسار = 82 نقطة نهاية (method+path): 6+2+16+23+34+1 — الخطة قالت 57 (انحراف موثق)
- كتابة docs/CONTRACTS.md v0.9 (~1865 سطرًا، 11 قسمًا): مقدمة (مغلف ok/fail بدلالاته، نموذج المصادقة الفعلي، دلالات الحالات، حدود المعدل، أشكال مشتركة، Enums) + بطاقة لكل نقطة نهاية: الدور/الطلب بالتحقق/النجاح حقليًا بمثال واقعي بالسنت/الأخطاء برسائلها العربية الحرفية/الآثار الجانبية (تدقيق+بث socket+إشعارات)/المستهلك (W/F1/F4/F5)/الحالة DRAFT
- قسم placeholder «عقد المصادقة للجوال — يُستكمل بعد H3» (§1.2.1) جاهز لاستكمال وكيل H3
- حزمة F1 (§8): 16 نقطة نهاية أساسية + مكملات + 7 قواعد عقدية (Bearer، موت الجلسة اللحظي عند الخروج/الإبطال، 403 الكيان مقابل الصلاحية، السنت الصحيح، socket اختياري عبر /?XTransformPort=3002)
- قاعدة الاستقرار (§9) منقولة من H4.2 + جدول وسم STABLE فارغ + سجل تغييرات الوثيقة
- ملاحظات انحراف (§10، 11 بندًا) — أهمها: المصادقة اليوم Bearer في Authorization لا كوكي؛ GET /api بقايا سقالة خارج المغلف؛ غرفة socket admin معرفة بلا بث؛ تفاصيل audit تُعاد نصًا خامًا؛ تفاوتات عدّ (departuresToday سقف 5، unreadCount داخل العينة، 201/200 غير متسق)؛ حالة بيانات حية: db/custom.db (H1) بلا سجل Hotel → public يعيد 503 بالرسالة الحرفية (مسار الكود سليم)
- تحقق curl مقيد بالقراءة وحالات خطأ غير مكتوبة (صفر كتابة بيانات): public/hotel 503 حرفية، /api «Hello, world!»، validate بكود غير موجود 400 حرفي، bookings بجسم فارغ 400 حرفي، و401 الحرفي لمسارات محمية
- المراجعة العشوائية الإلزامية: 5 مسارات من 5 قنوات (validate، bookings، guest/bill، reception/rooms/[id]/status، admin/codes) × قراءتين كود↔وثيقة — صفر انحراف؛ النتائج الحية مطابقة حرفيًا
- كتابة سجل العمل في agent-ctx/H4-a-full-stack-developer.md

Stage Summary:
- docs/CONTRACTS.md v0.9 مكتمل ومغطٍ 100% لملفات المسارات (67 ملفًا/82 نقطة نهاية موثقة، العدد موثق صراحة)
- كل رسائل الأخطاء العربية منقولة حرفيًا من الكود (جزء من العقد)؛ حزمة F1 مجمعة وكاملة؛ قاعدة الاستقرار + placeholder عقد الجوال موجودان
- المراجعة العشوائية الخماسية المزدوجة: صفر انحراف (وثيقة↔كود) — الانحرافات المكتشفة كلها «خطة↔كود» وموثقة في §10
- لا يُلمس أي ملف غير docs/CONTRACTS.md؛ الخادم يعمل بلا أي تأثير من عملي

---
Task ID: H3
Agent: full-stack-developer
Task: عقد المصادقة للعميل الثاني — تجديد التوكن (H3 من المرحلة H في MASTER_PLAN v2.0): POST /api/auth/renew يمديد نفس التوكن + لمسة lastSeenAt في getAuth + اختبارات العقد a-g + توثيق §1.2.1 في CONTRACTS.md

Work Log:
- قراءة worklog.md كاملًا (H1/H2-a/H4-a) + MASTER_PLAN.md §5 (H3 وبوابة الثقة)؛ تأكيد اكتشاف H4-a من الكود: Bearer مطبَّق بالفعل (getAuth يفحص الجلسة+الكود+الإقامة مع كل طلب) — **لا تغيير مخطط مطلوب**؛ الفجوة الوحيدة = لا آلية تجديد
- إنشاء src/app/api/auth/renew/route.ts: rate-limit أولًا (10/دقيقة لكل IP بنمط validate → 429 بالرسالة المتسقة) → getAuth للتوكن الحالي (أي فشل → 401 بالرسالة الحرفية لـ requireRole) → العمر الجديد min(الآن+12س، accessCode.expiresAt) → معاملة $transaction واحدة: session.update لنفس التوكن (expiresAt + lastSeenAt) + سطر تدقيق AUTH_RENEW (actor/actorRole من سياق الجلسة) → الرد ok({ expiresAt }) — **لا توكن جديد يُصدر**، التوكن المخزَّن لدى العميل يبقى صالحًا
- لمسة lastSeenAt في src/lib/auth.ts (التعديل الوحيد على كود قائم): داخل getAuth بعد فحوص الصلاحية وقبل تفريع الأدوار — كتابة فقط إذا كان lastSeenAt أقدم من 60 ثانية، مغلَّفة try/catch فارغ (فشلها لا يُفشل الطلب أبدًا) — تقييم المخاطر موثق في agent-ctx/H3-full-stack-developer.md: صفر تغيير لقيم الإرجاع أو حقول الصلاحية
- tests/auth/flows.test.ts (ملف واحد): البنية المشتركة حرفيًا (أول سطر DATABASE_URL لقاعدة test-auth.db المعزولة → setupTestDb('auth') عبر migrate deploy + seed الرسمي → استيراد ديناميكي فقط) + استدعاء مباشر بلا شبكة؛ ترويسة x-forwarded-for مستقلة لكل نداء إصدار/تجديد (3 validate + 5 renew — تحت السقوف)
- السيناريوهات a-g كلها خضراء من أول تشغيل: (a) دخول H834729X7 → 200 + توكن GUEST مسطح · (b) GET /api/guest/dashboard بالتوكن → 200 + عزل إقامة خالد · (c) renew → 200 + expiresAt لاحقة + لا حقل token في الرد + نفس التوكن يظل يعمل + السجل نفسه امتُد في القاعدة · (d) renew بعد revoked=true يدويًا → 401 · (e) renew بعد expiresAt في الماضي → 401 · (f) نداء محمي بعد accessCode.status=REVOKED → 401 (I4، بعد إثبات 200 قبله) · (g) renew بلا ترويسة/بتوكن ملفق → 401
- docs/CONTRACTS.md: استبدال القسم placeholder §1.2.1 فقط بالعقد النهائي — قرار H3 الموثَّق (توحيد على Bearer بدل كوكي H3.2: الواقع أفضل، الويب والجوال نفس العقد بلا كسر سلوك ويب) + جدول العقد + عقد renew الكامل بالرسائل الحرفية + سياسة العميل المحمول (renew عند الإطلاق/العودة للمقدمة؛ 401 → شاشة الكود) + ملاحظة جرد داخلية: قناة auth أصبحت 3 مسارات (بطاقة §3 لصاحب الوثيقة) — لم يُلمس أي جزء آخر من الوثيقة
- التحقق الحي (معيار القبول الحرفي): validate بـ R492671M3 → توكن → GET /api/reception/dashboard بالتوكن → 200 → renew → 200 ({"ok":true,"expiresAt":"2026-09-02T14:46:26.006Z"}) → dashboard مجددًا → 200 (نفس التوكن بعد التمديد)؛ بلا توكن → 401 بالرسالة الحرفية؛ سطر AUTH_RENEW مؤكد في قاعدة التطوير بقراءة فقط (actor «أحمد الاستقبال»/RECEPTION)
- bun test tests/auth/ → 7 pass / 0 fail (41 expect) · bun test tests/unit/ → 124 pass / 0 fail (لا انحدار) · bun run lint → exit 0 · خادم dev:3000 حي طوال العمل وdev.log نظيف (renew مجمّع 200)
- كتابة سجل الوكيل في agent-ctx/H3-full-stack-developer.md

Stage Summary:
- الملفات المنشأة: src/app/api/auth/renew/route.ts وtests/auth/flows.test.ts؛ المعدلة: src/lib/auth.ts (لمسة lastSeenAt المشروطة فقط) وdocs/CONTRACTS.md (القسم 1.2.1 فقط)
- المنجز: H3 كاملة بلا أي تغيير مخطط — H3.1 كانت منجزة بنيويًا (نموذج Session جاهز من الأساس)، H3.2 تحققت بقرار موثَّق (توحيد Bearer بدل إضافة كوكي — أفضل من الخطة)، H3.3 (حماية 10/د + إبطال التوكن مع الكود/الخروج قائم أصلًا + تدقيق AUTH_RENEW)، H3.4 (اختبارات a-g + سيناريو عميل محمول حي)
- **بوابة الثقة 5.5 البند 3 مقفل**: توكن بعمر وتجديد صالح للجوال والويب نفسه بلا كسر — تنتظر البوابة إغلاق H2-b فقط
- لم يُلمس: prisma/schema.prisma (لا migration ولا db:push)، أي كود عميل ويب (store/api-client/مكونات)، tests/integration (H2-b)، قاعدة التطوير إلا بنداءات معيار القبول
- لـ F0: عقد الجوال جاهز في CONTRACTS.md §1.2.1 (سياسة renew عند الإطلاق/العودة للمقدمة + 401 → شاشة الكود)؛ lastSeenAt صار جاهزًا لأي لوحة «جلسات نشطة» مستقبلية بلا عمل إضافي
- تنبيه لصاحب CONTRACTS.md: قناة auth الآن 3 مسارات (renew بلا بطاقة في §3) — موثق داخل §1.2.1

---
Task ID: H2-b
Agent: full-stack-developer
Task: اختبارات التكامل H2.3 + H2.4 + H2.5 + H2.6 من MASTER_PLAN v2.0 §5 (H2) — فوق قاعدة اختبار معزولة (migrate deploy + seed بالمسار الرسمي) تستدعي معالجات المسارات مباشرة وتثبت الثوابت التجارية من طرف إلى طرف

Work Log:
- قراءة worklog.md كاملًا (H2-a «للوكيل التالي» + H1 + H4-a + H3 الذي اكتمل أثناء عملي) + MASTER_PLAN §5 (H2) و§12 (I1-I12 وقواعد المال §12.2) + prisma/seed.ts سطرًا سطرًا (حسبت كل القيم المالية المتوقعة من المصدر) + كود كل مسار مستدعى (availability/bookings/validate/arrivals/check-in/check-out/charges/payments/requests+status/bill/billing/dashboard) + docs/CONTRACTS.md للمطابقة
- تحقق بنيتين قبل الكتابة (مسبار محذوف بعده): (1) استيراد معالجات المسارات ديناميكيًا يعمل في bun test وأن NextRequest يُبنى بـ nextUrl.searchParams (لازم لمسارات arrivals/requests) والنمط `{ params: Promise.resolve({ id }) }` لمسارات الباراميتر الديناميكي في Next 16 · (2) **الذرية تحت التزامن حقيقية**: طلبا حجز متزامنان (Promise.all) على آخر مخزون → واحد 201 وواحد 409 — المعاملة التفاعلية تعيد فحص التوفر وتمنع الـ oversell
- إنشاء tests/integration/flows.test.ts (ملف واحد متسلسل، 1161 سطرًا): أول سطر حرفي يضبط DATABASE_URL على db/test-integration.db ثم setupTestDb('integration') ثم استيراد ديناميكي فقط لـ 14 معالجًا + @/lib/db — نداء مباشر بلا شبكة، IP فريد (x-forwarded-for متزايد) لكل نداء لتفادي حدود المعدل في الذاكرة (validate 5/دقيقة، bookings 10/ساعة)، وتواريخ نسبية لـ«اليوم» تُحسب داخل الاختبار، والرحلة الذهبية في نافذة أحد→ثلاثاء بلا زيادة نهاية أسبوع
- H2.3 (8 اختبارات · I1/I7/I8/I6/I9): التوفر بمدى صالح → الأنواع الأربعة الفعالة بسعات seed الحرفية (مفردة 2 · مزدوجة 4 · ديلوكس 4 بعد حجز أحمد المتداخل · عائلي 2 مع استبعاد 303 خارج الخدمة) + الأسعار deep-equal مع إعادة حساب مستقلة من قواعد §12.2 (شاملة زيادة الجمعة/السبت 10% إن أصابت المدى) · تواريخ معكوسة → 400 بالرسالة الحرفية · حجز PAY_AT_HOTEL → 201 + مرجع HTL-YYYY-NNNNNN + totals بالسنت + snapshot مجمد (I9) · Idempotency: نفس المفتاح يعيد نفس الحجز replayed=true والقاعدة فيها حجز واحد فقط · الماضي/الأفق (365)/الحد الأقصى (30 ليلة) → رسائل الكود الحرفية · **I1/I7**: حجز كل مخزون المفردة (غرفتان) بطلبين متزامنين → 201+409 ثم النوع يختفي من التوفر ثم محاولة متسلسلة → 409 وaggregate=2 (لا oversell)
- H2.4 (5 اختبارات · §12.2): فاتورة خالد (H834729X7) مطابقة لـ seed بالسنت: 55200 + 6500 − 30000 = **31700** (roomNights 3 · roomSubtotal 48000 · roomTax 7200) · رسم 1200 عبر الاستقبال → الرصيد 32900 فورًا في فاتورة الضيف · دفعة 10000 → paidCents 40000 وPARTIALLY_PAID والرصيد 22900 · مسار الاستقبال billing/[stayId] بنفس الأرقام حرفيًا · **خروج برصيد موجب** (نورا): رفض 400 برسالة الرصيد + balanceCents=5000 في الجسم ثم نجاح مع confirmOutstanding (وإغلاق كامل: CLOSED/DIRTY/REVOKED)
- H2.5 (5 اختبارات · I4/I11/§12.4): arrivals اليوم يحوي HTL-2026-000421 بأرقامه (55200/عربون 27600/ديلوكس/بلا إقامة) · check-in بغرفة 202 → 200 + **كود ضيف خام H\d{6}[A-Z0-9]{2} مرة واحدة** + هاش SHA-256 والقناع مطابقان في القاعدة والغرفة OCCUPIED · validate بالكود الجديد → GUEST يعمل على لوحة الضيف (204→202) · الخروج: رفض مع رصيد $276.00 حرفيًا → دفعة تسوية 27600 → خروج برصيد صفر · **I11**: الكود القديم «تم إلغاء هذا الكود. تواصل مع إدارة الفندق» حرفيًا + التوكن القديم 401 «جلسة غير صالحة...» + من القاعدة: CLOSED + actualCheckOutAt + DIRTY + REVOKED + كل الجلسات revoked + الحجز COMPLETED
- H2.6 (8 اختبارات a→h · الرحلة الذهبية كاملة برحلة جديدة): a) توفر المزدوجة بquote مطابق (27600 محسوبًا) · b) حجز باسم/هاتف جديدين → 201 + مرجع + totals بالسنت (24000+3600=27600) · c) arrivals بتاريخ الحجز يحويه → check-in بغرفة 104 → كود خام · d) لوحة الضيف: غرفة 104 + رصيد افتتاحي 27600 · e) طلب خدمة → 201 → الاستقبال يراه (NEW) → ACKNOWLEDGED → IN_PROGRESS → COMPLETED (الخط الزمني NEW+3 في القاعدة + completedAt + حماية الطرفية «لا يمكن تعديل طلب منتهٍ») · f) رسم 2500 + دفعة 30100 → **27600 + 2500 − 30100 = 0** في فاتورة الضيف · g) خروج → 200 → تحقق نهائي شامل من القاعدة: CLOSED + DIRTY + REVOKED + جلسات مبطلة + reservation COMPLETED/paidCents 30100/PAID + معادلة الرصيد صفري من القاعدة مباشرة · h) **I10**: auditLog يوثق RESERVATION_CREATED/CHECK_IN/CODE_GENERATED/REQUEST_CREATED/REQUEST_UPDATED/CHARGE_ADDED/PAYMENT_RECORDED/CHECK_OUT كلها مربوطة بكيانات الرحلة (الفاعل «أحمد الاستقبال»/RECEPTION والمبلغ 30100 في تفاصيل الدفع)
- النتائج: `bun test tests/integration/` → **26 pass / 0 fail / 243 expect** (شغّل مرتين متتاليتين للتأكد من إعادة التهيئة النظيفة) · `bun test tests/unit/` → 124/0 (لا انحدار على H2-a) · `bun run lint` → exit 0 · خادم dev:3000 حي (200) وdev.log نظيف ولم يُلمس · تنظيف db/test-integration.db* بعد آخر تشغيل ناجح
- **صفر تعديلات تحت src/** (AD-09/AD-06: لم أكتشف خللًا حقيقيًا واحدًا في منطق المال/الدومين من طرف إلى طرف — كل الأرقام طابقت المحسوب من seed/المسارات من أول تشغيل، والفشلان الوحيدان كانا خطأين في اختباري نفسه صُححا فورًا: مفتاح أسماء عربي/لاتيني في مصفوفة BASE، وحقل guestName المسطح بدل guest.fullName المتداخل في arrivals)
- تصويبان لق نص المهمة (لا خلل كود — الكود والعقد متسقان): `/api/public/availability` **POST بجسم JSON** لا GET بباراميترات (كما في CONTRACTS PUB-03) · وصيغة مرجع الحجز **6 أرقام** HTL-YYYY-NNNNNN (refs.ts + seed + CONTRACTS) لا 7 كما ورد في نص المهمة
- كتابة سجل الوكيل في agent-ctx/H2-b-full-stack-developer.md (فيه أيضًا إرشادات تقنية مفصلة للنمط: NextRequest للـ nextUrl · params كوعد · IP فريد لكل نداء)

Stage Summary:
- H2.3 + H2.4 + H2.5 + H2.6 منجزة بالكامل: 26 اختبار تكامل حقيقي فوق قاعدة معزولة عبر migrations الرسمية، معالجات المسارات مستدعاة مباشرة، وكل قيمة مالية بالسنت محققة ضد المحسوب من seed/المسارات — الثوابت I1/I4/I7/I8/I10/I11 و§12.2/§12.4/§12.6 مغطاة ومعلقة فوق اختباراتها
- **بوابة الثقة 5.5 البند 2 مقفل**: أمر اختبار أخضر يغطي التسعير والعربون (عبر seed لأحمد: 27600 = 50%) والرصيد والإلغاء (نصوص حرفية) والأكواد — الدومين المثبت بالاختبار لا بالعين؛ تنتظر البوابة اعتماد الوكيل الرئيسي (H2.7/الحالة الهيكلية أدناه)
- **تنبيه هيكلي لـ H2.7 (قرار للوكيل الرئيسي — ليس خلل كود)**: `bun test` العاري يشغّل كل الملفات في عملية واحدة و`src/lib/db.ts` يخزّن PrismaClient في globalThis — أول ملف DB يُحمَّل أبجديًا (tests/auth/ لـ H3) يثبّت العميل على قاعدة auth ويتجاهل DATABASE_URL اللاحق لملف integration → «أمر واحد أخضر» يتطلب تشغيل كل مجموعة في عملية مستقلة (مثل سكربت ي chained: bun test tests/unit/ && bun test tests/auth/ && bun test tests/integration/) — والملف المساعد المجمد يمنع حلًا داخلية؛ لم أشغّل bun test عاريًا قط التزامًا بالقيود
- لم يُلمس: src/ (صفر) · prisma/ · tests/helpers/test-db.ts (مجمدة) · tests/auth/ (H3) · tests/unit/ (H2-a) · docs/ · db/custom.db — H3 أنهى عمله أثناء جلستي واختباراتي ركضت خضراء بعد تغييره في src/lib/auth.ts (لا انحدار متبادل)

---
Task ID: 11
Agent: Main Agent (Z.ai Code)
Task: تنفيذ المرحلة H كاملة (التحصين) بتوزيع متوازٍ على وكلاء فرعيين + إغلاق بوابة الثقة + رفع كل شيء إلى GitHub

Work Log:
- بناء خطة التوازي: موجة 1 (H1 migrations + H2-a وحدات + H4-a جرد العقارات — بلا تبعيات بينها) ثم موجة 2 (H3 تجديد التوكن + H2-b تكامل) ثم موجة 3 (تكامل وتحقق وإغلاق) — ملكيات ملفات صارمة لكل وكيل منعًا للتعارض
- قبل الموجة 2: تجربة أثبتت أن bun test يشغّل الملفات في عملية واحدة (نفس PID) → بنية tests/helpers/test-db.ts (setupTestDb باسم مستقل لكل مجموعة + حارس مرة واحدة/عملية + قواعد الاستيراد الديناميكي بعد ضبط DATABASE_URL) + التحقق بنمط «الاستدعاء المباشر لمعالجات المسارات» فوق قاعدة معزولة (smoke أخضر ثم حذفه) — بنية مشتركة مجمدة استهلكها وكولا الموجة 2 بأمان (قاعدتان منفصلتان test-auth.db/test-integration.db منعًا لسباق الملفات بينهما)
- الموجة 1 (3 وكلاء بالتوازي): H1 (baseline migration بـ22 نموذجًا + resolve + مسار نظيف deploy+seed+عدّ ثم حذف الـ scratch + README/سكربت db:deploy — واستعاد قاعدة بيئة الجلسة الفارغة عبر seed الرسمي) · H2-a (124 اختبار وحدة: تسعير/أكواد/مراجع/تنسيق — صفر تعديلات src) · H4-a (docs/CONTRACTS.md: 67 ملفًا/82 نقطة نهاية موثقة من الكود + حزمة F1 + اكتشاف أن المصادقة Bearer أصلًا لا كوكي)
- الموجة 2 (وكيلان بالتوازي): H3 (POST /api/auth/renew: نفس التوكن يُمدّد min(12س، صلاحية الكود) + rate-limit 10/د + تدقيق AUTH_RENEW + لمسة lastSeenAt كل 60ث في getAuth + 7 اختبارات سيناريو + عقد الجوال §1.2.1 — بلا أي تغيير مخطط) · H2-b (26 اختبار تكامل/243 تأكيدًا: I1/I7 بطلبين متزامنين و409، I8 idempotency، §12.2 أرصدة بالسنت، I4/I11 موت الكود والجلسات، الرحلة الذهبية a→h كاملة، I10 تدقيق — صفر تعديلات src)
- موجة 3 (التكامل): حل القضية الهيكلية التي نبّه إليها H2-b: سكربت رسمي `"test": "bun test tests/unit/ && bun test tests/auth/ && bun test tests/integration/"` بسلاسل عمليات معزولة → **الأمر الواحد أخضر: 157 اختبارًا (124+7+26)** · bun run lint نظيف (exit 0) · تحقق حي: renew بالتوكن 200 + بلا توكن 401
- تحقق المتصفح (agent-browser): الموقع يعرض RTL سليمًا (عنوان + ودجت بحث + أنواع الغرف) · دخول الضيف H834729X7 → لوحة خالد (غرفة 201 + إشعارات) · دخول الاستقبال R492671M3 → لوحة بأرقام حية (وصول 2/مغادرة 1/مقيمون 2/طلب عاجل) · دخول الإدارة A371849L9 → كل الأقسام · صفر أخطاء console وصفحة · موبايل 390px: NO-OVERFLOW · سلوك الويب لم يتغير إطلاقًا بعد H3
- إغلاق H4.2: CONTRACTS.md → v1.0 (مجموعة F1 §8 + عقد مصادقة الجوال §1.2.1 + مكملات F1 معلَنة STABLE بقرار موثق في جدول §9.2؛ reception/admin تبقى DRAFT حتى F4/F5)
- تحديث MASTER_PLAN → v2.1: المرحلة H مكتملة ومقفلة 2026-09-02 (كل بنودها ب evidence) · بوابة الثقة §5.5 مقفلة بالأدلة الأربعة · تصويبات الجرد (22 نموذجًا · 67/82 · ServiceRequest تبدأ NEW · H3: بلا migration والواقع أفضل من الخطة) · خريطة المسار تعلم ✅ على H وبوابة الثقة · سجل تغييرات v2.1 · README: قسم الاختبارات الرسمي (`bun run test` + سبب عزل العمليات + AD-09)

Stage Summary:
- **المرحلة H مقفلة بالكامل وبوابة الثقة مقفلة**: migrations رسمية (H1) · 157 اختبارًا آليًا بأمر واحد (H2) · عقد جوال موحّد Bearer + renew (H3) · CONTRACTS.md v1.0 ومجموعة F1 STABLE (H4)
- التنفيذ المتوازي احترم القائمة المغلقة حرفيًا (صفر «بينما نحن هنا»: لم يُلمس الدومين ولا الـ SPA ولا أي منطق مثبت — تعديلات src الكلية = ملف renew جديد + لمسة additive واحدة في auth.ts)
- الموجة التالية بحسب الخطة: **المرحلة F (Flutter)** — بوابة الثقة مفتوحة رسميًا؛ ملاحظة تشغيلية: Flutter SDK غير مثبت في بيئة التطوير هذه (فُحص) — F0 يحتاج قرار تثبيت SDK أو سقالة هيكلية يبنيها المالك محليًا؛ W0 (قرار مزود واتساب) جاهز للبدء بالتوازي بقرار عمل من المالك

---
Task ID: 13-b
Agent: full-stack-developer
Task: F1-b — نقل حوارات تطبيق ضيف الويب إلى Flutter: شاشة المحادثة (chat-dialog.tsx) + شاشة الإشعارات (notifications-sheet.tsx) + حوارات الأفعال الأربعة كصفائح سفلية (extension/room-change/checkout/feedback) — السلوك حرفيًا من ملفات الويب المناظرة فوق GuestStore الجاهز

Work Log:
- قراءة worklog.md كاملًا + CONTRACTS.md (§1.6 الأشكال، §4 بطاقات G-07/08/10/11/12/13/14/15/16، §8 حزمة F1) + قراءة حرفية للمراجع الستة: chat-dialog.tsx · notifications-sheet.tsx · extension-dialog.tsx · room-change-dialog.tsx · checkout-dialog.tsx · feedback-dialog.tsx + guest-context.tsx (لمنطق الفتح/التحديث/الاستطلاع 12 ثانية والمسح بزر فقط)
- قراءة البنية الجاهزة قبل أي كتابة: lib/state/guest_store.dart (كل التوقيعات) · lib/models/guest.dart (ChatMessage/NotificationItem/Quote/RoomOption/RoomChangeRequestInfo/…) · lib/ui/widgets.dart (AppCard/LoadingView/EmptyState/showAppToast…) · lib/ui/theme.dart (AppColors) · lib/core/format.dart وcore/api_client.dart (ApiError) وguest_shell.dart (نقاط الاستهلاك الثابتة)
- 8 ملفات داخل ملكي فقط: chat_screen.dart (شاشة كاملة: فقاعات RTL ضيف=primary يمين/استقبال=رمادي يسار + فواصل أيام اليوم/أمس/تاريخ + اسم مرسل للاستقبال فقط + formatTimeAr + إرسال Enter/معطل عند الفراغ/maxLength 1000 + تمرير تلقائي عند الفتح وللجديد إن كان المستخدم بالأسفل + Realtime عبر استماع Store + استطلاع 12ث صامت الأخطاء كالويب) · notifications_screen.dart (بطاقات بتمييز ذهبي لغير المقروء + نقطة + timeAgoAr + formatDateTimeAr + زر «تعليم الكل كمقروء/كل الإشعارات مقروءة» بbusy — بلا مسح تلقائي عند الفتح مطابقًا للويب) · actions.dart (التواقيع الأربع الثابتة + مفتوح موحد showModalBottomSheet isScrollControlled+useSafeArea+viewInsets) · sheet_frame.dart (رأس ذهبي/وصف/محتوى متمرر/تذييل مثبّت) + 4 صفائح كاملة (تمديد: منتقي عربي min وابتدائي = الخروج+1 كالويب + ليالٍ + ملاحظة 300؛ تغيير غرفة: تحميل عند الفتح + هياكل + بلاطات برقم LTR وطابق وشريحة فرق +/−/بدون فرق بألوان الويب + سبب 300 + زر يتبع الاختيار؛ خروج: بطاقة رصيد حية تحذيرية/خضراء + مبلغ LTR + تأكيد؛ تقييم: نجوم 1-5 بمعاينة تحويم + تسميات + 5 وسوم حرفية بألوانها + تعليق 500 + زر ذهبي)
- كل النصوص العربية منقولة حرفيًا من الويب (جرد كامل في agent-ctx/13-b)؛ النجاح: toast بعنوان الويب ووصفه بسطرين؛ الأخطاء: رسالة ApiError الحرفية toast أحمر بmounted-guards؛ أزرار busy بتعطيل + مؤشر 18×18
- مراجعة يدوية ثلاثية (لا Flutter SDK بالبيئة — لا ترجمة محلية): موازنة أقواس برمجية (ALL OK لكل الملفات) · مطابقة كل توقيع/حقل مستهلك مع الكود الفعلي · تدقيق lint (const حيث يمكن، صفر print، صفر import غير مستخدم، use_build_context_synchronously محروس، بلا withOpacity، أيقونات Material متحقق من وجودها ومن مطابقة إيقاع guest_shell)
- كتابة سجل الوكيل agent-ctx/13-b-full-stack-developer.md (القرارات + جرد النصوص + 7 انحرافات موثقة، أهمها: أخطاء الإرسال تظهر برسالة الخادم الحرفية بدل العنوان العام للويب التزامًا بقاعدة المهمة، وinitialDate للمنتقي = سلوك الويب (الخروج+1) لا «الغد»، وفشل G-11 صامت يعرض «لا غرف متاحة» كما في الويب)

Stage Summary:
- الملفات المنشأة/المستبدلة (8، كلها بملكية 13-b): mobile/lib/screens/chat/chat_screen.dart · notifications/notifications_screen.dart · actions/{actions,sheet_frame,extension_sheet,room_change_sheet,checkout_sheet,feedback_sheet}.dart — التواقيع الثابتة محفوظة (ChatScreen/NotificationsScreen StatelessWidget بالباني نفسه، والدوال الأربع بالتواقيع نفسها في actions.dart مع تصديرها منه)
- نقطة guest_shell المفعلة أصبحت حية: جرس الإشعارات والمحادثة العائمة يشغّلان الشاشتين الكاملتين؛ الأفعال الأربعة جاهزة للاستهلاك من home/stay (تقرأ store.dashboard مباشرة وتعمل بأمان قبل اكتمال bootstrap)
- صفر تعديلات خارج الملكية (pubspec/core/state/services/ui/app/main/شاشات الوكيل الآخر) وصفر اختبارات (ملك الوكيل الرئيسي) — خادم الويب حي طوال العمل (dev.log: 200) ولم يُلمس
- بانتظار وكيل F1-a لربط الأزرار في home/stay (show*Sheet جاهزة) ثم flutter analyze محليًا عند توفر SDK

---
Task ID: 13-a1
Agent: full-stack-developer
Task: F1-a1 — شاشات تطبيق ضيف الجوال الأساسية: استبدال home_screen.dart (من guest-home.tsx) وservices_screen.dart (من guest-services.tsx) وإنشاء new_request_sheet.dart (من request-dialog.tsx بتوقيع showNewRequestSheet {ServiceItem? presetService}) وrequest_detail_screen.dart (من request-detail-dialog.tsx شاشة كاملة بAppBar) — السلوك والنصوص حرفيًا من الويب فوق GuestStore الجاهز

Work Log:
- قراءة worklog.md (الأقسام H و11 و13-b) + agent-ctx/13-b + المراجع الويب حرفيًا: guest-home.tsx · guest-services.tsx · request-dialog.tsx · request-detail-dialog.tsx · bits.tsx · guest-context.tsx (goRequests/guestName/ابتلاع الأخطاء) + كل البنية الجاهزة (guest_store/guest.dart/widgets/format/api_client/theme/session/sheet_frame/panels/tab_route/guest_shell) وقنوات الاستهلاك القائمة (requests_list_view وrequests_screen وstay_screen الذي يستخدمهما)
- اكتشاف سياقي: الملفات الأربعة كانت موجودة بنسخة تشغيل وكيل 13-a1 سابق قُطع قبل أي تسجيل (لا قسم له في worklog) — نسخته كانت تحمل انحرافين عن الويب (منتقي قسم في صفيحة الإنشاء + توقيع مختلف showNewRequestSheet بـ RequestSheetPreset/onCreated)؛ أعدت بناءها وفق نص مهمتي بالتوقيع المطلوب وحرفية الويب مع الإبقاء على المطابق
- home_screen.dart (818 سطرًا): بطاقة ترحيب كحلية متدرجة بزخارف دوائر (رقم الغرفة الكبير صار LTR — كان مفقودًا، الويب dir=ltr) + ليالٍ متبقية/آخر اليوم + شارة حالة ذهبية + لافتتا requestedCheckout الذهبية والرصيد التحذيرية بشرطيهما + الإجراءات السريعة الستة (طلب خدمة→pushTabScreen الخدمات بالكتالوج، محادثة→ChatScreen، الأفعال الأربعة→show*Sheet من 13-b، طلب الخروج معطل عند CHECKOUT_REQUESTED) + ملخص الإقامة 2×2 (ضيوف/مدة/مرجع LTR/رصيد أحمر-أخضر LTR بعملة اللوحة) + آخر الإشعارات (أول 3 بنقطة ذهبية للمقروء-عكس) + بطاقة الطلبات النشطة → RequestsScreen (وجه goRequests)؛ رحلة bootstrapLoading→ErrorRetryView بنصّي EmptyState الويب (إعادة المحاولة = bootstrap) → محتوى + RefreshIndicator(refreshDashboard)
- services_screen.dart (350): مبدّل الكتالوج/طلباتي بعدّاد primary + زر «طلب خاص (خارج الكتالوج)» → showNewRequestSheet بلا خدمة (OTHER فارغ كالويب) + skeleton 3 أقسام → فراغ → أقسام بعناوين بذهبية وأيقونات sparkles/wrench/concierge-bell (كأسماء lucide في قاعدة البيانات) وبطاقات خدمات (سعر LTR أو «مجانًا ضمن الإقامة» + زر طلب) + عرض طلباتي عبر requests_list_view بزر «تصفح الخدمات» للعودة للكتالوج؛ بعد إغلاق صفيحة الإنشاء: التحويل لعرض الطلبات فقط إذا نما عدد الطلبات (مكافئ onCreated→setServicesView('requests'))؛ Pull-to-refresh = services+requests
- new_request_sheet.dart (270): showModalBottomSheet(isScrollControlled+useSafeArea+viewInsets) بإطار SheetFrame؛ عنوان الصفيحة = تسمية القسم المشتق (presetService.categoryKey أو OTHER، احتياط «طلب خدمة») — لا منتقي قسم (الويب لا يملك واحدًا والقسم دومًا من preset — إزالة انحراف النسخة السابقة)؛ الحقول: عنوان 80 (autofocus، تحقق محلي ≥3 برسالة الويب) + وصف 3 أسطر 500 اختياري + أولوية عادي/عاجل بألوان primary/destructive وأيقونة Zap؛ زرا إلغاء/إرسال بbusy؛ النجاح toast بسطرين (عاجل/عادي)، فشل ApiError → رسالة الخادم الحرفية؛ createRequest يحدّث الطلبات واللوحة داخل المخزن
- request_detail_screen.dart (427): شاشة كاملة AppBar بعنوان الطلب؛ بطاقة الطلب (مرجع LTR · الغرفة · القسم + شارة الحالة + «عاجل» عند URGENT فقط + «أُنشئ {منذ}» + الوصف بصندوق + المسند إليه بأيقونة) + فاصل + «سجل الطلب» بخط زمني (آخر تحديث بعلامة تم خضراء، البقية نقاط على خط متصل يمين RTL كborder-r-2) بعناصر (تسمية الحالة + التاريخ-الوقت + الملاحظة + «بواسطة {الاسم} (أنت)») + شريط إلغاء مثبّت destructive للحالتين NEW/ACKNOWLEDGED فقط ينفذ مباشرة بلا confirm (سلوك الويب الحرفي — الزر onClick={cancel}) بbusy «جارٍ الإلغاء…»؛ ListenableBuilder ينعش الطلب حيًّا من المخزن بالمعرّف (Realtime) مع fallback للقطة
- مراجعة يدوية ثلاثية (لا Flutter SDK بالبيئة — تحققت): توازن أقواس برمجي بعد إزالة السلاسل والتعليقات (ALL OK ×4) + مطابقة كل توقيع/حقل مستهلك مع الكود الفعلي + تدقيق lint (صفر print/withOpacity/import غير مستخدم، const الممكنة شاملة const-gradient، hex 8 خانات، mounted-guards بعد كل await، child آخر وسيط، بانونيات const)؛ grep يؤكد صفر مراجع متبقية لـ RequestSheetPreset في mobile كله
- كتابة سجل الوكيل agent-ctx/13-a1-full-stack-developer.md (القرارات + جرد النصوص + 8 انحرافات موثقة + التبعيات)

Stage Summary:
- الملفات المستبدلة (4، كلها بملكية 13-a1): home_screen.dart · services_screen.dart · requests/new_request_sheet.dart · requests/request_detail_screen.dart — التواقيع الثابتة محفوظة (HomeScreen/ServicesScreen بالبانيين نفسهما، showNewRequestSheet بالتوقيع الجديد {ServiceItem? presetService}، RequestDetailScreen({store, request}) كما يستهلكه requests_list_view)
- أهم قرارين سلوكيين: (1) لا منتقي قسم في صفيحة الإنشاء — القسم يُشتق من الخدمة/OTHER حرفيًا كالويب (نص المهمة «القسم HOUSEKEEPING/… بنصوص عربية للويب» يُحقَّق بعنوان الصفيحة بتسميات الويب الأربع)؛ (2) الإلغاء بلا حوار تأكيد — نص المهمة قال «مع confirm كما في الويب» لكن الويب ينفذه فورًا (المرجع السلوكي الوحيد → تُبِع الويب كسابقة 13-b/initialDate — قرار قابل للقلب بإضافة حوار واحد إن طلب المالك)
- التحويل لعرض «طلباتي» بعد إنشاء طلب محقق بمقارنة طول القائمة قبل/بعد الصفيحة (بديل onCreated المحذوف من التوقيع)؛ تحديث الطلبات/اللوحة يجري داخل store.createRequest تلقائيًا
- صفر تعديلات خارج الملكية (لم تُلمس chat/notifications/actions/stay/bill/core/state/ui/models/pubspec/guest_shell/requests_screen/requests_list_view/room_image) وصفر اختبارات؛ خادم الويب حي طوال العمل (dev.log: 200) ولم يتأثر
- تبعيات معلنة للوكيل الرئيسي: home→requests_screen وservices→requests_list_view (ملفات قائمة يستهلكها stay أيضًا — حذفها يكسر الترجمة)؛ guest_shell ما يزال يستورد actions دون استدعاء (ملك صاحبه، تنبيه 13-b قائم)
- بانتظار flutter analyze عند توفر SDK (لا ترجمة محلية ممكنة في هذه البيئة) — المراجعة اليدوية الثلاثية خضراء

---
Task ID: 13-a2
Agent: full-stack-developer
Task: F1-a2 — نقل تبويبَي «إقامتي» و«الفاتورة» من تطبيق ضيف الويب إلى Flutter: استبدال mobile/lib/screens/stay/stay_screen.dart (من guest-stay.tsx) وmobile/lib/screens/bill/bill_screen.dart (من guest-bill.tsx) — السلوك والنصوص والقيم حرفيًا فوق GuestStore الجاهز

Work Log:
- قراءة worklog من السطر 160 (أقسام H و13-b) + المراجع الويب حرفيًا (guest-stay.tsx/guest-bill.tsx/bits.tsx) + guest-context (goRequests = تبويب الخدمات بمنظر الطلبات · refreshStay يبتلع الأخطاء) + guest-app (بنية التبويبات) + كل الواجهات الجاهزة (store/models/widgets/format/api_client/config/theme) + نقاط الاستهلاك (guest_shell وhome_screen للوكيل الموازي — التوقيعان الثابتان محفوظان)
- استبدال stay_screen.dart بالكامل (1146 سطرًا): الرحلة loading→error(ErrorRetryView بrefreshStay)→محتوى داخل RefreshIndicator+ListView بpadding (16,16,16,96) · بطاقة غرفتك (صورة roomType.images.first بديلها الثابت عبر Image.network فوق AppConfig.baseUrl بارتفاع 176px + تدرج أسود + رقم الغرفة أبيض LTR + شارة الطابق white/20 + حبوب السرير/المساحة + مزايا الغرفة بشارات pill) · خط زمني 3 عقد (منجز بعلامة صح/حالي بعقدة primary بظل وشارة «الآن»/قادم) بخط وصل مستمر على جهة البداية بصيغ التاريخ الحرفية · بيانات الحجز (4 حبات: مرجع LTR/ضيوف/ليالٍ/إجمالي بالسنت + طلبات الخاصة عند النص فقط) · جدول الليالي من snapshot بشرط الويب (رأس + صفوف + تذييل المجموع قبل الضريبة و+ ضريبة N%) · معلومات الفندق (الاسم—المدينة/العنوان/هاتف primary LTR/أوقات الدخول والخروج بأيقونة مائلة 45°) + سياسات الفندق ExpansionTile بالبنود الخمسة مع حذف الفارغ · طلباتي آخر 3 (زر «كل الطلبات» عند الوجود → push RequestsScreen · هيكلان عند التحميل · DashedNote الفارغ الحرفي · بطاقات مختصرة بعاجل وشارة حالة تنقل لشاشة الطلبات)
- استبدال bill_screen.dart بالكامل (661 سطرًا): نفس الرحلة بrefreshBill · رأس الفاتورة (صبغة primary/5 + «فاتورة إقامتك» + المرجع والغرفة LTR كdir=auto + دائرة إيصال) · جدول البنود بأوزان 5/4/3 (صف إقامة الغرفة مميز bg-accent/40 بنصه الحرفي وضريبته وتاريخ checkIn من لوحة الضيف بfallback اليوم + صفوف extraCharges بتصنيف label) بمحاذاة المبلغ كما في الويب (رأس RTL-end يسارًا وقيم dir=ltr يمين الخلية) · المدفوعات (DashedNote الفارغ أو بطاقات محفظة خضراء بتسمية method وتاريخ/مسجِّل ومبلغ +$ LTR) · الإجماليات (بطاقة danger/30+danger/5 عند رصيد موجب وإلا success + المتبقي 24/800 بلون الإشارة + النصان الحرفيان — صفر حسابات محلية: كل قيمة من GuestBill) · زر الخروع الذهبي h-48 معطل عند CHECKOUT_REQUESTED بنصه الحرفي يستدعي showCheckoutSheet من actions.dart (تحققت من المرجع: لا أزرار تمديد/تغيير غرفة في guest-stay ولا زر خروج إلا في bill — كما نُقل)
- مراجعة يدوية ثلاثية (لا Flutter SDK بالبيئة): توازن أقواس برمجي بعد تجريد النصوص/التعليقات (ALL OK لكل الملفين وأعيد بعد كل تعديل) · مطابقة كل توقيع/حقل مستهلك مع الكود الفعلي (store/models/widgets/format/actions/panels/requests_screen) · تدقيق lint (صفر print، صفر import غير مستخدم بتحقق برمجي، const على كل القابل للثبات بلا const متداخلة، use_build_context_synchronously محروس، sort_child_properties_last، لا withOpacity، hex 8 أرقام) — وقرار تحوطي: دائرة المحفظة SizedBox+DecoratedBox+Center (const مؤكدة عبر كل الإصدارات) بدل const Container المشكوك في ثبات مُنشئه
- كتابة سجل الوكيل agent-ctx/13-a2-full-stack-developer.md (جرد النصوص الحرفية + 10 انحرافات ويب↔تطبيق موثقة)

Stage Summary:
- الملفان المستبدلان (ملكية 13-a2 فقط): mobile/lib/screens/stay/stay_screen.dart وmobile/lib/screens/bill/bill_screen.dart — التواقيع الثابتة محفوظة (StayScreen/BillScreen StatelessWidget بالباني نفسه) وكل مستهلكيها (guest_shell + home_screen للوكيل الموازي) يعملون بلا تغيير
- أبرز الانحرافات الموثقة: goRequests → push RequestsScreen (الـ Shell يملك فهرس التبويب — نفس تكيف الوكيل الموازي) · حالة الخطأ بErrorRetryView المشترك بنصي العنوان/التلميح الحرفيين بدل EmptyState البصري للويب · RefreshIndicator مضاف وفق تعليمات المهمة (أخطاؤه توست ApiError الحرفي بmounted-guards) · SectionTitle المشترك بلا أيقونات (قيد الويدجت) · هاتف الفندق يُعرض بأسلوبه دون فتح المتصل (لا url_launcher) · UrgentMark → StatusChip.priority (عرف التطبيق) · font-mono → Cairo مع LTR للمراجع/المبالغ
- صفر تعديلات خارج الملكية · صفر اختبارات (ملك الوكيل الرئيسي) · خادم الويب حي طوال العمل (dev.log: 200) ولم يُلمس
- بانتظار flutter analyze عند توفر SDK (المراجعة اليدوية الثلاثية هي الضمان الحالي — نمط 13-b نفسه)

---
Task ID: 12
Agent: Main Agent (Z.ai Code)
Task: F0 — تأسيس مشروع Flutter في mobile/ (البند 6.1 من MASTER_PLAN): سقالة كاملة + عميل API بعقد §1.2.1 + النماذج + الجلسة + المخزن + Realtime + الدخول + هيكل الضيف

Work Log:
- التحقق من أن Phase H مقفلة وبوابة الثقة مفتوحة (commit 4ed07d4 + worklog H1/H2-a/H4-a/H3/H2-b/11) ثم قياس الواقع: لا Flutter SDK محليًا (فحص مباشر) → البناء عبر GitHub Actions بقرار المالك («لديك جميع الإمكانيات هناك») — Scaffolding يدوي بلا flutter create
- تنزيل خط Cairo (400/600/700 TTF من Google Fonts) + توليد أصول العلامة: logo.png 512 من public/logo-hotel.svg بcairosvg + أيقونات ic_launcher لكل الكثافات (48→192 بأساس كحلي وزوايا مستديرة عبر PIL)
- كتابة الأساس: pubspec.yaml (http + shared_preferences + socket_io_client 3.x + flutter_localizations) · config.dart (API_BASE_URL عبر --dart-define أو إدخال المستخدم مع تخزين محلي) · core/api_client.dart (مغلف ok/fail + 401→renew→retry مرة واحدة→SessionExpiredError وفق سياسة §1.2.1 حرفيًا) · core/format.dart (نقل حرفي لsrc/lib/format.ts: formatMoney بالسنت + تواريخ عربية + كل خرائط التسميات) · models/guest.dart (نماذج كل نقاط G-01..G-16 بالسنت) · state/session.dart (restore→renew عند الإطلاق + renewOnForeground + logout) · state/guest_store.dart (كل نداءات guest الست عشرة + مؤشرات تحميل + مزامنات Realtime) · services/socket_service.dart (socket_io_client بنفس طوبولوجيا الويب: path=/ + query XTransformPort=3002 + join stay:{id} + الأحداث السبعة) · ui/theme.dart (كحلي #1A3C6E + ذهبي #D4A843 + Cairo + ليلي/نهاري) · ui/widgets.dart (AppCard/StatusChip/LoadingView/ErrorRetryView/EmptyState/showAppToast/InfoRow)
- شاشات الجذر: splash_gate + login_screen (نقل code-login.tsx: تطبيع الكود، أكواد العرض، إعدادات الخادم عند غياب المخبوز) + role_placeholder (أكواد الطاقم → إرشاد F4/F5) + guest_shell (نقل guest-app.tsx: هيدر بالجرس والخروج + 4 تبويبات + FAB محادثة + توصيل Realtime بمعالجات الويب نفسها) + app.dart (MaterialApp RTL عربي + مراقبة دورة الحياة للمقدمة) + شاشات stub قابلة للترجمة لكل ملكيات الوكلاء
- منصة Android يدويًا (متوافق قوالب 3.29): settings.gradle (AGP 8.7.3 + Kotlin 1.9.24) · gradle-wrapper.jar منقولة من gradle v8.12.0 الرسمي + gradlew/gradlew.bat · app/build.gradle (namespace com.cairoheart.aden + minSdk 23 + flavors dev/prod بsuffix حزمة واسم تطبيق عربي + توقيع release من key.properties عند وجوده وإلا debug-sign) · Manifest بINTERNET + res كاملة (styles/launch_background كحلي/أيقونات) — بلا local.properties (تولّده أداة flutter)
- اختبارات الأساس: format_test (المال والتواريخ والتسميات الحرفية) + api_client_test (المغلف + سياسة 401→renew→retry + 429 ليس خروجًا + Bearer) بMockClient + guest_models_test (أشكال CONTRACTS الحرفية: G-01/G-09/G-04/G-11) + login_widget_test — كلها بلا شبكة
- إصلاحات جولة CI الأولى بعد تشخيص سجلات GitHub: flavorDimensions قائمة لا سلسلة · تعارض اسم label مع حقل StatusChip (بادئة fmt للاستيراد) · استيراد services_screen ناقص في guest_shell · AlignmentDirectional بدل Alignment.centerStart · colorScheme.outlineVariant · SnackBar بلا contentTextStyle (بناء النص بالتنسيق مباشرة) · إصلاح أخطاء الاختبارات نفسها (closures لfail() + findsAtLeastNWidgets) — ثم جولة ثانية: 9 إصلاحات const + --no-fatal-infos
- **جولة CI الثانية أثبتت البنية كاملة: Android build smoke نجح** (Gradle + flavors + Kotlin + الرموز + Dart compile كلها خضراء على GitHub) — التحليل فقط كان يفشل بسبب fatal-infos الافتراضية

Stage Summary:
- mobile/ مشروع Flutter كامل الملكية (38 ملف dart + منصة android + أصول العلامة + 4 ملفات اختبار) — الهوية والسلوك منقولان من الويب والعقد لا من فراغ
- قرار توثيق: W (واتساب) يبقى على روابط wa.me الحالية بلا Twilio/Cloud API بقرار المالك — والأدمن يتحكم برقم الوجهة (Task 14)
- كل تعديلات الويب في هذه المرحلة: check-in-wizard فقط (Task 14) — القائمة المجمدة محترمة (صفر «بينما نحن هنا» في الدومين/المنطق المالي)

---
Task ID: 14-15-16
Agent: Main Agent (Z.ai Code)
Task: WhatsApp برقم وجهة يتحكم به الأدمن (بطلب المالك) + CI/Release على GitHub Actions + الدفع والمراقبة والتحقق (Tasks 14/15/16 من خطة F)

Work Log:
- Task 14 (واتساب على حالته + تحكم الأدمن): قلب الموضوع موجود أصلًا — hotel.whatsapp يُدار من إعدادات الفندق (A-03) وكل روابط wa.me (الهيرو/الفوتر/تأكيد الحجز/إدارة الحجز/تطبيق الضيف) تشرب منه؛ الفجوة الوحيدة: معالج تسجيل الوصول كان يرسل كود الضيف لهاتف الحجز بلا تحرير → أضفت حالة waNumber (افتراضي هاتف الضيف بعد الوصول) + حقل إدخال قابل للتحرير بlabel عربي وملاحظة إرشادية في الخطوة 4 + whatsappLink يستخدم الرقم المحرَّر (normalizePhone) — لا مساس بأي منطق مالي ولا مخطط (AD-06/AD-09 لا تنطبقان: تغيير عرض فقط)
- تحقق المتصفح (agent-browser) بعد التغيير: الموقع 200 سليم · دخول استقبال R492671M3 → فتح معالج الوصول لوصيل اليوم → تنقّل حتى خطوة تعيين الغرفة يعمل بكامل أزراره (Fast Refresh أعاد التجميع بلا أخطاء) — لم يُستكمل الوصول حفاظًا على بيانات العرض · دخول ضيف H834729X7 → لوحة خالد كاملة (إشعارات 2 + إجراءات سريعة) · صفر أخطاء console/page · bun run lint exit 0
- Task 15 (CI/Release): توليد مفتاح توقيع PKCS12 محليًا (keytool، صلاحية 30 سنة، alias upload) ورفعه كأسرار GitHub مشفرة بlibsodium (ANDROID_KEYSTORE_BASE64/PASSWORD/ALIAS/KEY_PASSWORD عبر API — المفتاح نفسه خارج المستودع نهائيًا) · ثلاثة workflows: mobile-ci (analyze --no-fatal-infos + test + build smoke لdev flavor برفع artifact) · mobile-release (workflow_dispatch + tags: استعادة المفتاح من الأسرار → بناء prod/dev release APKs → Release بتAG عربي وAPKs كمرفقات، عنوان خادم مدمج اختياري كمدخل) · web-ci (bun install + prisma generate + lint + bun run test عبر symlink لمسار /home/z/my-project الذي يصلبه حامل الاختبارات — بلا أي تعديل على الملف المجمد)
- إصلاح جذري قبل الدفع: سطر `test` في .gitignore الجذر كان سيستبني mobile/test/ بالكامل — ضيّقته إلى /test
- Task 16 (الدفع والمراقبة): دفعة أولى b693bbc (67 ملف mobile + workflows) → Web CI نجح من أول مرة (157 اختبارًا أخضر على GitHub) · جولتا إصلاح للجوال (أخطاء أعلاه) → **بناء Android أخضر في الجولة الثانية** — التحليل بقي يفشل بسبب fatal-infos الافتراضية فأصلحت المواضع وأضفت --no-fatal-infos (الجولة الثالثة 3ed2c46)

Stage Summary:
- البناء والتشغيل والاختبار والصيانة صارت كلها على GitHub Actions بقرار المالك — الخادم المحلي بلا Flutter SDK وأثبتت CI ذلك مسارًا موثوقًا (سجل كامل قابل للتنقيح)
- توقيع الإصدارات مؤمَّن بالأسرار (لا مفتاح في المستودع العام) مع مسار fallback إلى debug-sign إن غابت الأسرار
- الويب لم يتأثر سلبًا: Web CI أخضر من الجولة الأولى والمتصفح يعرض كل شيء سليمًا بعد تغيير الواتساب
- بانتظار الجولة الثالثة (analyze + test) ثم تشغيل mobile-release والتحقق من الـ APK الموقَّع والمرفق بإصدار GitHub

---
Task ID: 17
Agent: Main Agent (Z.ai Code)
Task: إغلاق تنفيذ F0+F1+F2: التحقق النهائي من الإصدار الموقَّع + MASTER_PLAN v2.2 + الدفع الختامي + تقرير المالك

Work Log:
- مراقبة CI عبر GitHub API جولة بجولة: الجولة 1 فشلت (أخطاء تجميع منقولة من الوكلاء: flavorDimensions سلسلة بدل قائمة، تعارض اسم label مع حقل، استيراد ناقص، Alignment.centerStart غير موجود، ThemeData.outlineVariant بدل colorScheme، SnackBar بلا contentTextStyle، أخطاء في اختباراتي) · الجولة 2: **بناء Android أخضر** (المسار الهيكلي كله سليم) والتحليل فشل بسبب fatal-infos الافتراضية · الجولة 3: التحليل أخضر وظهر فشلان في الاختبارات (خطآن في الاختبارات نفسها: مقارنة مسارات url.path بلا الشرطة الأولى، وتوقع سالب لا يطابق سلوك الويب $-5.00) · الجولة 4: خطأ هروب $ في عنوان اختبار · **الجولة 5: Mobile CI خضراء بالكامل (analyze + 33 اختبار Flutter + بناء Android debug)**
- **mobile-release نجح بالكامل**: استعادة المفتاح من الأسرار ("keystore restored" في السجل) → بناء prod/dev release APKs (52.9MB) → GitHub Release منشور (tag v1.0.0+1+2) بملفّي APK وملاحظات عربية
- تحقق نهائي من الـ APK الموقَّع: تنزيل prod APK من الرابط العام → `file` يتعرف عليه كحزمة Android → سلامة ZIP كاملة (383 مدخلًا: dex + native libs + flutter_assets + Manifest)
- web-ci على GitHub: **157 اختبارًا أخضر من الجولة الأولى** (الويب لم يتأثر إطلاقًا بتغييرات F)
- تحقق المتصفح الختامي: GET / = 200 · dev.log نظيف (كل المسارات 200) · دخول ضيف واستقبال سليم (موثق أعلاه في Task 14-15-16)
- MASTER_PLAN → **v2.2**: جدولا الجرد يوثقان Flutter (F0/F1/F2 منفَّذة) وقرار W0 (بلا مزود واتساب — wa.me + الأدمن يتحكم برقم الوجهة) · أقسام F0/F1/F2/F6 معلَّمة بالمنفَّذ والقبول · قسم W بسجل قرار المالك الحرفي · سجل تغييرات 2.2

Stage Summary:
- **المرحلة F المطلوبة من المالك مكتملة في نطاقها المعتمد**: تطبيق ضيف Flutter أصلي كامل البنية والشاشات + Realtime + بناء وإصدار موقَّع عبر GitHub Actions (بقرار المالك: «لديك جميع الإمكانيات هناك»)
- **المرفقات الحية:** https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-0/releases — CairoHeartGuest-v1.0.0+1-prod.apk و-dev.apk (موقَّعان، قابلان للتثبيت)
- واتساب كما قرر المالك: بلا ربط — والأدمن يتحكم برقم الوجهة من إعدادات الفندق (روابط الموقع) ومن حقل قابل للتحرير في معالج الوصول (كود الضيف)
- المتبقي من خريطة F (لم يُطلب ولم يُنفَّذ — بلا «بينما نحن هنا»): F3 Push · F4/F5 استقبال/إدارة في التطبيق · F6-minAppVersion · F7 Dogfooding · F8 المتاجر

---
Task ID: 18
Agent: Main Agent (Z.ai Code)
Task: F6-minAppVersion — إغلاال البند المفتوح الأخير من F6 (فرض حد أدنى لإصدار تطبيق الضيف بدفع من الخادم) بأمر المالك: خطوة واحدة فقط، بلا توسيع نطاق، بلا فتح جبهات جديدة (F4 تالية)

Work Log:
- [قرار الترتيب] تحليل الاعتماديات من MASTER_PLAN v2.2: F4/F5 تنتظر (F5 يعتمد أنماط F4 · F3 يحتاج بيانات اعتماد Firebase خارجية) · minAppVersion هو البند الوحيد المفتوح داخل مرحلة بدأت + آلية الحماية R4 + شرط بوابة المتجر → الخطوة الصحيحة الوحيدة الآن
- [Prisma] Hotel.minAppVersion String @default("") في schema + migration `20260902000000_add_min_app_version` (ALTER TABLE) — طُبِّق بالإجراء الرسمي نفسه من H1: `migrate resolve --applied baseline` (البيئة أُعيدت تهيئتها فاختفي تسجيله — نفس حالة H1 الموثقة حرفيًا) ثم `migrate deploy` ثم `prisma generate` — migrate status: up to date
- [اكتشاف موثَّق] قاعدة dev أعادت التهيئة wiping: custom.db بصفر صفوف و503 على كل الـ APIs العامة (نفس ما وثّقه H1: إعادة تهيئة الحاضنة تشغّل مسار إنشاء المخطط دون seed) → استعادة بالـ seed الرسمي `bun prisma/seed.ts` (فندق + 14 غرفة + أكواد العرض R492671M3/A371849L9/H834729X7/H119922K4) + إعادة تشغيل dev (العميل القديم لم يكن يعرف العمود) — التشغيل الباقي عبر `(setsid bun run dev &)` (نمط double-fork ينجو من حاصد الجلسات)
- [Server] نقطة عامة جديدة `GET /api/public/app-config` (PUB-07): بلا مصادقة · fail-open بالتصميم (أي خلل → قيمة فارغة = لا فرض) · نداء واحد لكل إطلاق تطبيق
- [Server] A-03 PATCH يقبل `minAppVersion` (نص اختياري: فارغ لإلغاء الفرض أو `^\d+\.\d+\.\d+$` مع trim) برسالة 400 حرفية `صيغة إصدار التطبيق يجب أن تكون ثلاثية رقمية (مثال: 1.2.0)` — يدخل تلقائيًا في SETTINGS_UPDATED وchangedFields (لا مساس بأي منطق مالي)
- [Web UI] بطاقة «تطبيق الضيف (Flutter)» في إعدادات الفندق: حقل «أقل إصدار مسموح للتطبيق» + إرشاد (فارغ = لا فرض · لا يؤثر على الويب) + HotelAdmin.minAppVersion في types
- [اختبار كشف خطأً حقيقيًا] الإصدار الأول من المسار كان يرفض التفريغ (regex بلا حالة الفراغ) رغم أنه حالة «إلغاء الفرض» الموثقة → أُصلح + 8 اختبارات جديدة في tests/integration/app-version.test.ts (قاعدة معزولة appversion): PUB-07 بلا مصادقة · تعيين/trim/إفراغ/نفس القيمة · 3 صيغ فاسدة برسالة حرفية · حارس الدور (ضيف → 401/403) · التدقيق details.changed.minAppVersion
- [التحقق المحلي] `bun test tests/` = **165 اختبارًا أخضر** (157 + 8) صفر انحدار · `bun run lint` exit 0 · E2E بالمتصفح (agent-browser): دخول أدمن → الحقل ظاهر → تعيين 1.0.0 → حفظ (toast + تدقيق) → curl PUB-07 = "1.0.0" → إفراغ (بمفاتيح حقيقية بعد كشف انفصال fill الفارغ عن حالة React) → PUB-07 = "" · صفر أخطاء console/dev.log (كل المسارات 200)
- [Mobile] `core/app_version.dart`: kAppVersion من `--dart-define=APP_VERSION` (CI يستخرجه من pubspec · الافتراضي 0.0.0 = اتجاه آمن fail-closed) + compareSemver رقمي (10>9) متسامح مع التشوه + needsUpdate + fetchMinAppVersion (PUB-07 · null عند أي فشل = fail-open) · `screens/update_required_screen.dart`: حجب كامل (شعار + العنوان + إصدارك/الحد المطلوب + رابط Releases قابل للنسخ عبر Clipboard بلا حزم جديدة + إعادة المحاولة) · الحارس في `app.dart`: فحص عند الإطلاق (بلا خادم → تجاوز؛ فشل → متسامح؛ حد أعلى → حجب) + إعادة فحص عبر SplashGate
- [Mobile tests] app_version_test (المقارنة الدلالية 10 حالات · قرار التحديث · جلب PUB-07 بMockClient: النجاح/المسار الصحيح بلا توكن/500/ok=false/جسم غير JSON/خطأ شبكة) + update_required_test (العرض الكامل · onRetry يعمل · لا مسار خروج — 2 أزرار فقط)
- [CI] حقن APP_VERSION في mobile-ci (test + build smoke) وmobile-release (prod + dev) — خطوة استخراج من pubspec واحدة لكل workflow · README الجوال: قسم «إصدار التطبيق وحد التحديث (F6)»
- [Docs] CONTRACTS **v1.1**: بطاقة PUB-07 كاملة + صف A-03 + حالة 400 + تحديث العدّ (68 ملفًا / 83 نقطة) + سجل تغيير موثَّق (امتداد §9.1.2 لا كسر — الجواب على سؤال §9.1.4 مسجَّل) · MASTER_PLAN **v2.3**: F6 «مكتملة نهائيًا» + بوابة المتجر «تعمل ✓» + سجل 2.3

Stage Summary:
- **F6 مكتملة نهائيًا** (كل بنودها): CI/Release/التوقيع (سابقًا) + minAppVersion (هذه الخطوة) — بوابة المتجر فقدت آخر بند معلَّق داخلها
- آلية R4 فعّالة: كسر عقد مستقبلي → الأدمن يرفع الحد → التطبيقات المثبتة القديمة تُحجب عند الإطلاق وتوجَّه لصفحة الإصدارات
- الويب لم يتأثر: 165 أخضر + E2E متصفح نظيف · التغييرات إضافية بالكامل (لا حقل حُذف ولا رسالة تغيّرت ولا دلالة اهتزّت)
- بانتظار دفع GitHub ومراقبة web-ci + mobile-ci حتى الخضار (لا إصدار APK جديد الآن — القرار للمالك: الإصدار التالي سيحمل الحارس تلقائيًا لأن CI يدمج APP_VERSION)
- المتبقي من F كما هو: F3 (Push — يحتاج Firebase) · F4 (الخطوة الكبيرة التالية) · F5 · F7 · F8

---
Task ID: 18 (استكمال التحقق النهائي)
Agent: Main Agent (Z.ai Code)
Task: مراقبة CI على GitHub حتى الخضار الكامل + إصلاحات الجولات + إقفال Task 18 رسميًا

Work Log:
- الجولة 1 (addce53): **Web CI نجح من أول مرة** (كل تغييرات الويب خضراء على GitHub) · Mobile CI فشل **قبل إنشاء أي وظيفة**: قيمة `run:` كسلسلة YAML مجردة احتوت `: ` داخل `sed 's/version: *//'` فكسرت الملف — الأصل في الملف كان يستخدم `run: |` البلوكي لهذا السبب (درس: أي أمر shell يحوي نقطتين+مسافة يلزمه بلوك سكالار) → أُصلح في 05eee4c
- الجولة 2 (f3708fd): Android build smoke نجح لكن اختبارين فشلا + ثالث: أ) `InfoRow(label:)` والصحيح `labelText:` (خطأ تجميع التقطته CI فورًا — دليل قيمة CI كفاحص وحيد بلا Flutter محلي) ب) زر «إعادة المحاولة» أسفل ScrollView خارج نافذة 800×600 → hit-test miss → `ensureVisible` ج) `OutlinedButton.icon` يُنشئ نوعًا فرعيًا خاصًا فـ `byType(OutlinedButton)` يجد صفرًا → العدّ بالنصوص د) اختبار «الافتراض 0.0.0» اعتمد على kAppVersion المدمجة بينما CI صار يمرر APP_VERSION=1.0.0 (تحسيني نفسه قلب الافتراض!) → استقلال صريح عن القيمة المدمجة
- الجولة 3 (c0de123): **Mobile CI خضراء بالكامل — 46 اختبار Flutter (33 سابقة + 13 جديدة) + Android build smoke ✓** وWeb CI خضراء (addce53)
- تحقق ختامي للخادم المحلي: GET / = 200 · PUB-07 = {"ok":true,"minAppVersion":""} · /api/public/hotel = 200 ببيانات الفندق · dev.log نظيف

Stage Summary:
- **Task 18 مقفل: F6 مكتملة نهائيًا بكل بنودها** — CI الثلاث كلها خضراء على GitHub (web-ci + mobile-ci analyze/test/build) والمتحقق المحلي (165 اختبارًا + lint + E2E متصفح) سليم
- درس CI موثَّح للوراثة: أوامر shell داخل workflows ذات محارف `: ` تستلزم `run: |`؛ و`byType` لا يطابق الأنواع الفرعية الخاصة لمصانع `.icon`
- لا إصدار APK جديد أُطلق في هذه الخطوة (القرار للمالك — الإصدار التالي سيحمل الحارس تلقائيًا لأن CI يدمج APP_VERSION من pubspec)

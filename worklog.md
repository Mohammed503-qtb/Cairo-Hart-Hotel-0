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

---
Task ID: 19
Agent: Main Agent (Z.ai Code) + وكيلان متوازيان (19-a/19-b — تقاريرهما في agent-ctx/)
Task: F4-a — وضع الاستقبال في تطبيق Flutter: الأساس + مسار القبول كاملًا (وصول 4 خطوات + خروج 3 خطوات) بأمر المالك: التقدم المنطقي داخل F4 بقرار هندسي ذاتي، بلا فتح مراحل أخرى، بلا UI وهمي

Work Log:
- [قرار الترتيب] تحليل الاعتماديات من MASTER_PLAN v2.3: F4 (جهد L) مساره الحرفي «استقبال يجري وصولًا وخروجًا كاملين من جهاز لوحي» · جهة الخادم مكتملة بالكامل (R-01..R-23 متعاقدة ومنفَّذة ومستهلكة من الويب) → صفر عمل خادم، النقل من مراجع الويب الحية · التقسيم الداخلي بقراري: F4-a (الأساس + مسار القبول) ثم F4-b (المقيمون/تفصيل الإقامة/الطلبات/الغرف/البحث)
- [الأساس — Main] models/reception.dart (نماذج R-01..R-07/R-10/R-22 + R-05 المتداخل بالفاتورة والطلبات والتمديد وتغيير الغرفة والرسائل + InHouseStay لنموذج F4-b) + state/reception_store.dart (كل HTTP في المخزن فقط — نمط F1: تحميل/عمليات/realtime hooks/reset + markVisibleNotificationsRead بسلوك الورقة في الويب) + RealtimeService.joinReceptionRoom() + إضافة reservation:new وroom:status للأحداث المسموعة + app.dart يوجه RECEPTION→ReceptionShell (ADMIN يبقى placeholder لـ F5) + SessionController.role getter + StatusChip.reservationStatus/roomStatus/extensionStatus في widgets.dart + reception_bits.dart (RefCodeText/MoneyText/InfoBox/KpiCard/DateFieldRow/buildWhatsappCheckInUrl حرفيًا من الويب)
- [الوكيلان المتوازيان] 19-a: dashboard + arrivals + معالج الوصول 4 خطوات · 19-b: departures + معالج الخروج 3 خطوات + إشعارات الاستقبال — تقاريرهما الموثقة في agent-ctx/19-b (19-a انتهت مهلته قبل كتابة تقريره فراجعتُ ملفاته بنفسي)
- [مراجعة تكامل — Main] اكتشفت وأصلحت خطأين قاتلين قبل CI: أعماق استيراد خاطئة في check_in_wizard (../../ من wizards/ تحل إلى screens/ — نفس الفخ الذي وثّقه 19-b وتجنّبه) + AppColors مستخدمة بلا استيراد ui/theme.dart (23 استخدامًا)
- [قرار موثَّق] إضافة url_launcher (حزمة flutter.dev الأولى كshared_preferences) لزر «إرسال واتساب» في الخطوة الرابعة — يخدم قرار W0 المقفل (wa.me هو القناة) — قرار «بلا حزم» كان لإدارة الحالة ChangeNotifier لا منعًا مطلقًا (http/socket_io_client موجودتان أصلًا)
- [CI جولة 1 (3429cba)] Web CI أخضر فورًا (لا تغيير ويب) · Mobile فشل في Analyze: ColorScheme.card غير موجود (مرتان — KpiCard وبطاقة الإشعار) + context غير معرف في _pumpOpener → الإصلاح: surface + Builder (03c9b64)
- [CI جولة 2 (03c9b64)] Analyze نجح + Android build smoke أخضر ✓ · Test: 76/78 — فشلان: أ) RenderFlex overflow 7px في صف «الإجمالي/المدفوع» بخطوط الاختبار (Ahem بعرض ثابت/محرف) → Wrap بدل Row (يلتف كالويب) ب) overflow 2.5px في تحذير «احتفظ بالكود» → Flexible ج) اختبار اللوحة بحث عن «خالد يوسف» بنص مدمج داخل سطر واحد → textContaining (54c303e) — الاستثناءات الثانوية (widget inspector) كانت تبعات إبلاغ الفيض لا مشاكل مستقلة
- [CI جولة 3 (54c303e)] ✅ **Mobile CI خضراء بالكامل: analyze + 78 اختبارًا (46 سابقة + 32 جديدة) + Android build smoke (dev flavor)** · Web CI خضراء (3429cba)
- [الاختبارات الجديدة 32] نماذج الاستقبال (11: تحليل/سنت/قيم آمنة/إشعار غير مقروء/InHouseStay متداخل) + المخزن (9: جسم R-06 الحرفي مع trim وidNumber شرطي/confirmOutstanding كما هو/جسم R-12/تعليم المعروض غير المقروء stateful/حرس التكرار/reset/صمت realtime) + معالج الوصول (2: المسار الكامل بجسم POST المُتحقق + الغرفة المشغولة ونوع آخر غير قابلين للاختيار + الكود الخام مرة واحدة + حجز غير موجود بالرسالة الحرفية) + معالج الخروج (2: دفعة→مسدد→تأكيد بجسدي R-12/R-07 + مسار الرصيد بconfirmOutstanding=true عبر حوار التوكيد) + لوحة/وصولون/مغادرون/إشعارات (11) — تصريف مؤقتات SnackBar في نهاية الاختبارات المُتوِّستة (درس مؤقّت Timer معلّق = فشل اختبار في flutter_test)
- [تحقق المتصفح] الويب: / سليم بلا أخطاء console + دخول R492671M3 → لوحة استقبال الويب كاملة (تحقق انحدار القناة التي يستهلكها التطبيق) · الخادم المحلي: GET / = 200
- [Docs] MASTER_PLAN §6.5 → «قيد التنفيذ: F4-a منفَّذة (Task 19) + المتبقي F4-b» + سطر الحالة في جدول §أول + README الجوال: قسم «وضع الاستقبال (F4)» — لا تغيير CONTRACTS (صفر نقاط جديدة: المستهلك F4 كان مسجلًا مسبقًا في بطاقات R)

Stage Summary:
- **F4-a مكتملة ومقبولة بمعيارها الذاتي:** استقبال يستطيع الآن إجراء وصول كامل (تحقق→غرفة من نفس النوع→تأكيد→كود ضيف مرة واحدة + wa.me قابل للتعديل) وخروج كامل (مراجعة→تسوية/تأكيد→تنفيذ) من تطبيق الجوال — مسار القبول الحرفي لـ F4
- CI الثلاث خضراء على GitHub: web (165) + mobile (78) + Android build smoke — لا انحدار: الويب لم يُمس، وتطبيق الضيف يتصرف كالسابق (app.dart تغيير توجيه فقط عند role=RECEPTION)
- 15 ملف dart جديدة (7 lib + 8 test) + 5 معدَّلة — التغييرات كلها في mobile/ + توثيق
- المتبقي داخل F4 كما خططت: F4-b (Task 20): المقيمون + تفصيل الإقامة (R-05 الكامل: فاتورة/بنود/رسائل R-20/21/قرارات التمديد R-15/16 وتغيير الغرفة R-17/18) + الطلبات R-08/09 + لوحة الغرف R-10/11 + البحث R-19 — ثم إقفال F4 وتحديث v2.4
- لا إصدار APK جديد (قرار المالك كالمعتاد — الإصدار التالي سيحمل وضع الاستقبال تلقائيًا)

---
Task ID: 20
Agent: Main Agent (Z.ai Code) + وكيلان متوازيان (20-a/20-b — تقاريرهما في agent-ctx/)
Task: F4-b — تكملة وضع الاستقبال في تطبيق Flutter: المقيمون + تفصيل الإقامة الكامل (فاتورة/بنود/رسائل/قرارات التمديد وتغيير الغرفة) + الطلبات + لوحة الغرف + البحث، بأمر المالك: سحب المستودع ثم المتابعة المتوازية الدقيقة بلا خروج عن النطاق

Work Log:
- [سحب وتحقق] git fetch: المحلي = البعيد (393c0c0 = F4-a مقبولة) · الفروقات المحلية كانت أوضاع ملفات فقط (644→755 بلا أي تغيير محتوى) — صُفّرت · اكتشاف وإصلاح بيئي موثق: قاعدة dev مُسحت مجددًا (نفس ظاهرة الحاضنة في Task 18: صفر صفوف + 503) → seed الرسمي + إعادة تشغيل dev → كل المسارات 200 · ملاحظة تحقق مهمة: أمر الاختبار الرسمي هو `bun run test` (المجموعات الثلاث بالتسلسل بعزل قواعدها) = **165/165 أخضر** — تشغيل `bun test tests/` بعملية واحدة يخلط ملفات الاختبار ويتداخل على نفس القاعدة المعزولة (ظاهرة أمر غير رسمي لا انحدار كود — CI على نفس الـ commit خضراء)
- [الأساس — Main] models/reception.dart: نماذج R-19 (SearchReservationItem/SearchStayItem/SearchResults) · state/reception_store.dart: توسعة كاملة — R-04 refreshInHouse + R-08 refreshRequests + R-09 setRequestStatus (يعيد الطلب المحدَّث + تحديث القوائم الخمس بصمت) + R-11 setRoomStatus + R-13 addCharge + R-15/16 decideExtension + R-17/18 decideRoomChange + R-20/21 loadStayMessages/sendMessage + R-19 search (بتشيير الاستعلام) + recordPayment صار يعيد balanceCents (متوافق رجعيًا مع معالج الخروج) + دمج inhouse/requests في bootstrap/_refreshAfterOperation/onRealtimeBump/reset — تصحيحان ذاتيان قبل أي دفع: قوس مكسور في bootstrap + استخدام _m الخاص بمكتبة النماذج من المخزن (خصوصية مكتبة Dart) — كلاهما اكتُشف بالمراجعة وأُصلح فورًا
- [الوكيلان المتوازيان] 20-b: الطلبات + تفصيل الطلب (خريطة الإجراءات الحرفية + الخط الزمني + الإسناد بفريق) + لوحة الغرف (الانتقالات الخمسة بتأكيدين) + البحث (debounce 350ms) + 13 اختبارًا — تقريره كامل في agent-ctx/20-b · 20-a: المقيمون + تفصيل الإقامة (5 تبويبات) + حوارا الدفعة/البند + اختباراته — **استجابته فُقدت بمهلة نقل بعد كتابة ملفاته** → أعاد الوكيل الرئيسي كتابة تقريره agent-ctx/20-a بعد مراجعة تكاملية مستقلة لكل ملف (العقود/الاستيرادات/نداءات المتجر/التسميات الحرفية/الأيقونات)
- [مراجعة تكامل — Main] تحقق فعلي لا افتراضي: توازن أقواس برمجي لكل ملف (كلها متوازنة) · العقود المجمدة مطابقة سطرًا بسطر (showStayDetail/showRequestDetail/showReceptionSearch + InHouseScreen/RequestsScreen/RoomsScreen {super.key, required this.store}) · الاستيرادات المتقاطعة كلها تحل ولا دورة (stay_detail→request_detail أحادي الاتجاه) · نداءات المتجر كلها مطابقة للتواقيع · صفر print/withOpacity/HTTP محلي · أيقونات كل ملف جديد فُحصت ضد icons.dart الرسمي للـFlutter المجلوب من المستودع (تدقيق مستقل ثانٍ: 29 أيقونة كلها مؤكدة) · الاختبارات الحالية لن تنكسر (dashboard لا يفحص نصوصًا جديدة تعارضها، departures يتوقع 'تسجيل الخروج' مرتين — الفاتورة الجديدة لا تمسه)
- [التكامل — Main] reception_shell.dart: 6 تبويبات (NavigationRail للعرض ≥700 — كالشريط الجانبي في الويب للديسكتوب/اللوحي · تنقل سفلي للضيق) + زر بحث عام في الهيدر (showReceptionSearch) · dashboard_screen.dart: وصل كل نقاط F4-b المعلقة الموثقة في F4-a — KPI المقيمين/الطلبات قابلتان للنقر (فهارس جديدة 2/3) + تحديث فهارس المغادرين من 2→4 في كل المواضع (KPI + الكل + الإجراءات السريعة) + إجراءات سريعة: لوحة الغرف (5) + بحث عام + صف الطلب يفتح showRequestDetail (InkWell داخل البطاقة) + زر «الفاتورة» في بطاقات المغادرة → showStayDetail(initialTab:'bill') · departures_screen.dart: زر «الفاتورة» (المعلق الموثق من 19-b) بنفس الوصل
- [إصلاح خلل حقيقي قبل الدفع] التنقل السفلي بـ 4 أساسية فقط (تقليد الويب حرفيًا) كان سيدخل currentIndex خارج النطاق عند تفعيل تبويب ثانوي (المغادرون/الغرف من لوحة التحكم) → فشل assertion في debug — الحل الموثق: 6 عناصر ثابتة في السفلي (الفئة الست تضمن الوصول دائمًا؛ اللوحي هدف F4 الأساسي يستخدم الشريط الجانبي)
- [Docs] README الجوال: قسم «وضع الاستقبال (F4)» موسَّع بكل شاشات F4-b · MASTER_PLAN v2.4: F4 ✅ منفَّذة (§6.5 + صف الحالة + سجل 2.4) · لا تغيير CONTRACTS (صفر نقاط خادم جديدة — كل المستهلكات كانت مسجلة في بطاقات R)
- [CI جولة 1 (abbc385)] الويب لم يُشغَّل (فلتر المسارات — لا تغييرات src/prisma/tests) · Mobile فشلت: خطآن لي في التكامل (widget.store داخل _DashboardBody — StatelessWidget له حقل store لا State) + 3 نداءات بالاختبار نسيت غلاف _api (MockClient→ApiClient) → a7aada4
- [CI جولة 2 (a7aada4)] Analyze+البناء أخضر و100/101 اختبارًا — فشل واحد: find.text('طلبات خاصة:') صفر مطابقات → textContaining (نص Text.rich مدمج — نفس درس Task 19) → c2694ae
- [CI جولة 3 (c2694ae)] ما زالت صفر — التشخيص الحقيقي: صندوق «طلبات خاصة» آخر ابن في ListView كسول بتبويب الضيف خارج طية 600px فلا يُبنى أصلًا (الفتّاش لا يرى غير المبني) → سطح اختبار أطول 800×1600 (الودجت نفسه سليم — المستخدم الحقيقي يمرّر) → d83625f
- [CI جولة 4 (d83625f)] ✅ **Mobile CI خضراء بالكامل: analyze (36 ملاحظة info قديمة فقط — صفر أخطاء) + 101 اختبار Flutter (78 سابقة + 23 جديدة) + Android build smoke (dev flavor) ✓** · web-ci آثرت التخطي بفلتر المسارات (آخر خضراء لها 3429cba) والتحقق المحلي: lint exit 0 + 165/165
- [تحقق المتصفح] الويب: / سليم بلا أخطاء console (تحذير a11y قديم وحيد) + دخول R492671M3 → لوحة استقبال الويب الكاملة بستة عناصر تنقل + تحقق حي لنفس القناة التي يستهلكها التطبيق: R-04 فيها إقامتان (نورا غرفة 103 رصيد $50 · خالد غرفة 201 رصيد $317 وطلب نشط) + R-05 لخالد (رصيد 31700 سنت + 3 رسائل + طلبان + طلب تمديد واحد) + R-08 طلبان + R-10 أربع عشرة غرفة + R-19 بحث «103» → إقامة واحدة

Stage Summary:
- **F4 مكتملة بكامل نطاقها المخطط (a+b):** استقبال يمسك التشغيل اليومي كاملًا من التطبيق — وصول/خروج (F4-a) + مقيمون/تفصيل إقامة بمال وقرارات ومحادثة/طلبات بكل إدارتها/غرف بكل انتقالاتها/بحث فوري (F4-b)
- 7 شاشات/حوارات جديدة (inhouse/stay_detail/stay_dialogs/requests/request_detail/rooms/search) + 13+ اختبار شاشة + الأساس (نماذج R-19 + 11 نداء متجر) + القشرة/اللوحة/المغادرون موصولة — صفر تغيير خادم وصفر تعديل على ملفات ضيف
- ✅ **CI خضراء بالكامل على GitHub** (d83625f): 101 اختبار Flutter (23 جديدة) + بناء Android smoke + الويب محليًا 165/165 وlint نظيف — لا انحدار: الويب لم يُلمس، وضع الضيف لم يُلمس، تطبيق الاستقبال يحمل كل التشغيل اليومي الآن
- المتبقي من F كما هو: F3 (Push — يحتاج Firebase) · F5 (الإدارة — الأنماط جاهزة من F4) · F7 · F8

---
Task ID: 21-b
Agent: full-stack-developer (21-b)
Task: F5 شاشات الإدارة — الغرف (إنشاء/تعديل/حذف) + أنواع الغرف + المعدلات الموسمية

Work Log:
- قرأت worklog.md (دروس Task 19/20: أعماق الاستيراد من screens/admin/ بـ ../../، ColorScheme.surface لا card، withValues(alpha:)، textContaining، سطح 800×1600 بـ tester.binding.setSurfaceSize + addTearDown(null)، تصريف مؤقتات SnackBar بـ pump(4s)+pumpAndSettle، لا print) ثم المراجع الحية كاملة قبل أي سطر: rooms.tsx (371) + room-types.tsx (432) + rates.tsx (260) + shared.tsx + كل مسارات API الإدارية الستة + _shared.ts (MANUALLY_SETTABLE_ROOM_STATUSES) + الأساس: admin_store/admin.dart/admin_bits/admin_shell/widgets/theme/format + نمط بطاقات reception/rooms_screen ونمط الحوارات stay_dialogs (المال بالسنت round())
- بنيت rooms_screen.dart (AdminRoomsScreen): فلاتر طابق/حالة/نوع حرفية + بحث برقم (مهمة الوكيل) + بطاقة لكل غرفة (الرقم/النوع/الطابق/StatusChip.roomStatus/الضيف الحالي وموعد خروجه إن مشغولة/الملاحظات) + قائمة إجراءات لكل غرفة (تبديل سريع QUICK_STATUSES بجسم {status} فقط + تعديل + حذف بحوار تأكيد حرفي) + حوارا الإنشاء (رقم/طابق 1-30/نوع/ملاحظات → createRoom) والتعديل (OCCUPIED غائبة إطلاقًا عن خيارات الحالة — والقيمة الأصلية تُرسل كما هي كالويب فيقبلها الخادم برفضه الحرفي) — OCCUPIED أيضًا غائبة عن التبديل السريع
- بنيت room_types_screen.dart (RoomTypesScreen): بطاقة نوع كاملة (رأس صورة مع حارس AppConfig.hasBaseUrl لتفادي شبكة في الاختبارات + شارة نشط/معطّل بعتامة 0.6 + الاسم/الإنجليزي/السعر fmt.formatMoney/السعة/السرير/المساحة/مرافق أول 4 + عدّاد/+عدادات الغرف والحجوزات والمعدلات/مفتاح تفعيل PATCH {active}) + نموذج كامل بكل حقول الويب (name/nameEn/description/البالغون 1-8/الأطفال 0-6/bedConfig/sizeSqm/basePrice بالدولار ×100 round → cents/amenities كـ tag input بصناديق قابلة للحذف/اختيار الصور الثمانية الحرفية بمعاينات/sortOrder/active) + حذف بحوار يفرّق المرتبط (تعطيل) عن الحر (نهائي) ويعرض رسالة الخادم
- بنيت rates_screen.dart (RatesScreen): لافتة شرح التسعير الحرفية + تجميع حسب النوع (مع مجموعات يتيمة كالويب) + بطاقة معدل (الاسم/نشط/النطاق من-إلى/السعر MoneyText/مقارنة بفرق الأساس) + حوار الإنشاء (نوع مسبق/اسم/تاريخان قابلان للكتابة مع منتقي + صيغة ISO بثابت Z مطابقة dateInputToISO للويب/سعر بالسنت) — النتيجة (rate, warning): التحذير يظهر توست ذهبي مخصص لكن الحوار يُغلق والإنشاء نجح + حذف بحوار التأكيد الحرفي (النطاق LTR + لقطة السعر)
- الاختبارات: 3 ملفات في mobile/test/screens/admin/ بنمط reception_store_test (MockClient → ApiClient → AdminStore → pump في MaterialApp): rooms_test (6) + rates_test (4) + room_types_test (4) = 14 اختبار widget تغطي: جسم POST الحرفي للغرفة مع trim + جسم {status:'CLEANING'} فقط للتبديل السريع + OCCUPIED غائبة عن خيارات حوار التعديل (تحليل items مباشرة) + جسم التعديل الكامل + حذف بحوار التأكيد وDELETE ورسالة الخادم الحرفية في التوست (نجاح ورفض) + إنشاء معدل 25 دولارًا → priceCents 2500 بتواريخ ISO الحرفية + ظهور تحذير التداخل توست (والإنشاء نجح) + الحذف + الجسم الكامل لنوع (45.5 دولارًا → 4550) + تبديل التفعيل + بطاقات العرض
- تدقيق ذاتي بلا Flutter محلي: توازن الأقواس برمجيًا لكل ملف (stripper واعٍ بالنصوص) + صفر print/withOpacity/HTTP مباشر + كل نداءات store مطابقة للتواقيع + تدقيق كل أيقونة ضد icons.dart الرسمي للـFlutter 3.24 المجلوب من المستودع — اكتشفت وأصلحت في ملفاتي: Icons.door_front_rounded→door_front_door_rounded و clipboard_rounded→content_paste_rounded و calendar_range_rounded→date_range_rounded (الأسماء الثلاثة غير موجودة في مكتبة أيقونات Flutter)

Stage Summary:
- 6 ملفات جديدة: lib/screens/admin/{rooms,room_types,rates}_screen.dart + test/screens/admin/{rooms,rates,room_types}_test.dart — 2929 سطرًا، صفر تعديل على الأساس أو الويب أو الخادم
- عقود مجمّدة محفوظة: AdminRoomsScreen/RoomTypesScreen/RatesScreen كلها {super.key, required this.store} كما تستوردها admin_shell.dart
- ⚠️ خللان تجميعيان في الأساس اكتُشفا بالتدقيق (لا أملك صلاحية تعديلهما — يُذكران في تقريري): 1) admin_shell.dart يستخدم Icons.door_front_rounded (×3) و Icons.clipboard_rounded (×2) — غير موجودين في Flutter (الصحيح door_front_door_rounded و content_paste_rounded) 2) dashboard_screen.dart يستدعي loadingBlocks(5) دون استيراد — admin_bits.dart يعيد تصدير KpiCard/KpiTone/RefCodeText/MoneyText/InfoBox فقط لا loadingBlocks (يتطلب إضافته لقائمة show في export أو استيراد مباشر في dashboard)
- كل المال بالسنت (إرسال int عبر ×100 مع round()، عرض fmt.formatMoney/MoneyText)، التسميات حرفية من ملفات الويب، أيقونات Material فقط
- بانتظار CI: لا يمكن تشغيل flutter محليًا — التسليم بعد مراجعة سطر-بسطر

---
Task ID: 21-a
Agent: full-stack-developer (21-a)
Task: F5 شاشات الإدارة — الطاقم والأكواد (توليد/إبطال) + سجل التدقيق + الضيوف + التقارير

Work Log:
- قرأت worklog.md أولًا (دروس Task 19/20/21-b): أعماق الاستيراد ../../ من screens/admin/، ColorScheme.surface لا card، withValues(alpha:)، textContaining للنصوص المدمجة (Text.rich مضبوطة في CI جولة d83625f)، سطح 800×1600 عبر tester.binding.setSurfaceSize + addTearDown(null)، تصريف مؤقتات SnackBar بـ pump(4s)+pumpAndSettle، لا print/withOpacity، تدقيق الأيقونات ضد /tmp/icons_324.dart
- قرأت المراجع الحية كاملة قبل أي سطر: staff-codes.tsx (513) + audit-log.tsx + guests.tsx + reports.tsx + shared.tsx (شارات CODE_TYPE/CODE_STATUS/ROLE/AUDIT_ROLE + Pager + Ltr) + مسارات API السبعة (staff/route + staff/[id] + codes/route + codes/revoke + audit + guests + reports) — أشكال الاستجابة ورسائل التحقق الحرفية من الخادم
- قرأت الأساس (ملكية الوكيل الرئيسي — لم أعدّل حرفًا): admin_store.dart (تواقيع A-23..A-33 ملزمة) + models/admin.dart (AdminStaffMember/AdminAccessCode/GeneratedCodeResult/AuditPageData/AdminGuest/AdminReports) + admin_bits.dart (RawCodeBox/AdminSectionTitle/AdminBarChart) + admin_shell.dart (عقود الاستيراد) + rooms_screen/reservations_screen/services_screen (أنماط الزملاء: حوارات/فلاتر/متتاليات toast/pager/سويتش) + widgets/theme/format
- بنيت staff_codes_screen.dart (1417 سطرًا): قسمان بـ SegmentedButton (الأكواد افتراضيًا كالويب) — الأكواد: فلاتر النوع/الحالة (GUEST/RECEPTION/ADMIN + ACTIVE/EXPIRED/REVOKED/USED — المستخدمة إضافية من مهمتي) عبر store.refreshCodes(type:,status:) + بطاقة كود (codeMasked LTR monospace/النوع/الحالة/السياق: موظف أو ضيف+غرفة أو مرجع إقامة/ينتهي في/آخر استخدام timeAgoAr أو «لم يُستخدم»/إبطال للفعّال فقط + الملغي بعتامة 0.55) + حوار توليد (نوع RECEPTION/ADMIN فقط مع حاشية كود الضيف + موظفون فعّالون مطابقون للدور فقط مع تحذير الكود الفعّال الحالي + صلاحية 1-30 افتراضي 7 → store.generateCode → RawCodeBox(code) مع «كود استقبال — فلان (7 يومًا)» + ينتهي formatDateTimeAr + المخزّن codeMasked + إغلاق/توليد آخر + توست) + حوار إبطال يذكر الجلسات حرفيًا → store.revokeCode → توست برسالة الخادم الحرفية. الطاقم: بطاقة (الاسم/شارة الدور/الهاتف LTR/سويتش/تعديل + صندوق «أحدث كود» {codeMasked,type,status,expiresAt} أو «لا يوجد كود») + إضافة {fullName,role,phone} بtrim + تعديل {fullName,phone} (الدور مجمد بنص الويب) + تعطيل بحوار تأكيد يذكر إبطال الكود والجلسات (توجيه المهمة — الويب بلا تأكيد) ثم PATCH {active:false}
- بنيت audit_log_screen.dart (570): فلتر إجراء بكل الأفعال الـ 24 الحرفية من الويب + بحث حر (فاعل/كيان/معرّف) بزر بحث ومسح + تحديث + قائمة مصفّحة عبر store.refreshAudit(action:,q:,page:) + بطاقة سجل (chip الإجراء بلون دور الفاعل WEBSITE/RECEPTION/GUEST/ADMIN/SYSTEM + الفاعل ودوره + entityType + entityId مقتطع 14 محرفًا + details خريطة «مفتاح: قيمة» بText.rich LTR + timeAgoAr + formatDateTimeAr) + Pager (الإجمالي بأرقام عربية-هندية + السابق/«صفحة X من Y»/التالي)
- بنيت guests_screen.dart (382): بحث (اسم/هاتف/بريد) عبر store.refreshGuests(q:) يقيم في المخزن + بطاقة ضيف (الاسم/الهاتف LTR/البريد/الجنسية/أُضيف formatDateAr/عدد الحجوزات + آخر حجز {bookingReference LTR, checkIn, StatusChip.reservationStatus}) — كل فارغ «—» بأمان. حوار حجوزات الضيف في الويب استُبعد (خارج نطاق المهمة المحدد + لا نداء مخزن مخصص له — موثق في تقريري)
- بنيت reports_screen.dart (501): الإشغال 14 يومًا (AdminBarChart بنسبة فوق كل عمود + «المحسوبة على N غرفة فعّالة») + الإيراد 6 أشهر (AdminBarChart ذهبية بالسنت → fmt.formatMoney في valueFormatter) + طلبات الخدمة (صناديق الإجمالي/مكتمل/نشط/متوسط الإنجاز «Nد» أو «—» null-آمن + byStatus chips بتسمية requestStatusLabels + أعلى الخدمات بأشرطة تقدم) + الجنسيات أعلى 5 (صف + شريط) — تخطيط عمودان للعرض الواسع
- الاختبارات: ملفان بنمط rooms_test/reception_store_test (MockClient → ApiClient → AdminStore → pump في MaterialApp): staff_codes_test (8) + audit_test (7: تدقيق 4 + ضيوف 1 + تقارير 2) = 15 اختبار widget تغطي وجوبًا: جسم POST الحرفي {'type':'RECEPTION','staffId':'st_1','days':7} + ظهور الكود الخام R1234567 (find.text) + إبطال بحوار تأكيد وجسم {'codeId':'ac_1'} وتوست الخادم الحرفي + فلاتر الأكواد في استعلام GET (type=RECEPTION&status=ACTIVE حرفيًا) + صفحة التدقيق التالية (page=2 + أزرار التنقل + عناصر الصفحة) + الموظف المعطّل/غير المطابق غير قابلين للاختيار (تحليل عناصر DropdownButton مباشرة + تبديل النوع ADMIN) + رفض تطابق الدور برسالة الخادم + إضافة موظف بtrim + تعطيل بحوار {active:false} + فلتر الإجراء action=RESERVATION_CREATED + البحث الحر q= ومسحه + الضيوف (فارغ آمن «—»×3 + البحث) + التقارير (50%/75%/0% + $3,170.00/$1,500.00 + صناديق/chips/جنسيات + فراغ كامل + متوسط null → «—»)
- تدقيق ذاتي بلا Flutter محليًا (لا يمكن التشغيل — CI على GitHub بعد دفع الوكيل الرئيسي): توازن أقواس برمجيًا واعٍ بالنصوص للملفات الستة (كلها متوازنة {}) + صفر print/withOpacity/HTTP مباشر + كل نداءات store مطابقة للتوقيعات (مقاطعة برمجية store.* ضد تعريفات admin_store) + كل أيقونات Material الـ 25 المختلفة فُحصت grep ضد /tmp/icons_324.dart قبل التسليم (كلها OK — لا door_front_rounded/clipboard_rounded) + التسميات العربية منسوخة حرفيًا من ملفات الويب + فحص محارف موحّد (النقطة الوسطى U+00B7 والرموز • U+2022 متطابقة بين lib/test) + تحققت أن خللَي الأساس اللذين رصدّهما 21-b أصلحهما الوكيل الرئيسي مسبقًا (أيقونات admin_shell + loadingBlocks في تصدير admin_bits)

Stage Summary:
- 6 ملفات جديدة: lib/screens/admin/{staff_codes,audit_log,guests,reports}_screen.dart + test/screens/admin/{staff_codes,audit}_test.dart — 3996 سطرًا، صفر تعديل على الأساس أو الويب أو الخادم أو شاشات الزملاء
- عقود مجمّدة محفوظة: StaffCodesScreen/AuditLogScreen/GuestsScreen/ReportsScreen كلها {super.key, required this.store} كما تستوردها admin_shell.dart — آخر 4 شاشات F5 الناقصة اكتملت
- لا تغيير مطلوب في الأساس: توليد/إبطال/فلاتر/تدقيق/ضيوف/تقارير كلها عبر AdminStore الموجود بتواقيعه الحالية — الأساس كان كاملًا لي
- مراجعة سطر-بسطر انتهت؛ مخاطر متبقية موثقة في تقريري: 1) افتراض توقيت UTC في CI لتواريخ الاختبارات (نفس افتراض الزملاء ال CLI-أخضر) 2) textContaining على Text.rich (تفاصيل التدقيق) — نمط مجرَّب أخضر في CI Task 20 3) مطابقة عناصر القائمة المنسدلة بـ .last عند ازدواج نص الشارة (نمط الزملاء)

---
Task ID: 21
Agent: Main Agent (Z.ai Code) + ثلاثة وكلاء متوازيين (21-a/21-b/21-c — تقاريرهم في agent-ctx/؛ تقريرا 21-a و21-c أعاد كتابتهما الوكيل الرئيسي بعد مراجعة تكاملية مستقلة لأن مهلة النقل قصّت تقاريرهما — نفس ظاهرة 20-a)
Task: F5 — وضع الإدارة كاملًا في تطبيق Flutter (نقل الأقسام الإحدة عشر بأمر المالك: وكلاء موجهون بدقة وبضوابط نجاح حسب المخطط لا حسب الظن)

Work Log:
- [الترتيب] MASTER_PLAN §6.6: نقل أقسام الإدارة كاملة · القبول: العمليات اليومية للإدارة (توليد/إبطال كود، إدارة غرفة، مراجعة تدقيق) من التطبيق · جهد M · يعتمد على أنماط F4 · صفر عمل خادم (A-01..A-34 مجمّدة ومنفَّذة ومستهلكة من الويب)
- [الأساس — Main] ApiClient.delete() (كان مفقودًا — تلزمه A-07/A-11/A-14/A-18/A-22) + RealtimeService.joinAdminRoom() (غرفة admin كالويب) + models/admin.dart (كل نماذج A-01..A-34 بالسنت وقيم آمنة) + state/admin_store.dart (34 نداءً: كل GET/POST/PATCH/DELETE عبر المخزن فقط + الفلاتر وأرقام الصفحات تقيم في المخزن — تقاوم تنقّل الأقسام كقرار F4 الموثق + bootstrap = لوحة+إشعارات فقط كبوت الويب؛ كل قسم يُحمّل عند فتح شاشته) + admin_bits.dart (RawCodeBox: الكود الخام بحدود ذهبية+نسخ كالويب · AdminSectionTitle · AdminBarChart · AdminAlertBox · AdminNotificationCard + إعادة تصدير عناصر الاستقبال العامة) + KpiCard قيمة نصية اختيارية valueText (إضافي — سلوك النداءات القديمة لا يتغير) + dashboard_screen.dart (نقل dashboard.tsx: 4 KPIs حرفية + توزيع الغرف بألوان الويب ومفاتيحه + إيراد 14 يومًا ذهبي + أحدث الحجوزات + تنبيهات + الأكواد النشطة→توليد)
- [القشرة — Main] admin_shell.dart: 11 قسمًا حرفية من admin-app.tsx (SECTIONS/MOBILE_PRIMARY نفسها): شريط جانبي قابل للطي للواسع (aside القابل للطي في الويب) + سفلي بـ4 أساسية+«المزيد» يفتح شبكة الأقسام (Sheet bottom في الويب) + جرس بBadge غير المقروء → DraggableSheet إشعارات (A-34 — لا تعليم مقروء للإدارة: الويب كذلك) + Realtime بنفس معالجات الويب (notification:new→toast+تحديث · reservation:new→toast+لوحة · room:status→لوحة) + app.dart يوجه ADMIN→AdminShell (نقطة الدمج المعينة كF4) + RolePlaceholder حُذف (كل الأدوار حقيقية الآن)
- [الوكلاء الثلاثة المتوازيون] 21-a: الطاقم والأكواد (توليد بحوار مطابقة الدور + RawCodeBox مرة واحدة + إبطال بتأكيد يذكر الجلسات) + سجل التدقيق المُصفّح (24 فعلًا حرفيًا) + الضيوف + التقارير + 15 اختبارًا · 21-b: الغرف (إنشاء/تعديل بلا OCCUPIED يدويًا/حذف) + أنواع الغرف (النموذج الكامل) + المعدلات (تحذير التداخل يُعرض والإنشاء ينجح) + 14 اختبارًا · 21-c: إعدادات الفندق (كل الحقول + minAppVersion من F6) + الخدمات وأقسامها + الحجوزات (مصفّحة + تفصيل بلقطة السعر الحرفية) + 15 اختبارًا — مهل نقل النتائج انتهت (context deadline) لكن كل الوكلاء أكملوا ملفاتهم؛ 21-b سلم تقريره، و21-a سلم قسم worklog، و21-c قُطع قبل الاثنين — الرقابة التكاملية أدناه تعوض
- [مراجعة تكامل — Main — فعلية لا افتراضية] توازن أقواس برمجي واعٍ بالنصوص لكل الملفات الثلاثة عشر ✓ · كل أيقونة grep ضد icons.dart الرسمي: اكتشفت وأصلحت خطأين قاتلين مني (door_front_rounded و clipboard_rounded غير موجودين في Flutter — 21-b رصدهما أولًا: الإصلاح door_front_door_rounded و content_paste_rounded — تحققت منهما بنفسي قبل التعديل) + loadingBlocks مفقود من تصدير admin_bits (أصلحته بإضافته لقائمة show) · كل الاستيرادات تحل (فحص برمجي لمسار كل import) · كل نداء store مطابق للتوقيعات (استخراج برمجي لكل store.*) · العقود المجمدة مطابقة (11 شاشة {super.key, required this.store}) · صفر print/withOpacity/HTTP مباشر · المال كله بالسنت · تقريرا 21-a/21-c أعيد كتابتهما بعد قراءة عينية للكود الحرج (حوار التوليد 890-1000، لقطة السعر 740-920، حفظ الإعدادات 37-213، مفاتيح جسد الخدمة/القسم 732-920)
- [الاختبارات الجديدة 44+] نماذج (13) + مخزن (11: جسد A-03 الحرفي+note/جسد A-27 {type,staffId,days}+التحديثات الصامتة الأربعة/A-28 {codeId}+رسالة الخادم/فلاتر الأكواد في الاستعلام/الحجوزات page&status&q/التدقيق page&action&q/جسد الغرفة بtrim/المعدل بwarning/الإشعارات/reset يمسح الفلاتر والصفحات/DELETE الخمسة) + شاشات (44: staff_codes 8 + audit 7 + rooms 6 + hotel_settings 5 + reservations 5 + services 5 + rates 4 + room_types 4)
- [انحدار الويب محليًا] lint exit 0 + bun run test 165/165 (124+7+34) — الويب لم يُلمس إطلاقًا (كل التغييرات في mobile/ + docs)

Stage Summary:
- **F5 كاملة النطاق في التطبيق:** 11 قسمًا منقولة — لوحة تحكم بأرقام حقيقية ورسوم + إعدادات الفندق (مع minAppVersion) + أنواع الغرف + الغرف + المعدلات + الخدمات وأقسامها + الطاقم والأكواد (توليد/إبطال) + الحجوزات وتفاصيلها بلقطة السعر + الضيوف + التقارير + سجل التدقيق المُصفّح — كلها عبر AdminStore وA-01..A-34 بصفر تغيير خادم
- 13 ملف شاشة/حوارات جديدة (3 أساس + 10 شاشات) + admin_bits + نماذج ومخزن + 10 ملفات اختبار (24 نموذج/مخزن + 44 شاشة = 68 اختبارًا جديدًا) + تعديلات محددة (app.dart/api_client/socket/reception_bits إضافي فقط)
- في انتظار CI على GitHub (mobile-ci: analyze+test+build smoke) — الجولات القادمة موثقة أدناه عند حدوثها

---
Task ID: 21 (استكمال — جولات CI والتحقق النهائي والإقفال)
Agent: Main Agent (Z.ai Code)
Task: F5 — جولات CI على GitHub حتى الخضار الكامل + تحقق المتصفح الحي بالقناة نفسها + التوثيق (MASTER_PLAN v2.5 + README + سجل CI)

Work Log:
- [CI جولة 1 (4f867de)] Mobile فشلت: 6 أخطاء تجميع — خطأي: c.width غير موجود في BoxConstraints (dashboard: الصحيح c.maxWidth) · وكلاء: const Text(title) غير ثابت (hotel_settings) + '$' غير مهرَّب في نصين (room_types/services → r'…') + إغلاق لدالولة بحوار الموظف onPressed: () => _openStaffDialog(null) + سلسلة خام في اختبار الحجوزات — كلها أُصلحت
- [CI جولة 2 (edd5895)] Android build smoke ✓ أخضر أول مرة · Analyze فشل بـ5 تحذيرات قاتلة: import غير مستخدم في admin_bits (التصدير يكفي — أزلت الاستيراد وأبقيت export) + متغير scheme غير مستخدم + دالة اختبار ميتة _drainToast + تعبيران null ميتان (req.url.query غير منتهٍ) — كلها أُصلحت
- [CI جولة 3 (9803f81)] Analyze ✓ + Build ✓ · Test فشل بـ7: خلل حقيقي واحد في AdminBarChart (فيض 2px بخطوط الاختبار — أصلحته بالمرونة: Flexible تحت العمود + ميزانية تسميات 34px بدل 26) · 6 اختبارات هشة أُصلحت: غرف — tap على DropdownButton نفسه (نص التلميح لا يستقبل الأحداث — نمط اختبار (د) الناجح) + نص العنصر بصيغة الويب الحرفية «— 3 غرفة» · خدمات — عنوان الحوار يطابق نص الزر بعد الفتح (findsNWidgets(2)) · تدقيق — المعرّف يُعرض مقتطعًا 14 محرفًا (textContaining قصيرة) + ثلاثة نصوص «2» (الإجمالي+النشط+عدد أعلى خدمة) · إعدادات — التلميح يبقى في شجرة InputDecorator للقياس حتى مع وجود قيمة (قيمة+تلميح = 2)
- [CI جولة 4 (1a0b0d2)] ✅ **Mobile CI خضراء بالكامل: analyze + 169 اختبارًا (101 سابقة + 68 جديدة) + Android build smoke (dev flavor)** — أربع جولات موثقة كنمط F4 نفسه
- [web-ci] آثر التخطي بفلتر المسارات (لا تغييرات src/prisma/tests — كل F5 في mobile/ + docs) والتحقق المحلي: lint exit 0 + bun run test 165/165 (آخر خضراء لها d83625f نفسها)
- [تحقق المتصفح الحي] الويب / بلا أخطاء console · دخول A371849L9 → لوحة الإدارة كاملة بأرقام حقيقية (إشغال 14% · مقيمون 3 · إيراد الشهر $940 · 14 غرفة بأحوالها) — هذه هي القناة A-01..A-34 نفسها التي يستهلكها AdminStore الجديد · **مسار القبول حيًا من الويب: توليد كود استقبال لأحمد الاستقبال (R2••••T0 — الخام ظهر مرة واحدة بالحوار + نسخ) ثم إبطاله بحوار التأكيد → حالته «ملغي» والقائمة عدّت صحيحًا + إعادة حالة العرض** — صفر أخطاء console
- [Docs] MASTER_PLAN v2.5: §6.6 F5 ✅ منفَّذة (المنفَّذ فعليًا كامل + القبول محقق) + صف الحالة في جدول أول + سجل 2.5 · README الجوال: قسم «وضع الإدارة (F5)» كامل + تحديث سطر ADMIN · لا تغيير CONTRACTS (صفر نقاط خادم جديدة — المستهلكات كلها كانت مسجلة في بطاقات A)
- لا إصدار APK جديد (قرار المالك كالمعتاد — الإصدار التالي يحمل وضع الإدارة تلقائيًا)

Stage Summary:
- **F5 مقفولة بمعيارها الحرفي:** العمليات اليومية للإدارة (توليد/إبطال كود، إدارة غرفة، مراجعة تدقيق) تعمل من التطبيق — بل كل الأقسام الإحدة عشر تعمل
- CI خضراء بالكامل على GitHub (1a0b0d2): 169 اختبار Flutter (68 جديدة) + Android build smoke · الويب: 165/165 محليًا ولم يُلمس
- المتبقي من F: F3 (Push — يحتاج Firebase) · F7 (Dogfooding) · F8 (المتاجر) — W/P معلّقة بقرارات المالك

---
Task ID: 22
Agent: Main Agent (Z.ai Code)
Task: أمر المالك — قبل الانتقال لأي مرحلة: إعداد «ملف المطالبة» (برومبت مؤسسي) لمهمة جرد وتدقيق شامل حي يسلم لنموذج ذكاء اصطناعي خارجي (سحب + تعرف + تجهيز + فحص نظري + فحص حي للويب والجوال + اكتشاف كل الأخطاء في كل الأبعاد + التقرير الكامل)

Work Log:
- جرد وقائعي فعلي قبل الكتابة (لا من الذاكرة): git status/log (نظيف عند fb9edf2 — إغلاق F5) + remote/branch · MASTER_PLAN.md كامل البنية (v2.5 بفقرة تغييرات 2.5 · حالة المراحل: H/F0-F2/F4/F5/F6 ✅، F3/F7/F8/W1-4/P معلّقة، W0 مقفل) · ذيل worklog (Task 21 + جولات CI الأربع: 169 اختبار جوال خضراء + 165 ويب محليًا) · README الجذر (أوامر التشغيل الرسمية + الأكواد التجريبية) · رؤوس CONTRACTS.md (قنوات public/auth/guest/reception/admin + §9 الاستقرار) · mobile/README + pubspec (flavors dev/prod + dart-define) · .env.example و.env (متغير واحد: DATABASE_URL مطلق) · Caddyfile (بوابة :81 + XTransformPort) · realtime/index.ts (3002 عملاء + 3004 بث داخلي) · workflows الثلاثة · seed.ts (الفندق + whatsapp + الطاقم والضيوف)
- أثناء الجرد رصدتُ 3 انحرافات توثيقية حقيقية (ضُمّت كعينات معايرة في الملحق ب): عنوان MASTER_PLAN ما زال v2.4 (سجل التغييرات يقول 2.5) · README الجذر «157 اختبارًا» (الصحيح 165) · README «20 نموذجًا» (المخطط 22)
- كتبت AUDIT_BRIEF.md في جذر المستودع (366 سطرًا، عربي مؤسسي): 15 قسمًا + ملحقان — روح المهمة والقواعد الثلاث (الواقع/الدليل/الإنجاز + محظورات «يبدو/أظن») · بطاقة حقائق مثبتة (المستودع fb9edf2 · الستاك · 22 نموذجًا · 67/82 API · المنافذ 3000/3002/3004 · الأكواد الأربعة · الألوان · حالة المراحل) · قيود البيئة (3000 فقط، لا build، XTransformPort، لا db:push) · المرحلة صفر سحب+تجهيز بأوامر حرفية + بوابة قبول + قاعدة فشل التجهيز · مرحلة التعرف + 12 سؤال معايرة · الفحص الساكن S1–S8 · الفحص الحي للويب 6.1–6.10 (كل وضع بتدفقاته الكاملة + اختبارات سلبية + ثنائي الجلسة للوقت الفوري + ألوان/ثيم/لغة/RTL/استجابة/تذييل + محاسبة عميقة I1/I7/I8/I9/I12 + انضباط الاختبارات المدمّرة والاستعادة) · الجوال بمستويات A/B/C + فحص تكافؤ النقل AD-03 · مصفوفة الأبعاد الاثني عشر الحرفية (شاشات/صفحات/وظائف/عمليات/متطلبات/اعتمادات/ألوان/ثيم/لغة/منطق/محاسبة/أقسام) · إلزامية كل المهارات والوكلاء المتوازيين · حقول سجل العيوب · تصنيف الخطورة + فئة INV-كسر · هيكل التقرير النهائي 14 قسمًا · الضوابط (قراءة فقط، لا push، لا Actions، كتابة على seed فقط مع الاستعادة) · قائمة قبول نهائية · ورقة أوامر جاهزة · ملاحظات المعايرة الثلاث
- لا تغيير في أي كود (وثيقة جديدة + هذا السجل فقط) — F5 تبقى مقفلة كما هي
- [بعد الالتزام — انحراف بيئي مكتشف بالتحقق الحي] إعادة تهيئة الحاضنة بين الجلسات مسحت بيانات قاعدة dev: `GET /api/public/hotel` → 503 «معلومات الفندق غير متاحة» + `migrate status`: لا migrations مطبقة + Hotel/rooms/guests = 0 (الظاهرة نفسها الموثقة في Task 18 — لا تمس الكود) → استعادة بالمسار الرسمي: `bunx prisma migrate reset --force` (طبّق migrations الاثنين + توليد العميل) ثم `bun prisma/seed.ts` → التحقق الحي بعد الاستعادة: «Database schema is up to date!» + `/api/public/hotel` 200 باسم الفندق + دخول `A371849L9` حيًا (token/ADMIN/سالم المدير) + خدمة realtime 3002 تجيب 200

Stage Summary:
- المخرج: AUDIT_BRIEF.md في جذر المستودع (مُلتزم إلى main) — ملف مطالبة كامل جاهز للتسليم لنموذج خارجي؛ الفارق عن جولة سابقة: كل حقيقة فيه مثبتة من المستودع الفعلي + 3 انحرافات موثقة بدليل موضعي
- صفر مساس بالكود أو المراحل المقفلة (AD-06 محفوظ — الملف يفرض على المدقق «قراءة فقط» ويمنع الإصلاح)
- الانتقال لأي مرحلة تالية (F3/F7/W/P) متوقف بقرار المالك على نتيجة التدقيق الخارجي

---
Task ID: A-rec
Agent: A-rec (general-purpose)
Task: بوابة المعايرة — المرحلة الأولى (التعرف والفهم) لموجة الفحص الساكن وفق AUDIT_BRIEF.md §4: الإجابة عن الأسئلة الاثني عشر من ملفات المستودع نفسه بدليل موضعي (ملف:سطر) لكل ادعاء — قراءة ساكنة فقط (لا فحص حي، لا تعديل كود، لا لمس قاعدة البيانات).
Work Log:
- قراءة AUDIT_BRIEF.md كاملًا (القواعد الثلاث + الأسئلة الاثنا عشر + الضوابط) وذيل worklog.md (Task 18→22: إغلاق F5 عند fb9edf2 + إعداد المطالبة)
- قراءة المصادر المحددة: README.md وMASTER_PLAN.md كاملًا (§2/§3/§12/§13 بالتركيز) وdocs/CONTRACTS.md (المقدمة + الفهرس + §8/§9/§10/§11) وmobile/README.md وprisma/schema.prisma (22 نموذجًا) وsrc/lib/{codes,pricing,refs,events,auth,availability}.ts
- تتبع مسارات الكود للأجوبة: reception/check-in (نقطة تحويل Reservation→Stay + كود الضيف الخام مرة واحدة) · check-out (I11) · reception/_helpers (قاعدة الرصيد) · public/bookings (I1/I2/I6/I7/I8/I9 + عربون 50%) · guest/requests (مسار الحدث اللحظي request:new) · reception/requests/[id]/status وguest/requests/[id]/cancel (آلات الحالة) · rooms status (I12 + مصفوفة الانتقالات) · auth/validate (12 ساعة + rate-limit) · use-socket + page.tsx + store.ts + code-login.tsx (SPA/الأوضاع) · Caddyfile + mini-services/realtime/index.ts (المنافذ 3002/3004/81)
- جرد ساكن لعدد ملفات/نقاط الـ API: 69 ملف route.ts / 84 نقطة نهاية (7 public + 3 auth + 16 guest + 23 reception + 34 admin + 1 جذر؛ 40 GET + 33 POST + 6 PATCH + 5 DELETE) — مقابل «67/82» في الخطة و«68/83» في CONTRACTS §10.1
- كتابة التقرير الكامل في agent-ctx/A-rec.md (سؤال/إجابة/أدلة لكل بند + قسم تعارضات C1–C9 + إقرار نزاهة)
Stage Summary:
- الأجوبة الاثنا عشر مكتملة بالأدلة الموضعية؛ النقاط المفصلية: نقطة التحويل = POST /api/reception/check-in (CONFIRMED→CHECKED_IN + Stay ACTIVE) · الهويات الأربع والكود الخام مرة واحدة لأن المخزن SHA-256 فقط · المال بالسنت مفروض في schema.prisma:5 وpricing.ts (الضريبة round(subtotal×15/100) والرصيد grand+Σcharges−paid) · مجموعة F1 STABLE = 16 نقطة §8.1 + عقد الجوال §1.2.1 + المكملات §8.2
- 9 تعارضات موثقة (الواقع يغلب): أبرزها عدد الـ API فعليًا 69/84 (الوثائق 67/82 و68/83 — الفارق قناة auth/renew) · طول الكود 9 خانات (الوثائق تقول بادئة+7 رموز) · NO_SHOW/EXPIRED لا يضبطهما مسار (فلتر فقط) · رأس CONTRACTS ما زال v1.0 (السجل v1.1) · README: عدد النماذج/الاختبارات/القنوات/اسم نورا
- صفر فحص حي وصفر مساس بالكود أو القاعدة أو الخوادم — التقرير جاهز للاستهلاك في موجات التدقيق التالية

---
Task ID: A-s6
Agent: Audit Sub-Agent (A-s6 — الفحص الساكن S6 من AUDIT_BRIEF §5)
Task: مطابقة العقد — عدّ فعلي لملفات المسارات ونقاط النهاية تحت src/app/api/ ومطابقتها ضد docs/CONTRACTS.md + تحقق حرفي من 6 عينات + التحقق من الادعاء المرجعي «67 ملفًا / 82 نقطة» (قراءة فقط — صفر تعديل كود)

Work Log:
- [الجرد البرمجي] `rg --files src/app/api -g 'route.ts'` = **69 ملفًا** (تحقق إضافي: لا route.ts واحد خارج src/app/api/ في src/app كله) · استخراج المعالجات بـ regex على `export async function (GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)` = **84 نقطة نهاية** (GET 40 · POST 33 · PATCH 6 · DELETE 5 · PUT/HEAD/OPTIONS صفر — ولا صيغ تصدير بديلة: صفر export const GET، وصفر دالة غير async)
- [جرد العقد] 83 بطاقة مرقمة في CONTRACTS.md (1919 سطرًا): PUB-01..07 + AUTH-01..02 + G-01..16 + R-01..23 + A-01..34 + ROOT-01 — إضافة بطاقة نصية كاملة لـ POST /api/auth/renew في §1.2.1 (سطرا 79-84) موسومة STABLE في §9.2
- [المطابقة الثلاثية] فرق أزواج (منهج+طريق) بين الكود والبطاقات: (أ) في الكود بلا عقد = صفر · (ب) في العقد بلا كود = صفر · (ج) اختلافات منهج = صفر — `comm -13` أعاد فراغًا و`comm -23` أعاد renew فقط (موثقة في §1.2.1 لا ببطاقة §3)
- [العينات الست + تكميلية] PUB-01 public/hotel (503/500 الحرفيان + 24 حقلاً في toHotelPublic) · AUTH-01 auth/validate (الرسائل الثماني حرفية + 12 ساعة + قفل 10/15 دقيقة + معاملة ثلاثية) · G-09 guest/bill (بنية bill بـ 16 حقلًا + 404/500) · R-11 rooms/[id]/status (مصفوفة الانتقالات الخمس + الرسائل الست + بث room:status) · A-03 admin/hotel PATCH (11 رسالة خطأ + minAppVersion بامتداد v1.1 + note الحرفية) · A-27 admin/codes POST (8 رسائل + 201 بالكود الخام مرة واحدة + CODE_GENERATED) + عينة تكميلية renew ضد §1.2.1 — **6/6 (و7/7) تطابق حرفي، صفر انحراف في الحقول/الرموز/الرسائل العربية**
- [الادعاء المرجعي 67/82] **غير مطابق للواقع الخام**: الفعلي 69 ملفًا / 84 نقطة. الرقم 67/82 = بطاقات القنوات الخمس حصرًا (7+2+16+23+34=82 عبر 67 ملفًا) — يستثني POST /api/auth/renew (موثقة §1.2.1 ومستهلكة فعليًا من تطبيق الجوال F0/F1) وGET /api الجذر (موثق ROOT-01 و«مرشح للحذف» §10.3). CONTRACTS.md نفسها تحمل ثلاثة أعداد متضاربة داخليًا: فهرس auth=2 · §10.1=68/83 (قبل renew) · §9.3 v0.9=67/82 — وترويستها ما زالت v1.0 بينما §9.3 آخر صف v1.1
- [ملاحظتان دقيقتان لا كسر عقد] validate يصفّر عداد فشل NOT_FOUND عند العثور على الكود (route.ts:64) لا عند النجاح الصارم كما تقول البطاقة · R-11 يثبّت actorRole='RECEPTION' في التدقيق حتى لو نفّذ ADMIN (route.ts:25,60) — العقد لا يوثّق actorRole لهذا الحدث
- [المخرجات] تقرير كامل بجرد 69 صفًا (الطريق|المناهج|بطاقة العقد|تطابق) + العينات + انحرافات العدّ في agent-ctx/A-s6.md (274 سطرًا) · صفر مساس بأي ملف كود أو قاعدة بيانات أو git

Stage Summary:
- **S6 = ناجح مع انحراف عدّ موثق:** الكود والعقد متطابقان 84/84 على مستوى (منهج+طريق) والرسائل العربية حرفية في كل العينات السبع — لكن الرقم المرجعي «67/82» في AUDIT_BRIEF متقادم (الفعلي 69/84) والانحراف INFO توثيقي من فئة ملحق ب نفسها (ترويسة CONTRACTS v1.0 مقابل سجل v1.1 كنمط MASTER_PLAN v2.4/2.5)
- توصية مسجَّلة بلا تنفيذ (نطاق قراءة فقط): تحديث AUDIT_BRIEF §1 إلى 69/84 + فهرس CONTRACTS «auth — 3 مسارات» + §10.1 + ترويسة الإصدار — كلها تحرير وثائق صفر كود

---
Task ID: A-mob
Agent: general-purpose (وكيل تدقيق ساكن — المستوى C من AUDIT_BRIEF §7)
Task: A-mob — الفحص الساكن لتطبيق الجوال (Level C): GitHub API قراءة فقط (جولات CI + خطوط + Releases/APK) + تكافؤ النقل AD-03 (ألوان/تسميات/RTL/اتصال) + جودة كود mobile/lib + حارس minAppVersion — بلا تشغيل Flutter (غير مثبت — حد بيئي صريح)

Work Log:
- [حدود البيئة أولًا] Flutter SDK غير مثبت: which flutter/dart فارغ + PATH بلا مسار Flutter + المسارات الشائعة (/usr/lib,/opt,/home/z,/snap,/root) كلها غائبة ⇒ S4/S5 محليًا مستحيلان — عُوّضا بسجلات CI الحرفية (تنزيل logs لوظيفة الاختبار). لا محاكي/جهاز (المستوى A/B خارج المتاح) · apksigner غير موجود (عُوّض بـ unzip+keytool+فحص كتلة v2 الثنائي) · db/custom.db لم يُمس
- [CI — الادعاء الأول مؤكد] الجولة 20 (run 33828056973) عند 1a0b0d2 = completed/success بوظيفتين: «Flutter analyze + test» (كل الخطوات خضراء) و«Android build smoke (dev flavor)» ✓ — وسجل الوظيفة المنزَّل يحوي حرفيًا: «🎉 169 tests passed.» و«59 issues found» (كلها info — صفر warning/error؛ CI يمر بـ --no-fatal-infos بتصميمه)
- [CI — الادعاء الثاني مؤكد] أربع جولات F5 بالضبط كما في worklog Task 21: 4f867de (17 فشل) → edd5895 (18 فشل) → 9803f81 (19 فشل) → 1a0b0d2 (20 نجاح) — وجولة 21 عند fb9edf2 (docs مست mobile/README فأطلقت mobile-ci بالفلتر): success. الإجمالي 27 جولة: Mobile 23 (منها جولتان أوليان باسم مسار الملف — ظاهرة YAML Task 18) + Web 3 كلها خضراء (آخرها 3429cba) + Mobile Release 2 (فشل ثم نجح)
- [الخطوط الثلاثة موجودة وفاعلة] mobile-ci.yml: وظيفتا analyze-test (باستخراج APP_VERSION من pubspec → dart-define) وbuild-smoke (debug dev flavor + أثر 7 أيام) · mobile-release.yml: workflow_dispatch/tags v* — مفتاح التوقيع من Secrets (ANDROID_KEYSTORE_BASE64 → key.properties) + بناء prod/dev release + ncipollo/release-action · web-ci.yml: lint+test بربط /home/z/my-project ثابتًا
- [Releases + APK موقّع] إصدار واحد v1.0.0+1+2 (من Mobile Release #2 عند 308db82 — 2026-09-02، أنشأه github-actions[bot]) بأصلين: prod (52,939,895B) وdev (52,939,896B) — حمّلت prod إلى audit-evidence/mobile/ (HTTP 200): sha256 = 7907161f130e70089656508f664ebb3568cf895f5db6c6888c5e66cdafcc5a12 · التوقيع v1 (META-INF/CERT.RSA+SF+MANIFEST.MF، X-Android-APK-Signed: 2، Signflinger/AG 8.7.3) + v2 (magic «APK Sig Block 42» موجود) · الشهادة: CN=Cairo Heart Hotel Aden ذاتية، 2026→2056، SHA256 88:51:36:43:CE:B1:A1:BE:FD:A5:2C:9B:66:DF:1D:B3:54:1F:2D:D6:89:C4:88:2F:FA:AD:FF:94:7C:3D:D8:B2
- [MOB-01 — الأهم] فحص سلاسل libapp.so (UTF-16LE): إيجاب «فندق قلب القاهرة/الفاتورة/إقامتي/XTransformPort/3002/chat:message//api/auth/validate//api/guest/» وغياب «يتوفر تحديث مطلوب/minAppVersion/app-config/الوصولون/المغادرون/حالة الغرف/تأكيد تسجيل الوصول/سجل التدقيق/أنواع الغرف/الطاقم والأكواد» ⇒ الـ APK المنشور = وضع الضيف F1/F2 فقط (بُني قبل F4/F5/F6) — الحارس لا يحمي النسخة المنشورة
- [AD-03 الألوان] الكحلي #1A3C6E والذهبي #D4A843 متطابقان حرفيًا في النهاري (theme.dart:10,13,29,33 ↔ globals.css:62,64,74) — انحرافات ثانوية موثقة (MOB-02): الكحلي الليلي mobile #A8C2E8 (theme.dart:55) ≠ web #8FB3E3 (globals.css:100) + خلفيتا scaffold (#F6F8FB≠#FAF8F5 و#0E1726≠#0C1320) + onSecondary (#3A2E07≠#2A2110) — COSMETIC. وملاحظة MOB-04: tailwind.config.ts موروث أجوف (hsl(var(--hex))) والنافذ هو @theme inline في globals.css (Tailwind 4)
- [AD-03 التسميات] 24 تسمية مقارنة بملف:سطر في الطرفين (تبويبات الاستقبال الستة + معالجا الوصول/الخروج بكل أزرارهما + حالات الغرف الخمس + حالات الحجز السبع + أقسام الإدارة الأحد عشر + شاشة الدخول + حقل minAppVersion + تبويبات الضيف الأربعة + حالة الفراغ) — **صفر انحراف تسمية** (رؤوس الجدول في تقريري) · «يتوفر تحديث مطلوب» (update_required_screen.dart:56) شاشة تطبيقية بلا نظير ويب (ب التصميم)
- [RTL] MaterialApp في app.dart:130 مع locale Locale('ar') (:136) وsupportedLocales [:137] ومندوبي flutter_localizations (:138-142) ⇒ اتجاه RTL مشتق من اللغة (لا Directionality صريح — النمط الأصيل) · 96 جزيرة LTR للرموز/الهواتف/المراجع (كنمط dir=ltr بالويب)
- [الاتصال] http مستورد في ملفين فقط: api_client.dart:8 (العميل) + app_version.dart:12 (حارس PUB-07 قبل الجلسة — استثناء مقصود) · صفر dio/HttpClient · socket_service.dart:92-101 يبني العنوان بـ setPath('/') + setQuery({'XTransformPort': AppConfig.realtimePort='3002'} — config.dart:77) ⇒ مطابق لعقد io("/?XTransformPort=3002") بلا منفذ مباشر
- [جودة] صفر print في lib+test (avoid_print مفعل) · صفر withOpacity (106 withValues بدلها) · صفر debugPrint · 67 ملف/32,411 سطرًا في lib و31 ملف اختبار
- [حارس F6] الموثق حرفيًا: schema.prisma:44-45 (افتراضي ""=لا فرض) → app-config/route.ts:12-19 (نقطة عامة fail-open تعيد ok({minAppVersion})) → app_version.dart (kAppVersion من dart-define افتراضي 0.0.0 + compareSemver ثلاثي + needsUpdate: فارغ=false + مهلة 10 ث بفشل متسامح) → app.dart:109-118 (فحص عند الإطلاق، يتخطى بلا عنوان خادم) → app.dart:149-158 (حجب كامل بـ UpdateRequiredScreen مع onRetry يعيد الفحص) — والاختبار update_required_test.dart أخضر في CI
- [النزاهة] صفر POST على GitHub وصفر إطلاق Actions وصفر تعديل كود/commit/push — الأدلة الخام في audit-evidence/mobile/ (غير متتبعة في git) والتقرير الكامل في agent-ctx/A-mob.md

Stage Summary:
- **المستوى C مكتمل بأدلة حرفية:** ادعاءا CI السابقان مؤكدان من GitHub API (1a0b0d2 خضراء: analyze+169 اختبارًا+build smoke، وأربع جولات F5 بالتسلسل الموثق) والخطوط الثلاثة فاعلة والـ APK الموقّع موجود وموثق (v1+v2، sha256، شهادة 30 سنة)
- **MOB-01 (MAJOR تعملقي):** الـ APK المنشور نسخة ضيف فقط سابقة لـ F4/F5/F6 — حارس minAppVersion غير موجود فيها: أي فرض للحد اليوم لن يحجب النسخة العامة — توصية: إصدار جديد من main قبل أي فرض (قرار مالك)
- **MOB-02 (COSMETIC):** انحراف قيم ألوان ثانوية (ليلي/خلفيات/onSecondary) مع تطابق حرفي للهوية الكحلي/الذهبي نهارًا · **MOB-03 (INFO):** analyze = 59 ملاحظة info (معيار S4 «صفر إشكالات» غير محقق حرفيًا — CI خضراء بـ --no-fatal-infos) · **MOB-04 (INFO):** tailwind.config.ts أجوف
- تكافؤ AD-03 ممتاز نصيًا: 24/24 تسمية بلا انحراف + آلات حالة حرفية + RTL + socket بالبوابة — حدود البيئة: لا Flutter SDK محليًا (S4/S5 عبر سجلات CI) ولا جهاز تشغيل ولا apksigner
---
Task ID: A-s8
Agent: general-purpose (A-s8 — وكيل تدقيق ساكن)
Task: الفحص الساكن S8 من AUDIT_BRIEF.md — مراجعة الاعتماديات كاملة (package.json الجذر + mobile/pubspec.yaml + mini-services/realtime/package.json): الاستخدام الفعلي لكل حزمة، تناقضات الإصدارات مقابل bun.lock، التوافق البيني، والمخاطر الأمنية المنشورة — قراءة فقط بلا أي تعديل كود

Work Log:
- [المنهجية] مسح برمجي للاستخدام (ريجكس استيراد على كل ملفات src/ tests/ examples/ prisma/ mini-services/ + workflows + إعدادات الجذر) + تحليل سلسلة مكونات ui بمستويين (هل يستهلك التطبيق المكون الذي يستورد الحزمة؟ 58 ملف ui: 22 حي/36 ميت) + تحليل bun.lock برمجيًا (الجذر وrealtime) + تحقق Grep مستقل لكل ادعاء «لا استخدام»
- [الأمن — مصدر حي] لا مهارة Web-Search في البيئة فاستُعملت واجهات OSV.dev وpub.dev مباشرة (استعلامات فعلية بتاريخ 2026-09-05: 34 npm + 6 Pub + 6 تبعيات realtime) — كل بند أمني بمصدره
- [نتيجة الجذر] 68 dependencies: 32 مستخدمة فعليًا فقط (47%) — **36 بلا أثر استخدام (53%)**: 17 بلا أي استيراد (dnd-kit×3, hookform/resolvers, mdxeditor, reactuse, tanstack×2, next-auth, next-intl, date-fns, react-markdown, react-syntax-highlighter, remark-gfm, sharp, z-ai-web-dev-sdk, zod) + 19 «سلسلة ميتة» (مستوردة فقط في مكونات ui غير مستهلكة: cmdk, embla, input-otp, react-day-picker, react-hook-form, react-resizable-panels, sonner, vaul, tailwindcss-animate + 10 حزم radix) · devDeps: 8/9 مستخدمة + bun-types معلنة غير موصولة بـtsconfig
- [الأمن الحرج] **next@16.1.3 عليها 32 تحذيرًا منشورًا في OSV** (middleware/proxy bypass · تسميم كاش · SSRF · DoS · XSS · تهريب طلبات — أقدم إصلاح 16.1.5/16.1.7 والأشمل 16.2.11، كله داخل نطاق ^16.1.1 بلا كسر) — التطبيق المباشر منخفض (لا middleware.ts · لا next/image · لا Server Actions · لا rewrites) لكن الإنتاج standalone هو نمط عدة تحذيرات → **MAJOR: يجب الترقية** · كامنة في حزم غير مستوردة: next-auth 4.24.13 (3 CVEs — الإصلاح 4.24.15) · next-intl 4.7.0 (2) · sharp 0.34.5 (libvips) · uuid 11.1.0 (GHSA-w5hq-g745-h8pq — لا ينطبق على v4() المستخدمة في validate/route.ts:11) · نظيفة حيًّا: prisma/@prisma/client 6.19.2 · socket.io 4.8.3 + engine.io 6.6.9 + ws 8.21.3 · react/react-dom 19.2.3 · framer-motion 12.26.2 · zustand · lucide-react · recharts وكل الحزم الجارية الأخرى
- [الجوال] 5 runtime: 4 مستخدمة + **cupertino_icons غير مستخدمة** (صفر CupertinoIcons في lib/test) · **لا pubspec.lock مؤرشف** — الحزم تُحل طازجة كل CI (اليوم حيًّا: socket_io_client 3.1.6 · http 1.6.0 · shared_preferences 2.5.5 · url_launcher 6.3.2) · صفر ثغرات في OSV-Pub (بتحفظ تغطية)
- [realtime] socket.io ^4.8.1→محجوزة 4.8.3 مستخدمة في index.ts:9 — مطابقة للعميل JS 4.8.3 (تطابق تام في القفلين) ومتوافقة مع عميل Dart 3.x (بروتوكول v4) + تبعياتها engine.io/ws نظيفة
- [التناقضات] **صفر تناقضات حادة** — كل نسخة محجوزة داخل نطاق caret · انجرافات موثقة (prisma 6.11.1→6.19.2 · react 19.0→19.2.3 · next 16.1.1→16.1.3 — زعم بطاقة AUDIT_BRIEF «16.1.3» مطابق للقفل) · التوافق البيني كله سليم (prisma==client · next↔react 19.2 · tailwindcss==postcss 4.1.18 · eslint-config-next==next)
- [ازدواج/موضع] tailwindcss-animate ميت فعليًا (tailwind.config.ts غير محمَّل في Tailwind 4 — لا @config في globals.css وأنماط content فيه لمسارات غير موجودة) مقابل tw-animate-css الفعال · react-query مقابل zustand · next-auth مقابل المصادقة الداخلية · منظومة markdown رباعية كاملة غير مستخدمة · prisma CLI في dependencies (الأدق dev) · sharp غير مستخدمة أصلًا · examples/websocket/server.ts يستورد socket.io غير المتوفرة في الجذر (مثال مكسور)
- [خطر caret] لا كسر متوقع (كل النطاقات major-مقيدة — والأهم: ترقية الأمان 16.2.11 تنفذ من داخل ^16.1.1 نفسه) · الخطر الأعلى فعليًا: bun-version: latest في web-ci.yml:29 (أداة CI غير مثبتة) + غياب pubspec.lock
- [المخرجات] تقرير كامل بجداول (الحزمة/المعلن/المحجوز/مستخدمة؟/ملاحظات) للجذر (76 صفًا في 3 جداول) والجوال وrealtime + قوائم غير المستخدمة وسجل الأمن بمصادره + التوصيات المرتبة: agent-ctx/A-s8.md · نقطة الوقوف: HEAD 2e3897b (فروقات docs-only عن fb9edf2 — ملفات الاعتماديات لم تتغير) · صفر تعديل على أي ملف كود

Stage Summary:
- **S8 منفذة بالكامل بمعيار الأدلة:** 36/68 من اعتماديات الجذر (53%) بلا أثر استخدام فعلي (17 بلا استيراد + 19 سلسلة ميتة عبر مكونات ui ميتة) + cupertino_icons في الجوال — المشروع يحمل ~الضعف من اللازم في node_modules
- **أهم خطر أمني:** next 16.1.3 العمود الفقري عليها 32 تحذيرًا منشورًا (OSV حي 2026-09-05) — MAJOR مع تطبيق مباشر منخفض (غياب middleware/image/actions) لكن الترقية إلى ≥16.2.11 إلزامية وسهلة (داخل caret) · 6 تحذيرات كامنة أخرى كلها في حزم غير مستوردة (next-auth/next-intl/sharp/uuid)
- **صفر تناقضات إصدارات حادة** والتوافق البيني سليم كليًا (socket.io 4.8.3 خادمًا وعميلًا JS متطابقان + Dart 3.x متوافق بروتوكولًا؛ prisma==client 6.19.2)
- ملاحظتان بنيويتان للتقرير النهائي: tailwind.config.ts غير محمَّل أصلًا في Tailwind 4 (وtailwindcss-animate ميت معه) · لا pubspec.lock في mobile وbun CI غير مثبت
- ساكنة تمامًا: لا كود عُدّل، لا حزم ثُبتت، لا قواعد لمست — التقرير في agent-ctx/A-s8.md وهذا السجل فقط

---
Task ID: A-s7
Agent: Audit Sub-Agent (A-s7 — الفحص الساكن S7: تتبع المتطلبات)
Task: S7 من AUDIT_BRIEF §5 — تتبع متطلبات upload/PLAN_WEBSITE.md وupload/PLAN_ MOBILE-APK.md وMASTER_PLAN §2.1/§6 إلى المنفَّذ فعليًا (قراءة فقط — لا تعديل كود، لا commit، لا db:push)

Work Log:
- قرأت ذيل worklog.md وAUDIT_BRIEF.md كاملًا (القسم 5 جدول S7 + القواعد الثلاث) قبل أي عمل
- قرأت الخطين الأصليين سطرًا بسطر: PLAN_WEBSITE.md (3424 سطرًا — 137 قسمًا مرقّمًا) وPLAN_ MOBILE-APK.md (2070 سطرًا — 18 قسمًا) + MASTER_PLAN.md v2.5 (§1.2 أسبقية الوثائق، §2.1 المبني، §2.2 المؤجل، §3 ADR، §6 مراحل F، §7 W، §8 P، §12 الثوابت)
- جردت المنفَّذ: 67 ملف مسار API + مكونات website/guest/reception/admin كاملة + mobile/lib (79 ملف dart) + prisma/schema.prisma (22 نموذجًا)
- تتبعت 72 متطلبًا قابلًا للتحقق بالقراءة المباشرة وGrep — لكل متطلب موضع دليل (ملف:سطر) أو بحث الإثبات للغياب (نماذج المخطط، المسارات، المكونات، package.json/pubspec)
- النتائج الحرفية: 49 منفَّذًا (68.1%) · 7 منحرفة بقرار موثق (SPA §2.1/§6.10 · عربون بلا بوابة §2.1+P5 · wa.me قرار W0 · طباعة بدل PDF §2.1 · كود الضيف حصري عند الوصول I11 · الهولد يُستبدل بتأكيد فوري) · 4 منحرفة إعادة نطاق (مرافق/معرض ثابتة بلا CMS · About مدمج · CMS جزئي · SEO بلا sitemap/بيانات مهيكلة ببنية SPA) · 4 غائبة فعليًا · 8 مؤجلة بقرار صريح (F3/F7/F8/W1-4/P5/P1-6/O4)
- الأدلة المفصلية الموثقة في التقرير: availability.ts:40-56 (كل حالات التحقق) · bookings/route.ts:23-68/151/233-248 (Idempotency+ذرية+عربون 50%) · pricing.ts:73-129 (الحتمية+اللقطة) · lookup/cancel (أمان التعداد 5/دقيقة) · codes.ts:12-35 (checksum+sha256) · auth/validate:14-60 (5/د+قفل 10) · check-in:45-49 (نفس النوع+متاحة) · check-out:63-70 (موت الكود I11) · admin/codes:66-88 (تطابق الدور+1-30 يومًا) · إشعارات مولدة فعليًا في 9 مسارات · mobile: api_client 401→renew + app_version guard + socket عبر البوابة
- الغائب فعليًا بلا قرار يؤجل (قائمة مرشحي العيوب): تعديل الحجز من الموقع+سجل التعديلات (Journey C كاملة — المرشح الوحيد لمستوى MAJOR) · تأكيد البريد الإلكتروني (SHOULD) · FAQ+العروض (قابل للإعداد/اختياري) · رابط «تحتاج مساعدة؟» بالدخول — + نواقص فرعية موثقة (مرفق صورة/وقت مفضل بالطلب، فلاتر طلباتي للضيف، تحويل محادثة لطلب+مرفقات الرسائل، تذكير الخروج المجدول، تصدير التقارير/التدقيق، تنبيهات LOW_AVAILABILITY/Revenue، sitemap+schema.org)
- كتبت التقرير الكامل في agent-ctx/A-s7.md (جداول التتبع الثلاثة + الإحصاءات + قائمة الغائب + خلاصة) — صفر تعديل على أي ملف كود

Stage Summary:
- S7 مكتمل: 72 صف تتبع بأدلة موضعية — 77.8% منفذ أو منحرف بقرار موثق، وكل التأجيلات (8) بأقسام صريحة في MASTER_PLAN
- عيب جوهري وحيد مرشح MAJOR: غياب «تعديل الحجز المؤهل» من الموقع بلا قرار مؤجل مسجل (سقط من الخطة الحاكمة بعد أن كان Journey C كاملة بالخطة الأصلية) — توصيته للمالك: قرار موثق (تأجيل أو تنفيذ)
- نواقص فرعية (MINOR غالبًا): بريد/FAQ/عروض/مساعدة بالدخول/مرفقات وتصدير — كلها موثقة بموضع البحث في التقرير
- لا تغييرات على الكود أو البيانات (مهمة قراءة فقط) — المخرجان: agent-ctx/A-s7.md + هذا القسم

---
Task ID: 23
Agent: Main Agent (Z.ai Code)
Task: استكمال التدقيق الشامل الحي من نقطة توقف الجلسة السابقة (أدلة EV-002..018 مجموعة بلا تقرير) → إكمال الفحوص الحية الناقصة + التقرير النهائي الموحد (§12) + الدفع

Work Log:
- [بيئة] القاعدة مُسحت مجددًا بإعادة تهيئة الحاضنة (ثالث مرة) → استعادة بالمسار الرسمي (migrate reset --force + seed) → تحقق حي: hotel 200 · A371849L9 يعيد token · realtime 3002 polling 200
- [S1-S3 طازجة] lint exit 0 · bun run test 165/165 (124+7+34) exit 0 · migrate status «Database schema is up to date!»
- [6.1] الرئيسية كاملة بلا أخطاء console (EV-019) · سلبيات API: معكوس 400 «تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول» · ماضٍ 400 · فارغ 400 · UI تصحح بصمت (LIVE-01 INFO — الخادم يحمي)
- [6.2] كود خاطئ ×5 → 400 · السادسة → 429 «محاولات كثيرة جدًا… بعد 60 ثانية» · بعد النافذة الدخول الصحيح 200 (قيد المعدل 5/د يعمل حيًا)
- [6.8] 375/768/1440: صفر فيض أفقي (scrollWidth مطابق للعمود) + تذييل تدفق طبيعي (EV-019/020/021)
- [6.9] فاتورة خالد يدويًا: 3×16000=48000 · ضريبة 7200=15% · رسوم 6500 · رصيد 31700=61700−30000 ✓ · حجز 000008: علاوة نهاية أسبوع 1600 + ضريبة 2640 محسوبة خادميًا (I6) ✓
- [I9 حيًا] حجز بأساس 8000 → رفع المدير إلى 9500 → الاستعلام يعرض subtotal 16000/grand 18400 (اللقطة ثابتة) ✓ — ملاحظة LIVE-03 INFO: حقل roomType.basePriceCents يعرض الجاري
- [I1/I7 حيًا] حجز آخر غرفتي المفردة (roomsCount=2) → محاولة إضافية → 409 «الغرفة لم تعد متاحة لهذه التواريخ…» ✓
- [I8 حيًا] replay بنفس idempotencyKey → replayed:true بنفس الحجز دون تكرار ✓ · lookup بهاتف خاطئ → 404 لا يكشف الوجود ✓
- [6.6 حيًا] جلستان عبر البوابة :81: تغيير إدارة لحالة 101 → لوحة استقبال تحدثت بلا تفاعل (EV-023/024) · حجز موقع جديد → إشعار فوري + عداد 5→6 (EV-025) · chat ثنائي (EV-017 موجة سابقة)
- [I12 حيًا] قائمة حالة الغرفة بالإدارة بلا خيار «مشغولة» إطلاقًا
- [إفلات زائفين موثقين] فشل حجز ظاهري = خطأ كتابي للمدقق في معرف النوع (3fbb/3fbf) — أعيد بمعرف ديناميكي فنجح · delivered:false = وصول مباشر على :3000 بتجاوز البوابة (LIVE-02 INFO)
- [6.10] كتابات مدمّرة (4 حجوزات + إلغاء + replay + تغيير سعر مع استرجاعه + حالات غرفة) → الاستعادة النهائية: reset+seed → reservations=5/guests=5/audit_logs=8 + 200/200/200
- [المخرج] AUDIT_REPORT.md في جذر المستودع (14 قسمًا حرفية): الحكم الكلي + جدول الإصابات (0 CRITICAL / 3 MAJOR: MOB-01 APK متقادم، DEP-01 ترقية next، REQ-01 تعديل الحجز / 2 MINOR / 8 INFO) + S1-S8 + 6.1-6.10 + مصفوفة الأبعاد بلا بُعد فارغ + I1-I12 ثابتًا-ثابتًا + التوصيات المرتبة + إقرار النزاهة + ملحق الأدلة EV-001..025

Stage Summary:
- التدقيق الشامل الحي مكتمل وموثق بالكامل: التقرير النهائي AUDIT_REPORT.md جاهز للمالك — النظام سليم وظيفيًا (الثوابت 12/12 قائمة، 3 منها حية اليوم) والعيوب الثلاثة الكبرى قرارات نشر/أمن/متطلبات لا أعطال كود
- أدلة جديدة: EV-019→EV-025 + كل الأوامر الحية قابلة للإعادة مضمنة في التقرير
- صفر تعديل على كود المشروع — الاستعادة النهائية للقاعدة منفذة ومثبتة بالأرقام
---
Task ID: 24-b
Agent: Docs Sub-Agent (F8 Store Kit)
Task: كتابة سياسة الخصوصية (PRIVACY_POLICY.md) + حزمة تقديم المتاجر (STORE_SUBMISSION.md)

Work Log:
- قرأت ذيل worklog.md (آخر الحالة: Task 23 التدقيق الحي مكتمل — F1/F2/F4/F5/F6 مقفولة · F3 مؤجلة بقرار · F7 معلقة مسؤولية المالك · F8 هذه المهمة) + MASTER_PLAN §6.7–6.10 (F6/F7/F8/بوابة المتجر) و§160–260 (مرحلة F كاملة)
- جمعت الحقائق من الملفات بنفسي (لا من الذاكرة): pubspec (cairo_heart_hotel v1.0.0+1) · build.gradle (applicationId=com.cairoheart.aden · minSdk 23 · flavors dev/prod · versionCode/Name من pubspec) · AndroidManifest (إذن INTERNET فقط + queries PROCESS_TEXT قياسي — صفر أذونات حساسة) · strings.xml (تسمية prod «فندق قلب القاهرة» / dev «قلب القاهرة DEV») · workflows الثلاثة وmobile-release تفصيلًا (workflow_dispatch + tags v* → وظيفة release «Build & publish signed APK» → توقيع من أسرار ANDROID_KEYSTORE_* → CairoHeartGuest-v{VERSION}-prod/dev.apk → GitHub Release بncipollo مع APP_VERSION من pubspec عبر dart-define) · codes.ts (H/R/A + 6 أرقام + حرفا تحقق + SHA-256 فقط) · مسارات api كاملة (public/auth/guest/reception/admin) · الجلسة 12 ساعة (SESSION_MAX_HOURS) · تبويبات الضيف الأربعة من guest_shell.dart · بيانات seed اتصالية (وضعتها جانبًا كبيانات عرض — استُخدمت عناصر قرار بدلها) · جلسة سبق البحث عن F7/بروتوكول/Task 24 (لا 24-a — بروتوكول F7 = معايير §6.8 نفسها)
- كتبت docs/PRIVACY_POLICY.md (94 سطرًا): 9 أقسام عربية كاملة + إصدار 1.0 بتاريخ 2026-09-05 — جدول البيانات المجموعة (اسم/هاتف · كود SHA-256 · إقامة/فوترة/مدفوعات نقدًا وP5 معلق · رسائل/طلبات · تدقيق · إعدادات الجهاز = لا شيء) + وصول الجهاز (INTERNET فقط + روابط wa.me/tel/mailto بضغط المستخدم) + لا مشاركة/لا Firebase (F3 معلق) + احتفاظ (سنتان محاسبة · تدقيق 12 شهرًا · جلسة تموت بالإبطال/الانتهاء) + حقوق + أمان (HTTPS/تجزئة/حد معدل 5 فشائل بالدقيقة/RBAC) + سجل تغييرات + فقرة إنجليزية موجزة تعلن العربية مرجعًا — 7 عناصر قرار مالك (اتصال/عنوان)
- كتبت docs/STORE_SUBMISSION.md (186 سطرًا): §1 جدول بوابة §6.10 (F1–F4 ✓ بدقة توثيق F3 مؤجلة بقرار · F5 ✓ · F6 ✓ · F7 التقويم الحي بمسؤولية المالك والبروتوكول جاهز §6.8 · العقد لم يُكسر ✓ → الخلاصة: جاهز إجرائيًا بعد شهادة أسبوعي F7) + §2 قائمة الحساب التجاري (D-U-N-S يُجهز مبكرًا · URL الخصوصية) + §3 نصوص القائمة العربية جاهزة للنسخ (اسم 22/30 حرفًا ✓ · مختصر 77/80 ✓ · كامل يشرح: حجز بلا حساب/كود عند الوصول/طلبات ومحادثة وفاتورة لحظيًا/استقبال وإدارة للطاقم · كلمات مفتاحية) + §4 إجابات Data Safety حرفية (نجمع اسم/هاتف لتشغيل الحساب/العمليات · لا نشارك · لا بطاقات · لا تتبع/إعلانات/تحليلات · تشفير نقل ✓ · حذف عند الطلب ✓) + §5 تقييم الجميع + إقرار رفع البيانات غير إلزامي + §6 Travel & Local و18+ + §7 جدول 8 لقطات (شاشة→ملف→المحتوى) بقاعدة الجهاز الحقيقي/APK من Releases/APP_VERSION + تنبيه MOB-01 (الإصدار المنشور v1.0.0+1+2 أقدم من F4/F5/F6 → يلزم إصدار جديد أولًا) + §8 App Store مؤجل (TestFlight أولًا · iOS بعد البوابة) + §9 الخطوات المرقمة مع قرار AAB الموثق (Play يطلب AAB والـCI ينتج APK — خطوة تحويل محفوظة بلا تغيير كود) + §10 جدول رفضات متوقعة وردودها الجاهزة + ملخص 7 عناصر قرار مالك
- التحقق: صفر تعديل على أي كود (الملفان في docs/ فقط) · حدود الأحرف مؤكدة برمجيًا (22≤30 · 77≤80) · كل رقم/اسم مستخدم موجود في الملفات (com.cairoheart.aden · 1.0.0+1 · v1.0.0+1+2 من AUDIT_REPORT) وما غاب وُسم [يُستكمل بقرار المالك: ...] (17 موضعًا)

Stage Summary:
- المخرجان: docs/PRIVACY_POLICY.md (v1.0 — 2026-09-05 — المصدر النصي للويب والتطبيق، 9 أقسام + ملخص إنجليزي) وdocs/STORE_SUBMISSION.md (حزمة F8 كاملة: بوابة/حساب/نصوص/Data Safety/تقييم/استهداف/لقطات/App Store/خطوات/رفضات)
- الخلاصة التشغيلية: التقديم جاهز إجرائيًا 100% ورقيًا — البوابة تنتظر شهادة أسبوعي F7 فقط؛ وقبله قراران تقنيان للمالك: URL الخصوصية العام + خطوة AAB في mobile-release (متطلب Play للتطبيقات الجديدة — CI ينتج APK حاليًا)
- عناصر قرار المالك المجمعة (7): بيانات الاتصال/العنوان · URL الخصوصية · نوع حساب Play + D-U-N-S + السجل التجاري · تنفيذ AAB + Play App Signing · أيقونة 512 · بلدان النشر وقرار iOS · شهادة F7
---
Task ID: 24-a
Agent: Docs Sub-Agent (F7 Dogfooding Kit)
Task: كتابة بروتوكول التجربة الداخلية F7 (DOGFOOD_PLAN.md) + قائمة الإصلاح المُدارة (DOGFOOD_FINDINGS.md)

Work Log:
- قرأت ذيل worklog.md (آخر حالة: Task 23 التدقيق الشامل الحي مكتمل — AUDIT_REPORT.md جاهز، 0 CRITICAL / 3 MAJOR: MOB-01 APK متقادم، DEP-01 ترقية next، REQ-01 تعديل الحجز)
- قرأت MASTER_PLAN.md: القسم 3 كاملًا (AD-01..AD-10 — خصوصًا AD-09 اختبار الانحدار وAD-10 فصل بيانات العرض) + §6.8 (F7) + §6.10 (بوابة المتجر) + §8 (المرحلة P: P2 انضباط البيانات وP4 Runbook) للسياق
- استعرضت mobile/lib/screens/ (الأوضاع الثلاثة كاملة: ضيف F1/F2 + استقبال F4: arrivals/inhouse/departures/requests/rooms/search/wizards + إدارة F5 بأقسامها الـ11) وsrc/components/ (website/guest/reception/admin) — لمس كل سيناريو بالشاشات الفعلية الموجودة
- تحققت من واقع الأكواد في src/lib/codes.ts (بادئات H/R/A + 6 أرقام + حرفا تحقق + SHA-256 خام لا يُخزن) ومن غياب scripts/ (السكربتان purge-demo/smoke جزء من طقم F7 يوثقان كقرارَي ما قبل اليوم صفر مع قاعدة: غيابهما يوم صفر = بند SEV-2 حاجب)
- كتبت docs/DOGFOOD_PLAN.md (181 سطرًا، 9 أقسام، 76 صف جدول): بطاقة البرنامج (أسبوعان لا تُختصر + الأدوار بلا أسماء + أدوات ويب/APK/أكواد H/R/A) · قرارات ما قبل اليوم صفر الخمسة (مسح AD-10 + أكواد طاقم حقيقية R/A خام مرة واحدة + smoke اليومي + قناة الإبلاغ + إصدار APK جديد من main بمرجع MOB-01 من AUDIT_REPORT) · جدول 14 يومًا بيوم بمعايير فحص حرفية (يوم 5: رصيد بالسنت وموت الكود · يوم 8: دوران الأكواد وإبطالها · يوم 11: مسار المال كاملًا · يوم 12: اليوم السلبي 429/عزل البيانات/تجديد الجلسة) · تصنيف SEV-1/2/3 (SEV-1 يوقف البرنامج حتى إصلاح + انحدار AD-09 + قرار استئناف موثق؛ الشك يصنف من الأعلى) · قاعدة AD-09 الحرفية بشرطيها (يفشل قبل الإصلاح وينجح بعده وإلا فالبند لا يغلق) · الإيقاع اليومي/الأسبوعي (smoke صباحًا + مراجعة DOGFOOD_FINDINGS مساءً + قرار صريح أسبوعيًا) · معايير الخروج الحرفية من §6.8 مفككة إلى 5 معايير فحص + قاعدة إعادة النافذة النظيفة بعد SEV-1 · جدول الجهة المسؤولة بصراحة أن التقويم الحي خارج نطاق البيئة · الروابط الداخلية (FINDINGS/RUNBOOK/RESTORE_DRILL/CONTRACTS)
- كتبت docs/DOGFOOD_FINDINGS.md (66 سطرًا): قواعد الاستخدام الثمانية (يُفتح فور الاكتشاف، لا يُحذف أبدًا، يُغلق بدليل أو يُؤجل بقرار، الحالات الأربع فقط، التأجيل يُراجع أسبوعيًا) · قالب البند بأعمدته التسعة (DF-001 يتصاعد، الاختبار المرافق إلزامي لـ SEV-1/2 في مال/دومين) · لوحة حالة + جدول فارغ جاهز + صف مثال تعليمي واحد DF-000 معلَّم «مثال توضيحي — احذفه عند أول بند حقيقي» (مثال SEV-1 مالي بملف انحدار مرافق ليوضح مسار AD-09 كاملًا) · قسم سجل القرارات اليومية (تاريخ/اليوم/القرار/المرجع) بجدول فارغ
- صفر مساس بأي كود أو أي ملف غير الملفين أعلاه (الاختبارات والسكربتات المذكورة تُوثَّق كقرارات ولا تُنشأ هنا)

Stage Summary:
- المخرجان: docs/DOGFOOD_PLAN.md v1.0 (البروتوكول الحاكم لـ F7 بأسلوب الخطة: جداول + معايير قابلة للفحص) + docs/DOGFOOD_FINDINGS.md v1.0 (أداة التشغيل الحية الفارغة بقوالبها)
- أبرز قرارات البروتوكول: (1) أي SEV-1 يوقف البرنامج فورًا ولا استئناف إلا بإصلاح + اختبار انحدار AD-09 + قرار موثق، وبعده تُعاد نافذة الـ14 يومًا النظيفة من يوم الاستئناف — (2) قرار ما قبل اليوم صفر الخامس المضاف بأدلة: إصدار APK جديد من main (المنشور v1.0.0+1+2 ضيف فقط بلا حارس — MOB-01) — (3) غياب purge-demo/smoke يوم صفر = بند SEV-2 حاجب لا يبدأ به البرنامج — (4) التصنيف عند الشك من الأعلى، وحدود «مال/دومين» معرَّفة حرفيًا — (5) صراحة كاملة في جدول الجهة المسؤولة: التقويم الحي والتنسيق البشري خارج نطاق البيئة، والمنصة جهزت البروتوكول والقوائم
- الوثيقتان مرتبطتان ببوابة المتجر §6.10 (نجاح F7 بمعاييرها أحد شروطها الأربعة) ومرجعاهما الأعلى MASTER_PLAN v2.5 §6.8 — جاهزتان لاستهلاك المالك وطاقمه مع أول يوم صفر
---
Task ID: 24-c
Agent: Deploy/Docs Sub-Agent (Phase P Production Kit)
Task: حزمة الإنتاج P1–P7 (deploy/ + BACKUP_POLICY + MONITORING + RUNBOOK + SECURITY_CHECKLIST + PAYMENT_GATEWAY_DECISION + LAUNCH_PLAN + RESTORE_DRILL)

Work Log:
- قرأت ذيل worklog.md (آخر الحالة: Task 23 التدقيق الحي مكتمل + بالتوازي 24-a أدوات F7 و24-b حزمة F8) وقسم MASTER_PLAN §8 كاملًا (جدول P1–P7 + بوابة 8.8 + قبول كل خطوة)
- جمعت الحقائق التقنية بنفسي: package.json (build=standalone+نسخ static/public · start=NODE_ENV=production bun .next/standalone/server.js · db:deploy=migrate deploy) · Caddyfile الرملية (matcher query XTransformPort=* → localhost:{query} · الافتراضي → 3000 · header_up الرباعية حرفيًا) · realtime/index.ts (3002 عملاء عبر البوابة · 3004 emit على 127.0.0.1 فقط · SIGTERM نظيف · /health على 3004) · .env/.env.example (DATABASE_URL مطلق) · الهجرات (baseline + add_min_app_version) · rate-limit.ts (login 5/د + قفل 10 فشائل→15 د + lookup/cancel 5/د + avail 20/د + book 10/س + renew 10/د) · schema (sqlite · جدول Hotel بلا @@map والبقية snake_case) · use-socket.ts وsocket_service.dart (كلاهما /?XTransformPort=3002 — آلية البوابة موحدة للويب والجوال)
- تعارضات مع الواقع وُثِّقت وعولجت بأمانة: (1) **/api/health غير موجودة في الكود** — deploy.sh يحمل المتغير HEALTH_PATH=/api/health كما بالمواصفة مع تعليق صريح بالبديل العامل اليوم /api/public/hotel · فحص caddy الصحي معلّق كتعليق حتى تُضاف · MONITORING يوثق المصدرين (2) **مجلد scripts/ وrollbacks/ غير موجودين بالمستودع** — backup.sh/restore.sh/health-check.sh كُتبت بمحتوى حرفي كامل داخل وثائقها للإنشاء على الخادم (deploy/README §11) وrollbacks/last-good ينشئه deploy.sh (3) **scripts/purge-demo.ts غير موجود** — تحذير AD-10 في README/LAUNCH_PLAN يذكر المسار المخطط + البديل الموثق (إبطال أكواد العرض من الإدارة أو reset+seed قبل أول ضيف) (4) جدول Hotel بلا @@map → تصحيح استعلام التحقق إلى FROM Hotel
- أنشأت deploy/ (6 ملفات): Caddyfile.prod (نطاق {$DOMAIN} واحد · TLS تلقائي LE · matcher **XTransformPort=3002** حرفيًا كما الرملة لكن محصورًا بـ 3002 فقط أمنيًا — 3004 الداخلي لا يُمرَّر · HSTS 180 يومًا · فحص صحة اختياري معلّق بشرط توفر /api/health — **نجح caddy validate فعليًا: Valid configuration**) · systemd/cairo-hart-web.service (deploy · /opt/cairo-hart · EnvironmentFile=/etc/cairo-hart/env · ExecStart=/usr/bin/env NODE_ENV=production PORT=3000 bun .next/standalone/server.js مطابق لstart · Restart=always/3s · NoNewPrivileges+ProtectSystem=strict+ReadWritePaths=.next,db · After=network-online+realtime) · systemd/cairo-hart-realtime.service (المجلد mini-services/realtime · /usr/bin/env bun index.ts · نفس النمط · **Before=web** للترتيب) · deploy.sh (bash صارم · بلا أي سر · DOMAIN من env · last-good قبل pull ثم تحديثه عند نجاح الفحص · git pull --ff-only · bun install للجذر ولrealtime + prisma generate · migrate deploy من env · build · إعادة تشغيل الخدمتين · curl -fsS https://$DOMAIN/api/health ×3 · عند الفشل كتلة استرجاع حرفية git checkout $PREV_REV+بناء+تشغيل + ملاحظة الهجرات للأمام · **bash -n يمر**) · env.production.example (المتغيرات الأربعة بتعليقات عربية + إنذار /etc/cairo-hart/env بصلاحية 600 لا يدخل المستودع + ALERT_WEBHOOK/RCLONE_REMOTE اختياريان معلّقان) · README.md (دليل VPS جديد→موقع: 12 خطوة حرفية + sudoers محصورة systemctl cairo-hart-* wildcard مبررة + mkdir db (غير متتبع في git!) + seed مع تحذير AD-10 + cron + جدول مشاكل شائعة 10 صفوف + خريطة الحزمة)
- أنشأت docs/ (7 ملفات): BACKUP_POLICY.md (P2: ليلي 02:00 cron · sqlite3 wal_checkpoint(TRUNCATE)+.backup حرفيًا داخل backup.sh كاملًا بتحقق quick_check فوري · احتفاظ 7/4/6 · rclone اختياري · restore.sh كامل بشرط إيقاف الخدمات ونسخة أمان pre-restore · §6 يحيل إلى RESTORE_DRILL) · RESTORE_DRILL.md (13th ملف لحل الإحالة المعلقة في مهمتي وفي DOGFOOD_PLAN للوكيل الموازي 24-a: بروتوكول شهري بملف تجريبي + كامل كل 6 أشهر على المسار الحقيقي + جدول سجل فارغ هو مفتاح بوابة 8.8 + جدول معالجة الفشل) · MONITORING.md (P3: مصادر الحقيقة journalctl×2 + /api/public/hotel اليوم و/api/health هدفيًا + 3004/health · health-check.sh كامل كل 5 دقائق: صحة+رئيسية+3002 polling عبر البوابة حرفيًا+EIO=4+قاعدة+قرص<85% · تنبيه تغيّر الحالة فقط عبر ALERT_WEBHOOK أي قناة للمالك · **واتساب المشغل معلق بقرار W0 بلا مزود — موثق** · إيقاعات يومي/أسبوعي/شهري بأوامر · أرقام متوقعة: صحة<500ms · قاعدة<20MB/سنة) · RUNBOOK.md (P4: **6 بطاقات حوادث** كاملة (IC-1 لا استجابة · IC-2 قاعدة معطوبة→restore.sh · IC-3 **تسريب كود طاقم**: إبطال من الإدارة يقتل الكود+جلساته في معاملة واحدة (مطابق لمسار codes/revoke الفعلي) + فورًا مراجعة audit_logs بتلك الفترة + قاعدة كودي إدارة + كود احتياطي مختوم · IC-4 realtime واقفة بفحص 3002/3004 والبوابة · IC-5 قرص ممتلئ · IC-6 تحديث خاطئ→rollback) + روتين الطاقم (دور صحيح 1–30 يومًا حرفيًا من admin/codes · خام مرة واحدة · الإبطال يقتل الجلسات · قائمة استقبال يومية) + مسارات سرية (env 600 · لا سر بالمستودع · فحص git grep حرفي · تدوير) + تصعيد SEV-1/2/3 بالأدوار) · SECURITY_CHECKLIST.md (P6: 10 بنود أساسية+3 إسناد بعمود ✅ بالمستودع/🔲 على الخادم/👤 قرار مالك: HTTPS+HSTS · حدود المعدل بالقيم الحقيقية من الكود · أذونات env/قاعدة بأوامر · تحديث محسوب bun outdated/update+audit مع DEP-01 من AUDIT_REPORT · تدوير عند تسريب · مراجعة أكواد باستعلام حرفي · خارج الموقع · ufw 80/443 · SSH بمفاتيح) · PAYMENT_GATEWAY_DECISION.md (P5 مفتوحة عمدًا: السياق نقدًا بالفندق ومسار CARD يعتمد مزودًا · **7 معايير ملزمة** (عدن فعلًا · عملة واضحة · callback+verify · idempotency · لا حفظ بطاقات I2 · تكاليف · مراجع) · جدول مرشحين فارغ [يُستكمل بقرار المالك] + سجل قرار + **بند صريح لا تُبنى بوابة قبل قرار موثق** + ملحق الربط المستقبلي: checkout عند المزود→رد موقّع→verify خادمي→تسجيل بمرجع المزود يحترم Idempotency الحالي) · LAUNCH_PLAN.md (P7: قائمة إقلاع 8 بنود (P1–P4+تدريب منفذ+P6+F7 أسبوعين صفر SEV-1 مال/مصادقة+P5 بأي حال) · خطة تراجع (ويب: last-good+restore · **جوال: minAppVersion من F6 كحاجب** + GitHub Release مع MOB-01 موثقًا) · إطلاق ناعم 3 مراحل (ويب أسبوعان→تطبيق بعد بوابة المتجر→واتساب بقرار W مستقبلي) · قائمة يوم الإطلاق الحرفية (AD-10→أكواد حقيقية→نسخة يدوية أولى→مراقبة 48 ساعة كل ساعتين) · جدول Go/No-Go)
- تحققات نهائية: **bash -n deploy/deploy.sh = يمر** · **caddy validate deploy/Caddyfile.prod = Valid configuration** (والاختبار كشف أن الـ header_up الموروثة من الرملة تطلق تحذيرات unnecessary فقط — سلوك مطابق مقصود) · كل كتل bash المضمنة في الوثائق الأربع استُخرجت وbash -n مرت · فحص روابط داخلية آلي: كل docs/deploy المشار إليها من ملفاتي موجودة (وإحالة RESTORE_DRILL المعلقة في DOGFOOD_PLAN للوكيل 24-a أصبحت تشير لملف حقيقي) · git status: صفر تعديل على أي ملف متتبع — كل المخرجات ملفات جديدة فقط

Stage Summary:
- **13 ملفًا** (12 مطلوبة + RESTORE_DRILL.md لحل إحالة مزدوجة): deploy/ (Caddyfile.prod · systemd×2 · deploy.sh · env.production.example · README.md) + docs/ (BACKUP_POLICY · RESTORE_DRILL · MONITORING · RUNBOOK · SECURITY_CHECKLIST · PAYMENT_GATEWAY_DECISION · LAUNCH_PLAN)
- **التحقق الآلي:** bash -n deploy.sh يمر · Caddyfile.prod يعبر caddy validate فعليًا · كل السكربتات المضمنة (backup.sh/restore.sh/health-check.sh) صياغتها سليمة
- **3 تعارضات مع الواقع وُثقت بلا اختلاق:** /api/health غير موجودة (السكربتات تحمل البديل العامل /api/public/hotel بتعليق صريح) · مجلد scripts/ فارغ من المستودع (المحتوى الحرفي كامل في الوثائق للإنشاء على الخادم) · purge-demo.ts غير موجود (تحذير AD-10 يذكر المسار المخطط + البديل الموثق)
- المرحلة P صارت قابلة للتنفيذ من الورق: أي مشغل يتبع deploy/README.md من VPS فارغ، وكل ما بعده (نسخ/مراقبة/حوادث/إطلاق) له دليل حرفي — البوابة 8.8 تنتظر فقط التنفيذ الفعلي على الخادم وتدريب الاستعادة الموقّع في RESTORE_DRILL §4
- بنود قرار مالك مجمعة: DOMAIN الفعلي · وجهة rclone · قناة ALERT_WEBHOOK · توقيت ترقية next (DEP-01) · اختيار مزود الدفع (P5 مفتوحة بتصميم) · إصدار APK جديد قبل الاعتماد على minAppVersion (MOB-01)

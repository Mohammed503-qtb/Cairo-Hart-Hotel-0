# Task 5-c — وضع الاستقبال (Reception Mode)

## الوكيل
full-stack-developer

## العمل
وجدت بنية API + الواجهة مكتملة من وكيل سابق قُطع اتصاله قبل التحقق. مهمتي كانت التحقق الكامل وإصلاح العيوب:

### إصلاحات (ملفاتي: src/app/api/reception/** + src/components/reception/**)
1. **search/route.ts — خطأ 500**: استخدم `{ OR: variants.map(v => ({ contains: v })) }` كقيمة لحقل واحد (صيغة Prisma غير صالحة). أعدت بناء شروط البحث بمصفوفة OR مسطحة لكل حقل/تنويع حالة. اختبرت: عربي/مرجع/رقم غرفة/lowercase.
2. **dashboard/route.ts**: inHouseStays كان يعد ACTIVE فقط → أصبح IN (ACTIVE, CHECKOUT_REQUESTED) حسب المواصفة.
3. **dashboard-view.tsx — Hydration error (button داخل button)**: بطاقة الطلب المعلق كانت `<button>` تحوي زر «إدارة» — حوّلتها div[role=button] مع دعم لوحة المفاتيح.
4. **check-in-wizard.tsx + check-out-wizard.tsx — Hydration error (div داخل p)**: شريط خطوات المعالج كان `<div>` داخل DialogDescription (p في Radix) → صار `<span>` flex. أيضًا: تعطيل «متابعة» إن لم يكن الحجز CONFIRMED.
5. **rooms-view.tsx + room-dialog.tsx**: تغيير حالة الغرفة لم يكن يحدّث اللوحة (الاعتماد كان على socket فقط) → أضفت onChanged→bump فيُحدَّث فورًا. + وصف حوار دائم (إزالة تحذير aria-describedby).
6. **stay-detail-dialog / request-detail-dialog / payment-dialog**: وصف افتراضي أثناء التحميل (إزالة تحذير Radix).

### التحقق (كل المسارات + المتصفح)
- **curl**: كل GETs ‏200 (dashboard/arrivals/departures/inhouse/stays/requests/rooms/search/extension/room-change/notifications)؛ حالات سالبة: خروج برصيد → 400 مع balanceCents؛ تغيير غرفة مشغولة → مرفوض؛ check-in بنوع غرفة خاطئ → مرفوض.
- **dev server**: قُتل بـ OOM أثناء الاختبار → أُعيد تشغيله بـ `(setsid bun run dev &)` (كما في worklog) وعاد خلال ثوانٍ.
- **المتصفح (agent-browser)**:
  - دخول R492671M3 → لوحة الاستقبال KPI صحيحة (2/1/2/1 عاجل)
  - تسجيل وصول «أحمد محمد» (HTL-2026-000421): معالج 4 خطوات → غرفة 202 ديلوكس → **كود ضيف H334469T0** ظهر مرة واحدة → تحقق عبر POST /api/auth/validate ✓ ودخول فعلي به في تبويب جديد → تطبيق ضيف أحمد غرفة 202 مع إشعار الترحيب ✓
  - الطلبات: أُكمل «المكيف لا يبرد» العاجل بملاحظة → اختفى من المعلقة ✓
  - المغادرون: تسجيل خروج «نورا» — معالج 3 خطوات: دفعة نقدية $50 (الافتراضي = الرصيد) → الفاتورة مسددة → تأكيد نهائي (ما سيحدث) → نجاح؛ الغرفة 103 «تحتاج تنظيف» → بدء تنظيف → اكتمل → «متاحة» ✓
  - لوحة الغرف: 303 خارج الخدمة ✓ 106 تحتاج تنظيف ✓ بطاقات ملونة + Legend
  - المقيمون: وافقت على تمديد خالد ($184) → تاريخ الخروج تحدّث إلى 3 سبتمبر في تبويب الضيف + بند ROOM_EXTENSION في الفاتورة ✓
  - الإشعارات: Sheet بـ 15 إشعارًا + عداد غير المقروء ✓
  - **Realtime**: عبر البوابة (localhost:81) — emit إلى room reception يعيد delivered:true، وطلب ضيف جديد REQ-1004 ظهر في اللوحة تلقائيًا بلا تحديث. (ملاحظة: عبر localhost:3000 مباشرة لا يعمل websocket لأن Caddy على منفذ 81 — بيئة الاختبار المحلية فقط؛ preview المستخدم يمر بالبوابة ويعمل.)
  - صفر أخطاء console بعد الإصلاحات، موبايل 390×844 بلا overflow، skeleton + حالات فراغ + toasts كلها ظاهرة.
- **lint**: `bunx eslint src/app/api/reception src/components/reception` → exit 0 (الخطأ الوحيد في المشروع بملف use-socket.ts مشترك خارج ملكيتي).
- **dev.log**: بلا أخطاء runtime.

### استعادة بيانات العرض
بعد اكتمال الاختبارات شغّلت `bun prisma/seed.ts` — الحالة الابتدائية مستعادة ومتحققة: وصولان اليوم (أحمد عربون مدفوع + سارة غير مدفوعة)، مغادرة نورا $50، خالد مقيم مع تمديد معلق + طلب عاجل قيد التنفيذ، 106 تحتاج تنظيف، 303 خارج الخدمة. الكود التجريبي المولّد H334469T0 مات مع إعادة التهيئة (الكود الخام لا يُخزن).

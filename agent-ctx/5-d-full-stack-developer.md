# Task 5-d — وضع الإدارة (Admin Mode)

## الوضع عند الاستلام
وجدت عمل وكيل سابق مكتمل البنية (API + واجهة) لكنه **غير متحقق ومحتوي أخطاء حرجة**:
- `/api/admin/services` و `/api/admin/service-categories` ترجعان **500** (PrismaClientValidationError): `orderBy: createdAt` على نموذجين لا يملكان createdAt (Service/ServiceCategory)
- `services/[id]` DELETE يستخدم `_count.serviceRequests` — علاقة غير موجودة في المخطط (ServiceRequest.serviceId بدون relation)
- `service-categories/[id]` DELETE يستخدم `serviceRequests: { some: {} }` — غير صالح كذلك
- 22 خطأ TS: `const { staffName } = guard.auth` على union AuthContext (GUEST variant بلا staffName)

## الإصلاحات
1. `services/route.ts` + `services/[id]/route.ts`: orderBy → `[{sortOrder}, {name}]`، حذف createdAt من الاستجابات، DELETE يعدّ الطلبات عبر `db.serviceRequest.count({where:{serviceId}})`
2. `service-categories/route.ts`: orderBy ثابت + `_count` يعمل
3. `service-categories/[id]/route.ts` DELETE: عدّ الطلبات عبر معرفات خدمات القسم ثم `serviceId IN`
4. نمط `staffName` موحّد بكل 17 مسارًا: `guard.auth as Extract<AuthContext, { role: 'ADMIN' }>` (نفس نمط الاستقبال)
5. `dashboard/route.ts`: أضفت RESERVED إلى roomsByStatus (المواصفة تطلبها)
6. `admin-app.tsx`: SheetDescription للجرس و«كل الأقسام» (إزالة تحذيرات aria)
7. `types.ts`: حذف createdAt من ServiceAdmin

## التحقق (curl)
- 13 مسار GET كلها 200 بأرقام حقيقية (لوحة، فندق، أنواع، غرف، معدلات، خدمات، أقسام، طاقم، أكواد، حجوزات+تفاصيل، ضيوف، تدقيق، تقارير، إشعارات)
- سلبيات مقصودة: OCCUPIED يدويًا مرفوض، رقم غرفة مكرر رسالة عربية، taxPercent>100، اسم فارغ، endDate<startDate، كود ADMIN لموظف استقبال مرفوض
- معدل متداخل → `warning` يعاد والإنشاء يسمح
- توليد كود R499949IV لأحمد (3 أيام) → validate يعيد جلسة RECEPTION → إبطال → validate يرفض «تم إلغاء هذا الكود»

## التحقق (agent-browser)
دخول A371849L9: لوحة بأرقام حقيقية + مخططات (31 SVG)؛ tagline حُفظ وثبت بعد reload؛ إضافة «غرفة اقتصادية» $50 مع صورة؛ إضافة غرفة 107؛ 106→متاحة (أُعيدت DIRTY لاحقًا)؛ معدل «موسم رأس السنة» للديلوكس؛ خدمة «توصيل مطعم» $5؛ توليد كود R695693CP من الواجهة (الكود الخام كبير monospace + تحذير «لن يظهر مرة أخرى» + نسخ)؛ إبطاله بتأكيد؛ HTL-2026-000421 → لقطة السعر (3 ليالٍ، $480+$72=$552) + دفعة $276؛ التقارير والتدقيق يعرضان أفعالي؛ الجرس فيه «تم توليد كود استقبال جديد لـأحمد»؛ موبايل 390×844: **صفر overflow في كل الأقسام الإحدى عشرة**؛ صفر أخطاء/تحذيرات console؛ الوضع الداكن يعمل.

## ملاحظة للوكيل الرئيسي (خارج ملكيتي)
- Hydration error قابل للاسترجاع في `src/app/page.tsx` (BootScreen `typeof window` branch) يظهر عند وجود جلسة persisted — لا يمكنني تعديله
- `src/hooks/use-socket.ts` خطأ lint react-hooks/refs موجود مسبقًا (ملف مشترك)

## بيانات العرض النهائية
- أُبقي (مسجلة): غرفة اقتصادية $50 + غرفة 107 (متاحة)، معدل موسم رأس السنة (ديلوكس 2026-12-20→2027-01-05 $180)، خدمة توصيل مطعم $5، tagline جديد، كودان ملغيان في سجل الأكواد (R4••••IV، R6••••CP)
- أُعيد: 106 → تحتاج تنظيف (حالة Seed)، تنظيف الغرفة أُعيد إنشاؤه بعد حذفه في اختبار (12 خدمة)

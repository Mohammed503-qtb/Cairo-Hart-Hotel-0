# Task 5-a — Website Public + Full Booking Engine
**Agent:** full-stack-developer
**Scope:** `src/components/website/**` + `src/app/api/public/**` (فقط — لا شيء غيرها)

## الوضع عند الاستلام
وجدت عمل وكيل 5-a السابق شبه كامل على القرص (API + مكونات الواجهة) لكن **بدون أي تحقق** وبدون سجل عمل، مع مشكلتين: خطأ Hydration في hero-section (p يحوي div/骨架) وسيرفر dev متوقف (قُتل بـ OOM). أكملت التحقق الكامل وأصلحت.

## الملفات (API — الخادم مصدر الحقيقة)
| الملف | الوظيفة |
|---|---|
| `src/app/api/public/_lib.ts` | مساعدات مشتركة: maskPhone، parseSnapshot، cancellationInfo، toReservationPublic/toHotelPublic/toRoomTypePublic |
| `src/app/api/public/hotel/route.ts` | GET — HotelPublic |
| `src/app/api/public/room-types/route.ts` | GET — الأنواع النشطة بـ sortOrder + parse amenities/images |
| `src/app/api/public/availability/route.ts` | POST — rate limit 20/د، validateStayDates، فلترة بالسعة، availableRoomCount، computeQuote، ترتيب بالسعر |
| `src/app/api/public/bookings/route.ts` | POST — rate limit 10/س، Idempotency (TTL 10د، in-memory)، $transaction (توفر داخلي + Guest upsert + nextBookingReference + snapshot + Payment CARD 50% + audit×2 + Notification)، emitEvent(RESERVATION_NEW) |
| `src/app/api/public/lookup/route.ts` | POST — 5/د، تحقق مرجع+آخر 9 أرقام هاتف، لا يكشف الوجود، snapshot + cancellation |
| `src/app/api/public/cancel/route.ts` | POST — سياسة مجاني حتى (الوصول−24س) وإلا رسوم ليلة، transaction + audit + Notification |

## الملفات (UI)
`website-view.tsx` (المنسّق) — `site-header.tsx` — `hero-section.tsx` — `search-widget.tsx` — `rooms-section.tsx` — `facilities-gallery.tsx` — `contact-footer.tsx` — `booking-dialog.tsx` (5 خطوات) — `manage-booking-dialog.tsx` — `print-confirmation.tsx` — `helpers.tsx`

## الإصلاح الذي أجريته في هذه الجولة
- `hero-section.tsx`: `<motion.p>` → `<motion.div>` (كان يحوي Skeleton/div → خطأ "p cannot contain nested div" + Hydration mismatch). بعد الإصلاح: صفر أخطاء console.
- إعادة تشغيل خادم dev 3000 (كان ميتًا بـ OOM) بطريقة تبقى حية بين الجلسات: `(setsid bun run dev &)`.

## نتائج التحقق (MUST-VERIFY)
- **lint:** 0 errors/0 warnings في ملفاتي (التحذير الوحيد في `src/hooks/use-socket.ts` — ملف مشترك لا أملكه، تركته).
- **API curl:** hotel/room-types/availability 200؛ bookings 201 (PAY_AT_HOTEL=UNPAID، CARD=PARTIALLY_PAID+Payment ONLINE 50%)؛ idempotency replay يعيد نفس HTL-2026-000006؛ lookup هاتف خاطئ=404 رسالة موحدة؛ cancel مزدوج=400 «لا يمكن إلغاء…»؛ التدقيق/الإشعارات/الدفعات تتحقق في DB (Prisma).
- **browser (agent-browser):**
  - RTL عربي (dir=rtl, lang=ar)، 21 صورة كلها محملة (0 broken)، الوضع الليلي يبدّل class=dark + localStorage.
  - ودجت البحث (اليوم→+2): نتائج مزدوجة/ديلوكس/جناح بأسعار صحيحة ($276/$368/$506)؛ مفردة مستبعدة (2 بالغين > سعة 1).
  - حجز كامل PAY_AT_HOTEL → **HTL-2026-000008** (سالم العمودي، $276، غير مدفوع) + طباعة التأكيد (مستند رسمي كامل) + نسخ المرجع (toast «تم النسخ»).
  - حجز CARD (5–7 سبتمبر، زيادة نهاية أسبوع 10% الجمعة/السبت: $132+$120) → **HTL-2026-000009** عربون $144.90، مدفوع جزئيًا.
  - إدارة الحجز: lookup بالمرجع+الهاتف → التفاصيل/اللقطة → إلغاء HTL-2026-000009 (مجاني — حتى 4 سبتمبر) → Badge «ملغي» + toast.
  - التذييل: بنية mt-auto صحيحة والمحتوى الطويل يدفعه طبيعيًا؛ موبايل 390×844: overflow=false، burger ظاهر؛ Lightbox: تنقل + أسهم كيبورد؛ Dialog تفاصيل الغرفة كامل.
  - dev.log: كل الطلبات 200/201 (الاستثناءات مقصودة: 404/400 اختبارات سلبية) + لا أخطاء runtime.
- **ملاحظة:** خطأ Hydration من `BootScreen` في page.tsx يظهر أحيانًا في أول تحميل بارد (سباق zustand-persist) — ملف لا أملكه ولا يمكنني تعديله، ولا يتكرر عند reload.

## قرارات تصميمية
- Guest upsert داخل الحجز بمطابقة آخر 9 أرقام (endsWith) للحفاظ على فرادة phone.
- رسوم الإلغاء = أول ليلة من snapshot × عدد الغرف (بدون ضريبة — خصم ليلة غرفة فقط).
- Idempotency cache تنظيف كسول عند كل نداء (بلا مؤقت).
- Toast للنسخ عبر navigator.clipboard مع fallback destructive toast.

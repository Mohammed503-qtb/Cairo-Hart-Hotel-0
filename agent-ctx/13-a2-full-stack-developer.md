# Task 13-a2 — full-stack-developer

**الملكية الصارمة**: ملفان فقط داخل `mobile/lib/screens/`:
- `stay/stay_screen.dart` (استبدال كامل — نقل guest-stay.tsx)
- `bill/bill_screen.dart` (استبدال كامل — نقل guest-bill.tsx)
+ هذا السجل. لم ألمس أي شيء آخر (لا home/services/requests/chat/notifications/actions ولا core/state/ui/models ولا pubspec/app/main ولا خارج mobile/).

## ما قرأته قبل الكتابة
- worklog.md من السطر 160 (H1/H2-a/H4-a/H3/H2-b/11/13-b) — خاصة قسم 13-b (الأفعال الأربعة جاهزة في actions.dart بتواقيع ثابتة).
- المراجع الويب حرفيًا: `src/components/guest/guest-stay.tsx` + `guest-bill.tsx` + `bits.tsx` (استرشاد) + `guest-context.tsx` (goRequests = setTab('services')+setServicesView('requests') · refreshStay يبتلع الأخطاء صامتًا والتبويب يعرض حالة الخطأ) + `guest-app.tsx` (بنية التبويبات).
- الواجهات الجاهزة: guest_store.dart (كل التوقيعات) · models/guest.dart (StayDetail/Stay/StaySnapshot/NightlyRate/GuestBill/ExtraCharge/PaymentEntry/ServiceRequestModel/HotelFull) · ui/widgets.dart · core/format.dart · core/api_client.dart (ApiError) · config.dart (AppConfig.baseUrl) · ui/theme.dart (AppColors).
- المستهلكون الحاليون: guest_shell.dart (IndexedStack: `StayScreen(store:)` و`BillScreen(store:)`) وhome_screen.dart للوكيل الموازي (`pushTabScreen(context, 'إقامتي', StayScreen(store: store))` — التوقيع الثابت محفوظ).

## stay_screen.dart — بنية النقل (1146 سطرًا)
- **الرحلة**: `bootstrapLoading && stayDetail == null` → LoadingView → `data == null || data.hotel == null` (شرط الويب `!data || !data.hotel`) → ErrorRetryView برسالة «تعذر تحميل تفاصيل الإقامة\nحدث خطأ في الاتصال — أعد المحاولة» مع onRetry = refreshStay (زره الحرفي «إعادة المحاولة» داخل الويدجت المشترك) → المحتوى داخل RefreshIndicator+ListView بpadding (16,16,16,96).
- **بطاقة غرفتك**: صورة roomType.images.first (بديل الويب الثابت `/images/room-deluxe.png`) عبر `Image.network('${AppConfig.baseUrl}$path', errorBuilder/loadingBuilder)` بارتفاع 176px (h-44) + تدرج from-black/70 via-black/10 + اسم النوع (white/80) + رقم الغرفة 30/800 أبيض LTR (dir=ltr في الويب) + شارة «الطابق N» white/20 — ثم InfoPill السرير/المساحة (bg-muted/50) + «مزايا الغرفة» بأيقونة ذهبية auto_awesome + Wrap شارات pill.
- **خط زمني الإقامة**: 3 عقد (الوصول منجز بعلامة صح خضراء · إقامتك الآن بعقدة primary بظل shadow-md وشارة «الآن» · الخروج المتوقع) بخط وصل مستمر على جهة البداية (border-r-2) — تواريخ العقد حرفية: «الخروج المتوقع: {formatDateAr} — حتى {checkOutTime}» و«{formatDateWithDayAr} — {remainingNights} ليلة متبقية/ليالٍ متبقية».
- **بيانات الحجز**: 4 InfoPill (مرجع الحجز LTR · «{adults} بالغ + {children} طفل» · «{nights} ليلة/ليالٍ» من data.nights · إجمالي الغرفة formatMoney بالسنت) + فقرة «طلبات خاصة عند الحجز: » فقط عند وجود نص + **جدول الليالي من snapshot** (شرط الويب: `snapshot != null && snapshot.nightly.isNotEmpty`): رأس (الليلة/السعر/السعر المعتمد) bg-muted/60 + صفوف (formatDateAr + formatMoney LTR + rateName) + تذييل (المجموع قبل الضريبة bold + formatMoney + «+ ضريبة {taxPercent}%») bg-muted/40.
- **معلومات الفندق**: «{name} — {city}» bold + العنوان + صف Wrap (هاتف primary LTR + «الدخول {time}» + «الخروج {time}» بأيقونة مائلة 45° تعكس Maximize rotate-45) + ExpansionTile «سياسات الفندق» بالبنود الخمسة (الإلغاء/الدفع/الأطفال/الحيوانات الأليفة/التدخين) — البند الفارغ يُحذف (Policy ترجع null في الويب).
- **طلباتي (آخر 3)**: زر «كل الطلبات» فقط عند وجود طلبات (شرط الويب) → push RequestsScreen (goRequests) · طلبات قيد التحميل وقائمة فارغة → SkeletonBox×2 (h-16) · فارغ → DashedNote «لا طلبات بعد — اطلب أي خدمة من تبويب الخدمات» · بطاقات مختصرة (عنوان + StatusChip.priority عاجل + «{reference} — {timeAgoAr}» + StatusChip.requestStatus) قابلة للضغط → RequestsScreen.
- سيمانتكس: عناوين الأقسام بcontainer+label منقولة من aria-label الويب (غرفة الإقامة/الخط الزمني للإقامة/بيانات الحجز/معلومات الفندق والسياسات/طلباتي الأخيرة) + alt الصورة.

## bill_screen.dart — بنية النقل (661 سطرًا)
- **الرحلة**: مثل الإقامة («تعذر تحميل الفاتورة\nحدث خطأ…» + refreshBill) — لا AppBar، RefreshIndicator، padding (16,16,16,96).
- **رأس الفاتورة**: AppCard بصبغة primary/5 + «فاتورة إقامتك» + «{stayReference} — الغرفة {roomNumber}» داخل Directionality ltr (مكافئ dir=auto: المرجع لاتيني أولًا) + دائرة إيصال 44px (bg-accent text-primary).
- **البنود**: جدول (البند/التاريخ/المبلغ) بأوزان 5/4/3 — صف إقامة الغرفة مميز bg-accent/40 («إقامة الغرفة ({roomNights} ليلة/ليالٍ)» bold + «يشمل الضريبة {formatMoney(roomTaxCents)}» + تاريخ checkIn من لوحة الضيف مع fallback اليوم كما في الويب + formatMoney(roomTotalCents) LTR bold) ثم صفوف extraCharges (description + label(chargeCategoryLabels, fallback: category) + formatDateAr + formatMoney). محاذاة المبلغ كما في الويب حرفيًا: الرأس text-end باتجاه الصفحة (RTL→يسار) والقيم dir=ltr text-end (يمين الخلية).
- **المدفوعات**: فارغ → DashedNote «لا مدفوعات مسجلة بعد» · وإلا بطاقات بفواصل (دائرة محفظة success/10 + label(paymentMethodLabels, fallback) + «{formatDateAr(createdAt)} — {recordedBy}» فقط عند وجوده + «+{formatMoney}» أخضر LTR).
- **الإجماليات**: بطاقة ملونة بإشارة الرصيد (balance > 0 → danger/30 حد + danger/5 خلفية · وإلا success — كما في الويب) + صفوف (إجمالي المستحقات / إجمالي المدفوع بلون success) + فاصل + «المتبقي» بخط 24/800 بلون الإشارة LTR + النص الحرفي («يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة» / «حسابك مسوّى — شكرًا لك 💛»). **صفر حسابات محلية** — كل قيمة من GuestBill.
- **زر الخروج**: FilledButton h-48 كامل العرض ذهبي (gold + #2A2110) — معطل رمادي عند `store.dashboard?.stay.status == 'CHECKOUT_REQUESTED'` بنصه الحرفي «طلب الخروج قيد المعالجة» · الاستدعاء: `showCheckoutSheet(context, store)` (من actions.dart — مكافئ openDialog('checkout')).

## المراجعة اليدوية (لا Flutter SDK بالبيئة — قصوى الدقة)
- توازن الأقواس برمجيًا بعد تجريد النصوص/التعليقات: stay 42/42 و388/388 و55/55 · bill 30/30 و216/216 و22/22 — ALL OK (أُعيد الفحص بعد كل تعديل).
- مطابقة كل توقيع/حقل مستهلك مع الكود الفعلي (store/models/widgets/format/actions/panels/requests_screen) — جدولة كاملة أعلاه.
- تدقيق lint: صفر print · صفر import غير مستخدم (تحقق برمجي لكل استيراد) · const على كل استدعاء قابل للثبات وبدون const متداخلة زائدة (unnecessary_const) · use_build_context_synchronously محروس بcontext.mounted بعد كل await · sort_child_properties_last (child/children دائمًا أخيرًا) · لا withOpacity (withAlpha فقط) · ألوان hex كاملة 8 أرقام · توقيعا البانيين الثابتان محفوظان حرفيًا.
- قرار تحوطي موثق: دائرة المحفظة بُنيت `SizedBox+DecoratedBox+Center` (كلها const مؤكدة) بدل `Container` لأن ثبات مُنشئ Container غير مضمون عبر إصدارات Flutter ≥3.24 (خطر ترجمة إن لم يكن const، أو lint إن كان) — نفس السلوك البصري تمامًا.
- dev.log (الويب): نظيف 200 — عملي لم يلمس الويب إطلاقًا.

## انحرافات الويب ↔ التطبيق (موثقة)
1. **goRequests**: الويب يبدّل إلى تبويب الخدمات بمنظر «طلباتي»؛ الـ Shell في Flutter يملك فهرس التبويب ولا يمكن لشاشة ابنة تغييره → `Navigator.push(RequestsScreen(store:))` — نفس تكيف الوكيل الموازي في home («متابعة طلباتي» = نفس goRequests).
2. **حالة الخطأ**: الويب EmptyState (صندوق متقطع بأيقونة وزر)؛ التطبيق ErrorRetryView المشترك (توأم WarningView في بقية الشاشات) بنصَي العنوان والتلميح الحرفيين وزر «إعادة المحاولة».
3. **سحب التحديث**: الويب بلا pull-to-refresh (تحديث عبر الأزرار فقط)؛ أُضيف RefreshIndicator وفق تعليمات المهمة — أخطاؤه تظهر توستًا برسالة ApiError الحرفية (عرف 13-b: mounted-guards) بينما الويب يبتلعها صامتًا والتبويب يعرض حالة الخطأ فقط عند غياب البيانات (مغطى أيضًا).
4. **Skeleton الافتتاحي**: الويب StaySkeleton (3 صناديق) وbill 3 صناديق؛ التطبيق LoadingView المشترك (عرف التطبيق وجولة المهمة المرسومة).
5. **SectionTitle بلا أيقونات**: الويب يعرض أيقونة ذهبية بجانب كل عنوان قسم؛ الويدجت المشترك `SectionTitle(text)` لا يدعم أيقونة (ملك الوكيل الرئيسي) — العناوين نصية كما في بقية التطبيق.
6. **هاتف الفندق**: الويب رابط `tel:` قابل للنقر؛ بلا url_launcher في pubspec (وحظر الحزم الخارجية) → يُعرض بأسلوبه البصري (primary + أيقونة + LTR) دون فتح المتصل.
7. **UrgentMark**: الويب شارة حمراء شفافة بأيقونة Zap؛ التطبيق StatusChip.priority (خلفية حمراء صلبة «عاجل») — عرف التطبيق الموحد في requests_list_view للوكيل الموازي.
8. **font-mono للمراجع والمبالغ**: تطبيق Cairo فقط (لا خط mono) → اكتفاء باتجاه LTR للمراجع اللاتينية والمبالغ.
9. **دقة city في العنوان**: الويب `{name} — {city}` قد يطبع undefined نظريًا؛ التطبيق null-safe (يعرض الاسم وحده إن خلت المدينة).
10. **أزرار تمديد/تغيير غرفة في الإقامة**: تحققت من المرجع — guest-stay.tsx لا يحوي أي زر فعل؛ الأزرار الأربعة في الرئيسية (ملك الوكيل الموازي) وزر الخروج في الفاتورة فقط → لم أستورد سوى showCheckoutSheet (المطلوب والموجود فعلاً في هاتين الشاشتين).

## نصوص عربية منقولة حرفيًا (جرد نهائي)
تعذر تحميل تفاصيل الإقامة · حدث خطأ في الاتصال — أعد المحاولة · إعادة المحاولة (زر الويدجت) · غرفتك · الطابق N · السرير · المساحة · N م² · مزايا الغرفة · خط زمني الإقامة · الوصول · إقامتك الآن · الآن · الخروج المتوقع (+ صيغتا التاريخ الحرفيتان + ليلة متبقية/ليالٍ متبقية) · بيانات الحجز · مرجع الحجز · الضيوف · N بالغ + N طفل · الليالي · ليلة/ليالٍ · إجمالي الغرفة · طلبات خاصة عند الحجز: · تفصيل الليالي (لقطة الحجز) · الليلة · السعر · السعر المعتمد · المجموع قبل الضريبة · + ضريبة N% · معلومات الفندق · الدخول T · الخروج T · سياسات الفندق · الإلغاء · الدفع · الأطفال · الحيوانات الأليفة · التدخين · طلباتي · كل الطلبات · لا طلبات بعد — اطلب أي خدمة من تبويب الخدمات —
تعذر تحميل الفاتورة · فاتورة إقامتك · ST… — الغرفة N · البنود · البند · التاريخ · المبلغ · إقامة الغرفة (N ليلة/ليالٍ) · يشمل الضريبة $… · المدفوعات · لا مدفوعات مسجلة بعد · الإجماليات · إجمالي المستحقات · إجمالي المدفوع · المتبقي · يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة · حسابك مسوّى — شكرًا لك 💛 · طلب تسجيل الخروج · طلب الخروج قيد المعالجة.

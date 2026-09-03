# Task 13-a1 — سجل الوكيل (full-stack-developer)
## شاشات تطبيق ضيف الجوال الأساسية: الرئيسية + الخدمات + صفيحة إنشاء الطلب + تفاصيل الطلب

**Task ID:** 13-a1 · **التاريخ:** 2026-09-02 · **الملكية:** `mobile/lib/screens/home/home_screen.dart` · `mobile/lib/screens/services/services_screen.dart` · `mobile/lib/screens/requests/new_request_sheet.dart` · `mobile/lib/screens/requests/request_detail_screen.dart` فقط (+ سجلاتي).

---

## 1. الملفات المستبدلة (كلها داخل ملكي)

| الملف | السطور | المرجع الويب (قُرئ حرفيًا قبل الكتابة) |
|---|---|---|
| `lib/screens/home/home_screen.dart` | 818 | `src/components/guest/guest-home.tsx` (+ bits.tsx لللافتات وguest-context.tsx للاسم وgoRequests) |
| `lib/screens/services/services_screen.dart` | 350 | `src/components/guest/guest-services.tsx` (+ bits.tsx لأيقونات الأقسام) |
| `lib/screens/requests/new_request_sheet.dart` | 270 | `src/components/guest/request-dialog.tsx` (G-05) |
| `lib/screens/requests/request_detail_screen.dart` | 427 | `src/components/guest/request-detail-dialog.tsx` (G-06) |

التواقيع الثابتة محفوظة حرفيًا: `HomeScreen({required this.store, required this.session})` · `ServicesScreen({required this.store})` · `Future<void> showNewRequestSheet(BuildContext, GuestStore, {ServiceItem? presetService})` (التوقيع الجديد المطلوب في نص المهمة) · `RequestDetailScreen({required this.store, required this.request})` (يستهلكه `requests_list_view.dart` كما هو).

**ملاحظة سياق مهمة:** الملفات الأربعة كانت موجودة بنسخة سابقة من تشغيل وكيل 13-a1 قُطِع قبل تسجيل أي worklog/agent-ctx (لا قسم 13-a1 في worklog عند بدئي). النسخ السابقة كانت جيدة بنيويًا لكن حملت انحرافين عن الويب (منتقي قسم في الصفيحة + توقيع showNewRequestSheet مختلف بـ RequestSheetPreset/onCreated). أعدت بناءها وفق نص مهمتي الحالي بالتوقيع المطلوب وحرفية الويب، واحتفظت بما كان مطابقًا.

## 2. القرارات الهندسية

1. **بلا منتقي قسم في صفيحة الإنشاء** (أهم قرار): request-dialog.tsx لا يملك أي منتقي — القسم يأتي دومًا من preset: من الخدمة (`s.categoryKey`) أو `OTHER` لطلب خاص. التوقيع المطلوب `{ServiceItem? presetService}` يؤكد ذلك (لا يمكن تمرير قسم حر). أزلت منتقي النسخة السابقة (كان انحرافًا). القسم يظهر **كعنوان الصفيحة** بتسميات الويب الأربع الحرفية (خدمات التنظيف/الصيانة/خدمات الضيافة/طلب خاص — احتياط «طلب خدمة»). تسميات الأقسام تُصدَّر من new_request_sheet (`requestCategoryLabels`) وتستهلكها شاشة التفاصيل كما كانت.
2. **onCreated في الويب → كشف الإنشاء بعد الإغلاق**: `refreshRequests()` يجري تلقائيًا داخل `store.createRequest` (مع refreshDashboard). التحويل لعرض «طلباتي» (`setServicesView('requests')`) ينفذه services_screen (ملكي): يقارن طول `store.requests` قبل/بعد `await showNewRequestSheet(...)` — يتحول فقط إذا نُشئ طلب جديد (نفس الشرط الفعلي في الويب).
3. **إلغاء بلا تأكيد**: نص المهمة قال «مع confirm كما في الويب»، لكن request-detail-dialog.tsx ينفذ `cancel` مباشرة عند الضغط (لا حوار تأكيد إطلاقًا). المرجع السلوكي الوحيد هو الويب (قاعدة المهمة رقم 1) وسابقة 13-b الانحرافية رقم 2 → طُبِّق سلوك الويب حرفيًا: الزر destructive ينفذ فورًا مع busy «جارٍ الإلغاء…».
4. **الأولوية في بطاقة التفاصيل**: تظهر كشارة «عاجل» (StatusChip.priority) في صف الحالة **فقط عند URGENT** — دلالة UrgentMark في الويب (الويب لا يعرض NORMAL أبدًا في أي مكان). عنوان AppBar = عنوان الطلب (موضع DialogTitle).
5. **Live-refresh لشاشة التفاصيل**: الويب يعرض لقطة ثابتة في الحوار؛ هنا ListenableBuilder على المخزن يجلب النسخة الحية بالمعرّف من `store.requests` (مع fallback للقطة) — فتتحدث الحالة/الخط الزمني/ظهور زر الإلغاء لحظيًا عبر Realtime (متسق مع F2 ويتفادى زر إلغاء يابسًا على طلب تغيّرت حالته أثناء العرض).
6. **رحلة الشاشات**: loading (LoadingView عند `bootstrapLoading && dashboard==null` — مقابل dashboardLoading الويب) → خطأ (ErrorRetryView بنصّي EmptyState الويب معًا، onRetry = `store.bootstrap()` — يبتلع الأخطاء داخليًا كابتلاع guest-context للويب) → محتوى. كتالوج الخدمات: skeleton (3× عنوان+بطاقتان) → فراغ («لا خدمات متاحة حاليًا») → أقسام. «طلباتي» عبر requests_list_view (skeleton → فراغ بزر «تصفح الخدمات» → بطاقات).
7. **Pull-to-refresh** (أمر المهمة): الرئيسية = refreshDashboard فقط؛ الخدمات = refreshServices + refreshRequests (بيانات العرضين). الأخطاء toast أحمر برسالة ApiError الحرفية مع mounted-guards.
8. **الإجراءات السريعة الستة** من QUICK_ACTIONS بنصوصها: طلب خدمة → `pushTabScreen('الخدمات', ServicesScreen)` (نسخة جديدة تبدأ على الكتالوج = setServicesView('catalog')) · محادثة الاستقبال → ChatScreen · تمديد/تغيير غرفة/خروج/ملاحظات → show*Sheet من actions.dart (13-b). «طلب الخروج» معطلة (Opacity 0.5 + onTap null) عند CHECKOUT_REQUESTED.
9. **«متابعة طلباتي»** (goRequests الويب = setTab('services')+setServicesView('requests')) → دفع `RequestsScreen` (شاشة الطلبات المستقلة الجاهزة) — التواقيع الثابتة لـ ServicesScreen لا تسمح بتمرير عرض ابتدائي، وstay_screen (الوكيل الموازي) يستخدم RequestsScreen نفسها، فاتُّبع النمط القائم.
10. **أرقام لاتينية LTR** (قاعدة المهمة 6): رقم الغرفة الكبير في الترحيب (كان مفقودًا في النسخة السابقة — الويب `dir="ltr"`)، مراجع الحجز/الطلبات، كل الأموال (formatMoney). RTL تلقائي في كل ما عدا ذلك.
11. **استهلاك جاهز الآخرين بلا تعديل**: SheetFrame/SheetLabel/sheetBusyIndicator/mirroredSendIcon (13-b) لصفيحة الإنشاء · GoldBanner/BalanceBanner/DashedNote/SkeletonBox (panels) للرئيسية والخدمات · pushTabScreen (tab_route) · requestsViewChildren/RequestsScreen (requests_list_view/requests_screen) · الأيقونات Material معادلة لucide (auto_awesome/build/room_service لsparkles/wrench/concierge-bell كbits.tsx).
12. **لا ترجمة محلية** (لا Flutter SDK في البيئة — تحققت): مراجعة يدوية ثلاثية: (أ) توازن أقواس برمجي بعد إزالة السلاسل/التعليقات — ALL OK للملفات الأربعة؛ (ب) مطابقة كل توقيع/حقل مستهلك مقابل الملفات الفعلية (store/widgets/format/models/sheet_frame/panels/tab_route/requests_list_view)؛ (ج) تدقيق lint: صفر print، صفر withOpacity (withAlpha فقط)، صفر import غير مستخدم (تحقق ملفًا ملفًا)، const حيث يمكن (شاملة const LinearGradient)، ألوان hex كاملة 8 خانات، child آخر وسيط، بانونيات const للودجت، use_build_context_synchronously محروسة بmounted بعد كل await، بلا حزم خارجية، بلا اختبارات.

## 3. النصوص المنقولة حرفيًا (جرد)

- **الرئيسية**: «مرحبًا {الاسم} 👋» · «رقم غرفتك» · «{النوع} — الطابق {N}» · «{n} ليلة متبقية/ليالٍ متبقية/آخر يوم اليوم» · «إقامتك حتى» · «تم إرسال طلب تسجيل الخروج» + «الاستقبال سيجهّز مغادرتك ويتواصل معك قريبًا — يرجى تسوية الرصيد إن وُجد.» · «لديك رصيد مستحق على الإقامة» (BalanceBanner) · «إجراءات سريعة» · «طلب خدمة/محادثة الاستقبال/تمديد الإقامة/تغيير الغرفة/طلب الخروج/ملاحظات» · «ملخص إقامتك» · «عرض التفاصيل» · «الضيوف/مدة الإقامة/مرجع الحجز/الرصيد المستحق» · «{n} بالغ + {n} طفل» · «{n} ليلة/ليالٍ» · «آخر الإشعارات» · «كل الإشعارات» · «لا إشعارات بعد — سنعلمك بكل جديد» · «لديك {n} طلب نشط/طلبات نشطة» · «متابعة طلباتي» · «تعذر تحميل بيانات الإقامة» + «حدث خطأ في الاتصال — أعد المحاولة» + «إعادة المحاولة».
- **الخدمات**: «الكتالوج» · «طلباتي» · «طلب خاص (خارج الكتالوج)» · «لا خدمات متاحة حاليًا» + «يمكنك دائمًا استخدام «طلب خاص» أو مراسلة الاستقبال» · «مجانًا ضمن الإقامة» · «طلب» · «لا طلبات بعد» + «اطلب أي خدمة من الكتالوج وستظهر هنا مع حالتها لحظة بلحظة» + «تصفح الخدمات» (الأخيرة داخل requests_list_view المشترك).
- **صفيحة الإنشاء**: عنوان = تسمية القسم (احتياط «طلب خدمة») · «يصل طلبك للاستقبال فورًا وسيتولى التعامل معه» · «عنوان الطلب» · «مثال: تنظيف الغرفة» · «تفاصيل إضافية (اختياري)» · «أضف أي تفاصيل تساعد الفريق...» · «الأولوية» · «عادي/عاجل» · «إلغاء» · «إرسال الطلب» · تحقق: «اكتب عنوانًا للطلب (3 أحرف على الأقل)» · نجاح: «تم إرسال طلبك»/«تم إرسال طلبك العاجل 🔔» + «يظهر الآن في «طلباتي» مع حالته لحظة بلحظة».
- **تفاصيل الطلب**: «الغرفة {N}» · «أُنشئ {منذ…}» · «المسند إلى: » · «سجل الطلب» · «بواسطة {الاسم}{ (أنت)}» · «إلغاء الطلب»/«جارٍ الإلغاء…» · نجاح: «تم إلغاء الطلب» + المرجع. حدود الحقول: العنوان 80 والوصف 500 وصفوف الوصف 3 (كالويب)، autoFocus للعنوان.

## 4. انحرافات ويب↔تنفيذ (موثقة بشفافية)

1. **confirm الإلغاء** (انظر القرار 3): نص المهمة ذكر confirm والويب لا يملكه → تَبِع الويب (سابقة 13-b رقم 2). إن أراد المالك إضافة تأكيد فهو قرار منتج بسيط (حوار واحد قبل `_cancel`).
2. **أخطاء الخادم**: تُعرض برسالة ApiError الحرفية وحدها، لا العناوين العامة للويب («تعذر إرسال الطلب»/«تعذر إلغاء الطلب» مع الوصف) — التزامًا بنص المهمة (منهج 13-b رقم 1 نفسه).
3. **زر إعادة المحاولة** يستدعي `store.bootstrap()` (إعادة التحميل الأولي كاملًا، فاشلُه صامت داخليًا) بدل refreshDashboard وحدها في الويب — أقرب لسلوك «التحميل الأولي» الكلي ويستفيد الأقسام التي لم تُحمَّل أصلًا.
4. **اسم الضيف**: ويب `session?.name ?? 'ضيف'` — عالجت الفراغ أيضًا («ضيف») لأن الجلسة المحفوظة قد تحمل اسمًا فارغًا.
5. **تحميل الرئيسية**: LoadingView مركزي بدل هيكل HomeSkeleton التفصيلي (دستور الودجت المشترك وقواعد المهمة)؛ كتالوج الخدمات/الطلبات تستخدم SkeletonBox كالويب.
6. **toast مركّب**: نجاح الويب بعنوان+وصف → سطران بفاصل «\n» في showAppToast (منهج 13-b نفسه).
7. **تحويم/حركات motion**: انتقالات framer-motion غير منقولة (لا مكافئ مباشر بلا حزم) — البنية والألوان مطابقة.
8. **عنوان صفيحة الإنشاء** يظهر بأيقونة ذهبية عبر SheetFrame (نمط 13-b للحوارات) بدل نص DialogTitle الأجرد — اتساقًا مع بقية حوارات التطبيق؛ النص نفسه نص الويب.

## 5. ملاحظات للوكيل الرئيسي / الوكلاء المجاورين

- **تبعيات خارج ملكيتي (موجودة ومطابقة، لم ألمسها)**: home → `requests/requests_screen.dart` («متابعة طلباتي»)؛ services → `requests/requests_list_view.dart` («طلباتي» المشتركة). كلاهما يستهلكه stay_screen أيضًا. إن حُذفا مستقبلًا فتكسير الترجمة سيظهر في home/services — التوافق الحالي محفوظ بالتواقيع أعلاه.
- **`requestCategoryLabels` مصدرها new_request_sheet** (ملكي) وتستوردها request_detail_screen بـ `show` — إن نُقلت مستقبلًا إلى core فبلا كسر.
- **طلبات لم أستخدمها**: `shared/room_image.dart` (موجود، guest-home بلا صور — لم ألمسه) وstore.stayDetail/bill (تخص إقامتي/الفاتورة).
- **guest_shell.dart لا يزال يستورد actions/actions.dart دون استدعاء** (نبّه إليه 13-b) — ملك صاحبه؛ الربط الفعلي للأفعال صار في home (ملكي) فالاستخدام قائم في التطبيق لكن ليس في guest_shell نفسه.
- مواقع قد يريدها المالك لاحقًا: Skeleton shimmer مشترك، وانتقالات صفحات خفيفة — كلاهما تحسينات عرض لا سلوك.
- الخادم حي طوال العمل (dev.log آخره 200 على public/hotel وroom-types) ولم ألمس شيئًا خارج mobile/lib/screens/{home,services,requests} + السجلات.

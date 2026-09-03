# Task 20-b — F4-b (الحزمة الثانية من F4-b): الطلبات + تفصيل الطلب + لوحة الغرف + البحث (Flutter)

Agent: full-stack-developer
Scope: نقل حرفي لـ `requests-view.tsx` + `request-detail-dialog.tsx` + `rooms-view.tsx` + `room-dialog.tsx` + `search-dialog.tsx` من الويب إلى Flutter فوق الأساس الجاهز (models/reception.dart · state/reception_store.dart · reception_bits.dart · ui/* · core/*). صفر تعديلات على أي ملف موجود — ملفات جديدة فقط (لا worklog ولا pubspec ولا حزم).

## الملفات المُنشأة (9)

| الملف | السطور | الوصف |
|---|---|---|
| `mobile/lib/screens/reception/requests_screen.dart` | 422 | شاشة الطلبات (R-08): عنوان مع عدّاد + 9 رقاقات فلترة + صف «⚡ العاجل فقط» بمفتاح وشارة «{n} معلق» + بطاقات (bolt أحمر للعاجل المفتوح / room_service رمادي + حد أحمر للعاجل المفتوح) + skeletons/خطأ/فراغ |
| `mobile/lib/screens/reception/request_detail_screen.dart` | 808 | حوار تفصيل الطلب (R-09): العنوان (أحمر إن عاجل + دائرة bolt) + وصف الرأس + الخط الزمني بنقاط وخط واصل (primary/gold/success) + قسم «إجراءات الاستقبال» (ملاحظة + محدد فريق + خريطة ACTIONS الحرفية) + حوار تأكيد الرفض/الإلغاء |
| `mobile/lib/screens/reception/rooms_screen.dart` | 778 | لوحة الغرف (R-10): دليل الألوان بعدّادات + أقسام طوابق + Wrap بطاقات 104×92 ملونة بحسب الحالة. وفيه **`_RoomDialog`** (R-11): رأس ببطاقة ملونة + بطاقة الضيف + الملاحظات بتحذير + الانتقالات الخمسة حسب الحالة + تأكيدا «اعتماد متاحة»/«خارج الخدمة» + «عرض الإقامة» |
| `mobile/lib/screens/reception/search_screen.dart` | 423 | حوار البحث العام (R-19): حقل عريض + **debounce 350ms (Timer يُلغى ويُنظف في dispose)** + حد الحرفين + هياكل تحميل + «الحجوزات (n)»/«الإقامات النشطة (n)» + فشل البحث → قوائم فارغة |
| `mobile/test/screens/reception/requests_screen_test.dart` | 197 | 3 اختبارات: بطاقة معلقة + فلتر افتراضي «المعلقة» / رقاقة «مكتمل» / مفتاح العاجل يخفي غير العاجل |
| `mobile/test/screens/reception/request_detail_screen_test.dart` | 282 | 4 اختبارات: العرض والخط الزمني / «استلام» بجسم {status:'ACKNOWLEDGED'} + توست / «إسناد» معطل→فريق→جسم assignedTo / «رفض» بتأكيد → {status:'REJECTED'} |
| `mobile/test/screens/reception/rooms_screen_test.dart` | 216 | 3 اختبارات: غرفتان بطابقيهما + الدليل / DIRTY→CLEANING بجسم وتوست حرفي / AVAILABLE→OUT_OF_ORDER مع notes بتأكيد |
| `mobile/test/screens/reception/search_screen_test.dart` | 244 | 3 اختبارات: حرفان+debounce→القسمان / أقل من حرفين → التلميح / نقر إقامة → فتح showStayDetail بجلب R-05 (بوهمي يجيب /api/reception/stays/st_9) |
| `agent-ctx/20-b-full-stack-developer.md` | — | هذا التقرير |

**مجموع**: 3370 سطرًا (8 ملفات كود) + هذا التقرير. **13 اختبار testWidgets جديدًا.**

## عقد الواجهة (مطابَق حرفيًا كما تبلّغ — مجمّد)

```dart
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, required this.store});
  final ReceptionStore store;
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.store});
  final ReceptionStore store;
}

Future<void> showRequestDetail(BuildContext context, {
  required ReceptionStore store,
  required String requestId,
});

Future<void> showReceptionSearch(BuildContext context, {
  required ReceptionStore store,
});
```

- الاسم العام الإضافي الوحيد: `kPendingRequestStatuses` (PENDING_SET) — عام كي تستورده شاشة 20-a أو القشرة إذا احتاجت نفس التعريف؛ لا تعارض أسماء مع أحد (كل البقية `_private` لكل ملف).
- **التحقق التكاملي مع 20-a تم فعليًا (لا نظريًا)**: ملف `stay_detail_screen.dart` هبط أثناء عملي ووقّعت `showStayDetail` بالعقد الحرفي نفسه — استدعاءاتي في rooms (زر «عرض الإقامة») وsearch (نقر إقامة/حجز له stayId) تترجم مباشرة. وبالمقابل 20-a يستدعي `showRequestDetail(context, store:, requestId:)` من ملفي (سطر 897 عنده) — الاعتماد المتبادل محسوم.
- حوار الغرفة يفتح تفصيل الإقامة عبر `onShowStay` مُعاد من سياق **الشاشة** (لا سياق الحوار): pop ثم push متزامنان في نفس رد النقر — نفس منوال RoomsView في الويب.
- درس الغرف/الطلبات: `initState` يعلّم `_loaded=true` مباشرة إن كان المخزن يحمل بيانات (bootstrap) وإلا يحمّل — العنوان «(n)» لا يظهر إلا بعد أول تحميل ناجح (نفس دلالة `requests !== null` في الويب).

## الانحرافات عن مرجع الويب (مع السبب)

1. **توست نجاح تحديث الطلب مدموج**: الويب توست بعنوان «تم تحديث الطلب ✅» ووصفه عنوان الطلب — `showAppToast` نص واحد → `'تم تحديث الطلب ✅ — {title}'` (فاصل —). الاختبار يستخدم `textContaining` فلا يتأثر. خطأ التحديث حرفي بلا إلحاق: «تعذر تحديث الطلب» error:true.
2. **خطأ الجلب في شاشتي الطلبات/الغرف**: الويب يعرض EmptyState بعنوان «تعذر التحميل» ورسالة الخادم subtitle **بلا توست** — نفس الحرفية هنا (بخلاف مغادرون 19-b التي توّست؛ هذه الشاشة لا تفعل). والخطأ مع بيانات قديمة يبقي القائمة أسفل الصندوق (كما الويب تمامًا: error يعلو، `requests!==null` تبقى قائمته).
3. **`urgent-pulse` (CSS نبض)**: أيقونة ثابتة بلا نبض (المواصفة سمحت: «نابضة→أيقونة فقط») — في دائرة العاجل ببطاقة القائمة وفي رأس الحوار.
4. **حد متقطع border-dashed** (صندوق «الطلب منتهٍ») → حد صلب عادي (لا dashed مبسط في Flutter بلا painter مخصص).
5. **شبكة الغرف**: `grid-cols-3 sm:4 md:6` → **Wrap ببطاقات عرض ثابت 104×92** (الخيار الذي سمحت به المواصفة) — نفس سلوك «عدد أعمدة حسب العرض» ويلتف مثل grid الويب.
6. **أزرار variant الويب → Flutter**: default→FilledButton · outline→OutlinedButton · destructive→Filled أحمر · secondary→Filled بخلفية surfaceContainerHighest، وزر COMPLETED (secondary + className bg-success) → secondary+success → Filled أخضر/أبيض. زر «متاحة» (secondary) وزر «عرض الإقامة» (secondary) بنفس النمط.
7. **محدد فريق الإسناد (Select w-36)** → `DropdownButton` داخل Container بحد، نفس القيم الثلاث والتلميح «اختر فريقًا»، يظهر فقط إن كان ASSIGNED ضمن الإجراءات (كما الويب).
8. **الخط الزمني** (ol بنقاط absolute على border-s-2): بناء `_TimelineEntry` — نقطة + خط واصل `Expanded` داخل `IntrinsicHeight`/stretch — نفس الشكل المرئي (نقطة أولى primary أكبر، تحديثات gold، اكتمل success). الترتيب والمحتوى حرفي.
9. **تلميح تعطيل الإسناد** (`title` في الويب) → `Tooltip(message: 'اختر الفريق أولًا')` حول الزر المعطل.
10. **debounce البحث**: Timer 350ms يُلغى عند كل تغيير ويُنظف في dispose (نفس useEffect/timeout). فشل البحث → `SearchResults` فارغة (catch الويب) — الطباعة «لا نتائج مطابقة» + «بحث عن «X»» حرفية.
11. **autofocus حقل البحث** بعد الفتح (الويب setTimeout 100ms → هنا autofocus مباشر).
12. **حوارا التفاصيل غير مستمعين للمخزن** (request/room يملكان حالتهما المحلية من القيمة المرجعة للعملية — الويب نفسه: setRequest/res.request). الحوار يفتتح بجلب refreshRequests (نفس load الويب) ثم يجد الطلب؛ «لم يتم العثور على الطلب» عند غيابه.
13. **حجم ملف الحوار 808 سطرًا** (فوق ~450): خريطة ACTIONS + الخط الزمني + بطاقة الإجراءات + زر لكل variant داخل ملف واحد إلزامي («حوار الغرفة في نفس الملف» نصًا في المواصفة + قيد ملفات F4-b) — غير قابل للتقسيم بلا ملفات إضافية ممنوعة.

## الأيقونات (كلها مؤكدة — تحققت بجلب `flutter/flutter/.../material/icons.dart` الرسمي + grep، وكلها أصلًا مستخدمة بنجاح في CI سابقة)

room_service_rounded · bolt_rounded · schedule_rounded · inbox_rounded (افتراضي EmptyState مقابل Inbox في الويب) · how_to_reg_rounded · person_add_rounded · play_arrow_rounded · pause_circle_rounded · check_circle_rounded · cancel_rounded · block_rounded · grid_view_rounded · bed_rounded · groups_rounded · event_rounded · warning_amber_rounded · cleaning_services_rounded · build_rounded · refresh_rounded · meeting_room_rounded · search_rounded · calendar_month_rounded · person_outline_rounded — **صفر استبدالات** (خريطة الويب→Flutter المفروضة طُبقت كما هي). Loader2 → `SizedBox(16,16,CircularProgressIndicator(strokeWidth:2))` كما في الخريطة.

## قرارات إضافية

- كل HTTP عبر ReceptionStore حصرًا (refreshRequests/setRequestStatus/refreshRooms/setRoomStatus/search) — صفر fetch في الشاشات.
- `withValues(alpha:)` فقط؛ صفر `print`؛ حرس `mounted`/`!mounted` بعد كل await؛ أزرار مادة بحد لمس ≥44 (نمط الثيم 48).
- المراجعة اليدوية الثلاثية المنفذة: (1) توازن أقواس برمجيًا لكل ملف (سكربت Python يقصّ السلاسل والتعليقات — كلها BALANCED)، (2) تدقيق كل import مستخدم فعلًا في كل ملف واحدًا-واحدًا (مذكور أعلاه)، (3) كل أيقونة مؤكدة ضد icons.dart الرسمي.
- الاختبارات بنمط MockClient لـ 19-b/Task 18: وهمي الطلب يجيب GET requests + POST status + **مسارات refresh الخمسة** (dashboard/departures/inhouse/requests/rooms)؛ وهمي الغرف يجيب rooms + rooms/[id]/status + الخمسة؛ وهمي البحث يجيب search + **stays/st_9 بشكل R-05 كامل** (لفتح showStayDetail)؛ `ensureVisible` قبل كل نقر زر داخل تمرير (نافذة 800×600)؛ `pump(400ms)` لعبور debounce ثم pumpAndSettle؛ تصريف مؤقتات SnackBar بنهاية كل اختبار مُتوِّست (`pump(4s)` + pumpAndSettle)؛ العدّ بالنصوص الحرفية لا byType.
- تفاصيل دقيقة في الاختبارات لتجنب الالتباس: «جديد»/«مكتمل»/«متاحة»/«خارج الخدمة» تظهر في رقاقات الفلتر/الدليل **و** الشارات معًا → findsNWidgets أو `.last` (زر الحوار فوق الدليل خلفه) أو نصوص عناوين فريدة؛ «إسناد» exact-match لا يلتقط «إسناد إلى:».
- تحقق تكاملي مع 20-a (ملفاته هبطت أثناء عملي): showStayDetail بنفس التوقيع المجمد، وهو يستورد showRequestDetail من ملفي — لا دورة استيراد (request_detail_screen لا يستورد stay_detail_screen).

## ملاحظات للوكيل الرئيسي

1. **التركيب المتبقي عليك**: `reception_shell.dart` لم يُلمس (ملكك) — يلحق تبويبا «الطلبات» و«الغرف» + زر بحث (showReceptionSearch) وفق نمط تبويباتك الحالي. عقد الواجهة أعلاه جاهز للتركيب حرفيًا.
2. **CI**: لا Flutter SDK محليًا → analyze/test على GitHub Actions فقط (نفس وضع كل مهام الجوال). الملفات الثمانية كُتبت بمراجعة ثلاثية؛ انتبه جولة CI الأولى لأي `prefer_const`/تفاصيل نمط.
3. الويب لم يُلمس (dev.log: كل المسارات 200 طوال الجلسة — تغييري mobile/ فقط).
4. اقتراح مستقبلي صغير: عند أول تعديل مسموح للأساس، انقل `kPendingRequestStatuses` إلى models أو core كي تتشاركه شاشات 20-a (لو احتاجته) دون استيراد شاشة.
5. توقيت كتابة التقرير: 20-a كان ما يزال يكتب ملفاته لحظة مراجعتي الأولى (inhouse/stay_dialogs ثم stay_detail) — توثيقي أعلاه يعكس الحالة النهائية بعد هبوط stay_detail_screen.dart والتحقق المتبادل.

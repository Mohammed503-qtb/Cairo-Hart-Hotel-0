# Task 19-b — F4-a (الحزمة الثانية): مغادرون + معالج خروج + إشعارات الاستقبال (Flutter)

Agent: full-stack-developer
Scope: نقل حرفي لـ `departures-view.tsx` + `check-out-wizard.tsx` + `notifications-sheet.tsx` من الويب إلى Flutter فوق الأساس الجاهز (models/reception.dart · state/reception_store.dart · reception_bits.dart · ui/* · core/*). صفر تعديلات على أي ملف موجود — ملفات جديدة فقط.

## الملفات المُنشأة (7)

| الملف | السطور | الوصف |
|---|---|---|
| `mobile/lib/screens/reception/departures_screen.dart` | 316 | شاشة المغادرون (R-03): عنوان + شريط تاريخ + أقسام متأخرون/مستحقو اليوم + بطاقات + معالج الخروج |
| `mobile/lib/screens/reception/wizards/check_out_wizard.dart` | 748 | معالج تسجيل الخروج (R-07/R-12): 3 خطوات + نجاح + دفعة سريعة + حوار تأكيد الرصيد |
| `mobile/lib/screens/reception/reception_notifications_screen.dart` | 250 | شاشة إشعارات الاستقبال (R-22/R-23): تعليم تلقائي عند الفتح + زر تحديد الكل |
| `mobile/test/screens/reception/departures_screen_test.dart` | 165 | 3 اختبارات: قائمتان/فراغ/خطأ |
| `mobile/test/screens/reception/check_out_wizard_test.dart` | 307 | اختباران: المسار الكامل (دفعة→تأكيد) + مسار الرصيد confirmOutstanding=true |
| `mobile/test/screens/reception/reception_notifications_screen_test.dart` | 125 | اختباران: تعليم تلقائي عند الفتح + زر تحديد الكل |
| `agent-ctx/19-b-full-stack-developer.md` | — | هذا التقرير |

## عقد الواجهة (مطابَق حرفيًا)

```dart
Future<void> showCheckOutWizard(BuildContext context, {
  required ReceptionStore store,
  required String stayId,
});
```
- تحقق تكاملي مع الوكيل الموازي (19-a): `dashboard_screen.dart` يستدعي `showCheckOutWizard(context, store: store, stayId: d.stayId)` — التوقيع مطابق تمامًا، والقشرة (reception_shell) تركّب `DeparturesScreen(store:)` و`ReceptionNotificationsScreen(store:)` كما بنيتها.
- الاسم العام الآخر الوحيد الذي أضفته: `ReceptionNotificationsScreen`. لا تعارض أسماء مع 19-a (كل البقية خاصة `_private`).

## الانحرافات عن مرجع الويب (مع السبب)

1. **`_nightsBetweenIso` مساعد محلي في ملفّي الشاشتين** — `fmt.nightsBetween` يلحق `T00:00:00` بقيمة التاريخ (مصمَّم لقيم input `YYYY-MM-DD`)، بينما المغادرون/المعالج يمرّران ISO كاملًا (`2026-09-01T14:00:00.000Z`) → tryParse يفشل والناتج صفر دائمًا. المساعد المحلي ينسخ `nightsBetweenDates` في الويب حرفيًا (اقتطاع لمنتصف الليل + max(0, n)). كررته في الملفين (لا يمكن تعديل الأساس ولا إضافة ملف مشترك) ووثّقته بتعليق. **تنبيه للوكيل الرئيسي: أي شاشة أخرى تعرض ليالي من ISO كامل يجب أن تفعل المثل** (تحقّق من arrivals_screen 19-a).
2. **أيقونات غير موجودة في Icons** (تحققت بجلب `flutter/flutter/packages/flutter/lib/src/material/icons.dart` والgrep — لا Flutter SDK محليًا): `banknote_rounded` و`calendar_add_rounded` غير موجودين → استخدمت `payments_rounded` (نفس إشارة المواصفة "(payments icon)") لبطاقة الدفعة السريعة ونوع PAYMENT، و`event_rounded` لنوع EXTENSION (البديل الذي سمحت به المواصفة). باقي الأيقونات (flight_takeoff/alarm/check_circle/warning_amber/cleaning_services/key/room_service/chat_bubble_outline/receipt/done_all/notifications/info_outline + `_rounded`) كلها مؤكدة الوجود.
3. **زر «تسجيل الخروج» أسفل البطاقة (محاذاة نهاية) بدل عمود جانبي** — الويب يستخدم `flex flex-wrap` فيلتف الزر تحت المحتوى على العرض الضيق؛ التخطيط الحرفي (زر لاصق يمينًا بجانب النص) يفيض على 360dp. نفس المنطق لصفوف الأزرار داخل المعالج (`Wrap` بمحاذاة النهاية). زر «الفاتورة» محذوف مع التعليق الإلزامي `// زر الفاتورة يُضاف مع شاشة تفصيل الإقامة في F4-b`.
4. **بطاقة الدفعة السريعة عمودية** — المحدد الثلاثي (SegmentedButton بثلاثة نصوص عربية) + حقل المبلغ + زر التسجيل لا تتسع في صف واحد داخل حوار 312dp؛ وُزّعت: المحدد بعرض كامل ثم صف (حقل + زر). السلوك والقيم والتسميات حرفية.
5. **توست نجاح الدفعة بعد إعادة التحميل** — المواصفة طلبت الحقل `bool _paymentJustRecorded (track toast semantics)`؛ أعطيته دلالة حقيقية: يُضبط عند نجاح POST الدفعة ويُستهلك داخل `_reload` لعرض «تم تسجيل دفعة {طريقة} ✅» مرة واحدة بعد هبوط البيانات المحدّثة (نفس النتيجة المرئية للمستخدم خلال نفس الإطار، والصندوق الأخضر يظهر معه).
6. **صندوق تنبيه موحّد `_NoticeBox`** لصناديق (خطأ/رصيد غير مسدد/مسددة بالكامل) — إطار 0.40 موحّد (الويب: warning/50 للرصيد وdestructive/40 للخطأ) — فرق بصري غير ملحوظ مقابل توفير ~120 سطرًا.
7. **صف «الرصيد» في MiniBill** — التسمية 16/extrabold كما في الويب، لكن `MoneyText` (ملكية الأساس) بحجم ثابت 14/800 ملوّن؛ التمييز تحقق بحجم التسمية (لا يمكن تمرير حجم للMoneyText بلا تعديل الأساس).
8. **«تحديد الكل كمقروء» عبر `markVisibleNotificationsRead()`** — كما قررت المواصفة: نداء `markNotificationsRead([])` يرجع مبكرًا بلا POST، والمخزن غير قابل للتعديل. الفرق الدلالي الموثّق: الويب يرسل POST بجسم فارغ {} فيعلّم كل الإشعارات على الخادم، بينما هنا تُعلَّم المعروضة (آخر 30 = نفس المجموعة التي يحدّثها الويب تفاؤليًا في القائمة المعروضة). التحديث اللاحق للمخزن ينعكس على جرس القشرة تلقائيًا.
9. **حذف تعليق عدد الإشعارات** `«{n} إشعار (آخر 30)»` — تعريف المواصفة للشاشة لم يتضمنه (اتبعت المواصفة).
10. **الخطأ مع قائمة فارغة يستبدل الأقسام** (كما في الويب حيث `data=null` يخفي الأقسام) — خطأ التحديث مع بيانات قديمة يبقي القائمة + توست (سلوك أفضل للجوال).
11. **أعماق الاستيراد في wizards/**: قائمة imports في المواصفة (`../../ui/widgets.dart`...) لا تُحلّ من `screens/reception/wizards/` — استخدمت الأعماق الصحيحة `../../../` (مسار الملف الإلزامي له الأولوية).
12. **حجم الملف**: المعالج 748 سطرًا (فوق حد ~450) — قيد «ملف واحد فقط» + 3 خطوات + نجاح + 7 ويدجت خاصة يجعله غير قابل للتقسيم بلا ملفات إضافية ممنوعة.

## قرارات إضافية

- **ListenableBuilder يلفّ السكافولد/القائمة كلها** في الشاشتين حتى يتبع شريط التاريخ وشارة غير المقروء حالة المخزن (وليس جسم القائمة فقط).
- **RefreshIndicator** حول القوائم (وملفوفة الحالات الفارغة/الهياكل بListView بAlwaysScrollableScrollPhysics كي يعمل السحب) — نمط الجوال المعتمد.
- initState للمغادرون والإشعارات: تحميل ذاتي فقط عند الفراغ/الفتح (لا تصادم مع `store.bootstrap()` الذي يستدعيه app.dart).
- حواجس `mounted`/`context.mounted` بعد كل await؛ `withValues(alpha:)` بلا withOpacity؛ صفر print؛ تحقق توازن أقواس برمجي + تدقيق يدوي لكل استيراد مستخدم.
- الاختبارات: MockClient بنمط `api_client_test` (jsonRes) + توجيه بالمسار والطريقة؛ وهمي المعالج يجيب أيضًا للمسارات الخمسة التي يجدّدها `checkOut` (dashboard/arrivals/departures/rooms/notifications)؛ وهمي الإشعارات stateless (GET يعيد n_1 غير مقروء دائمًا) كي تبقى شارة «1 جديد» مرئية بعد pumpAndSettle كما تتوقع المواصفة؛ `ensureVisible` قبل كل نقر زر داخل المعالج (درس Task 18: أزرار أسفل ScrollView خارج 800×600 تفوّت hit-test)؛ لا تفاعلات مع منتقي التاريخ (لا locale بالاختبارات).
- تحقق من مطابقة الأسماء/التسميات العربية الحرفية سطرًا بسطر مقابل ملفات الويب الثلاثة.

## ملاحظات للوكيل الرئيسي

- لا Flutter SDK في البيئة → `flutter analyze`/`test` على GitHub CI فقط (نفس وضع كل مهام الجوال). المراجعة اليدوية الثلاثية (أقواس/استيرادات/أيقونات مؤكدة من مصدر Flutter الرسمي) هي الضمان المحلي.
- القشرة والملفات الثلاثة للوكيل 19-a موجودة الآن (arrivals/dashboard/check_in_wizard) — الحزمة مكتملة التركيب من جهتي، وصفر تعديلات خارج ملكيتي.
- خادم الويب لم يُلمس (dev.log: كل المسارات 200 طوال الجلسة).
- مقترح صغير مستقبلي: نقل `_nightsBetweenIso` إلى `core/format.dart` (مثل `nightsBetweenDates`) عند أول تعديل مسموح للأساس — سأزيل التكرار حينها.

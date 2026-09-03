# Task 20-a — F4-b (الحزمة الأولى): المقيمون + تفصيل الإقامة الكامل + حوارا الدفعة/البند (Flutter)

Agent: full-stack-developer (**تنبيه**: استجابة الوكيل فُقدت في مهلة نقل بعد إتمام كتابة ملفاته — هذا التقرير أعاد كتابته الوكيل الرئيسي بعد مراجعة تكاملية كاملة لكل ملف قدمه)

Scope: نقل حرفي لـ `inhouse-view.tsx` + `stay-detail-dialog.tsx` (كصفحة كاملة بـ 5 تبويبات — قرار الجوال) + `payment-dialog.tsx` + `charge-dialog.tsx` من الويب إلى Flutter فوق الأساس (models/reception.dart · state/reception_store.dart الموسَّع في F4-b · reception_bits.dart · ui/* · core/*). صفر تعديلات على أي ملف موجود — ملفات جديدة فقط.

## الملفات المُنشأة (7)

| الملف | الوصف |
|---|---|
| `mobile/lib/screens/reception/inhouse_screen.dart` | المقيمون الآن (R-04): بطاقة لكل إقامة (الاسم + شارة الحالة + مرجع + نوع) + صندوق الغرفة + شارات (خروج بأحمر إذا تاريخه ≤ اليوم بمقارنة ISO مقصوصة 10 + «n طلب نشط» + الرصيد الملوّن) + زر «التفاصيل» → showStayDetail |
| `mobile/lib/screens/reception/stay_detail_screen.dart` | تفصيل الإقامة (R-05) صفحة كاملة: رأس (الاسم + غرفة + الحالة + المرجع/النوع/الرصيد) + 5 تبويبات: الضيف (InfoCells + صندوق الحجز بلقطة سعر الليالي + طلبات خاصة) · الفاتورة (الأرصدة + البنود + المدفوعات + زرا الدفعة/البند — معطّلان عند CLOSED) · الطلبات (صفوف → showRequestDetail) · الرسائل (جلب كامل بfallback للمدمجة + إرسال + تمرير تلقائي) · الإجراءات (قرارات تمديد/تغيير غرفة + محادثة + تسجيل خروج) |
| `mobile/lib/screens/reception/stay_dialogs.dart` | حوارا الدفعة (يعيد balanceCents الجديد → توست النجاح بسطرَي الويب) والبند (فئة SERVICE/EXTRA/PENALTY + تحقق وصف ≥ 3 أحرف ومبلغ > 0 بالرسائل الحرفية) — كلٌّ يعيد true عند النجاح ليعيد المتصل التحميل |
| `mobile/test/screens/reception/inhouse_screen_test.dart` | قائمة/فراغ/خطأ |
| `mobile/test/screens/reception/stay_detail_screen_test.dart` | التبويبات الخمسة بمفاتيحها + جسم R-12 الحرفي بالتوست بالرصيد + قرار تمديد PENDING {approve:true} + إرسال رسالة {stayId,body} |
| `mobile/test/screens/reception/stay_dialogs_test.dart` | تحقق الدفعة/البند بالرسائل الحرفية + جسم البند |
| (هذا التقرير) | |

## عقد الواجهة (مطابَق حرفيًا — مجمّد)

```dart
class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key, required this.store});
  final ReceptionStore store;
}
Future<void> showStayDetail(BuildContext context, {
  required ReceptionStore store,
  required String stayId,
  String initialTab = 'guest', // guest|bill|requests|messages|actions
});
Future<bool> showPaymentDialog(BuildContext context, {required ReceptionStore store, required String stayId, required int balanceCents});
Future<bool> showChargeDialog(BuildContext context, {required ReceptionStore store, required String stayId});
```

## تحقق الوكيل الرئيسي (بعد فقدان الاستجابة — كل بند فُحص فعليًا)
- **العقود أعلاه** مطابقة سطرًا بسطر (بما فيها initialTab القيم الخمس بالتبويب الافتراضي guest).
- **الاستيرادات المتقاطعة**: stay_detail → request_detail_screen (20-b) + stay_dialogs + wizards/check_out_wizard — كل المسارات صحيحة ولا دورة استيراد (request_detail لا يستورد stay_detail).
- **نداءات المتجر** مطابقة لتواقيع reception_store.dart الموسَّع: loadStayDetail/recordPayment(يعيد int)/addCharge/decideExtension/decideRoomChange/loadStayMessages/sendMessage — لا HTTP محلي في أي شاشة.
- **`_nightsBetweenIso` محلي** في الملف (نفس درس 19-b الموثق: fmt.nightsBetween لقيم input فقط بينما R-05 يرسل ISO كاملًا).
- **توازن أقواس** برمجيًا: كل الملفات متوازنة. صفر print/withOpacity. أيقونات كلها مؤكدة ضد icons.dart الرسمي للـFlutter (شاملة تحقق مستقل ثانٍ من الوكيل الرئيسي لكل أيقونة جديدة).
- **التسميات العربية الحرفية** قورنت بالويب (توستات القرارات «تمت الموافقة على التمديد ✅»/«تم تغيير الغرفة ✅»/«تعذر البت في الطلب»، تحققات «أدخل مبلغًا صحيحًا أكبر من صفر»/«أدخل وصفًا للبند (3 أحرف على الأقل)»، «لا رسائل بعد — ابدأ المحادثة 👋»…).

## الانحرافات الملاحَظة عن مرجع الويب (موثقة هنا)
1. **الحوار → صفحة كاملة** (Navigator.push) بدل Dialog: 5 تبويبات بحوارات داخلية تتصادم على الجوال؛ قرار نمط جوال موثق (نفس نمط معالجَي F4-a الموجودين كحوارات مستقلة).
2. Enter لإرسال الرسالة غير منفَّذ (الويب: Enter بدون Shift يرسل) — زر الإرسال وحده؛ Textarea الويب سلوك سطح مكتب.
3. نقطة «الطلبات النشطة» الحمراء على تبويب الطلبات في الويب (dot) → معروضة كنص/شارة داخل التبويب نفسه (تفصيل ثانوي).
4. bubble-max-80% عبر LayoutBuilder (بدل max-w-[80%]).

## ملاحظات للوكيل الرئيسي (نُفِّذت بالفعل في مرحلة التكامل)
- القشرة رُكِّبت: 6 تبويبات + زر بحث + NavigationRail للواسع.
- زر «الفاتورة» أُضيف في بطاقتي المغادرين (الشاشة واللوحة) → showStayDetail(initialTab: 'bill').

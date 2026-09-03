// ─────────────────────────────────────────────────────────────
// TEST: معالج تسجيل الخروج — نقل check-out-wizard.tsx
// المسار الكامل (دفعة → تأكيد نهائي → نجاح) + مسار الخروج مع رصيد
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/wizards/check_out_wizard.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _decodeBody(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

/// شكل R-05 كامل (بالسنت) — الرصيد متغيّر لمحاكاة إعادة التحميل بعد الدفعة
Map<String, dynamic> _stayDetailJson(int balanceCents) {
  final paid = 55700 - balanceCents;
  return {
    'ok': true,
    'stay': {
      'id': 'st_1',
      'reference': 'ST-2026-000003',
      'status': 'ACTIVE',
      'checkInAt': '2026-09-01T14:00:00.000Z',
      'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
    },
    'guest': {'id': 'g_1', 'fullName': 'نورا سعيد', 'phone': '+967771234567'},
    'room': {'id': 'rm_1', 'number': '103', 'floor': 1, 'status': 'OCCUPIED'},
    'roomType': {
      'id': 'rt_1',
      'name': 'غرفة ديلوكس',
      'bedConfig': 'سرير مزدوج',
      'sizeSqm': 28,
    },
    'reservation': {
      'id': 'rsv_1',
      'bookingReference': 'HTL-2026-000003',
      'status': 'CHECKED_IN',
      'source': 'WEBSITE',
      'checkIn': '2026-09-01',
      'checkOut': '2026-09-04',
      'adults': 2,
      'children': 0,
      'roomsCount': 1,
      'currency': 'USD',
      'subtotalCents': 48000,
      'taxCents': 7200,
      'grandTotalCents': 55200,
      'paidCents': paid,
      'paymentStatus': balanceCents > 0 ? 'PARTIALLY_PAID' : 'PAID',
    },
    'bill': {
      'stayId': 'st_1',
      'stayReference': 'ST-2026-000003',
      'roomTotalCents': 55200,
      'roomSubtotalCents': 48000,
      'roomTaxCents': 7200,
      'extraCharges': [
        {'description': 'غسيل', 'amountCents': 500, 'category': 'SERVICE'},
      ],
      'extraTotalCents': 500,
      'payments': <Map<String, dynamic>>[],
      'totalChargesCents': 55700,
      'totalPaidCents': paid,
      'balanceCents': balanceCents,
      'currency': 'USD',
    },
    'requests': <Map<String, dynamic>>[],
    'extensionRequests': <Map<String, dynamic>>[],
    'roomChangeRequests': <Map<String, dynamic>>[],
    'messages': <Map<String, dynamic>>[],
  };
}

/// وهمي موحّد: stays/payments/check-out + القوائم التي يجدّدها checkOut
MockClient _wizardMock({
  required int Function() balance,
  required void Function(Map<String, dynamic> body) onPayment,
  required void Function(Map<String, dynamic> body) onCheckOut,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/reception/stays/st_1') {
      return jsonRes(_stayDetailJson(balance()));
    }
    if (path == '/api/reception/payments' && req.method == 'POST') {
      final body = _decodeBody(req);
      onPayment(body);
      return jsonRes({
        'ok': true,
        'payment': {
          'id': 'pay_1',
          'method': body['method'],
          'amountCents': body['amountCents'],
        },
        'paidCents': 55700,
        'paymentStatus': 'PAID',
        'balanceCents': 0,
      });
    }
    if (path == '/api/reception/check-out' && req.method == 'POST') {
      final body = _decodeBody(req);
      onCheckOut(body);
      return jsonRes({
        'ok': true,
        'closed': true,
        'roomNumber': '103',
        'balanceCents': 0,
      });
    }
    // القوائم التي يجدّدها store.checkOut بعد النجاح (_refreshAfterOperation)
    if (path == '/api/reception/dashboard') {
      return jsonRes({
        'ok': true,
        'stats': <String, dynamic>{},
        'arrivals': <Map<String, dynamic>>[],
        'departures': <Map<String, dynamic>>[],
        'pendingRequests': <Map<String, dynamic>>[],
      });
    }
    if (path == '/api/reception/notifications') {
      return jsonRes({
        'ok': true,
        'notifications': <Map<String, dynamic>>[],
        'unreadCount': 0,
      });
    }
    if (path == '/api/reception/rooms') {
      return jsonRes({'ok': true, 'rooms': <Map<String, dynamic>>[]});
    }
    if (path == '/api/reception/arrivals') {
      return jsonRes({'ok': true, 'arrivals': <Map<String, dynamic>>[]});
    }
    if (path == '/api/reception/departures') {
      return jsonRes({'ok': true, 'departures': <Map<String, dynamic>>[]});
    }
    return jsonRes({'ok': true});
  });
}

/// مضيف يفتح المعالج بزر (يوفر سياق showDialog)
class _WizardHost extends StatelessWidget {
  const _WizardHost({required this.store, required this.stayId});

  final ReceptionStore store;
  final String stayId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () =>
              showCheckOutWizard(context, store: store, stayId: stayId),
          child: const Text('افتح المعالج'),
        ),
      ),
    );
  }
}

Future<void> _openWizard(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(
    MaterialApp(home: _WizardHost(store: store, stayId: 'st_1')),
  );
  await tester.tap(find.text('افتح المعالج'));
  await tester.pumpAndSettle();
}

void main() {
  group('معالج تسجيل الخروج', () {
    testWidgets('المسار الكامل: دفعة سريعة ثم خروج نظيف', (tester) async {
      var balance = 5500;
      Map<String, dynamic>? paymentBody;
      Map<String, dynamic>? checkOutBody;
      final api = ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: _wizardMock(
          balance: () => balance,
          onPayment: (body) {
            paymentBody = body;
            balance = 0; // إعادة التحميل التالية ترى الرصيد مسددًا
          },
          onCheckOut: (body) => checkOutBody = body,
        ),
      );
      final store = ReceptionStore(api);
      await _openWizard(tester, store);

      // الخطوة 1: مراجعة الإقامة
      expect(find.textContaining('مراجعة الإقامة'), findsOneWidget);
      expect(find.textContaining('نورا سعيد'), findsAtLeastNWidgets(1));
      expect(find.text('ملخص الفاتورة'), findsOneWidget);
      expect(find.text('إجمالي الغرفة'), findsOneWidget);
      expect(find.text('بنود إضافية (1)'), findsOneWidget);
      expect(find.text('الرصيد'), findsOneWidget);

      await tester.ensureVisible(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // الخطوة 2: تسوية الرصيد — تحذير + دفعة سريعة بمبلغ معبأ بالرصيد
      expect(find.textContaining('تسوية الرصيد'), findsOneWidget);
      expect(find.textContaining('يوجد رصيد غير مسدد'), findsOneWidget);
      expect(find.text('دفعة سريعة'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller, isNotNull);
      expect(field.controller!.text, '55.00');

      // الزر قد يقع أسفل نافذة 800×600 — ensureVisible (درس Task 18)
      await tester.ensureVisible(find.text('تسجيل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل'));
      await tester.pumpAndSettle();

      // الدفعة سُجلت وأُعيد التحميل: صندوق «مسددة بالكامل» + توست
      expect(find.textContaining('تم تسجيل دفعة'), findsOneWidget);
      expect(find.text('الفاتورة مسددة بالكامل ✅ — لا رصيد مستحق'), findsOneWidget);
      expect(paymentBody, isNotNull);
      expect(paymentBody!['stayId'], 'st_1');
      expect(paymentBody!['method'], 'CASH');
      expect(paymentBody!['amountCents'], 5500);
      expect(paymentBody!['note'], 'تسوية عند الخروج');

      await tester.ensureVisible(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // الخطوة 3: التأكيد النهائي — بنود التأثير
      expect(find.textContaining('التأكيد النهائي'), findsOneWidget);
      expect(find.text('سيتم تنفيذ ما يلي:'), findsOneWidget);
      expect(find.textContaining('تحتاج تنظيف'), findsOneWidget);
      expect(find.textContaining('انتهاء صلاحية كود'), findsOneWidget);

      await tester.ensureVisible(find.text('تأكيد الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الخروج'));
      await tester.pumpAndSettle();

      // النجاح: closed + الجسم بلا confirmOutstanding
      expect(find.text('تم تسجيل الخروج ✅'), findsAtLeastNWidgets(1));
      expect(checkOutBody, isNotNull);
      expect(checkOutBody!['stayId'], 'st_1');
      expect(checkOutBody!['confirmOutstanding'], isFalse);

      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();
      expect(find.text('ملخص الفاتورة'), findsNothing);
      expect(find.text('تم'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar (توست الدفعة/الخروج) — Timer معلّق يفشل الاختبار
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('مسار الخروج مع رصيد غير مسدد (confirmOutstanding=true)',
        (tester) async {
      Map<String, dynamic>? checkOutBody;
      final api = ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: _wizardMock(
          balance: () => 5500, // الرصيد لا يُسدد أبدًا في هذا المسار
          onPayment: (body) => fail('لا دفعات في مسار الرصيد'),
          onCheckOut: (body) => checkOutBody = body,
        ),
      );
      final store = ReceptionStore(api);
      await _openWizard(tester, store);

      await tester.ensureVisible(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // زر الخروج مع الرصيد → حوار التأكيد الحرفي
      expect(find.text('تأكيد الخروج مع الرصيد'), findsOneWidget);
      await tester.ensureVisible(find.text('تأكيد الخروج مع الرصيد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الخروج مع الرصيد'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الخروج مع رصيد غير مسدد؟'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);

      await tester.tap(find.text('نعم، أكّد الخروج'));
      await tester.pumpAndSettle();

      expect(find.text('تم تسجيل الخروج ✅'), findsAtLeastNWidgets(1));
      expect(checkOutBody, isNotNull);
      expect(checkOutBody!['stayId'], 'st_1');
      expect(checkOutBody!['confirmOutstanding'], isTrue);

      // تصريف مؤقّت إخفاء SnackBar (توست الخروج الناجح)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

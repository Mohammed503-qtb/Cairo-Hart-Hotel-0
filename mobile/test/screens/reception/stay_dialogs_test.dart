// ─────────────────────────────────────────────────────────────
// TEST: حوارا الدفعة والبند — نقل payment-dialog + charge-dialog
// تحقق المبلغ الحرفي + تحقق الوصف + نجاح البند بجسمه الكامل
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/stay_dialogs.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

/// وهمي يلتقط بنود R-13 (الدفعة لا تُستخدم إلا عند النجاح في اختبار الشاشة)
MockClient _captureMock(List<Map<String, dynamic>> chargeBodies) {
  return MockClient((req) async {
    if (req.method == 'POST' && req.url.path == '/api/reception/charges') {
      chargeBodies.add(_body(req));
      return jsonRes({'ok': true, 'charge': {'id': 'ch_1'}});
    }
    if (req.method == 'POST' && req.url.path == '/api/reception/payments') {
      return jsonRes({'ok': true, 'balanceCents': 0});
    }
    return jsonRes({'ok': true});
  });
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

/// مضيف بزرين لفتح الحوارين عبر العقدين العامين
Future<void> _pumpHost(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () => showPaymentDialog(
                    context,
                    store: store,
                    stayId: 'st_1',
                    balanceCents: 5000,
                  ),
                  child: const Text('دفعة'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => showChargeDialog(
                    context,
                    store: store,
                    stayId: 'st_1',
                  ),
                  child: const Text('بند'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('حوارا الدفعة والبند', () {
    testWidgets('تحقق الدفعة: مبلغ غير رقمي → توست حرفي بلا POST',
        (tester) async {
      final charges = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_captureMock(charges)));
      await _pumpHost(tester, store);

      await tester.tap(find.text('دفعة'));
      await tester.pumpAndSettle();

      // الحوار مفتوح والمبلغ يبدأ بالرصيد (50.00) — أفسده نصًا
      expect(find.text('تسجيل دفعة'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'أبجد');
      await tester.pump();

      await tester.ensureVisible(find.text('تسجيل الدفعة'));
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();

      // التوست الحرفي والحوار ما زال مفتوحًا (لا نجاح)
      expect(find.text('أدخل مبلغًا صحيحًا أكبر من صفر'), findsOneWidget);
      expect(find.text('تسجيل دفعة'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('تحقق البند: وصف قصير → «أدخل وصفًا للبند (3 أحرف على الأقل)»',
        (tester) async {
      final charges = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_captureMock(charges)));
      await _pumpHost(tester, store);

      await tester.tap(find.text('بند'));
      await tester.pumpAndSettle();

      // وصف بحرفين فقط (أقل من 3)
      await tester.enterText(find.byType(TextField).first, 'مي');
      await tester.pump();

      await tester.ensureVisible(find.text('إضافة البند'));
      await tester.tap(find.text('إضافة البند'));
      await tester.pumpAndSettle();

      expect(find.text('أدخل وصفًا للبند (3 أحرف على الأقل)'), findsOneWidget);
      // لم يُرسل أي POST والحوار ما زال مفتوحًا
      expect(charges, isEmpty);
      expect(find.text('إضافة بند للفاتورة'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('نجاح البند: جسم {stayId,description,amountCents,category} + إغلاق',
        (tester) async {
      final charges = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_captureMock(charges)));
      await _pumpHost(tester, store);

      await tester.tap(find.text('بند'));
      await tester.pumpAndSettle();

      // الوصف أولًا ثم المبلغ (حقلا الحوار بالترتيب)
      await tester.enterText(find.byType(TextField).first, 'ميني بار');
      await tester.enterText(find.byType(TextField).last, '15.50');
      await tester.pump();

      await tester.ensureVisible(find.text('إضافة البند'));
      await tester.tap(find.text('إضافة البند'));
      await tester.pumpAndSettle();

      // جسم POST حرفي كامل
      expect(charges, hasLength(1));
      expect(charges.single['stayId'], 'st_1');
      expect(charges.single['description'], 'ميني بار');
      expect(charges.single['amountCents'], 1550);
      expect(charges.single['category'], 'SERVICE');
      expect(
        charges.single.keys,
        unorderedEquals(
          <String>['stayId', 'description', 'amountCents', 'category'],
        ),
      );

      // توست النجاح الحرفي والحوار أغلق
      expect(find.text('تمت إضافة البند للفاتورة ✅'), findsOneWidget);
      expect(find.text('إضافة بند للفاتورة'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

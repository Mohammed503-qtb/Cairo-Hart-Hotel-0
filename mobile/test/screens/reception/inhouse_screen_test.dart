// ─────────────────────────────────────────────────────────────
// TEST: شاشة المقيمون — نقل inhouse-view.tsx فوق ReceptionStore
// بطاقات (اسم/غرفة/رصيد) + حالة الفراغ + حالة الخطأ
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/inhouse_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _stay(String id, String guestName, String roomNumber) => {
      'id': id,
      'reference': 'ST-2026-00000$id',
      'status': 'ACTIVE',
      'checkInAt': '2026-09-01T14:00:00.000Z',
      // مستقبل بعيد → شارة الخروج ليست حمراء في اختبار العرض
      'expectedCheckOutAt': '2030-01-01T12:00:00.000Z',
      'guest': {'fullName': guestName, 'phone': '+967771234567'},
      'room': {'number': roomNumber, 'floor': 1},
      'roomType': {'name': 'غرفة ديلوكس'},
      'activeRequests': 0,
      'balanceCents': 5000,
      'reservation': {
        'grandTotalCents': 55200,
        'paidCents': 50200,
        'paymentStatus': 'PARTIALLY_PAID',
      },
    };

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

Future<void> _pumpScreen(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: InHouseScreen(store: store))),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('شاشة المقيمون', () {
    testWidgets('تعرض بطاقة المقيم (الاسم/الغرفة/الرصيد) وزر التفاصيل',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/inhouse') {
          return jsonRes({
            'ok': true,
            'stays': [_stay('1', 'نورا سالم', '103')],
          });
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);
      await _pumpScreen(tester, store);

      // العنوان بالعدّاد (المقيمون الآن (n) في الويب)
      expect(find.text('المقيمون الآن (1)'), findsOneWidget);
      // البطاقة: الاسم + شارة الحالة + صندوق الغرفة + الرصيد الملوّن
      expect(find.text('نورا سالم'), findsOneWidget);
      expect(find.text('نشطة'), findsOneWidget);
      expect(find.text('الغرفة'), findsOneWidget);
      expect(find.text('103'), findsOneWidget);
      expect(find.text('رصيد:'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('التفاصيل'), findsOneWidget);
      expect(find.text('لا توجد إقامات نشطة'), findsNothing);
    });

    testWidgets('لا إقامات نشطة: حالة الفراغ مع العدّاد صفرًا', (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/inhouse') {
          return jsonRes({'ok': true, 'stays': <Map<String, dynamic>>[]});
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);
      await _pumpScreen(tester, store);

      expect(find.text('المقيمون الآن (0)'), findsOneWidget);
      expect(find.text('لا توجد إقامات نشطة'), findsOneWidget);
      expect(find.text('سجّل وصول الضيوف ليظهروا هنا'), findsOneWidget);
      expect(find.text('التفاصيل'), findsNothing);
    });

    testWidgets('فشل الجلب: EmptyState برسالة الخادم + توست الخطأ',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/inhouse') {
          return jsonRes(
            {'ok': false, 'error': 'تعذر تحميل المقيمين'},
            status: 500,
          );
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);
      await _pumpScreen(tester, store);

      // EmptyState كما الويب (الرسالة في العنوان الفرعي) + التوست (نمط المغادرون)
      expect(find.text('تعذر التحميل'), findsOneWidget);
      expect(find.text('تعذر تحميل المقيمين'), findsAtLeastNWidgets(1));
      expect(find.text('لا توجد إقامات نشطة'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar (توست الخطأ)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

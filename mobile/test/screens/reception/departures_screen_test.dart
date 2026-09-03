// ─────────────────────────────────────────────────────────────
// TEST: شاشة المغادرون — نقل departures-view.tsx فوق ReceptionStore
// أقسام المتأخرين/مستحقي اليوم + البطاقات + الفراغ + الخطأ
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/departures_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _departure({
  required String id,
  required String reference,
  required String status,
  required String guestName,
  required String roomNumber,
  required String roomTypeName,
  required int balanceCents,
  required int activeRequests,
  required bool overdue,
}) {
  return {
    'id': id,
    'reference': reference,
    'status': status,
    'guestName': guestName,
    'guestPhone': '+967771234567',
    'roomNumber': roomNumber,
    'roomTypeName': roomTypeName,
    'checkInAt': '2026-09-01T14:00:00.000Z',
    'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
    'balanceCents': balanceCents,
    'activeRequests': activeRequests,
    'overdue': overdue,
  };
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

void main() {
  group('شاشة المغادرون', () {
    testWidgets('تعرض المتأخرين ومستحقي اليوم ببطاقاتهم وأزرار الخروج',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/departures') {
          return jsonRes({
            'ok': true,
            'departures': [
              _departure(
                id: 'st_1',
                reference: 'ST-2026-000003',
                status: 'ACTIVE',
                guestName: 'نورا سعيد',
                roomNumber: '103',
                roomTypeName: 'غرفة ديلوكس',
                balanceCents: 5000,
                activeRequests: 0,
                overdue: true,
              ),
              _departure(
                id: 'st_2',
                reference: 'ST-2026-000004',
                status: 'CHECKOUT_REQUESTED',
                guestName: 'سالم العمري',
                roomNumber: '201',
                roomTypeName: 'غرفة قياسية',
                balanceCents: 0,
                activeRequests: 2,
                overdue: false,
              ),
            ],
          });
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DeparturesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // الأقسام: متأخرون (الأولى) + مستحقو اليوم (الثانية)
      expect(find.text('مغادرات متأخرة'), findsOneWidget);
      expect(find.text('مستحقو اليوم'), findsOneWidget);
      expect(find.text('المغادرون اليوم'), findsOneWidget);
      // بطاقة المتأخر: الاسم + شارة الغرفة + شارة «متأخر» + الحالة
      expect(find.text('نورا سعيد'), findsOneWidget);
      expect(find.text('غرفة 103'), findsOneWidget);
      expect(find.text('متأخر'), findsOneWidget);
      expect(find.text('نشطة'), findsOneWidget);
      // بطاقة اليوم: اسم + غرفة + الطلبات النشطة + الحالة
      expect(find.text('سالم العمري'), findsOneWidget);
      expect(find.text('غرفة 201'), findsOneWidget);
      expect(find.text('2 طلب نشط'), findsOneWidget);
      expect(find.text('طُلب الخروج'), findsOneWidget);
      // زر تسجيل الخروج على كل بطاقة
      expect(find.text('تسجيل الخروج'), findsNWidgets(2));
      // الليالي محسوبة من تاريخي ISO الكاملين (nightsBetweenDates في الويب)
      expect(find.text('3 ليالٍ'), findsNWidgets(2));
      expect(find.text('لا مغادرات مستحقة'), findsNothing);
    });

    testWidgets('يوم بلا مغادرات: حالة الفراغ في قسم مستحقي اليوم',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/departures') {
          return jsonRes({'ok': true, 'departures': <Map<String, dynamic>>[]});
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DeparturesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا مغادرات مستحقة'), findsOneWidget);
      expect(find.text('مستحقو اليوم'), findsOneWidget);
      expect(find.text('مغادرات متأخرة'), findsNothing);
      expect(find.text('تسجيل الخروج'), findsNothing);
    });

    testWidgets('فشل الجلب: صندوق الخطأ مع رسالة الخادم وزر إعادة المحاولة',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/departures') {
          return jsonRes(
            {'ok': false, 'error': 'تعذر تحميل المغادرات'},
            status: 500,
          );
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DeparturesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعذر تحميل المغادرات'), findsAtLeastNWidgets(1));
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('لا مغادرات مستحقة'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar (توست الخطأ)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

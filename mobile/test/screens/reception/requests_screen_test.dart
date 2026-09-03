// ─────────────────────────────────────────────────────────────
// TEST: شاشة الطلبات — نقل requests-view.tsx فوق ReceptionStore
// الفلتر الافتراضي «المعلقة» + رقاقة «مكتمل» + مفتاح «العاجل فقط»
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/requests_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _request({
  required String id,
  required String title,
  required String status,
  required String priority,
  String reference = 'REQ-1003',
  String roomNumber = '201',
  String guestName = 'خالد يوسف',
}) {
  return {
    'id': id,
    'reference': reference,
    'category': 'HOUSEKEEPING',
    'title': title,
    'priority': priority,
    'status': status,
    'createdAt': '2026-09-02T08:30:00.000Z',
    'updatedAt': '2026-09-02T08:30:00.000Z',
    'stay': {
      'id': 'st_1',
      'reference': 'ST-2026-000002',
      'roomNumber': roomNumber,
      'guestName': guestName,
    },
    'updates': <Map<String, dynamic>>[],
  };
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

void main() {
  group('شاشة الطلبات', () {
    testWidgets('(أ) بطاقة طلب معلقة + الفلتر الافتراضي «المعلقة»',
        (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/requests') {
          return jsonRes({
            'ok': true,
            'requests': [
              _request(
                id: 'req_1',
                title: 'منشفة إضافية',
                status: 'NEW',
                priority: 'NORMAL',
              ),
              _request(
                id: 'req_2',
                title: 'طلب مكتمل سابقًا',
                status: 'COMPLETED',
                priority: 'NORMAL',
                reference: 'REQ-1001',
              ),
            ],
          });
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RequestsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // العنوان مع العدد المعروض (المعلقة فقط) + رقاقة الفلتر الافتراضي
      expect(find.text('الطلبات (1 معروضة)'), findsOneWidget);
      expect(find.text('المعلقة'), findsOneWidget);
      expect(find.text('الكل (2)'), findsOneWidget);
      // بطاقة الطلب: العنوان + غرفة/الضيف + شارة الحالة + الأولوية
      expect(find.text('منشفة إضافية'), findsOneWidget);
      expect(find.textContaining('غرفة 201'), findsOneWidget);
      expect(find.text('REQ-1003'), findsOneWidget);
      // «جديد» في رقاقة الفلتر وشارة حالة البطاقة معًا
      expect(find.text('جديد'), findsNWidgets(2));
      expect(find.text('عادي'), findsOneWidget);
      // المكتمل لا يظهر تحت «المعلقة»
      expect(find.text('طلب مكتمل سابقًا'), findsNothing);
    });

    testWidgets('(ب) نقرة رقاقة «مكتمل» تفلتر القائمة', (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/requests') {
          return jsonRes({
            'ok': true,
            'requests': [
              _request(
                id: 'req_1',
                title: 'منشفة إضافية',
                status: 'NEW',
                priority: 'NORMAL',
              ),
              _request(
                id: 'req_2',
                title: 'طلب مكتمل سابقًا',
                status: 'COMPLETED',
                priority: 'NORMAL',
                reference: 'REQ-1001',
              ),
            ],
          });
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RequestsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // «مكتمل» فريد قبل النقر (لا بطاقة مكتملة معروضة بعد)
      await tester.tap(find.text('مكتمل'));
      await tester.pumpAndSettle();

      // الآن تظهر المكتملة وحدها — والمعلقة تختفي
      expect(find.text('طلب مكتمل سابقًا'), findsOneWidget);
      expect(find.text('منشفة إضافية'), findsNothing);
      expect(find.text('الطلبات (1 معروضة)'), findsOneWidget);
    });

    testWidgets('(ج) مفتاح «العاجل فقط» يخفي غير العاجل', (tester) async {
      final api = _api(MockClient((req) async {
        if (req.url.path == '/api/reception/requests') {
          return jsonRes({
            'ok': true,
            'requests': [
              _request(
                id: 'req_1',
                title: 'منشفة إضافية',
                status: 'NEW',
                priority: 'NORMAL',
              ),
              _request(
                id: 'req_2',
                title: 'المكيف لا يبرد',
                status: 'IN_PROGRESS',
                priority: 'URGENT',
                reference: 'REQ-1009',
                roomNumber: '105',
                guestName: 'سالم العمري',
              ),
            ],
          });
        }
        return jsonRes({'ok': true});
      }));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RequestsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // كلاهما معروض تحت «المعلقة» + شارة العدّاد
      expect(find.text('منشفة إضافية'), findsOneWidget);
      expect(find.text('المكيف لا يبرد'), findsOneWidget);
      expect(find.text('2 معلق'), findsOneWidget);
      expect(find.text('الطلبات (2 معروضة)'), findsOneWidget);

      // تشغيل المفتاح
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // العاجل يبقى والعادي يختفي — والعدّاد «العاجل فقط (1)»
      expect(find.text('المكيف لا يبرد'), findsOneWidget);
      expect(find.text('منشفة إضافية'), findsNothing);
      expect(find.text('الطلبات (1 معروضة)'), findsOneWidget);
      expect(find.text('⚡ العاجل فقط (1)'), findsOneWidget);
    });
  });
}

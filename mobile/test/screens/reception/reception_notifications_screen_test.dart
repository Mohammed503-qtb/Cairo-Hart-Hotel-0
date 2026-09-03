// ─────────────────────────────────────────────────────────────
// TEST: شاشة إشعارات الاستقبال — نقل notifications-sheet.tsx
// الفتح يجلب ويعلّم المعروض غير المقروء + زر تحديد الكل كمقروء
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/reception_notifications_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

const List<Map<String, dynamic>> _notifications = [
  {
    'id': 'n_1',
    'type': 'REQUEST',
    'title': 'طلب جديد',
    'body': 'غرفة 103 تطلب منشفات إضافية',
    'read': false,
  },
  {
    'id': 'n_2',
    'type': 'CHAT',
    'title': 'رسالة',
    'body': '',
    'read': true,
  },
];

/// وهمي: GET يرجع القائمة نفسها دائمًا (n_1 غير مقروء) + التقاط POST read
MockClient _notificationsMock(List<List<dynamic>> readPosts) {
  final now = DateTime.now();
  final items = [
    for (final n in _notifications)
      {
        ...n,
        'createdAt': n['id'] == 'n_1'
            ? now.subtract(const Duration(minutes: 5)).toIso8601String()
            : now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
  ];
  return MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/reception/notifications' && req.method == 'GET') {
      return jsonRes({
        'ok': true,
        'notifications': items,
        'unreadCount': 1,
      });
    }
    if (path == '/api/reception/notifications/read' && req.method == 'POST') {
      final body =
          jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
      readPosts.add(body['ids'] as List<dynamic>);
      return jsonRes({'ok': true, 'updated': 1});
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

Future<void> _pumpScreen(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(
    MaterialApp(home: ReceptionNotificationsScreen(store: store)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('شاشة إشعارات الاستقبال', () {
    testWidgets('تعرض الإشعارات وتعلّم المعروض غير المقروء تلقائيًا عند الفتح',
        (tester) async {
      final readPosts = <List<dynamic>>[];
      final api = _api(_notificationsMock(readPosts));
      final store = ReceptionStore(api);
      await _pumpScreen(tester, store);

      // القائمة + زر التحديد + شارة غير المقروء في الشريط
      expect(find.text('طلب جديد'), findsOneWidget);
      expect(find.text('غرفة 103 تطلب منشفات إضافية'), findsOneWidget);
      expect(find.text('رسالة'), findsOneWidget);
      expect(find.text('لا إشعارات بعد 🔕'), findsNothing);
      expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
      expect(find.text('1 جديد'), findsOneWidget);
      expect(find.textContaining('منذ'), findsAtLeastNWidgets(1));

      // التعليم التلقائي عند الفتح: POST بمعرفات غير المقروء في القائمة فقط
      expect(readPosts, isNotEmpty);
      expect(readPosts.first, equals(['n_1']));
    });

    testWidgets('زر «تحديد الكل كمقروء» يرسل معرفات غير المقروء المعروضة',
        (tester) async {
      final readPosts = <List<dynamic>>[];
      final api = _api(_notificationsMock(readPosts));
      final store = ReceptionStore(api);
      await _pumpScreen(tester, store);
      final postsAfterOpen = readPosts.length;

      await tester.tap(find.text('تحديد الكل كمقروء'));
      await tester.pumpAndSettle();

      // POST جديد حدث + آخر معرفات مرسلة هي غير المقروء في آخر استجابة GET
      expect(readPosts.length, greaterThan(postsAfterOpen));
      expect(readPosts.last, everyElement(isNot(equals('n_2'))));
      expect(readPosts.last, contains('n_1'));
    });
  });
}

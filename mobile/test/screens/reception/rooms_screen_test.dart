// ─────────────────────────────────────────────────────────────
// TEST: لوحة الغرف — نقل rooms-view.tsx + room-dialog.tsx
// الطوابق والدليل + انتقال DIRTY→CLEANING + AVAILABLE→OUT_OF_ORDER
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/rooms_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _decodeBody(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _room({
  required String id,
  required String number,
  required int floor,
  required String status,
}) {
  return {
    'id': id,
    'number': number,
    'floor': floor,
    'status': status,
    'roomTypeId': 'rt_1',
    'roomTypeName': 'غرفة ديلوكس',
    'notes': null,
    'guestName': null,
    'expectedCheckOutAt': null,
    'activeStayId': null,
  };
}

/// وهمي موحّد: غرفتان (101 متسخة طابق 1 · 201 متاحة طابق 2) بحالات
/// متغيّرة + تحديث حالة غرفة + مسارات refresh الخمسة
MockClient _roomsMock({
  required Map<String, String> statuses,
  required void Function(Map<String, dynamic> body) onRoomStatus,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/reception/rooms' && req.method == 'GET') {
      return jsonRes({
        'ok': true,
        'rooms': [
          _room(id: 'rm_101', number: '101', floor: 1, status: statuses['101']!),
          _room(id: 'rm_201', number: '201', floor: 2, status: statuses['201']!),
        ],
      });
    }
    if (path == '/api/reception/rooms/rm_101/status' ||
        path == '/api/reception/rooms/rm_201/status') {
      final body = _decodeBody(req);
      onRoomStatus(body);
      final number = path.contains('rm_101') ? '101' : '201';
      statuses[number] = body['status'] as String? ?? statuses[number]!;
      return jsonRes({'ok': true});
    }
    // مسارات _refreshAfterRequestChange بعد setRoomStatus
    if (path == '/api/reception/dashboard') {
      return jsonRes({
        'ok': true,
        'stats': <String, dynamic>{},
        'arrivals': <Map<String, dynamic>>[],
        'departures': <Map<String, dynamic>>[],
        'pendingRequests': <Map<String, dynamic>>[],
      });
    }
    if (path == '/api/reception/departures') {
      return jsonRes({'ok': true, 'departures': <Map<String, dynamic>>[]});
    }
    if (path == '/api/reception/inhouse') {
      return jsonRes({'ok': true, 'stays': <Map<String, dynamic>>[]});
    }
    if (path == '/api/reception/requests') {
      return jsonRes({'ok': true, 'requests': <Map<String, dynamic>>[]});
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

void main() {
  group('لوحة الغرف', () {
    testWidgets('(أ) الشبكة تعرض غرفتين بطابقيهما + دليل الألوان',
        (tester) async {
      final api = _api(_roomsMock(
        statuses: {'101': 'DIRTY', '201': 'AVAILABLE'},
        onRoomStatus: (body) => fail('لا عمليات في هذا الاختبار'),
      ));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // العنوان مع العدّاد
      expect(find.text('حالة الغرف (2)'), findsOneWidget);
      // الغرفتان بطابقيهما
      expect(find.text('101'), findsOneWidget);
      expect(find.text('201'), findsOneWidget);
      expect(find.text('الطابق 1'), findsOneWidget);
      expect(find.text('الطابق 2'), findsOneWidget);
      // دليل الألوان: كل التسميات (تظهر أيضًا على البطاقات الملونة)
      expect(find.text('متاحة'), findsNWidgets(2));
      expect(find.text('تحتاج تنظيف'), findsNWidgets(2));
      expect(find.text('مشغولة'), findsOneWidget);
      expect(find.text('قيد التنظيف'), findsOneWidget);
      expect(find.text('خارج الخدمة'), findsOneWidget);
    });

    testWidgets('(ب) DIRTY → «بدء التنظيف» → جسم {status: CLEANING} + توست',
        (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final statuses = {'101': 'DIRTY', '201': 'AVAILABLE'};
      final api = _api(_roomsMock(
        statuses: statuses,
        onRoomStatus: bodies.add,
      ));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // افتح حوار الغرفة المتسخة
      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();
      expect(find.text('بدء التنظيف'), findsOneWidget);
      expect(find.text('متاحة'), findsNWidgets(3)); // دليل + بطاقة + حوار

      await tester.ensureVisible(find.text('بدء التنظيف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بدء التنظيف'));
      await tester.pumpAndSettle();

      // الجسم الحرفي + التوست بترجمة roomStatusLabels الحقيقية
      expect(bodies, hasLength(1));
      expect(bodies.last['status'], 'CLEANING');
      expect(bodies.last.containsKey('notes'), isFalse);
      expect(find.text('الغرفة 101: قيد التنظيف ✅'), findsOneWidget);
      // الحوار أُغلق بعد النجاح
      expect(find.text('بدء التنظيف'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar (درس F4-a)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('(ج) AVAILABLE → «خارج الخدمة» بتأكيد → جسم notes',
        (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final statuses = {'101': 'DIRTY', '201': 'AVAILABLE'};
      final api = _api(_roomsMock(
        statuses: statuses,
        onRoomStatus: bodies.add,
      ));
      final store = ReceptionStore(api);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // افتح حوار الغرفة المتاحة وأدخل سببًا
      await tester.tap(find.text('201'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'مكيف معطل');

      // زر «خارج الخدمة» (آخر تطابق — الدليل خلف الحوار يحمل نفس النص)
      await tester.ensureVisible(find.text('خارج الخدمة').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('خارج الخدمة').last);
      await tester.pumpAndSettle();

      // حوار التأكيد الحرفي
      expect(find.text('إخراج الغرفة من الخدمة؟'), findsOneWidget);
      expect(
        find.textContaining('لن تُحسب ضمن المخزون المتاح'),
        findsOneWidget,
      );

      await tester.tap(find.text('نعم، أكّد'));
      await tester.pumpAndSettle();

      // الجسم يحمل الحالة والملاحظة المكتوبة
      expect(bodies, hasLength(1));
      expect(bodies.last['status'], 'OUT_OF_ORDER');
      expect(bodies.last['notes'], 'مكيف معطل');
      expect(find.text('الغرفة 201: خارج الخدمة ✅'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

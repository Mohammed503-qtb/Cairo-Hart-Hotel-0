// ─────────────────────────────────────────────────────────────
// TEST: حوار تفاصيل الطلب — نقل request-detail-dialog.tsx
// الخط الزمني + استلام (NEW→ACKNOWLEDGED) + إسناد بفريق + رفض بتأكيد
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/request_detail_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _decodeBody(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _requestJson({
  String status = 'NEW',
  List<Map<String, dynamic>> updates = const [],
}) {
  return {
    'id': 'req_1',
    'reference': 'REQ-1003',
    'category': 'MAINTENANCE',
    'title': 'المكيف لا يبرد',
    'description': 'الغرفة حارة جدًا والمكيف لا يعمل',
    'priority': 'NORMAL',
    'status': status,
    'createdAt': '2026-09-02T08:30:00.000Z',
    'updatedAt': '2026-09-02T08:30:00.000Z',
    'stay': {
      'id': 'st_1',
      'reference': 'ST-2026-000002',
      'roomNumber': '201',
      'guestName': 'خالد يوسف',
    },
    'updates': updates,
  };
}

/// وهمي موحّد: قائمة الطلبات + تحديث الحالة + مسارات refresh الخمسة
MockClient _detailMock({
  required void Function(Map<String, dynamic> body) onStatus,
  List<Map<String, dynamic>> updates = const [],
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/reception/requests' && req.method == 'GET') {
      return jsonRes({
        'ok': true,
        'requests': [_requestJson(updates: updates)],
      });
    }
    if (path == '/api/reception/requests/req_1/status' &&
        req.method == 'POST') {
      final body = _decodeBody(req);
      onStatus(body);
      return jsonRes({
        'ok': true,
        'request': _requestJson(status: body['status'] as String? ?? 'NEW'),
      });
    }
    // مسارات _refreshAfterRequestChange بعد setRequestStatus
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
    if (path == '/api/reception/rooms') {
      return jsonRes({'ok': true, 'rooms': <Map<String, dynamic>>[]});
    }
    return jsonRes({'ok': true});
  });
}

/// مضيف يفتح الحوار بزر (يوفر سياق showDialog)
class _Host extends StatelessWidget {
  const _Host({required this.store});

  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showRequestDetail(
            context,
            store: store,
            requestId: 'req_1',
          ),
          child: const Text('افتح الطلب'),
        ),
      ),
    );
  }
}

Future<void> _openDialog(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(MaterialApp(home: _Host(store: store)));
  await tester.tap(find.text('افتح الطلب'));
  await tester.pumpAndSettle();
}

void main() {
  group('حوار تفاصيل الطلب', () {
    testWidgets('(أ) يعرض الطلب والوصف والخط الزمني', (tester) async {
      final api = _api(_detailMock(onStatus: (body) {
        fail('لا عمليات في هذا الاختبار');
      }, updates: [
        {
          'id': 'u_1',
          'status': 'ACKNOWLEDGED',
          'note': 'جاري المتابعة',
          'byName': 'سارة حسن',
          'byRole': 'RECEPTION',
          'createdAt': '2026-09-02T08:45:00.000Z',
        },
      ]));
      final store = ReceptionStore(api);
      await _openDialog(tester, store);

      // العنوان + المرجع + الغرفة/الضيف + الوصف
      expect(find.text('المكيف لا يبرد'), findsOneWidget);
      expect(find.text('REQ-1003'), findsOneWidget);
      expect(find.textContaining('غرفة 201'), findsOneWidget);
      expect(find.text('الغرفة حارة جدًا والمكيف لا يعمل'), findsOneWidget);
      // الخط الزمني: أُنشئ + تحديث بملاحظة + صاحبه
      expect(find.text('الخط الزمني'), findsOneWidget);
      expect(find.textContaining('أُنشئ'), findsOneWidget);
      expect(find.textContaining('سارة حسن'), findsOneWidget);
      expect(find.text('جاري المتابعة'), findsOneWidget);
      // شارة حالة التحديث (قيد الاطلاع) + قسم الإجراءات وأزرار NEW
      expect(find.text('قيد الاطلاع'), findsOneWidget);
      expect(find.text('إجراءات الاستقبال'), findsOneWidget);
      expect(find.text('استلام'), findsOneWidget);
      expect(find.text('إسناد'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('ملاحظة تُضاف للخط الزمني (اختياري)…'), findsOneWidget);

      // أزرار الحوار أسفل تمرير — ensureVisible (درس Task 18)
      await tester.ensureVisible(find.text('إغلاق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      expect(find.text('الخط الزمني'), findsNothing);
    });

    testWidgets('(ب) «استلام»: جسم POST الحرفي + توست النجاح',
        (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final api = _api(_detailMock(onStatus: bodies.add));
      final store = ReceptionStore(api);
      await _openDialog(tester, store);

      await tester.ensureVisible(find.text('استلام'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('استلام'));
      await tester.pumpAndSettle();

      // الجسم الحرفي: {status:'ACKNOWLEDGED'} بلا note/assignedTo فارغين
      expect(bodies, hasLength(1));
      expect(bodies.last['status'], 'ACKNOWLEDGED');
      expect(bodies.last.containsKey('note'), isFalse);
      expect(bodies.last.containsKey('assignedTo'), isFalse);
      // التوست + تحديث الطلب محليًا من القيمة المرجعة (ACKNOWLEDGED)
      expect(find.textContaining('تم تحديث الطلب ✅'), findsOneWidget);
      expect(find.text('قيد الاطلاع'), findsOneWidget);
      // أزرار ACKNOWLEDGED الجديدة
      expect(find.text('بدء التنفيذ'), findsOneWidget);
      expect(find.text('استلام'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar (درس F4-a)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('(ج) «إسناد» معطّل بلا فريق → فريق → جسم assignedTo',
        (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final api = _api(_detailMock(onStatus: bodies.add));
      final store = ReceptionStore(api);
      await _openDialog(tester, store);

      // الزر معطّل قبل اختيار الفريق
      FilledButton assignButton() => tester.widget<FilledButton>(
            find.ancestor(
              of: find.text('إسناد'),
              matching: find.byType(FilledButton),
            ),
          );
      expect(assignButton().onPressed, isNull);

      // اختر فريق الصيانة من المحدد (الصف قد يكون أسفل التمرير)
      await tester.ensureVisible(find.text('اختر فريقًا'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر فريقًا'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الصيانة'));
      await tester.pumpAndSettle();

      // الزر ممكّن الآن
      expect(assignButton().onPressed, isNotNull);

      await tester.ensureVisible(find.text('إسناد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إسناد'));
      await tester.pumpAndSettle();

      expect(bodies, hasLength(1));
      expect(bodies.last['status'], 'ASSIGNED');
      expect(bodies.last['assignedTo'], 'الصيانة');
      expect(bodies.last.containsKey('note'), isFalse);
      expect(find.textContaining('تم تحديث الطلب ✅'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('(د) «رفض» بتأكيد → جسم {status: REJECTED}', (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final api = _api(_detailMock(onStatus: bodies.add));
      final store = ReceptionStore(api);
      await _openDialog(tester, store);

      await tester.ensureVisible(find.text('رفض'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();

      // حوار التأكيد الحرفي
      expect(find.text('تأكيد «رفض»؟'), findsOneWidget);
      expect(
        find.textContaining('سيتم إشعار الضيف بهذا القرار'),
        findsOneWidget,
      );
      expect(find.text('تراجع'), findsOneWidget);

      await tester.tap(find.text('نعم، أكّد'));
      await tester.pumpAndSettle();

      expect(bodies, hasLength(1));
      expect(bodies.last['status'], 'REJECTED');
      expect(bodies.last.containsKey('note'), isFalse);
      expect(bodies.last.containsKey('assignedTo'), isFalse);
      // الطلب رُفض: لا إجراءات متبقية
      expect(find.textContaining('الطلب منتهٍ'), findsOneWidget);
      expect(find.textContaining('تم تحديث الطلب ✅'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

// ─────────────────────────────────────────────────────────────
// TEST: شاشة غرف الإدارة (A-08..A-11) — نقل sections/rooms.tsx
// إنشاء (الجسم الحرفي + trim) + تبديل سريع {status} + تعديل
// (OCCUPIED غائب عن الخيارات) + حذف بتأكيد DELETE برسالة الخادم
// (نفس نمط reception_store_test: MockClient → ApiClient → AdminStore)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/rooms_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _roomJson({
  required String id,
  required String number,
  required int floor,
  required String status,
  String roomTypeId = 'rt_1',
  String roomTypeName = 'غرفة اقتصادية',
  String? notes,
  String? guestName,
  String? expectedCheckOut,
}) {
  return {
    'id': id,
    'number': number,
    'floor': floor,
    'status': status,
    'notes': notes,
    'roomTypeId': roomTypeId,
    'roomTypeName': roomTypeName,
    'guestName': guestName,
    'expectedCheckOut': expectedCheckOut,
    'createdAt': '2026-08-01T10:00:00.000Z',
  };
}

Map<String, dynamic> _typeJson({
  String id = 'rt_1',
  String name = 'غرفة اقتصادية',
  int roomsCount = 3,
}) {
  return {
    'id': id,
    'name': name,
    'nameEn': 'Economy Room',
    'description': '',
    'capacityAdults': 2,
    'capacityChildren': 0,
    'bedConfig': '',
    'sizeSqm': 20,
    'basePriceCents': 5000,
    'amenities': <String>[],
    'images': <String>[],
    'active': true,
    'sortOrder': 0,
    'roomsCount': roomsCount,
    'reservationsCount': 2,
    'ratesCount': 1,
    'createdAt': '2026-08-01T10:00:00.000Z',
  };
}

const Map<String, dynamic> _dashboardJson = {
  'ok': true,
  'kpis': <String, dynamic>{},
  'recentBookings': <Map<String, dynamic>>[],
  'roomsByStatus': <String, dynamic>{},
  'alerts': <String, dynamic>{},
  'revenueByDay': <Map<String, dynamic>>[],
};

/// وهمي موحّد: الغرف + الأنواع + اللوحة + POST/PATCH/DELETE
MockClient _roomsMock({
  required List<Map<String, dynamic>> rooms,
  required List<Map<String, dynamic>> types,
  void Function(Map<String, dynamic> body)? onPost,
  void Function(Map<String, dynamic> body)? onPatch,
  void Function(String id)? onDelete,
  http.Response Function(String id)? deleteResponse,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (req.method == 'GET' && path == '/api/admin/rooms') {
      return jsonRes({'ok': true, 'rooms': rooms});
    }
    if (req.method == 'GET' && path == '/api/admin/room-types') {
      return jsonRes({'ok': true, 'roomTypes': types});
    }
    if (req.method == 'GET' && path == '/api/admin/dashboard') {
      return jsonRes(_dashboardJson);
    }
    if (req.method == 'POST' && path == '/api/admin/rooms') {
      final b = _body(req);
      onPost?.call(b);
      return jsonRes({
        'ok': true,
        'room': _roomJson(
          id: 'rm_new',
          number: (b['number'] as String?) ?? '107',
          floor: ((b['floor'] as num?) ?? 1).toInt(),
          status: 'AVAILABLE',
        ),
      }, status: 201);
    }
    if (req.method == 'PATCH' && path.startsWith('/api/admin/rooms/')) {
      final b = _body(req);
      onPatch?.call(b);
      return jsonRes({
        'ok': true,
        'room': rooms.isNotEmpty
            ? rooms.first
            : _roomJson(id: 'rm_x', number: '1', floor: 1, status: 'AVAILABLE'),
        'changedFields': <String>['status'],
      });
    }
    if (req.method == 'DELETE' && path.startsWith('/api/admin/rooms/')) {
      final id = path.substring('/api/admin/rooms/'.length);
      onDelete?.call(id);
      if (deleteResponse != null) return deleteResponse(id);
      return jsonRes({
        'ok': true,
        'deleted': true,
        'message': 'تم حذف الغرفة نهائيًا',
      });
    }
    return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
  });
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-admin',
      onSessionExpired: () {},
      httpClient: client,
    );

/// سطح أطول للمحتوى تحت الطية (درس F4) + تصريف SnackBar
Future<void> _prepare(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  group('شاشة غرف الإدارة', () {
    testWidgets('(أ) البطاقات: الرقم/النوع/الحالة/الضيف وموعد الخروج + العدّاد',
        (tester) async {
      await _prepare(tester);
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
          _roomJson(
            id: 'rm_202',
            number: '202',
            floor: 2,
            status: 'OCCUPIED',
            guestName: 'نورا أحمد',
            expectedCheckOut: '2026-09-10T12:00:00.000Z',
          ),
        ],
        types: [_typeJson()],
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
      expect(find.text('202'), findsOneWidget);
      expect(find.text('غرفة اقتصادية'), findsNWidgets(2));
      expect(find.text('تحتاج تنظيف'), findsOneWidget);
      expect(find.text('مشغولة'), findsOneWidget);
      expect(find.text('نورا أحمد'), findsOneWidget);
      expect(find.text('خروج: 10 سبتمبر 2026'), findsOneWidget);
      expect(
        find.text('2 غرفة — 1 مشغولة · 0 خارج الخدمة'),
        findsOneWidget,
      );
      // الفلاتر الحرفية
      expect(find.text('كل الحالات'), findsOneWidget);
      expect(find.text('كل الطوابق'), findsOneWidget);
      expect(find.text('كل الأنواع'), findsOneWidget);
    });

    testWidgets('(ب) إنشاء غرفة: جسم POST الحرفي {number,floor,roomTypeId,notes} مع trim',
        (tester) async {
      await _prepare(tester);
      final posts = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
        ],
        types: [_typeJson(roomsCount: 3)],
        onPost: posts.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة غرفة'));
      await tester.pumpAndSettle();
      expect(find.text('غرفة فعلية جديدة — تبدأ بحالة «متاحة»'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'رقم الغرفة *'),
        ' 107 ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'الطابق (1-30)'),
        '2',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'ملاحظات'),
        ' ملاحظة ',
      );

      // نوع الغرفة من القائمة المنسدلة
      await tester.tap(find.text('اختر النوع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('غرفة اقتصادية — 3 غرف'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();

      expect(posts, hasLength(1));
      expect(posts.single, {
        'number': '107',
        'floor': 2,
        'roomTypeId': 'rt_1',
        'notes': 'ملاحظة',
      });
      expect(find.text('تمت إضافة الغرفة 107'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(ج) تبديل سريع للحالة: جسم {status: CLEANING} فقط + توست',
        (tester) async {
      await _prepare(tester);
      final patches = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
        ],
        types: [_typeJson()],
        onPatch: patches.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إجراءات الغرفة 101'));
      await tester.pumpAndSettle();
      expect(find.text('تبديل سريع للحالة'), findsOneWidget);

      await tester.tap(find.text('تنظيف جارٍ').last);
      await tester.pumpAndSettle();

      // جسم الحالة فقط — كما quickStatus في الويب
      expect(patches, hasLength(1));
      expect(patches.single, {'status': 'CLEANING'});
      expect(find.text('الغرفة 101 → قيد التنظيف'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(د) تعديل: OCCUPIED غائب عن خيارات الحالة + الجسم الكامل + توست',
        (tester) async {
      await _prepare(tester);
      final patches = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
        ],
        types: [
          _typeJson(id: 'rt_1', name: 'غرفة اقتصادية'),
          _typeJson(id: 'rt_2', name: 'غرفة ديلوكس'),
        ],
        onPatch: patches.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إجراءات الغرفة 101'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل الغرفة'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل الغرفة 101'), findsOneWidget);
      expect(
        find.text('لا يمكن ضبط «مشغولة» يدويًا — الحجز يتم عبر تسجيل الوصول'),
        findsOneWidget,
      );

      // خيارات الحالة: الخمس اليدوية فقط — OCCUPIED غائب إطلاقًا
      final dialogDropdowns = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(DropdownButton<String>),
      );
      final statusDropdown =
          tester.widget<DropdownButton<String>>(dialogDropdowns.last);
      final values =
          statusDropdown.items!.map((i) => i.value).toList(growable: false);
      expect(values, [
        'AVAILABLE',
        'RESERVED',
        'CLEANING',
        'DIRTY',
        'OUT_OF_ORDER',
      ]);
      expect(values.contains('OCCUPIED'), isFalse);

      // اختر «محجوزة»
      await tester.tap(dialogDropdowns.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('محجوزة').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ملاحظات'),
        'صيانة تكييف',
      );

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      expect(patches, hasLength(1));
      expect(patches.single, {
        'floor': 1,
        'roomTypeId': 'rt_1',
        'status': 'RESERVED',
        'notes': 'صيانة تكييف',
      });
      expect(find.text('تم تحديث الغرفة 101'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(هـ) حذف: حوار التأكيد الحرفي + DELETE + رسالة الخادم',
        (tester) async {
      await _prepare(tester);
      final deletes = <String>[];
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
        ],
        types: [_typeJson()],
        onDelete: deletes.add,
        deleteResponse: (_) => jsonRes({
          'ok': true,
          'deleted': true,
          'message': 'تم حذف الغرفة 101 نهائيًا',
        }),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إجراءات الغرفة 101'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();

      // حوار التأكيد الحرفي
      expect(find.text('حذف الغرفة 101؟'), findsOneWidget);
      expect(
        find.textContaining('الحذف نهائي ولا يتاح إلا للغرف'),
        findsOneWidget,
      );
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('حذف نهائي'), findsOneWidget);

      await tester.tap(find.text('حذف نهائي'));
      await tester.pumpAndSettle();

      expect(deletes, ['rm_101']);
      expect(find.text('تم حذف الغرفة 101 نهائيًا'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(و) حذف ممنوع: رسالة الخادم الحرفية في توست الخطأ',
        (tester) async {
      await _prepare(tester);
      final deletes = <String>[];
      final store = AdminStore(_api(_roomsMock(
        rooms: [
          _roomJson(id: 'rm_101', number: '101', floor: 1, status: 'DIRTY'),
        ],
        types: [_typeJson()],
        onDelete: deletes.add,
        deleteResponse: (_) => jsonRes({
          'ok': false,
          'error':
              'لا يمكن حذف الغرفة 101 لوجود سجل إقامات مرتبطة بها — استخدم حالة «خارج الخدمة» بدلًا من الحذف',
        }, status: 400),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AdminRoomsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إجراءات الغرفة 101'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف نهائي'));
      await tester.pumpAndSettle();

      expect(deletes, ['rm_101']);
      // التوست يحمل رسالة الخادم الحرفية (درس F4: textContaining)
      expect(find.textContaining('تعذّر تنفيذ العملية'), findsOneWidget);
      expect(
        find.textContaining('لا يمكن حذف الغرفة 101 لوجود سجل إقامات'),
        findsOneWidget,
      );

      await _drainToast(tester);
    });
  });
}

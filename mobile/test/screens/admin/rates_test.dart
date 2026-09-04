// ─────────────────────────────────────────────────────────────
// TEST: شاشة الأسعار الموسمية (A-12..A-14) — نقل sections/rates.tsx
// التجميع حسب النوع + إنشاء معدل (25 دولارًا → 2500 سنت) + ظهور
// تحذير التداخل (الإنشاء نجح) + الحذف بحوار التأكيد
// (نفس نمط reception_store_test: MockClient → ApiClient → AdminStore)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/rates_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _typeJson({
  String id = 'rt_1',
  String name = 'غرفة اقتصادية',
  int basePriceCents = 8000,
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
    'basePriceCents': basePriceCents,
    'amenities': <String>[],
    'images': <String>[],
    'active': true,
    'sortOrder': 0,
    'roomsCount': 3,
    'reservationsCount': 2,
    'ratesCount': 1,
    'createdAt': '2026-08-01T10:00:00.000Z',
  };
}

Map<String, dynamic> _rateJson({
  String id = 'rate_1',
  String name = 'الموسم الشتوي',
  String roomTypeId = 'rt_1',
  String roomTypeName = 'غرفة اقتصادية',
  int priceCents = 5000,
}) {
  return {
    'id': id,
    'name': name,
    'roomTypeId': roomTypeId,
    'roomTypeName': roomTypeName,
    'roomTypeBasePriceCents': 8000,
    'startDate': '2026-01-01T12:00:00.000Z',
    'endDate': '2026-03-31T12:00:00.000Z',
    'priceCents': priceCents,
    'active': true,
    'createdAt': '2026-08-01T10:00:00.000Z',
  };
}

/// وهمي موحّد: المعدلات + الأنواع + POST (مع تحذير اختياري) + DELETE
MockClient _ratesMock({
  required List<Map<String, dynamic>> rates,
  required List<Map<String, dynamic>> types,
  void Function(Map<String, dynamic> body)? onPost,
  void Function(String id)? onDelete,
  String? warning,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (req.method == 'GET' && path == '/api/admin/rates') {
      return jsonRes({'ok': true, 'rates': rates});
    }
    if (req.method == 'GET' && path == '/api/admin/room-types') {
      return jsonRes({'ok': true, 'roomTypes': types});
    }
    if (req.method == 'POST' && path == '/api/admin/rates') {
      final b = _body(req);
      onPost?.call(b);
      return jsonRes({
        'ok': true,
        'rate': _rateJson(id: 'rate_new', name: (b['name'] as String?) ?? 'معدل'),
        if (warning != null) 'warning': warning,
      }, status: 201);
    }
    if (req.method == 'DELETE' && path.startsWith('/api/admin/rates/')) {
      final id = path.substring('/api/admin/rates/'.length);
      onDelete?.call(id);
      return jsonRes({
        'ok': true,
        'deleted': true,
        'message': 'تم حذف المعدل «الموسم الشتوي»',
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
  group('شاشة الأسعار الموسمية', () {
    testWidgets('(أ) التجميع حسب النوع: الأساس/النطاق/السعر/المقارنة + فراغ النوع',
        (tester) async {
      await _prepare(tester);
      final store = AdminStore(_api(_ratesMock(
        rates: [_rateJson()],
        types: [
          _typeJson(),
          _typeJson(id: 'rt_2', name: 'غرفة ديلوكس', basePriceCents: 16000),
        ],
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RatesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // لافتة شرح التسعير (درس F4: textContaining للنص المدمج)
      expect(
        find.textContaining('السعر النهائي لليلة = المعدل الموسمي المطابق'),
        findsOneWidget,
      );
      // مجموعة النوع الأول
      expect(find.text('غرفة اقتصادية'), findsOneWidget);
      expect(find.text('(الأساس: \$80.00)'), findsOneWidget);
      expect(find.text('الموسم الشتوي'), findsOneWidget);
      expect(find.text('من 1 يناير 2026 إلى 31 مارس 2026'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      // المقارنة بالسعر الأساسي
      expect(find.text('أقل من الأساس بـ \$30.00'), findsOneWidget);
      // نوع بلا معدلات
      expect(find.text('غرفة ديلوكس'), findsOneWidget);
      expect(
        find.text('لا توجد معدلات موسمية — يُستخدم السعر الأساسي دائمًا'),
        findsOneWidget,
      );
      // زر معدل لكل مجموعة
      expect(find.text('معدل'), findsNWidgets(2));
    });

    testWidgets('(ب) إنشاء معدل: 25 دولارًا → priceCents 2500 + تحذير التداخل',
        (tester) async {
      await _prepare(tester);
      final posts = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_ratesMock(
        rates: [_rateJson()],
        types: [_typeJson()],
        onPost: posts.add,
        warning: 'يتداخل مع معدل «الموسم الشتوي» — المعدل الأحدث بدايةً يسود لكل ليلة',
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RatesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة معدل'));
      await tester.pumpAndSettle();
      expect(find.text('إضافة معدل موسمي'), findsOneWidget);

      // النوع الأول مختار مسبقًا — اسم المعدل والتاريخان والسعر
      await tester.enterText(
        find.widgetWithText(TextField, 'اسم المعدل *'),
        ' الموسم الصيفي ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'من *'),
        '2026-07-01',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'إلى *'),
        '2026-08-31',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'السعر لليلة (\$) *'),
        '25',
      );

      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();

      // الجسم الحرفي: الدولار العشري ×100 → سنت (نمط الويب)
      expect(posts, hasLength(1));
      expect(posts.single['roomTypeId'], 'rt_1');
      expect(posts.single['name'], 'الموسم الصيفي');
      expect(posts.single['priceCents'], 2500);
      expect(posts.single['startDate'], '2026-07-01T00:00:00.000Z');
      expect(posts.single['endDate'], '2026-08-31T23:59:59.000Z');

      // الإنشاء نجح (الحوار أُغلق) + التحذير ظهر توست تحذيري
      expect(find.text('اسم المعدل *'), findsNothing);
      expect(find.textContaining('أُنشئ المعدل مع تحذير'), findsOneWidget);
      expect(
        find.textContaining('يتداخل مع معدل «الموسم الشتوي»'),
        findsOneWidget,
      );

      await _drainToast(tester);
    });

    testWidgets('(ج) إنشاء معدل بلا تداخل: توست النجاح العادي', (tester) async {
      await _prepare(tester);
      final posts = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_ratesMock(
        rates: <Map<String, dynamic>>[],
        types: [_typeJson()],
        onPost: posts.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RatesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة معدل'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'اسم المعدل *'),
        'الموسم الصيفي',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'من *'),
        '2026-07-01',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'إلى *'),
        '2026-08-31',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'السعر لليلة (\$) *'),
        '180',
      );

      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();

      expect(posts.single['priceCents'], 18000);
      expect(find.text('تمت إضافة المعدل'), findsOneWidget);
      expect(find.textContaining('تحذير'), findsNothing);

      await _drainToast(tester);
    });

    testWidgets('(د) حذف معدل: حوار التأكيد الحرفي + DELETE + رسالة الخادم',
        (tester) async {
      await _prepare(tester);
      final deletes = <String>[];
      final store = AdminStore(_api(_ratesMock(
        rates: [_rateJson()],
        types: [_typeJson()],
        onDelete: deletes.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RatesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('حذف الموسم الشتوي'));
      await tester.pumpAndSettle();

      expect(find.text('حذف معدل «الموسم الشتوي»؟'), findsOneWidget);
      // النطاق LTR + نوع + ملاحظة لقطة السعر (نص مدمج → textContaining)
      expect(find.textContaining('2026-01-01 → 2026-03-31'), findsOneWidget);
      expect(find.textContaining('لنوع «غرفة اقتصادية»'), findsOneWidget);
      expect(
        find.textContaining('الحجوزات التي حُجزت أثناء هذا المعدل تحتفظ بلقطة سعرها'),
        findsOneWidget,
      );
      expect(find.text('تراجع'), findsOneWidget);

      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();

      expect(deletes, ['rate_1']);
      expect(find.text('تم حذف المعدل «الموسم الشتوي»'), findsOneWidget);

      await _drainToast(tester);
    });
  });
}

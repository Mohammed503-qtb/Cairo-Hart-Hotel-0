// ─────────────────────────────────────────────────────────────
// TEST: شاشة أنواع الغرف (A-04..A-07) — نقل sections/room-types.tsx
// البطاقة الكاملة + إنشاء نوع بالجسم الحرفي (45.5 دولارًا → 4550
// سنت + المزايا) + تبديل التفعيل + الحذف الناعم برسالة الخادم
// (نفس نمط reception_store_test: MockClient → ApiClient → AdminStore)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/room_types_screen.dart';
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
  bool active = true,
}) {
  return {
    'id': id,
    'name': name,
    'nameEn': 'Economy Room',
    'description': 'غرفة مريحة بإطلالة',
    'capacityAdults': 2,
    'capacityChildren': 1,
    'bedConfig': 'سرير مزدوج كبير',
    'sizeSqm': 28,
    'basePriceCents': 5000,
    'amenities': ['واي فاي مجاني', 'تكييف', 'تلفاز', 'ميني بار', 'خزنة'],
    'images': ['/images/room-double.png'],
    'active': active,
    'sortOrder': 0,
    'roomsCount': 3,
    'reservationsCount': 2,
    'ratesCount': 1,
    'createdAt': '2026-08-01T10:00:00.000Z',
  };
}

/// وهمي موحّد: الأنواع + POST/PATCH/DELETE
MockClient _typesMock({
  required List<Map<String, dynamic>> types,
  void Function(Map<String, dynamic> body)? onPost,
  void Function(Map<String, dynamic> body)? onPatch,
  void Function(String id)? onDelete,
  String? deleteMessage,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (req.method == 'GET' && path == '/api/admin/room-types') {
      return jsonRes({'ok': true, 'roomTypes': types});
    }
    if (req.method == 'POST' && path == '/api/admin/room-types') {
      final b = _body(req);
      onPost?.call(b);
      return jsonRes({'ok': true, 'roomType': _typeJson(name: 'غرفة عائلية')},
          status: 201);
    }
    if (req.method == 'PATCH' && path.startsWith('/api/admin/room-types/')) {
      final b = _body(req);
      onPatch?.call(b);
      return jsonRes({'ok': true, 'roomType': types.first});
    }
    if (req.method == 'DELETE' && path.startsWith('/api/admin/room-types/')) {
      final id = path.substring('/api/admin/room-types/'.length);
      onDelete?.call(id);
      return jsonRes({
        'ok': true,
        'deactivated': true,
        'message': deleteMessage ?? 'تم تعطيل النوع نهائيًا',
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
  group('شاشة أنواع الغرف', () {
    testWidgets('(أ) البطاقة: الاسم/الإنجليزي/السعر/السعة/السرير/المرافق/العدادات',
        (tester) async {
      await _prepare(tester);
      final store = AdminStore(_api(_typesMock(types: [_typeJson()])));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomTypesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('غرفة اقتصادية'), findsOneWidget);
      expect(find.text('Economy Room'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('لليلة'), findsOneWidget);
      expect(find.text('2 بالغ + 1 طفل'), findsOneWidget);
      expect(find.text('28 م²'), findsOneWidget);
      expect(find.text('سرير مزدوج كبير'), findsOneWidget);
      // المرافق: أول 4 + عدّاد البقية
      expect(find.text('واي فاي مجاني'), findsOneWidget);
      expect(find.text('تكييف'), findsOneWidget);
      expect(find.text('تلفاز'), findsOneWidget);
      expect(find.text('ميني بار'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      // عدد الغرف والحجوزات والمعدلات
      expect(find.text('3 غرفة فعلية'), findsOneWidget);
      expect(find.text('2 حجز'), findsOneWidget);
      expect(find.text('1 معدل'), findsOneWidget);
      // نشط/معروض + التبديل
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('معروض'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('1 نوع — السعر الأساسي لكل نوع + المزايا والصور'),
          findsOneWidget);
    });

    testWidgets('(ب) إنشاء نوع: الجسم الكامل الحرفي (45.5 دولارًا → 4550 سنت)',
        (tester) async {
      await _prepare(tester);
      final posts = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_typesMock(
        types: [_typeJson()],
        onPost: posts.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomTypesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة نوع'));
      await tester.pumpAndSettle();
      expect(find.text('نوع جديد سيظهر في محرك الحجز على الموقع'),
          findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم (عربي) *'),
        'غرفة عائلية',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم (إنجليزي)'),
        'Family Room',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'الوصف'),
        'وصف',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'تجهيز السرير'),
        'سريران كبيران',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'المساحة (م²)'),
        '35',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'السعر الأساسي لليلة (\$) *'),
        '45.5',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'الترتيب'),
        '2',
      );

      // المزايا: اكتب ثم زر «إضافة» (tag input كما الويب)
      await tester.ensureVisible(find.text('إضافة'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'واي فاي مجاني'),
        'واي فاي مجاني',
      );
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsOneWidget);

      // زر الحفظ أسفل النموذج — ensureVisible (درس F4)
      await tester.ensureVisible(find.text('إضافة النوع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة النوع'));
      await tester.pumpAndSettle();

      expect(posts, hasLength(1));
      expect(posts.single, {
        'name': 'غرفة عائلية',
        'nameEn': 'Family Room',
        'description': 'وصف',
        'capacityAdults': 2,
        'capacityChildren': 0,
        'bedConfig': 'سريران كبيران',
        'sizeSqm': 35,
        'basePriceCents': 4550,
        'amenities': ['واي فاي مجاني'],
        'images': <String>[],
        'sortOrder': 2,
        'active': true,
      });
      expect(find.text('تمت إضافة نوع الغرفة'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(ج) تبديل التفعيل: PATCH بجسم {active: false}', (tester) async {
      await _prepare(tester);
      final patches = <Map<String, dynamic>>[];
      final store = AdminStore(_api(_typesMock(
        types: [_typeJson()],
        onPatch: patches.add,
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomTypesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(patches, hasLength(1));
      expect(patches.single, {'active': false});
    });

    testWidgets('(د) حذف نوع مرتبط: حوار التعطيل + رسالة الخادم الحرفية',
        (tester) async {
      await _prepare(tester);
      final deletes = <String>[];
      final store = AdminStore(_api(_typesMock(
        types: [_typeJson()],
        onDelete: deletes.add,
        deleteMessage:
            'تم تعطيل النوع «غرفة اقتصادية» لوجود غرف أو حجوزات مرتبطة به',
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoomTypesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('حذف غرفة اقتصادية'));
      await tester.pumpAndSettle();

      expect(find.text('حذف نوع «غرفة اقتصادية»؟'), findsOneWidget);
      // نص الارتباطات (نص مدمج → textContaining — درس F4)
      expect(
        find.textContaining('هذا النوع مرتبط بـ 3 غرفة و2 حجز'),
        findsOneWidget,
      );
      expect(find.textContaining('سيتم تعطيله'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);

      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      expect(deletes, ['rt_1']);
      expect(
        find.textContaining('تم تعطيل النوع «غرفة اقتصادية»'),
        findsOneWidget,
      );

      await _drainToast(tester);
    });
  });
}

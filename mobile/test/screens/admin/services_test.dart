// ─────────────────────────────────────────────────────────────
// TEST: شاشة الخدمات والأقسام (A-15..A-22) — نقل services.tsx
// الجسد الحرفي: خدمة {name,nameEn,description,priceCents,
// categoryId,active} بالسنت (×100 round) + قسم {name,key,icon,
// sortOrder} + التفعيل/التعطيل PATCH + الحذف بتأكيد ورسالة الخادم
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/services_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _serviceJson() => {
      'id': 'svc_1',
      'name': 'تنظيف جاف',
      'nameEn': 'Dry Cleaning',
      'description': '',
      'priceCents': 1500,
      'active': true,
      'sortOrder': 0,
      'categoryId': 'cat_1',
      'categoryName': 'ضيافة',
      'categoryKey': 'GUEST_SERVICES',
    };

Map<String, dynamic> _categoryJson() => {
      'id': 'cat_1',
      'name': 'ضيافة',
      'nameEn': 'Guest Services',
      'key': 'GUEST_SERVICES',
      'icon': 'bell',
      'sortOrder': 1,
      'servicesCount': 1,
    };

Future<void> _drainSnackBar(WidgetTester tester) async {
  // درس F4: مؤقّت SnackBar معلّق = فشل اختبار — نصرفه دائمًا
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-admin',
      onSessionExpired: () {},
      httpClient: client,
    );

void main() {
  testWidgets('تبويب الخدمات: البطاقات بالسعر MoneyText والقسم والفعالية',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/services') {
        return jsonRes({'ok': true, 'services': [_serviceJson()]});
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/service-categories') {
        return jsonRes({'ok': true, 'categories': [_categoryJson()]});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ServicesScreen(store: store))),
    );
    await tester.pumpAndSettle();

    // الرأس + المبدّل (الافتراضي «الخدمات» كالويب)
    expect(find.text('الخدمات'), findsNWidgets(2)); // الرأس + التبويب
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.text('كتالوج الخدمات التي يطلبها الضيوف خلال الإقامة'),
        findsOneWidget);

    // بطاقة الخدمة: الاسم/الإنجليزي/القسم/السعر/الفعالية
    expect(find.text('تنظيف جاف'), findsOneWidget);
    expect(find.text('Dry Cleaning'), findsOneWidget);
    // «ضيافة» مرتين: شارة القسم في البطاقة + شريحة الفلتر
    expect(find.text('ضيافة'), findsNWidgets(2));
    expect(find.text(r'$15.00'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('1 خدمة'), findsOneWidget);

    // أزرار الإضافة والأدوات
    expect(find.text('إضافة خدمة'), findsOneWidget);
  });

  testWidgets('إنشاء خدمة: جسم POST الحرفي بالسنت الصحيح + toast النجاح',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final postBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/services') {
        return jsonRes({'ok': true, 'services': [_serviceJson()]});
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/service-categories') {
        return jsonRes({'ok': true, 'categories': [_categoryJson()]});
      }
      if (req.method == 'POST' && req.url.path == '/api/admin/services') {
        postBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'service': {..._serviceJson(), 'name': 'توصيل مطعم', 'priceCents': 525},
        }, status: 201);
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ServicesScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة خدمة'));
    await tester.pumpAndSettle();

    // زر الشاشة + عنوان الحوار — نصّان متطابقان بعد الفتح
    expect(find.text('إضافة خدمة'), findsNWidgets(2));
    expect(find.text('ستظهر للضيوف في تطبيق الإقامة حسب قسمها'),
        findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('service-name')), 'توصيل مطعم');
    await tester.pump();
    // الدولار العشري → السنت int (×100 بتحويل آمن round)
    await tester.enterText(
        find.byKey(const ValueKey('service-price')), '5.25');
    await tester.pump();

    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    // الجسم الحرفي: الأسماء الستة كما يرسلها الويب
    expect(postBodies, hasLength(1));
    expect(
      postBodies.single,
      {
        'name': 'توصيل مطعم',
        'nameEn': '',
        'description': '',
        'priceCents': 525,
        'categoryId': 'cat_1',
        'active': true,
      },
    );
    expect(postBodies.single['priceCents'], isA<int>());

    expect(find.text('تمت إضافة الخدمة'), findsOneWidget);

    await _drainSnackBar(tester);
  });

  testWidgets('التفعيل/التعطيل: PATCH بجسم {active} فقط كما الويب',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final patchBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/services') {
        return jsonRes({'ok': true, 'services': [_serviceJson()]});
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/service-categories') {
        return jsonRes({'ok': true, 'categories': [_categoryJson()]});
      }
      if (req.method == 'PATCH' &&
          req.url.path == '/api/admin/services/svc_1') {
        patchBodies.add(body(req));
        return jsonRes({'ok': true, 'service': _serviceJson()});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ServicesScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(patchBodies, hasLength(1));
    expect(patchBodies.single, {'active': false});
  });

  testWidgets('حذف خدمة: حوار تأكيد حرفي + رسالة الخادم (تعطيل ناعم)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final deletes = <String>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/services') {
        return jsonRes({'ok': true, 'services': [_serviceJson()]});
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/service-categories') {
        return jsonRes({'ok': true, 'categories': [_categoryJson()]});
      }
      if (req.method == 'DELETE' &&
          req.url.path == '/api/admin/services/svc_1') {
        deletes.add('${req.method} ${req.url.path}');
        return jsonRes({
          'ok': true,
          'deactivated': true,
          'message':
              'تم تعطيل الخدمة «تنظيف جاف» لوجود طلبات مرتبطة بها — يمكن تفعيلها مجددًا في أي وقت',
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ServicesScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حذف تنظيف جاف'));
    await tester.pumpAndSettle();

    // حوار التأكيد بالنص الحرفي من الويب
    expect(find.text('حذف خدمة «تنظيف جاف»؟'), findsOneWidget);
    expect(find.textContaining('بدل حذفها للحفاظ على السجلات'), findsOneWidget);
    expect(find.text('تراجع'), findsOneWidget);
    expect(find.text('متابعة'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();

    expect(deletes, ['DELETE /api/admin/services/svc_1']);
    // رسالة الخادم الحرفية تظهر (تعطيل ناعم لوجود طلبات مرتبطة)
    expect(find.textContaining('تم تعطيل الخدمة «تنظيف جاف»'), findsOneWidget);

    await _drainSnackBar(tester);
  });

  testWidgets('تبويب الأقسام: البطاقات + إنشاء قسم بجسم {name,key,icon,sortOrder}',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final postBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/services') {
        return jsonRes({'ok': true, 'services': [_serviceJson()]});
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/service-categories') {
        return jsonRes({'ok': true, 'categories': [_categoryJson()]});
      }
      if (req.method == 'POST' &&
          req.url.path == '/api/admin/service-categories') {
        postBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'category': {
            ..._categoryJson(),
            'id': 'cat_2',
            'name': 'خدمات إضافية',
            'key': 'OTHER',
            'icon': 'sparkles',
            'sortOrder': 2,
            'servicesCount': 0,
          },
        }, status: 201);
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ServicesScreen(store: store))),
    );
    await tester.pumpAndSettle();

    // الانتقال لتبويب الأقسام
    await tester.tap(find.text('الأقسام'));
    await tester.pumpAndSettle();

    // بطاقة القسم: الاسم/المفتاح/الأيقونة/الترتيب/عدد الخدمات
    expect(find.text('ضيافة'), findsOneWidget);
    expect(find.text('GUEST_SERVICES'), findsOneWidget);
    expect(find.text('bell'), findsOneWidget);
    expect(find.text('الترتيب: 1'), findsOneWidget);
    expect(find.text('1 خدمة'), findsOneWidget);
    expect(find.text('1 قسم'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);

    await tester.tap(find.text('إضافة قسم'));
    await tester.pumpAndSettle();

    // زر الشاشة + عنوان الحوار — نصّان متطابقان بعد الفتح
    expect(find.text('إضافة قسم'), findsNWidgets(2));
    expect(find.text('الأقسام تُصنّف الخدمات في تطبيق الضيف والاستقبال'),
        findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('category-name')), 'خدمات إضافية');
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('category-icon')), 'sparkles');
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('category-sort')), '2');
    await tester.pump();

    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    // الجسم الحرفي: المفتاح الافتراضي OTHER (كما الويب) + sortOrder int
    expect(postBodies, hasLength(1));
    expect(
      postBodies.single,
      {
        'name': 'خدمات إضافية',
        'key': 'OTHER',
        'icon': 'sparkles',
        'sortOrder': 2,
      },
    );
    expect(postBodies.single['sortOrder'], isA<int>());

    expect(find.text('تمت إضافة القسم'), findsOneWidget);

    await _drainSnackBar(tester);
  });
}

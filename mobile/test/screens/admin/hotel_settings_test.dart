// ─────────────────────────────────────────────────────────────
// TEST: شاشة إعدادات الفندق (A-02/A-03) — نقل hotel-settings.tsx
// حفظ PATCH بالحقول المتغيرة فقط (الأرقام int) + note الخادم
// toast + التحقق العميلي برسائل الخادم الحرفية (يشمل F6)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/hotel_settings_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

/// بيانات الفندق الكاملة (كل الحقول الحرفية — يشمل minAppVersion F6)
Map<String, dynamic> _hotelJson() => {
      'id': 'h1',
      'name': 'فندق قلب القاهرة',
      'tagline': 'ضيافة راقية في قلب المدينة',
      'description': 'فندق عائلي في قلب عدن',
      'phone': '+967771234567',
      'whatsapp': '+967771234567',
      'email': 'info@cairoheart.ye',
      'address': 'شارع الجمهورية',
      'city': 'عدن',
      'currency': 'USD',
      'checkInTime': '14:00',
      'checkOutTime': '12:00',
      'taxPercent': 15,
      'weekendSurchargePercent': 10,
      'minStayNights': 1,
      'maxStayNights': 30,
      'bookingHorizonDays': 365,
      'cancellationPolicy': 'إلغاء مجاني قبل 48 ساعة',
      'paymentPolicy': 'الدفع في الفندق',
      'childrenPolicy': 'الأطفال حتى 6 سنوات مجانًا',
      'petsPolicy': 'لا يُسمح بالحيوانات الأليفة',
      'smokingPolicy': 'ممنوع التدخين',
      'minAppVersion': '',
    };

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-admin',
      onSessionExpired: () {},
      httpClient: client,
    );

Future<void> _drainSnackBar(WidgetTester tester) async {
  // درس F4: مؤقّت SnackBar معلّق = فشل اختبار — نصرفه دائمًا
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('النموذج يُبنى من بيانات الفندق بكل الحقول الحرفية',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HotelSettingsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    // الرأس + البطاقات الخمس
    expect(find.text('إعدادات الفندق'), findsOneWidget);
    expect(find.text('بيانات الفندق وحدود الحجز والسياسات — مصدر الحقيقة لكل القنوات'),
        findsOneWidget);
    expect(find.text('المعلومات الأساسية'), findsOneWidget);
    expect(find.text('التواصل والموقع'), findsOneWidget);
    expect(find.text('حدود الحجز والأسعار'), findsOneWidget);
    expect(find.text('تطبيق الضيف (Flutter)'), findsOneWidget);
    expect(find.text('السياسات'), findsOneWidget);

    // حقول حرفية (تسميات الويب) — يشمل حقل F6
    expect(find.text('اسم الفندق *'), findsOneWidget);
    expect(find.text('أقل إصدار مسموح للتطبيق'), findsOneWidget);
    expect(find.text('سياسة الحيوانات الأليفة'), findsOneWidget);
    expect(find.text('الضريبة % (0-100)'), findsOneWidget);

    // بطاقة التحذير الذهبية — النص الحرفي
    expect(find.textContaining('الحجوزات القديمة تحتفظ بلقطة سعرها وقت الحجز'),
        findsOneWidget);

    // قيم من الخادم في الحقول — الشعار يظهر مرتين: قيمة الحقل
    // (EditableText) + نص التلميح الذي يبقيه InputDecorator في
    // الشجرة لأغراض القياس حتى مع وجود قيمة
    expect(find.text('فندق قلب القاهرة'), findsOneWidget);
    expect(find.text('ضيافة راقية في قلب المدينة'), findsNWidgets(2));

    // غير متغير → زر الحفظ خامد (تسمية الرأس الخاملة)
    expect(find.text('حفظ'), findsOneWidget);
  });

  testWidgets(
      'الحفظ: PATCH بالحقول المتغيرة فقط (الأرقام int) + note الخادم toast',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final patchBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({
          'ok': true,
          'hotel': patchBodies.isEmpty
              ? _hotelJson()
              : {..._hotelJson(), 'tagline': 'شعار جديد', 'taxPercent': 16},
        });
      }
      if (req.method == 'PATCH' && req.url.path == '/api/admin/hotel') {
        patchBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'hotel': {
            ..._hotelJson(),
            'tagline': 'شعار جديد',
            'taxPercent': 16,
          },
          'changedFields': ['tagline', 'taxPercent'],
          'note':
              'تم الحفظ — تغيير الضريبة والأسعار يؤثر على الحجوزات الجديدة فقط، والحجوزات القديمة تحتفظ بلقطة سعرها وقت الحجز',
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HotelSettingsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    // تعديل حقلين: نصي ورقمي (الرقم يُحوَّل int كما الويب)
    await tester.enterText(
        find.byKey(const ValueKey('hotel-tagline')), 'شعار جديد');
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('hotel-taxPercent')), '16');
    await tester.pump();

    // dirty → أزرار الحفظ فعُلت
    expect(find.text('حفظ التغييرات'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('حفظ التغييرات').first);
    await tester.pumpAndSettle();

    // جسم PATCH: الحقول المتغيرة فقط بأسمائها الحرفية
    expect(patchBodies, hasLength(1));
    expect(
      patchBodies.single,
      {'tagline': 'شعار جديد', 'taxPercent': 16},
    );
    expect(patchBodies.single['taxPercent'], isA<int>());

    // note الخادم يظهر (توست) — النص الحرفي
    expect(
      find.textContaining(
          'تغيير الضريبة والأسعار يؤثر على الحجوزات الجديدة فقط'),
      findsOneWidget,
    );

    // بعد الحفظ: النموذج عاد نظيفًا (زر الرأس خامد بتسميته الخاملة)
    expect(find.text('حفظ'), findsOneWidget);

    await _drainSnackBar(tester);
  });

  testWidgets('التحقق العميلي: اسم فارغ → رسالة الخادم الحرفية بلا PATCH',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final patchBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      if (req.method == 'PATCH' && req.url.path == '/api/admin/hotel') {
        patchBodies.add(body(req));
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HotelSettingsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('hotel-name')), '   ');
    await tester.pump();

    await tester.tap(find.text('حفظ التغييرات').first);
    await tester.pumpAndSettle();

    expect(find.text('اسم الفندق لا يمكن أن يكون فارغًا'), findsOneWidget);
    expect(patchBodies, isEmpty);

    await _drainSnackBar(tester);
  });

  testWidgets('التحقق العميلي لحقل F6: صيغة الإصدار الثلاثية', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final patchBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      if (req.method == 'PATCH' && req.url.path == '/api/admin/hotel') {
        patchBodies.add(body(req));
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HotelSettingsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('hotel-minAppVersion')), '1.2');
    await tester.pump();

    await tester.tap(find.text('حفظ التغييرات').first);
    await tester.pumpAndSettle();

    expect(
      find.text('صيغة إصدار التطبيق يجب أن تكون ثلاثية رقمية (مثال: 1.2.0)'),
      findsOneWidget,
    );
    expect(patchBodies, isEmpty);

    await _drainSnackBar(tester);
  });

  testWidgets('ApiError من الخادم عند الحفظ → رسالته الحرفية toast',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final patchBodies = <Map<String, dynamic>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({'ok': true, 'hotel': _hotelJson()});
      }
      if (req.method == 'PATCH' && req.url.path == '/api/admin/hotel') {
        patchBodies.add(body(req));
        return jsonRes(
          {'ok': false, 'error': 'النسبة يجب أن تكون بين 0 و 100'},
          status: 400,
        );
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HotelSettingsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('hotel-currency')), 'EUR');
    await tester.pump();

    await tester.tap(find.text('حفظ التغييرات').first);
    await tester.pumpAndSettle();

    // الجسم أُرسل (التحقق العميلي اجتاز) ثم الخادم رفض برسالته الحرفية
    expect(patchBodies, hasLength(1));
    expect(patchBodies.single, {'currency': 'EUR'});
    expect(find.text('النسبة يجب أن تكون بين 0 و 100'), findsOneWidget);

    await _drainSnackBar(tester);
  });
}

// ─────────────────────────────────────────────────────────────
// TEST: شاشة الطاقم والأكواد (A-23..A-28) — نقل staff-codes.tsx
// توليد (الجسم الحرفي {'type','staffId','days'} + الكود الخام
// يظهر مرة واحدة) + إبطال بحوار تأكيد {codeId} + فلاتر الأكواد
// في استعلام GET (type=RECEPTION&status=ACTIVE) + الموظف المعطّل
// غير قابل للاختيار + إضافة موظف + تعطيل بحوار تأكيد {active:false}
// (نفس نمط rooms_test: MockClient → ApiClient → AdminStore)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/staff_codes_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

Map<String, dynamic> _staffJson({
  required String id,
  required String fullName,
  required String role,
  bool active = true,
  String phone = '+96777123456',
  Map<String, dynamic>? lastCode,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'role': role,
    'phone': phone,
    'active': active,
    'createdAt': '2026-06-01T08:00:00.000Z',
    'lastCode': lastCode,
  };
}

Map<String, dynamic> _codeJson({
  required String id,
  required String codeMasked,
  required String type,
  required String status,
  String? staffName,
  String? staffRole,
  String? guestName,
  String? roomNumber,
  String? stayReference,
  String? lastUsedAt,
}) {
  return {
    'id': id,
    'codeMasked': codeMasked,
    'type': type,
    'status': status,
    'expiresAt': '2026-09-10T21:59:59.000Z',
    'lastUsedAt': lastUsedAt,
    'createdAt': '2026-08-01T10:00:00.000Z',
    'staffName': staffName,
    'staffRole': staffRole,
    'guestName': guestName,
    'roomNumber': roomNumber,
    'stayReference': stayReference,
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

/// مسجّل النداءات — يتحقق من الأجسام والاستعلامات الحرفية
class _Recorder {
  final List<String> codeGets = [];
  final List<Map<String, dynamic>> generates = [];
  final List<Map<String, dynamic>> revokes = [];
  final List<Map<String, dynamic>> staffPosts = [];
  final List<Map<String, dynamic>> staffPatches = [];
}

/// وهمي موحّد: الأكواد (مع الاستعلام) + الطاقم + اللوحة +
/// الإشعارات + توليد/إبطال/إضافة/تعديل الطاقم
MockClient _staffCodesMock(
  _Recorder rec, {
  required List<Map<String, dynamic>> staff,
  required List<Map<String, dynamic>> codes,
  String rawCode = 'R1234567',
  http.Response Function(Map<String, dynamic> body)? generateResponse,
  String revokeMessage =
      'تم إبطال كود R•••111 (خالد يوسف) وإبطال جلساته',
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (req.method == 'GET') {
      if (path == '/api/admin/codes') {
        rec.codeGets.add(req.url.query ?? '');
        return jsonRes({'ok': true, 'codes': codes});
      }
      if (path == '/api/admin/staff') {
        return jsonRes({'ok': true, 'staff': staff});
      }
      if (path == '/api/admin/dashboard') {
        return jsonRes(_dashboardJson);
      }
      if (path == '/api/admin/notifications') {
        return jsonRes({
          'ok': true,
          'notifications': <Map<String, dynamic>>[],
          'unreadCount': 0,
        });
      }
    }
    if (req.method == 'POST' && path == '/api/admin/codes') {
      final b = _body(req);
      rec.generates.add(b);
      if (generateResponse != null) return generateResponse(b);
      return jsonRes({
        'ok': true,
        'codeId': 'ac_new',
        'code': rawCode,
        'codeMasked': 'R•••444',
        'expiresAt': '2026-09-20T21:59:59.000Z',
        'staffName': 'خالد يوسف',
        'days': (b['days'] as num?)?.toInt() ?? 7,
        'type': b['type'],
      }, status: 201);
    }
    if (req.method == 'POST' && path == '/api/admin/codes/revoke') {
      final b = _body(req);
      rec.revokes.add(b);
      return jsonRes({'ok': true, 'revoked': true, 'message': revokeMessage});
    }
    if (req.method == 'POST' && path == '/api/admin/staff') {
      final b = _body(req);
      rec.staffPosts.add(b);
      return jsonRes({
        'ok': true,
        'staffMember': _staffJson(
          id: 'st_new',
          fullName: (b['fullName'] as String?) ?? '',
          role: (b['role'] as String?) ?? 'RECEPTION',
          phone: (b['phone'] as String?) ?? '',
        ),
      }, status: 201);
    }
    if (req.method == 'PATCH' && path.startsWith('/api/admin/staff/')) {
      final b = _body(req);
      rec.staffPatches.add(b);
      return jsonRes({
        'ok': true,
        'staffMember': staff.isNotEmpty
            ? staff.first
            : _staffJson(id: 'st_x', fullName: 'x', role: 'RECEPTION'),
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

List<Map<String, dynamic>> _defaultStaff() => [
      _staffJson(
        id: 'st_1',
        fullName: 'خالد يوسف',
        role: 'RECEPTION',
        lastCode: {
          'codeMasked': 'R•••900',
          'type': 'RECEPTION',
          'status': 'ACTIVE',
          'expiresAt': '2026-09-15T21:59:59.000Z',
        },
      ),
      _staffJson(
        id: 'st_2',
        fullName: 'سامية معطّلة',
        role: 'RECEPTION',
        active: false,
        phone: '+967770000000',
      ),
      _staffJson(
        id: 'st_3',
        fullName: 'مدير فندق',
        role: 'ADMIN',
        phone: '+967779999999',
      ),
    ];

List<Map<String, dynamic>> _defaultCodes() => [
      _codeJson(
        id: 'ac_1',
        codeMasked: 'R•••111',
        type: 'RECEPTION',
        status: 'ACTIVE',
        staffName: 'خالد يوسف',
        staffRole: 'RECEPTION',
      ),
      _codeJson(
        id: 'ac_2',
        codeMasked: 'H•••222',
        type: 'GUEST',
        status: 'REVOKED',
        guestName: 'نورا أحمد',
        roomNumber: '103',
        stayReference: 'ST-2026-77',
        lastUsedAt: '2026-08-20T10:00:00.000Z',
      ),
      _codeJson(
        id: 'ac_3',
        codeMasked: 'A•••333',
        type: 'ADMIN',
        status: 'EXPIRED',
        staffName: 'مدير فندق',
        staffRole: 'ADMIN',
      ),
    ];

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
  group('شاشة الطاقم والأكواد — تبويب الأكواد', () {
    testWidgets('(أ) بطاقات الأكواد: الكود/النوع/الحالة/السياق/آخر استخدام + العدّاد',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('الطاقم والأكواد'), findsOneWidget);
      expect(
        find.text('موظفو الفندق وأكواد الدخول — كود فعّال واحد على الأكثر لكل موظف'),
        findsOneWidget,
      );
      expect(find.text('3 كود'), findsOneWidget);
      // الكود المموّه LTR + شارات النوع/الحالة
      expect(find.text('R•••111'), findsOneWidget);
      expect(find.text('H•••222'), findsOneWidget);
      expect(find.text('A•••333'), findsOneWidget);
      expect(find.text('فعّال'), findsOneWidget);
      expect(find.text('ملغي'), findsOneWidget);
      expect(find.text('منتهي'), findsOneWidget);
      // السياق: موظف / ضيف + غرفة
      expect(find.text('خالد يوسف'), findsOneWidget);
      expect(find.text('ضيف — نورا أحمد (غرفة 103)'), findsOneWidget);
      expect(find.text('مدير فندق'), findsOneWidget);
      // الانتهاء وآخر استخدام (التواريخ بصيغة عربية)
      expect(find.textContaining('ينتهي في:'), findsNWidgets(3));
      expect(find.text('آخر استخدام: لم يُستخدم'), findsNWidgets(2));
      expect(find.textContaining('آخر استخدام:'), findsNWidgets(3));
      // إبطال للفعّال فقط — والملغي/المنتهي بدون زر
      expect(find.text('إبطال'), findsOneWidget);
      // الفلاتر الحرفية
      expect(find.text('كل الأنواع'), findsOneWidget);
      expect(find.text('كل الحالات'), findsOneWidget);
      expect(find.text('توليد كود'), findsOneWidget);
    });

    testWidgets('(ب) توليد كود: جسم POST الحرفي + الكود الخام يظهر مرة واحدة',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('توليد كود'));
      await tester.pumpAndSettle();
      expect(find.text('توليد كود دخول'), findsOneWidget);
      expect(
        find.text('الكود الخام يظهر مرة واحدة فقط عند التوليد — انسخه فورًا'),
        findsOneWidget,
      );

      // اختر الموظف (خالد — استقبال فعّال) — الافتراضي RECEPTION و7 أيام
      await tester.tap(find.text('اختر الموظف المطابق للدور'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خالد يوسف — استقبال'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('توليد الكود').last);
      await tester.pumpAndSettle();

      // جسم POST الحرفي — كما الويب {type, staffId, days}
      expect(rec.generates, hasLength(1));
      expect(rec.generates.single, {
        'type': 'RECEPTION',
        'staffId': 'st_1',
        'days': 7,
      });

      // الكود الخام ظاهر في الواجهة (RawCodeBox) مرة واحدة
      expect(find.text('R1234567'), findsOneWidget);
      expect(find.text('انسخه الآن — لن يظهر مرة أخرى'), findsOneWidget);
      expect(find.text('نسخ الكود'), findsOneWidget);
      expect(find.text('كود استقبال — خالد يوسف (7 يومًا)'), findsOneWidget);
      expect(find.textContaining('ينتهي:'), findsOneWidget);
      expect(find.text('المخزّن: '), findsOneWidget);
      expect(find.text('R•••444'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
      expect(find.text('توليد آخر'), findsOneWidget);
      expect(find.textContaining('تم توليد الكود'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(ج) الموظف المعطّل وغير المطابق غير قابلين للاختيار في حوار التوليد',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('توليد كود'));
      await tester.pumpAndSettle();

      // قوائم الحوار: النوع ثم الموظف (الأخير String)
      final dialogDropdowns = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(DropdownButton<String>),
      );
      final staffDropdown =
          tester.widget<DropdownButton<String>>(dialogDropdowns.last);

      // RECEPTION: الفعّال المطابق فقط — المعطّلة (st_2) والإدارة (st_3) غائبان
      final values =
          staffDropdown.items!.map((i) => i.value).toList(growable: false);
      expect(values, ['st_1']);
      expect(values.contains('st_2'), isFalse);
      expect(values.contains('st_3'), isFalse);

      // بدّل النوع إلى الإدارة — الموظفون المطابقون يتغيرون (A… فقط)
      await tester.tap(find.text('استقبال (R…)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إدارة (A…)').last);
      await tester.pumpAndSettle();

      final staffDropdownAfter =
          tester.widget<DropdownButton<String>>(dialogDropdowns.last);
      final valuesAfter =
          staffDropdownAfter.items!.map((i) => i.value).toList(growable: false);
      expect(valuesAfter, ['st_3']);
      expect(valuesAfter.contains('st_1'), isFalse);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
    });

    testWidgets('(د) إبطال كود: حوار تأكيد يذكر الجلسات + جسم {codeId} + رسالة الخادم',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إبطال'));
      await tester.pumpAndSettle();

      // حوار التأكيد الحرفي — يذكر إبطال الجلسات أيضًا
      expect(find.text('إبطال كود R•••111؟'), findsOneWidget);
      expect(find.textContaining('كود استقبال — خالد يوسف'), findsOneWidget);
      expect(
        find.textContaining('ستنتهي جلساته النشطة فورًا ولن يستطيع الدخول به'),
        findsOneWidget,
      );
      expect(find.textContaining('لن يمكن التراجع عن الإبطال'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('إبطال الكود'), findsOneWidget);

      await tester.tap(find.text('إبطال الكود'));
      await tester.pumpAndSettle();

      // جسم الإبطال الحرفي
      expect(rec.revokes, hasLength(1));
      expect(rec.revokes.single, {'codeId': 'ac_1'});

      // توست برسالة الخادم الحرفية («تم إبطال كود … وإبطال جلساته»)
      expect(find.textContaining('تم إبطال كود R•••111'), findsOneWidget);
      expect(find.textContaining('وإبطال جلساته'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(هـ) فلاتر الأكواد في استعلام GET: type=RECEPTION&status=ACTIVE',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();
      // التحميل الأولي: بلا فلاتر
      expect(rec.codeGets.last, '');

      await tester.tap(find.text('كل الأنواع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('استقبال').last);
      await tester.pumpAndSettle();
      expect(rec.codeGets.last, 'type=RECEPTION');

      await tester.tap(find.text('كل الحالات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('فعّال').last);
      await tester.pumpAndSettle();
      expect(rec.codeGets.last, 'type=RECEPTION&status=ACTIVE');
    });

    testWidgets('(و) رفض الخادم (تطابق الدور): رسالته الحرفية في توست الخطأ والحوار يبقى',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
        generateResponse: (_) => jsonRes({
          'ok': false,
          'error': 'كود الاستقبال يُولَّد لموظف بدور «استقبال» فقط',
        }, status: 400),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('توليد كود'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر الموظف المطابق للدور'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خالد يوسف — استقبال'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('توليد الكود').last);
      await tester.pumpAndSettle();

      expect(rec.generates, hasLength(1));
      // رسالة الخادم الحرفية في توست الخطأ
      expect(
        find.textContaining('كود الاستقبال يُولَّد لموظف بدور «استقبال» فقط'),
        findsOneWidget,
      );
      // الحوار بقى مفتوحًا — لا كود خام
      expect(find.text('توليد كود دخول'), findsOneWidget);
      expect(find.text('R1234567'), findsNothing);

      await _drainToast(tester);
    });
  });

  group('شاشة الطاقم والأكواد — تبويب الطاقم', () {
    testWidgets('(ز) إضافة موظف: جسم POST الحرفي {fullName,role,phone} مع trim',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الطاقم'));
      await tester.pumpAndSettle();
      expect(find.text('3 موظف'), findsOneWidget);

      await tester.tap(find.text('إضافة موظف'));
      await tester.pumpAndSettle();
      expect(find.text('أضف الموظف ثم ولّد له كود دخول'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم الكامل *'),
        '  سامي عبدالله  ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'الهاتف'),
        '  +96777111222  ',
      );
      // الدور الافتراضي: استقبال — كالويب (يُثبته جسم POST أدناه)

      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();

      expect(rec.staffPosts, hasLength(1));
      expect(rec.staffPosts.single, {
        'fullName': 'سامي عبدالله',
        'role': 'RECEPTION',
        'phone': '+96777111222',
      });
      expect(find.textContaining('تمت إضافة الموظف'), findsOneWidget);

      await _drainToast(tester);
    });

    testWidgets('(ح) تعطيل موظف: حوار تأكيد يذكر الكود والجلسات + جسم {active:false}',
        (tester) async {
      await _prepare(tester);
      final rec = _Recorder();
      final store = AdminStore(_api(_staffCodesMock(
        rec,
        staff: _defaultStaff(),
        codes: _defaultCodes(),
      )));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StaffCodesScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الطاقم'));
      await tester.pumpAndSettle();

      // بطاقة الموظف: الاسم/الدور/الهاتف/أحدث كود
      expect(find.text('خالد يوسف'), findsOneWidget);
      expect(find.text('أحدث كود'), findsNWidgets(3));
      expect(find.text('R•••900'), findsOneWidget);
      expect(find.text('لا يوجد كود — ولّد واحدًا من تبويب الأكواد'),
          findsNWidgets(2));
      expect(find.textContaining('ينتهي:'), findsOneWidget);

      // مفتاح التفعيل — التعطيل يستلزم تأكيدًا يذكر الكود والجلسات
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('تعطيل خالد يوسف؟'), findsOneWidget);
      expect(find.textContaining('كوده النشط وجلساته فورًا'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('تعطيل الموظف'), findsOneWidget);

      await tester.tap(find.text('تعطيل الموظف'));
      await tester.pumpAndSettle();

      expect(rec.staffPatches, hasLength(1));
      expect(rec.staffPatches.single, {'active': false});
      expect(
        find.textContaining('تم تعطيل الموظف — أُبطل كوده النشط وجلساته فورًا'),
        findsOneWidget,
      );

      await _drainToast(tester);
    });
  });
}

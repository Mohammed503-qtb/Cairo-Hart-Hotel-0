// ─────────────────────────────────────────────────────────────
// TEST: سجل التدقيق (A-32) + الضيوف (A-31) + التقارير (A-33)
// التدقيق: بطاقات السجل (chip/فاعل/كيان/تفاصيل) + الصفحة التالية
// (page=2 في الاستعلام + أزرار التنقل) + فلتر الإجراء في GET +
// البحث الحر q= — الضيوف: البحث + البطاقة (فارغ آمن) — التقارير:
// الإشغال (نسب) + الإيراد (تنسيق المال) + الطلبات + الجنسيات
// (نفس نمط rooms_test: MockClient → ApiClient → AdminStore)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/audit_log_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/guests_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/reports_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

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

// ═══════════════════ سجل التدقيق ═══════════════════

Map<String, dynamic> _auditJson({
  required String id,
  required String action,
  required String entityId,
  required String actor,
  required String actorRole,
  required Map<String, dynamic> details,
  required String createdAt,
  String entityType = 'AccessCode',
}) {
  return {
    'id': id,
    'action': action,
    'entityType': entityType,
    'entityId': entityId,
    'actor': actor,
    'actorRole': actorRole,
    'details': details,
    'createdAt': createdAt,
  };
}

final List<Map<String, dynamic>> _auditPage1 = [
  _auditJson(
    id: 'al_1',
    action: 'CODE_GENERATED',
    entityId: 'ac_9fullidentifier01',
    actor: 'خالد يوسف',
    actorRole: 'RECEPTION',
    details: {'op': 'CREATE', 'fullName': 'خالد يوسف', 'role': 'RECEPTION'},
    createdAt: '2026-08-25T10:00:00.000Z',
  ),
  _auditJson(
    id: 'al_2',
    action: 'STAFF_CHANGED',
    entityType: 'Staff',
    entityId: 'st_2',
    actor: 'مدير فندق',
    actorRole: 'ADMIN',
    details: {'op': 'UPDATE', 'changed': ['phone']},
    createdAt: '2026-08-24T09:30:00.000Z',
  ),
];

final List<Map<String, dynamic>> _auditPage2 = [
  _auditJson(
    id: 'al_3',
    action: 'CODE_REVOKED',
    entityId: 'ac_2',
    actor: 'سامي العمودي',
    actorRole: 'WEBSITE',
    details: {'codeMasked': 'R•••5678', 'context': 'خالد يوسف'},
    createdAt: '2026-08-23T08:00:00.000Z',
  ),
];

/// وهمي التدقيق: مصفّح 30/صفحة — يستجيب للصفحة/الفعل/البحث
MockClient _auditMock({
  int total = 45,
  int pages = 2,
  void Function(String query)? onGet,
}) {
  return MockClient((req) async {
    if (req.method == 'GET' && req.url.path == '/api/admin/audit') {
      final query = req.url.query ?? '';
      onGet?.call(query);
      final params = req.url.queryParameters;
      final page = params['page'] ?? '1';
      final items = page == '2' ? _auditPage2 : _auditPage1;
      return jsonRes({
        'ok': true,
        'items': items,
        'total': total,
        'page': int.tryParse(page) ?? 1,
        'limit': 30,
        'pages': pages,
      });
    }
    return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
  });
}

void main() {
  group('شاشة سجل التدقيق', () {
    testWidgets('(أ) بطاقات السجل: chip الإجراء/الفاعل ودوره/الكيان/التفاصيل + العدّاد',
        (tester) async {
      await _prepare(tester);
      final queries = <String>[];
      final store = AdminStore(_api(_auditMock(onGet: queries.add)));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AuditLogScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('سجل التدقيق'), findsOneWidget);
      expect(find.text('45 حدث — كل العمليات الحساسة مسجلة'), findsOneWidget);
      expect(queries.first, 'page=1');

      // شارة الإجراء + الفاعل ودوره + الكيان (entityType + معرّف مقتطع)
      expect(find.text('توليد كود'), findsOneWidget);
      expect(find.text('خالد يوسف · الاستقبال'), findsOneWidget);
      expect(find.text('مدير فندق · الإدارة'), findsOneWidget);
      expect(find.text('AccessCode'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.textContaining('ac_9fullidentifi'), findsOneWidget);
      // التفاصيل: خريطة (مفتاح: قيمة) قراءة-friendly
      expect(find.textContaining('op: CREATE'), findsOneWidget);
      expect(find.textContaining('fullName: خالد يوسف'), findsOneWidget);
      expect(find.textContaining('role: RECEPTION'), findsOneWidget);
      expect(find.textContaining('op: UPDATE'), findsOneWidget);
      expect(find.textContaining('changed: phone'), findsOneWidget);
      // الوقت (تاريخ كامل + منذ)
      expect(find.textContaining('أغسطس 2026'), findsNWidgets(2));

      // قائمة الفلتر الحرفية: 24 فعلًا + «كل الأفعال»
      final dropdown =
          tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      final values =
          dropdown.items!.map((i) => i.value).toList(growable: false);
      expect(values, hasLength(25));
      expect(values.first, 'all');
      expect(
        values,
        containsAll([
          'RESERVATION_CREATED',
          'CHECK_IN',
          'CHECK_OUT',
          'ROOM_CHANGED',
          'ROOM_TYPE_CHANGED',
          'RATE_CHANGED',
          'SETTINGS_UPDATED',
          'SERVICE_CATALOG_CHANGED',
          'STAFF_CHANGED',
          'CODE_GENERATED',
          'CODE_REVOKED',
          'CODE_LOGIN',
          'CODE_LOGIN_FAILED',
          'PAYMENT_RECORDED',
          'EXTENSION_APPROVED',
          'CHAT_MESSAGE',
          'CHARGE_ADDED',
          'CHECKOUT_REQUESTED',
        ]),
      );

      // العارض: الإجمالي + صفحة 1 من 2 + أزرار التنقل
      expect(find.text('الإجمالي: ٤٥'), findsOneWidget);
      expect(find.text('صفحة 1 من 2'), findsOneWidget);
      expect(find.text('السابق'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
      // البحث الحر
      expect(find.text('الفاعل / الكيان / المعرّف…'), findsOneWidget);
      expect(find.text('بحث'), findsOneWidget);
    });

    testWidgets('(ب) الصفحة التالية: page=2 في الاستعلام + عناصر الصفحة الجديدة',
        (tester) async {
      await _prepare(tester);
      final queries = <String>[];
      final store = AdminStore(_api(_auditMock(onGet: queries.add)));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AuditLogScreen(store: store))),
      );
      await tester.pumpAndSettle();
      expect(find.text('صفحة 1 من 2'), findsOneWidget);
      expect(find.text('خالد يوسف · الاستقبال'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // page=2 في استعلام GET + عناصر الصفحة الثانية
      expect(queries.last, 'page=2');
      expect(find.text('صفحة 2 من 2'), findsOneWidget);
      expect(find.text('سامي العمودي · الموقع'), findsOneWidget);
      expect(find.text('إبطال كود'), findsOneWidget);
      expect(find.textContaining('codeMasked: R•••5678'), findsOneWidget);
      // عناصر الصفحة الأولى اختفت
      expect(find.text('خالد يوسف · الاستقبال'), findsNothing);
    });

    testWidgets('(ج) فلتر الإجراء: action=RESERVATION_CREATED في استعلام GET',
        (tester) async {
      await _prepare(tester);
      final queries = <String>[];
      final store = AdminStore(_api(_auditMock(onGet: queries.add)));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AuditLogScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('كل الأفعال'));
      await tester.pumpAndSettle();
      // أول فعل في القائمة الحرفية (مرئي بلا تمرير)
      await tester.tap(find.text('إنشاء حجز').last);
      await tester.pumpAndSettle();

      expect(queries.last, 'page=1&action=RESERVATION_CREATED');
      // القائمة المغلقة تعرض الفعل المختار
      expect(find.text('إنشاء حجز'), findsOneWidget);
    });

    testWidgets('(د) البحث الحر: q= في استعلام GET + مسح البحث',
        (tester) async {
      await _prepare(tester);
      final queries = <String>[];
      final store = AdminStore(_api(_auditMock(onGet: queries.add)));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AuditLogScreen(store: store))),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'خالد');
      await tester.pumpAndSettle();
      await tester.tap(find.text('بحث'));
      await tester.pumpAndSettle();

      // q في استعلام GET (بترميز الاستعلام) — يُفك للتحقق
      final params = Uri.parse('https://h/?${queries.last}').queryParameters;
      expect(params['page'], '1');
      expect(params['q'], 'خالد');
      // البحث يقيم في المخزن — الحقل يحتفظ به (EditableText)
      expect(find.text('خالد'), findsOneWidget);

      // مسح البحث → q فارغ
      await tester.tap(find.byTooltip('مسح البحث'));
      await tester.pumpAndSettle();
      expect(queries.last, 'page=1');
    });
  });

  // ═══════════════════ الضيوف ═══════════════════

  group('شاشة الضيوف', () {
    testWidgets('(هـ) بطاقة الضيف (فارغ آمن) + البحث q= في استعلام GET',
        (tester) async {
      await _prepare(tester);
      final queries = <String>[];
      final guests = <Map<String, dynamic>>[
        {
          'id': 'g_1',
          'fullName': 'نورا أحمد',
          'phone': '+967778123456',
          'email': 'nora@example.com',
          'nationality': 'مصري',
          'createdAt': '2026-07-15T09:00:00.000Z',
          'reservationsCount': 3,
          'lastReservation': {
            'bookingReference': 'HTL-2026-88',
            'checkIn': '2026-09-05T12:00:00.000Z',
            'status': 'CHECKED_IN',
          },
        },
        {
          'id': 'g_2',
          'fullName': 'ضيف سابق',
          'phone': '+967770000000',
          'email': null,
          'nationality': null,
          'createdAt': '2026-06-01T09:00:00.000Z',
          'reservationsCount': 0,
          'lastReservation': null,
        },
      ];
      final store = AdminStore(_api(MockClient((req) async {
        if (req.method == 'GET' && req.url.path == '/api/admin/guests') {
          final q = req.url.queryParameters['q'] ?? '';
          queries.add(q);
          final list = q.isEmpty
              ? guests
              : guests
                  .where((g) => (g['fullName'] as String).contains(q))
                  .toList(growable: false);
          return jsonRes({'ok': true, 'guests': list});
        }
        return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
      })));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GuestsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('الضيوف'), findsOneWidget);
      expect(find.text('2 ضيف في السجل'), findsOneWidget);
      // بطاقة الضيف: الاسم/الهاتف/البريد/الجنسية/الحجوزات
      expect(find.text('نورا أحمد'), findsOneWidget);
      expect(find.text('+967778123456'), findsOneWidget);
      expect(find.text('nora@example.com'), findsOneWidget);
      expect(find.text('مصري'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.textContaining('يوليو 2026'), findsOneWidget);
      // آخر حجز: المرجع + تاريخ الوصول + شارة الحالة
      expect(find.text('HTL-2026-88'), findsOneWidget);
      expect(find.textContaining('5 سبتمبر 2026'), findsOneWidget);
      expect(find.text('مسجّل دخول'), findsOneWidget);
      // الحقول الفارغة بأمان: البريد/الجنسية/آخر حجز → '—'
      expect(find.text('ضيف سابق'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));

      // البحث: q= في استعلام GET + النتيجة تُرشَّح
      await tester.enterText(find.byType(TextField), 'نورا');
      await tester.pumpAndSettle();
      await tester.tap(find.text('بحث'));
      await tester.pumpAndSettle();

      expect(queries.last, 'نورا');
      expect(find.text('1 ضيف في السجل'), findsOneWidget);
      expect(find.text('نورا أحمد'), findsOneWidget);
      expect(find.text('ضيف سابق'), findsNothing);
    });
  });

  // ═══════════════════ التقارير ═══════════════════

  Map<String, dynamic> _reportsJson({
    List<Map<String, dynamic>> occupancy = const [
      {'date': '2026-08-11', 'label': '11 أغسطس', 'percent': 50, 'occupied': 7},
      {'date': '2026-08-12', 'label': '12 أغسطس', 'percent': 75, 'occupied': 10},
      {'date': '2026-08-13', 'label': '13 أغسطس', 'percent': 0, 'occupied': 0},
    ],
    List<Map<String, dynamic>> revenue = const [
      {'month': 'يونيو', 'totalCents': 317000, 'count': 2},
      {'month': 'يوليو', 'totalCents': 150000, 'count': 1},
    ],
    Map<String, dynamic> requestsStats = const {
      'total': 12,
      'byStatus': [
        {'status': 'NEW', 'count': 2},
        {'status': 'COMPLETED', 'count': 8},
        {'status': 'IN_PROGRESS', 'count': 2},
      ],
      'completed': 8,
      'active': 4,
      'avgCompletionMinutes': 35,
      'topServices': [
        {'title': 'تنظيف الغرفة', 'count': 5},
        {'title': 'صيانة تكييف', 'count': 2},
      ],
    },
    List<Map<String, dynamic>> nationalities = const [
      {'nationality': 'مصري', 'count': 9},
      {'nationality': 'سعودي', 'count': 3},
    ],
    int effectiveRooms = 14,
  }) {
    return {
      'ok': true,
      'effectiveRooms': effectiveRooms,
      'occupancyLast14Days': occupancy,
      'revenueByMonth': revenue,
      'requestsStats': requestsStats,
      'guestsByNationality': nationalities,
    };
  }

  group('شاشة التقارير', () {
    testWidgets('(و) الإشغال (نسبة فوق كل عمود) + الإيراد (تنسيق المال) + الطلبات + الجنسيات',
        (tester) async {
      await _prepare(tester);
      final store = AdminStore(_api(MockClient((req) async {
        if (req.method == 'GET' && req.url.path == '/api/admin/reports') {
          return jsonRes(_reportsJson());
        }
        return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
      })));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ReportsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      expect(find.text('التقارير'), findsOneWidget);
      expect(find.text('مؤشرات الأداء التشغيلي والمالي'), findsOneWidget);

      // الإشغال آخر 14 يومًا: القيمة فوق كل عمود + التسميات + الغرف الفعالة
      expect(find.text('نسبة الإشغال — آخر 14 يومًا'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('11 أغسطس'), findsOneWidget);
      expect(find.text('12 أغسطس'), findsOneWidget);
      expect(
        find.text('المحسوبة على 14 غرفة فعّالة (بدون خارج الخدمة)'),
        findsOneWidget,
      );

      // الإيراد آخر 6 أشهر: بالسنت → تنسيق fmt.formatMoney
      expect(find.text('الإيراد — آخر 6 أشهر'), findsOneWidget);
      expect(find.text(r'$3,170.00'), findsOneWidget);
      expect(find.text(r'$1,500.00'), findsOneWidget);
      expect(find.text('يونيو'), findsOneWidget);
      expect(find.text('يوليو'), findsOneWidget);

      // إحصاءات الطلبات: الصناديق الأربعة (المتوسط انتهائي)
      expect(find.text('طلبات الخدمة'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('متوسط الإنجاز'), findsOneWidget);
      expect(find.text('35د'), findsOneWidget);
      // byStatus chips: تسمية + عدد
      expect(find.text('جديد · 2'), findsOneWidget);
      expect(find.text('مكتمل · 8'), findsOneWidget);
      expect(find.text('قيد التنفيذ · 2'), findsOneWidget);
      // أعلى الخدمات
      expect(find.text('أكثر الخدمات طلبًا'), findsOneWidget);
      expect(find.text('تنظيف الغرفة'), findsOneWidget);
      expect(find.text('صيانة تكييف'), findsOneWidget);

      // الجنسيات (أعلى 5)
      expect(find.text('الضيوف حسب الجنسية (أعلى 5)'), findsOneWidget);
      expect(find.text('مصري'), findsOneWidget);
      expect(find.text('9 ضيف'), findsOneWidget);
      expect(find.text('سعودي'), findsOneWidget);
      expect(find.text('3 ضيف'), findsOneWidget);
    });

    testWidgets('(ز) فراغ آمن: بلا بيانات + متوسط إنجاز انتهائي null → «—»',
        (tester) async {
      await _prepare(tester);
      final store = AdminStore(_api(MockClient((req) async {
        if (req.method == 'GET' && req.url.path == '/api/admin/reports') {
          return jsonRes(_reportsJson(
            occupancy: const <Map<String, dynamic>>[],
            revenue: const <Map<String, dynamic>>[],
            requestsStats: const {
              'total': 2,
              'byStatus': [
                {'status': 'NEW', 'count': 2},
              ],
              'completed': 0,
              'active': 2,
              'avgCompletionMinutes': null,
              'topServices': [
                {'title': 'إفطار', 'count': 2},
              ],
            },
            nationalities: const <Map<String, dynamic>>[],
          ));
        }
        return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
      })));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ReportsScreen(store: store))),
      );
      await tester.pumpAndSettle();

      // المخططات الفارغة
      expect(find.text('لا توجد بيانات'), findsNWidgets(2));
      // متوسط الإنجاز null → «—» (انتهائي null آمن)
      expect(find.text('متوسط الإنجاز'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2)); // الإجمالي + نشط
      expect(find.text('0'), findsOneWidget); // مكتمل
      expect(find.text('إفطار'), findsOneWidget);
      // الجنسيات الفارغة
      expect(find.text('لا يوجد ضيوف'), findsOneWidget);
    });
  });
}

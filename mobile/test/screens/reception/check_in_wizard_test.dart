// ─────────────────────────────────────────────────────────────
// TEST: معالج تسجيل الوصول — المسار الكامل (4 خطوات) + الحجز غير الموجود
// (نقل check-in-wizard: التحكم في الغرف المتاحة وجسم POST وكود الضيف)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/wizards/check_in_wizard.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _arrivalJson() => {
      'id': 'rx_01',
      'bookingReference': 'HTL-2026-000421',
      'status': 'CONFIRMED',
      'source': 'WEBSITE',
      'checkIn': '2026-09-02T14:00:00.000Z',
      'checkOut': '2026-09-05T12:00:00.000Z',
      'nights': 3,
      'adults': 2,
      'children': 1,
      'roomsCount': 1,
      'currency': 'USD',
      'subtotalCents': 48000,
      'taxCents': 7200,
      'grandTotalCents': 55200,
      'paidCents': 27600,
      'paymentStatus': 'PARTIALLY_PAID',
      'createdAt': '2026-08-20T10:00:00.000Z',
      'hasStay': false,
      'guest': {
        'id': 'g_1',
        'fullName': 'أحمد محمد',
        'phone': '+967771234567',
      },
      'roomType': {
        'id': 'rt_deluxe',
        'name': 'غرفة ديلوكس',
        'basePriceCents': 16000,
        'capacityAdults': 2,
        'capacityChildren': 2,
        'bedConfig': 'سرير مزدوج كبير',
        'sizeSqm': 28,
      },
      'specialRequests': 'طابق مرتفع إن أمكن',
    };

List<Map<String, dynamic>> _roomsJson() => [
      {
        'id': 'r_201',
        'number': '201',
        'floor': 2,
        'status': 'AVAILABLE',
        'roomTypeId': 'rt_deluxe',
        'roomTypeName': 'غرفة ديلوكس',
      },
      {
        'id': 'r_202',
        'number': '202',
        'floor': 2,
        'status': 'AVAILABLE',
        'roomTypeId': 'rt_deluxe',
        'roomTypeName': 'غرفة ديلوكس',
      },
      {
        'id': 'r_301',
        'number': '301',
        'floor': 3,
        'status': 'OCCUPIED',
        'roomTypeId': 'rt_deluxe',
        'roomTypeName': 'غرفة ديلوكس',
      },
      {
        'id': 'r_101',
        'number': '101',
        'floor': 1,
        'status': 'AVAILABLE',
        'roomTypeId': 'rt_single',
        'roomTypeName': 'غرفة مفردة',
      },
    ];

Map<String, dynamic> _checkInResultJson() => {
      'ok': true,
      'stay': {'id': 'st_9', 'reference': 'ST-2026-000004'},
      'roomNumber': '202',
      'guestCode': 'H334469T0',
      'guestName': 'أحمد محمد',
      'guestPhone': '+967771234567',
    };

Map<String, dynamic> _emptyStats() => {
      'arrivalsToday': 0,
      'departuresToday': 0,
      'inHouseStays': 0,
      'pendingRequests': 0,
      'urgentRequests': 0,
      'occupancyPercent': 0,
      'totalRooms': 0,
      'occupiedRooms': 0,
    };

/// عميل وهمي كامل: وصولات + غرف + تسجيل وصول + تحديثات ما بعد العملية
MockClient _wizardMock(
  List<Map<String, dynamic>> checkInBodies,
  List<String> arrivalDates,
) {
  return MockClient((req) async {
    if (req.method == 'GET' && req.url.path == '/api/reception/arrivals') {
      arrivalDates.add(req.url.queryParameters['date'] ?? '');
      return jsonRes({
        'ok': true,
        'arrivals': <Map<String, dynamic>>[_arrivalJson()],
      });
    }
    if (req.method == 'GET' && req.url.path == '/api/reception/rooms') {
      return jsonRes({'ok': true, 'rooms': _roomsJson()});
    }
    if (req.method == 'POST' && req.url.path == '/api/reception/check-in') {
      checkInBodies.add(
        jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>,
      );
      return jsonRes(_checkInResultJson());
    }
    // تحديثات ما بعد العملية (كلها فارغة — فشلها لا يبطل النجاح)
    if (req.url.path == '/api/reception/dashboard') {
      return jsonRes({
        'ok': true,
        'stats': _emptyStats(),
        'arrivals': <Map<String, dynamic>>[],
        'departures': <Map<String, dynamic>>[],
        'pendingRequests': <Map<String, dynamic>>[],
      });
    }
    if (req.url.path == '/api/reception/departures') {
      return jsonRes({'ok': true, 'departures': <Map<String, dynamic>>[]});
    }
    if (req.url.path == '/api/reception/notifications') {
      return jsonRes({
        'ok': true,
        'notifications': <Map<String, dynamic>>[],
        'unreadCount': 0,
      });
    }
    return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
  });
}

ReceptionStore _store(MockClient mock) => ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: mock,
      ),
    );

/// ضخ شاشة حاضنة بزر يفتح المعالج (زر نصي كي لا يختلط بأزرار المعالج)
Future<void> _pumpOpener(
  WidgetTester tester, {
  required ReceptionStore store,
  required String reservationId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showCheckInWizard(
              context,
              store: store,
              reservationId: reservationId,
              checkInIso: '2026-09-02T14:00:00.000Z',
            ),
            child: const Text('افتح المعالج'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('افتح المعالج'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('المسار الكامل: تحقق → غرفة → تأكيد → كود الضيف', (tester) async {
    final checkInBodies = <Map<String, dynamic>>[];
    final arrivalDates = <String>[];
    final store = _store(_wizardMock(checkInBodies, arrivalDates));

    await _pumpOpener(tester, store: store, reservationId: 'rx_01');

    // الخطوة 1: بيانات الحجز من وصولات يوم الوصول
    expect(find.textContaining('التحقق من الضيف'), findsOneWidget);
    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(arrivalDates, contains('2026-09-02'));

    // الخطوة 2: الغرف المتاحة من نفس النوع فقط
    await tester.ensureVisible(find.text('متابعة'));
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعيين الغرفة'), findsOneWidget);
    expect(find.text('202'), findsOneWidget);
    expect(find.text('201'), findsOneWidget);
    expect(find.text('301'), findsNothing); // مشغولة — غير قابلة للاختيار
    expect(find.text('101'), findsNothing); // نوع مختلف

    // اختيار الغرفة 202 ثم المتابعة
    await tester.ensureVisible(find.text('202'));
    await tester.tap(find.text('202'));
    await tester.pump();
    await tester.ensureVisible(find.text('متابعة'));
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();

    // الخطوة 3: التأكيد النهائي
    expect(find.textContaining('التأكيد النهائي'), findsOneWidget);
    expect(find.text('الغرفة المختارة'), findsOneWidget);

    await tester.ensureVisible(find.text('تأكيد تسجيل الوصول'));
    await tester.tap(find.text('تأكيد تسجيل الوصول'));
    await tester.pumpAndSettle();

    // الخطوة 4: النجاح + كود الضيف مرة واحدة
    expect(find.text('تم تسجيل الوصول ✅'), findsOneWidget);
    expect(find.text('H334469T0'), findsOneWidget);
    expect(find.textContaining('احتفظ بالكود الآن'), findsOneWidget);
    expect(find.text('ST-2026-000004'), findsOneWidget);

    // جسم POST: reservationId + roomId المختارة وبلا idNumber فارغ
    expect(checkInBodies, hasLength(1));
    expect(checkInBodies.single['reservationId'], 'rx_01');
    expect(checkInBodies.single['roomId'], 'r_202');
    expect(checkInBodies.single.containsKey('idNumber'), isFalse);

    // الإغلاق: الحوار يُغلق ويختفي الكود
    await tester.ensureVisible(find.text('تم'));
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(find.text('H334469T0'), findsNothing);
  });

  testWidgets('حجز غير موجود في وصولات اليوم → الرسالة الحرفية والزر معطّل',
      (tester) async {
    final store = _store(
      MockClient((req) async {
        if (req.url.path == '/api/reception/arrivals') {
          return jsonRes({
            'ok': true,
            'arrivals': <Map<String, dynamic>>[_arrivalJson()],
          });
        }
        return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
      }),
    );

    await _pumpOpener(tester, store: store, reservationId: 'rx_404');

    expect(
      find.textContaining('لم يتم العثور على الحجز في وصولات هذا اليوم'),
      findsOneWidget,
    );
    // زر «متابعة» الوحيد في المعالج معطّل (الحجز غير موجود)
    expect(find.bySubtype<FilledButton>(), findsOneWidget);
    final next = tester.widget<FilledButton>(
      find.bySubtype<FilledButton>().first,
    );
    expect(next.enabled, isFalse);
  });
}

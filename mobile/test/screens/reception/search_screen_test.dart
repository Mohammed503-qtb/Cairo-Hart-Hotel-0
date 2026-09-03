// ─────────────────────────────────────────────────────────────
// TEST: حوار البحث العام — نقل search-dialog.tsx
// debounce 350ms + حد الحرفين + النقر يفتح تفصيل الإقامة (عقد 20-a)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/search_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

/// شكل R-05 كامل (بالسنت) — يخدم showStayDetail عبر loadStayDetail
Map<String, dynamic> _stayDetailJson() => {
      'ok': true,
      'stay': {
        'id': 'st_9',
        'reference': 'ST-2026-000009',
        'status': 'ACTIVE',
        'checkInAt': '2026-09-01T14:00:00.000Z',
        'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
      },
      'guest': {
        'id': 'g_9',
        'fullName': 'نورا سالم',
        'phone': '+967771234567',
      },
      'room': {
        'id': 'rm_105',
        'number': '105',
        'floor': 1,
        'status': 'OCCUPIED',
      },
      'roomType': {
        'id': 'rt_1',
        'name': 'غرفة قياسية',
        'bedConfig': 'سرير مزدوج',
        'sizeSqm': 22,
      },
      'reservation': {
        'id': 'rsv_9',
        'bookingReference': 'HTL-2026-000429',
        'status': 'CHECKED_IN',
        'source': 'WEBSITE',
        'checkIn': '2026-09-01',
        'checkOut': '2026-09-04',
        'adults': 2,
        'children': 0,
        'roomsCount': 1,
        'currency': 'USD',
        'subtotalCents': 48000,
        'taxCents': 7200,
        'grandTotalCents': 55200,
        'paidCents': 55200,
        'paymentStatus': 'PAID',
      },
      'bill': {
        'stayId': 'st_9',
        'stayReference': 'ST-2026-000009',
        'roomTotalCents': 55200,
        'roomSubtotalCents': 48000,
        'roomTaxCents': 7200,
        'extraCharges': <Map<String, dynamic>>[],
        'extraTotalCents': 0,
        'payments': <Map<String, dynamic>>[],
        'totalChargesCents': 55200,
        'totalPaidCents': 55200,
        'balanceCents': 0,
        'currency': 'USD',
      },
      'requests': <Map<String, dynamic>>[],
      'extensionRequests': <Map<String, dynamic>>[],
      'roomChangeRequests': <Map<String, dynamic>>[],
      'messages': <Map<String, dynamic>>[],
    };

/// وهمي موحّد: البحث + تفصيل الإقامة (المسار المستدعى من showStayDetail)
MockClient _searchMock({
  required List<String> searchQueries,
  required List<String> stayDetailCalls,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/reception/search') {
      searchQueries.add(req.url.queryParameters['q'] ?? '');
      return jsonRes({
        'ok': true,
        'reservations': [
          {
            'id': 'rsv_1',
            'bookingReference': 'HTL-2026-000421',
            'guestName': 'أحمد محمد',
            'guestPhone': '+967771234567',
            'status': 'CONFIRMED',
            'checkIn': '2026-09-02',
            'checkOut': '2026-09-05',
            'roomTypeName': 'غرفة ديلوكس',
            'paymentStatus': 'UNPAID',
            'stayId': null,
          },
        ],
        'stays': [
          {
            'id': 'st_9',
            'reference': 'ST-2026-000009',
            'guestName': 'نورا سالم',
            'guestPhone': '+967771234567',
            'roomNumber': '105',
            'roomTypeName': 'غرفة قياسية',
            'status': 'ACTIVE',
            'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
          },
        ],
      });
    }
    if (path == '/api/reception/stays/st_9') {
      stayDetailCalls.add(path);
      return jsonRes(_stayDetailJson());
    }
    return jsonRes({'ok': true});
  });
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () => {},
      httpClient: client,
    );

/// مضيف يفتح الحوار بزر (يوفر سياق showDialog)
class _Host extends StatelessWidget {
  const _Host({required this.store});

  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showReceptionSearch(context, store: store),
          child: const Text('افتح البحث'),
        ),
      ),
    );
  }
}

Future<void> _openSearch(WidgetTester tester, ReceptionStore store) async {
  await tester.pumpWidget(MaterialApp(home: _Host(store: store)));
  await tester.tap(find.text('افتح البحث'));
  await tester.pumpAndSettle();
}

void main() {
  group('حوار البحث العام', () {
    testWidgets('(أ) حرفان + debounce → قسما الحجوزات والإقامات',
        (tester) async {
      final searchQueries = <String>[];
      final stayDetailCalls = <String>[];
      final api = _api(_searchMock(
        searchQueries: searchQueries,
        stayDetailCalls: stayDetailCalls,
      ));
      final store = ReceptionStore(api);
      await _openSearch(tester, store);

      await tester.enterText(find.byType(TextField), 'خل');
      // انتظار debounce 350ms ثم اكتمال الجلب
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(searchQueries, ['خل']);
      expect(find.text('الحجوزات (1)'), findsOneWidget);
      expect(find.text('الإقامات النشطة (1)'), findsOneWidget);
      // بطاقة الحجز: الاسم + المرجع + شارتا الحجز والدفع + السطر
      expect(find.text('أحمد محمد'), findsOneWidget);
      expect(find.text('HTL-2026-000421'), findsOneWidget);
      expect(find.text('مؤكد'), findsOneWidget);
      expect(find.text('غير مدفوع'), findsOneWidget);
      expect(find.textContaining('غرفة ديلوكس'), findsOneWidget);
      // بطاقة الإقامة: الاسم + الغرفة + المرجع
      expect(find.text('نورا سالم'), findsOneWidget);
      expect(find.text('غرفة 105'), findsOneWidget);
      expect(find.text('ST-2026-000009'), findsOneWidget);
    });

    testWidgets('(ب) أقل من حرفين → «اكتب حرفين على الأقل للبحث…»',
        (tester) async {
      final searchQueries = <String>[];
      final stayDetailCalls = <String>[];
      final api = _api(_searchMock(
        searchQueries: searchQueries,
        stayDetailCalls: stayDetailCalls,
      ));
      final store = ReceptionStore(api);
      await _openSearch(tester, store);

      await tester.enterText(find.byType(TextField), 'خ');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('اكتب حرفين على الأقل للبحث…'), findsOneWidget);
      expect(searchQueries, isEmpty);
      expect(find.text('الحجوزات (1)'), findsNothing);
      expect(find.text('الإقامات النشطة (1)'), findsNothing);
    });

    testWidgets('(ج) نقر نتيجة إقامة → فتح showStayDetail بجلب R-05',
        (tester) async {
      final searchQueries = <String>[];
      final stayDetailCalls = <String>[];
      final api = _api(_searchMock(
        searchQueries: searchQueries,
        stayDetailCalls: stayDetailCalls,
      ));
      final store = ReceptionStore(api);
      await _openSearch(tester, store);

      await tester.enterText(find.byType(TextField), 'نورا');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // النقر على بطاقة الإقامة: يُغلق البحث ويفتح تفصيل الإقامة
      await tester.tap(find.text('نورا سالم'));
      await tester.pumpAndSettle();

      // عقد 20-a: showStayDetail(stayId: 'st_9') يجلب R-05 من الخادم
      expect(stayDetailCalls, ['/api/reception/stays/st_9']);
      // حوار البحث أُغلق (الزر المضيف عاد وحيدًا في الجذر)
      expect(find.text('الحجوزات (1)'), findsNothing);
    });
  });
}

// ─────────────────────────────────────────────────────────────
// TEST: شاشة الوصولون — بطاقات الحجوزات وحالة زر تسجيل الوصول
// (نقل حالتي arrivals-view: قائمة معبأة / يوم بلا وصولات)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/arrivals_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _arrivalJson(
  String id, {
  required String name,
  required String status,
  required String reference,
  String? specialRequests,
}) =>
    {
      'id': id,
      'bookingReference': reference,
      'status': status,
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
      'paymentMethod': 'CARD',
      'createdAt': '2026-08-20T10:00:00.000Z',
      'hasStay': false,
      'guest': {
        'id': 'g_$id',
        'fullName': name,
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
      'specialRequests': specialRequests,
    };

void main() {
  testWidgets('يعرض الوصولين ويعطّل زر الوصول للحجز غير المؤكد', (tester) async {
    final api = ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: MockClient(
        (req) async {
          if (req.url.path == '/api/reception/arrivals') {
            return jsonRes({
              'ok': true,
              'arrivals': [
                _arrivalJson(
                  'rx_01',
                  name: 'أحمد محمد',
                  status: 'CONFIRMED',
                  reference: 'HTL-2026-000421',
                ),
                _arrivalJson(
                  'rx_02',
                  name: 'سارة عبدالله',
                  status: 'PENDING',
                  reference: 'HTL-2026-000422',
                  specialRequests: 'سرير أطفال إن أمكن',
                ),
              ],
            });
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        },
      ),
    );
    final store = ReceptionStore(api);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ArrivalsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('سارة عبدالله'), findsOneWidget);
    expect(find.text('HTL-2026-000421'), findsOneWidget);
    expect(find.text('سرير أطفال إن أمكن'), findsOneWidget);
    expect(find.text('تسجيل الوصول'), findsNWidgets(2));

    // زر الوصول مفعّل للمؤكد ومعطّل لقيد الانتظار (ترتيب الشجرة = ترتيب القائمة)
    final buttons = find.bySubtype<FilledButton>();
    expect(buttons, findsNWidgets(2));
    expect(tester.widget<FilledButton>(buttons.at(0)).enabled, isTrue);
    expect(tester.widget<FilledButton>(buttons.at(1)).enabled, isFalse);
  });

  testWidgets('يوم بلا وصولات → حالة الفراغ', (tester) async {
    final api = ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: MockClient(
        (req) async {
          if (req.url.path == '/api/reception/arrivals') {
            return jsonRes({'ok': true, 'arrivals': <Map<String, dynamic>>[]});
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        },
      ),
    );
    final store = ReceptionStore(api);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ArrivalsScreen(store: store))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('لا وصولات'), findsOneWidget);
    expect(find.text('تسجيل الوصول'), findsNothing);
  });
}

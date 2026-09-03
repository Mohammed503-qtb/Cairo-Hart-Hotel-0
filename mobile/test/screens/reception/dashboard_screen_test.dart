// ─────────────────────────────────────────────────────────────
// TEST: لوحة تحكم الاستقبال — KPIs + الإشغال + الأقسام + التنقل
// (نقل dashboard-view: البيانات اليومية وزر «الكل»)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/dashboard_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _dashboardJson() => {
      'ok': true,
      'stats': {
        'arrivalsToday': 2,
        'departuresToday': 1,
        'inHouseStays': 3,
        'pendingRequests': 2,
        'urgentRequests': 1,
        'occupancyPercent': 21,
        'totalRooms': 14,
        'occupiedRooms': 3,
      },
      'arrivals': [
        {
          'reservationId': 'rx_01',
          'bookingReference': 'HTL-2026-000421',
          'guestName': 'أحمد محمد',
          'guestPhone': '+967771234567',
          'roomTypeId': 'rt_deluxe',
          'roomTypeName': 'غرفة ديلوكس',
          'nights': 3,
          'paidCents': 27600,
          'grandTotalCents': 55200,
          'paymentStatus': 'UNPAID',
          'checkIn': '2026-09-02T14:00:00.000Z',
          'checkOut': '2026-09-05T12:00:00.000Z',
        },
      ],
      'departures': [
        {
          'stayId': 'st_1',
          'reference': 'ST-2026-000002',
          'guestName': 'نورا سالم',
          'roomNumber': '103',
          'balanceCents': 5000,
          'status': 'ACTIVE',
          'expectedCheckOutAt': '2026-09-02T12:00:00.000Z',
        },
      ],
      'pendingRequests': [
        {
          'id': 'req_1',
          'reference': 'REQ-1003',
          'roomNumber': '201',
          'guestName': 'خالد يوسف',
          'title': 'المكيف لا يبرد',
          'priority': 'URGENT',
          'status': 'IN_PROGRESS',
          'createdAt': '2026-09-02T08:30:00.000Z',
        },
      ],
    };

void main() {
  testWidgets('KPIs والإشغال وأقسام اليوم وزر «الكل»', (tester) async {
    final tabs = <int>[];
    final api = ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: MockClient(
        (req) async {
          if (req.url.path == '/api/reception/dashboard') {
            return jsonRes(_dashboardJson());
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        },
      ),
    );
    final store = ReceptionStore(api);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(store: store, onGoTab: tabs.add),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // بطاقات KPI (عنوان «وصول اليوم» يظهر في البطاقة والقسم معًا)
    expect(find.text('وصول اليوم'), findsAtLeastNWidgets(1));
    expect(find.text('مغادرة اليوم'), findsOneWidget);
    expect(find.text('المقيمون الآن'), findsOneWidget);
    expect(find.text('طلبات معلقة'), findsAtLeastNWidgets(1));
    // القيم: 2 (الوصول) و2 (الطلبات) و1 (المغادرة)
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('منها 1 عاجل ⚡'), findsOneWidget);

    // الإشغال
    expect(find.text('إشغال الغرف'), findsOneWidget);
    expect(find.text('21%'), findsOneWidget);
    expect(find.text('3 مشغولة من 14 غرفة'), findsOneWidget);

    // أقسام اليوم: وصول + مغادرة + طلب معلق عاجل
    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('نورا سالم'), findsOneWidget);
    expect(find.text('خالد يوسف'), findsOneWidget);
    expect(find.text('المكيف لا يبرد'), findsOneWidget);
    expect(find.text('غرفة 103'), findsOneWidget);
    expect(find.text('تسجيل وصول'), findsOneWidget);
    expect(find.text('تسجيل خروج'), findsOneWidget);

    // زر «الكل» الأول (قسم الوصول) ينتقل لتبويب الوصولين
    await tester.tap(find.text('الكل').first);
    await tester.pump();
    expect(tabs, contains(1));
  });
}

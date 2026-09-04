// ─────────────────────────────────────────────────────────────
// TEST: شاشة الحجوزات (A-29/A-30) — نقل reservations.tsx
// القائمة بالفلتر/البحث/الترقيم (عبر المخزن) + صفحة التفاصيل
// الكاملة بلقطة السعر حرفيًا (الليالي + الضريبة + سياسة الإلغاء)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/reservations_screen.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
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

Map<String, dynamic> _item1() => {
      'id': 'rsv_1',
      'reference': 'HTL-2026-000421',
      'guestName': 'نورا سالم',
      'guestPhone': '+967771234567',
      'roomTypeName': 'غرفة ديلوكس',
      'checkIn': '2026-09-10T00:00:00.000Z',
      'checkOut': '2026-09-13T00:00:00.000Z',
      'nights': 3,
      'adults': 2,
      'children': 1,
      'grandTotalCents': 55200,
      'paidCents': 20000,
      'paymentStatus': 'PARTIALLY_PAID',
      'status': 'CONFIRMED',
      'source': 'WEBSITE',
      'createdAt': '2026-09-01T10:00:00.000Z',
      'stayId': null,
    };

Map<String, dynamic> _item2() => {
      'id': 'rsv_2',
      'reference': 'HTL-2026-000422',
      'guestName': 'خالد يوسف',
      'guestPhone': '+967772000000',
      'roomTypeName': 'غرفة مفردة',
      'checkIn': '2026-09-20T00:00:00.000Z',
      'checkOut': '2026-09-22T00:00:00.000Z',
      'nights': 2,
      'adults': 1,
      'children': 0,
      'grandTotalCents': 48000,
      'paidCents': 0,
      'paymentStatus': 'UNPAID',
      'status': 'PENDING',
      'source': 'WHATSAPP',
      'createdAt': '2026-09-02T10:00:00.000Z',
      'stayId': null,
    };

Map<String, dynamic> _pageJson({int page = 1, int pages = 1, int total = 2}) => {
      'ok': true,
      // صفحة 2 تُبقي عنصرًا واحدًا (كي يظهر شريط الترقيم دومًا)
      'items': [if (page == 1) _item1(), _item2()],
      'total': total,
      'page': page,
      'limit': 20,
      'pages': pages,
    };

/// تفاصيل حجز كاملة (A-30) — priceSnapshot خريطة خام كما يرسلها الخادم
Map<String, dynamic> _detailJson() => {
      'ok': true,
      'reservation': {
        'id': 'rsv_1',
        'reference': 'HTL-2026-000421',
        'status': 'CONFIRMED',
        'source': 'WEBSITE',
        'checkIn': '2026-09-10T00:00:00.000Z',
        'checkOut': '2026-09-13T00:00:00.000Z',
        'nights': 3,
        'adults': 2,
        'children': 1,
        'roomsCount': 1,
        'currency': 'USD',
        'subtotalCents': 48000,
        'discountCents': 0,
        'taxCents': 7200,
        'grandTotalCents': 55200,
        'paidCents': 20000,
        'paymentStatus': 'PARTIALLY_PAID',
        'paymentMethod': 'PAY_AT_HOTEL',
        'specialRequests': 'سرير أطفال',
        'createdAt': '2026-09-01T10:00:00.000Z',
        'confirmedAt': '2026-09-01T11:00:00.000Z',
        'cancelledAt': null,
        'guest': {
          'id': 'g_1',
          'fullName': 'نورا سالم',
          'phone': '+967771234567',
          'email': 'nora@example.com',
          'nationality': 'يمنانية',
        },
        'roomType': {
          'id': 'rt_1',
          'name': 'غرفة ديلوكس',
          'nameEn': 'Deluxe Room',
          'basePriceCents': 16000,
        },
        'payments': [
          {
            'id': 'pay_1',
            'method': 'CASH',
            'amountCents': 20000,
            'status': 'COMPLETED',
            'reference': null,
            'note': null,
            'recordedBy': 'سالم',
            'createdAt': '2026-09-01T15:00:00.000Z',
          },
        ],
        'stay': {
          'id': 'st_1',
          'reference': 'ST-2026-000003',
          'status': 'ACTIVE',
          'checkInAt': '2026-09-10T14:00:00.000Z',
          'expectedCheckOutAt': '2026-09-13T12:00:00.000Z',
          'actualCheckOutAt': null,
          'roomNumber': '103',
        },
        'priceSnapshot': {
          'nightly': [
            {'date': '2026-09-10', 'rateName': 'السعر الأساسي', 'priceCents': 16000},
            {'date': '2026-09-11', 'rateName': 'السعر الأساسي', 'priceCents': 16000},
            {'date': '2026-09-12', 'rateName': 'موسم عيد', 'priceCents': 16000},
          ],
          'subtotalCents': 48000,
          'discountCents': 0,
          'taxPercent': 15,
          'taxCents': 7200,
          'grandTotalCents': 55200,
          'currency': 'USD',
          'cancellationPolicy': 'إلغاء مجاني قبل 48 ساعة',
          'checkInTime': '14:00',
          'checkOutTime': '12:00',
          'bookedAt': '2026-09-01T10:00:00.000Z',
        },
      },
    };

void main() {
  testWidgets('القائمة: البطاقات + الشارات + الترقيم بالأرقام العربية',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/reservations') {
        return jsonRes(_pageJson());
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminReservationsScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    // الرأس + الإجمالي (الأرقام ASCII كما الويب في الوصف)
    expect(find.text('الحجوزات'), findsOneWidget);
    expect(find.text('2 حجز — كل القنوات'), findsOneWidget);

    // بطاقة الحجز 1: المرجع + الضيف + هاتفه + النوع + التواريخ والليالي
    expect(find.text('HTL-2026-000421'), findsOneWidget);
    expect(find.text('نورا سالم'), findsOneWidget);
    expect(find.text('+967771234567'), findsOneWidget);
    expect(find.text('غرفة ديلوكس'), findsOneWidget);
    expect(find.text('10 سبتمبر 2026 ← 13 سبتمبر 2026'), findsOneWidget);
    expect(find.text('3 ليالٍ'), findsOneWidget);

    // الإجمالي والمدفوع (MoneyText) + المصدر
    expect(find.text(r'$552.00'), findsOneWidget);
    expect(find.text('مدفوع: '), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);

    // الشارات
    expect(find.text('مؤكد'), findsOneWidget);
    expect(find.text('مدفوع جزئيًا'), findsOneWidget);
    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('غير مدفوع'), findsOneWidget);

    // الترقيم: الإجمالي بأرقام عربية-هندية (toLocaleString ar-EG)
    expect(find.text('الإجمالي: ٢'), findsOneWidget);
    expect(find.text('صفحة 1 من 1'), findsOneWidget);
    expect(find.text('السابق'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });

  testWidgets('فلتر الحالة: CONFIRMED في استعلام A-29 + إعادة للصفحة 1',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final queries = <Map<String, String>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/reservations') {
        queries.add(req.url.queryParameters);
        // عناصر PENDING فقط — كي يكون «مؤكد» فريدًا في قائمة الفتح
        return jsonRes({
          'ok': true,
          'items': [_item2()],
          'total': 1,
          'page': 1,
          'limit': 20,
          'pages': 1,
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminReservationsScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    // فتح فلتر الحالة واختيار «مؤكد» (CONFIRMED)
    await tester.tap(find.text('كل الحالات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مؤكد'));
    await tester.pumpAndSettle();

    expect(queries.last['status'], 'CONFIRMED');
    expect(queries.last['page'], '1');

    // التسمية تحدّثت على الفلتر
    expect(find.text('مؤكد').evaluate(), isNotEmpty);
  });

  testWidgets('البحث: q في الاستعلام + مسح البحث يعيّده فارغًا',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final queries = <Map<String, String>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/reservations') {
        queries.add(req.url.queryParameters);
        return jsonRes(_pageJson());
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminReservationsScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'نورا');
    await tester.pump();
    await tester.tap(find.text('بحث'));
    await tester.pumpAndSettle();

    expect(queries.last['q'], 'نورا');
    expect(queries.last['page'], '1');

    // مسح البحث (زر X) — يزيل q من الاستعلام
    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pumpAndSettle();
    expect(queries.last.containsKey('q'), isFalse);
    expect(queries.last['page'], '1');
  });

  testWidgets('الترقيم: التالي/السابق يغيّران صفحة الاستعلام',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final queries = <Map<String, String>>[];
    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/reservations') {
        final page = int.tryParse(
                req.url.queryParameters['page'] ?? '1') ??
            1;
        queries.add(req.url.queryParameters);
        return jsonRes(_pageJson(page: page, pages: 2, total: 3));
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminReservationsScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('صفحة 1 من 2'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(queries.last['page'], '2');
    expect(find.text('صفحة 2 من 2'), findsOneWidget);

    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    expect(queries.last['page'], '1');
    expect(find.text('صفحة 1 من 2'), findsOneWidget);
  });

  testWidgets(
      'التفاصيل: كل حقول A-30 + لقطة السعر حرفيًا (ليالٍ/ضريبة/سياسة)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = AdminStore(_api(MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/api/admin/reservations') {
        return jsonRes(_pageJson());
      }
      if (req.method == 'GET' &&
          req.url.path == '/api/admin/reservations/rsv_1') {
        return jsonRes(_detailJson());
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    })));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminReservationsScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    // فتح التفاصيل بنقر بطاقة الحجز
    await tester.tap(find.text('نورا سالم'));
    await tester.pumpAndSettle();

    // الرأس: المرجع + شارتا الحالة والدفع + سطر الإنشاء والمصدر
    expect(find.text('HTL-2026-000421'), findsOneWidget);
    expect(find.text('مؤكد'), findsOneWidget);
    expect(find.text('مدفوع جزئيًا'), findsOneWidget);
    expect(find.textContaining('— الموقع'), findsOneWidget);

    // بيانات الضيف (A-30)
    expect(find.text('بيانات الضيف'), findsOneWidget);
    expect(find.text('nora@example.com'), findsOneWidget);
    expect(find.text('يمنانية'), findsOneWidget);
    expect(find.text('2 بالغ + 1 طفل'), findsOneWidget);
    expect(find.text('الدفع في الفندق'), findsOneWidget);
    // Text.rich يدمج «طلبات خاصة: …» — المطابقة بالاحتواء (درس F4)
    expect(find.textContaining('طلبات خاصة'), findsOneWidget);
    expect(find.textContaining('سرير أطفال'), findsOneWidget);

    // لقطة السعر وقت الحجز — حرفيًا كما الويب
    expect(find.text('لقطة السعر وقت الحجز'), findsOneWidget);
    expect(find.textContaining('ضريبة 15%'), findsOneWidget);
    // الليالي الثلاث بسعر كل ليلة + المعدل
    expect(find.text('10 سبتمبر 2026'), findsOneWidget);
    expect(find.text('11 سبتمبر 2026'), findsOneWidget);
    expect(find.text('12 سبتمبر 2026'), findsOneWidget);
    expect(find.text('السعر الأساسي'), findsNWidgets(2));
    expect(find.text('موسم عيد'), findsOneWidget);
    expect(find.text(r'$160.00'), findsNWidgets(3));
    // المجاميع الأربعة
    expect(find.text('المجموع الفرعي'), findsOneWidget);
    expect(find.text(r'$480.00'), findsOneWidget);
    expect(find.text('الخصم'), findsOneWidget);
    expect(find.text('الضريبة (15%)'), findsOneWidget);
    expect(find.text(r'$72.00'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text(r'$552.00'), findsOneWidget);
    // سياسة الإلغاء وقت الحجز + أوقات الدخول/المغادرة
    expect(find.textContaining('سياسة الإلغاء وقت الحجز'), findsOneWidget);
    expect(find.textContaining('إلغاء مجاني قبل 48 ساعة'), findsOneWidget);
    expect(find.text('تسجيل الوصول 14:00 · المغادرة 12:00'), findsOneWidget);

    // المدفوعات
    expect(find.text('المدفوعات'), findsOneWidget);
    expect(find.textContaining(r'المدفوع $200.00 من $552.00'), findsOneWidget);
    expect(find.text('نقدًا'), findsOneWidget);
    expect(find.textContaining(' · سالم'), findsOneWidget);

    // الإقامة المرتبطة
    expect(find.text('الإقامة المرتبطة'), findsOneWidget);
    expect(find.text('ST-2026-000003'), findsOneWidget);
    expect(find.text('103'), findsOneWidget);
    expect(find.text('نشطة'), findsOneWidget);
    expect(find.text('13 سبتمبر 2026'), findsOneWidget);
  });
}

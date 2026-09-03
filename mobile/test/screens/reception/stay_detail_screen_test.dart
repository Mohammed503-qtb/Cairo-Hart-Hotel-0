// ─────────────────────────────────────────────────────────────
// TEST: شاشة تفصيل الإقامة — نقل stay-detail-dialog.tsx كصفحة كاملة
// التبويبات الخمسة + تسجيل دفعة (جسم R-12) + قرار تمديد (جسم POST)
// + إرسال رسالة (جسم {stayId, body})
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/reception/stay_detail_screen.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

/// تفصيل إقامة كامل (نفس شكل R-05: ضيف/حجز بلقطة سعر/فاتورة/طلب/تمديد)
Map<String, dynamic> _detailJson() => {
      'ok': true,
      'stay': {
        'id': 'st_1',
        'reference': 'ST-2026-000003',
        'status': 'ACTIVE',
        'checkInAt': '2026-09-01T14:00:00.000Z',
        'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
        'actualCheckOutAt': null,
      },
      'guest': {
        'id': 'g_1',
        'fullName': 'نورا سالم',
        'phone': '+967771234567',
        'whatsapp': null,
        'email': null,
        'idNumber': '998877',
        'nationality': 'يمناني',
      },
      'room': {
        'id': 'rm_1',
        'number': '103',
        'floor': 1,
        'status': 'OCCUPIED',
        'notes': null,
      },
      'roomType': {
        'id': 'rt_1',
        'name': 'غرفة ديلوكس',
        'bedConfig': 'سرير مزدوج',
        'sizeSqm': 28,
      },
      'reservation': {
        'id': 'rsv_1',
        'bookingReference': 'HTL-2026-000421',
        'status': 'CHECKED_IN',
        'source': 'WEBSITE',
        'checkIn': '2026-09-01T00:00:00.000Z',
        'checkOut': '2026-09-04T00:00:00.000Z',
        'adults': 2,
        'children': 1,
        'roomsCount': 1,
        'currency': 'USD',
        'subtotalCents': 48000,
        'taxCents': 7200,
        'grandTotalCents': 55200,
        'paidCents': 50200,
        'paymentStatus': 'PARTIALLY_PAID',
        'paymentMethod': null,
        'specialRequests': 'سرير أطفال',
        'priceSnapshot': {
          'nightly': [
            {'date': '2026-09-01', 'rateName': 'السعر الأساسي', 'priceCents': 16000},
            {'date': '2026-09-02', 'rateName': 'السعر الأساسي', 'priceCents': 16000},
            {'date': '2026-09-03', 'rateName': 'السعر الأساسي', 'priceCents': 16000},
          ],
        },
      },
      'bill': {
        'stayId': 'st_1',
        'stayReference': 'ST-2026-000003',
        'roomTotalCents': 55200,
        'roomSubtotalCents': 48000,
        'roomTaxCents': 7200,
        'extraCharges': [
          {
            'description': 'ميني بار',
            'amountCents': 1500,
            'category': 'EXTRA',
            'date': '2026-09-02T20:30:00.000Z',
          },
        ],
        'extraTotalCents': 1500,
        'payments': [
          {
            'id': 'pay_1',
            'method': 'CASH',
            'amountCents': 2000,
            'createdAt': '2026-09-01T15:00:00.000Z',
            'recordedBy': 'سالم',
          },
        ],
        'totalChargesCents': 56700,
        'totalPaidCents': 50200,
        'balanceCents': 6500,
        'currency': 'USD',
      },
      'requests': [
        {
          'id': 'req_1',
          'reference': 'REQ-1003',
          'category': 'HOUSEKEEPING',
          'title': 'منشفات إضافية',
          'description': 'المرجو إرسال منشفات',
          'priority': 'NORMAL',
          'status': 'IN_PROGRESS',
          'assignedTo': null,
          'createdAt': '2026-09-02T08:30:00.000Z',
          'updatedAt': '2026-09-02T09:00:00.000Z',
          'completedAt': null,
          'updates': <Map<String, dynamic>>[],
          'stay': {
            'id': 'st_1',
            'reference': 'ST-2026-000003',
            'roomNumber': '103',
            'guestName': 'نورا سالم',
          },
        },
      ],
      'extensionRequests': [
        {
          'id': 'ext_1',
          'newCheckOut': '2026-09-06T12:00:00.000Z',
          'nights': 2,
          'priceCents': 32000,
          'note': 'تأخرت رحلة الطيران',
          'status': 'PENDING',
          'decidedBy': null,
          'decidedAt': null,
          'createdAt': '2026-09-03T10:00:00.000Z',
        },
      ],
      'roomChangeRequests': <Map<String, dynamic>>[],
      'messages': <Map<String, dynamic>>[],
    };

/// وهمي واحد يجيب: stays/st_1 + messages + كل مسارات refresh الخمسة
/// التي يجدّدها قرار التمديد (dashboard/departures/inhouse/requests/rooms)
MockClient _mock({
  required List<Map<String, dynamic>> paymentBodies,
  required List<Map<String, dynamic>> decideBodies,
  required List<Map<String, dynamic>> messageBodies,
}) {
  return MockClient((req) async {
    final path = req.url.path;
    if (req.method == 'GET' && path == '/api/reception/stays/st_1') {
      return jsonRes(_detailJson());
    }
    if (req.method == 'GET' && path == '/api/reception/messages') {
      return jsonRes({'ok': true, 'messages': <Map<String, dynamic>>[]});
    }
    if (req.method == 'POST' && path == '/api/reception/payments') {
      paymentBodies.add(_body(req));
      return jsonRes({
        'ok': true,
        'balanceCents': 0,
        'paidCents': 56700,
        'paymentStatus': 'PAID',
      });
    }
    if (req.method == 'POST' &&
        path == '/api/reception/extension-requests/ext_1/decide') {
      decideBodies.add(_body(req));
      return jsonRes({'ok': true});
    }
    if (req.method == 'POST' && path == '/api/reception/messages') {
      messageBodies.add(_body(req));
      return jsonRes({
        'ok': true,
        'message': {
          'id': 'm_2',
          'sender': 'RECEPTION',
          'senderName': 'موظف الاستقبال',
          'body': _body(req)['body'],
          'createdAt': '2026-09-03T12:00:00.000Z',
        },
      });
    }
    return jsonRes({'ok': true});
  });
}

ApiClient _api(http.Client client) => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-1',
      onSessionExpired: () {},
      httpClient: client,
    );

/// فتح الصفحة عبر العقد العام showStayDetail (يختبر initialTab أيضًا)
Future<void> _openStay(
  WidgetTester tester,
  ReceptionStore store, {
  String initialTab = 'guest',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showStayDetail(
                context,
                store: store,
                stayId: 'st_1',
                initialTab: initialTab,
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();
}

void main() {
  group('شاشة تفصيل الإقامة', () {
    testWidgets('التحميل والتبويبات الخمسة تعرض مفاتيحها', (tester) async {
      final store = ReceptionStore(_api(_mock(
        paymentBodies: [],
        decideBodies: [],
        messageBodies: [],
      )));
      await _openStay(tester, store);

      // الرأس: الاسم + شارة الغرفة + شارة الحالة + سطر الوصف بالمرجع
      expect(find.text('نورا سالم'), findsAtLeastNWidgets(1));
      expect(find.text('غرفة 103'), findsOneWidget);
      expect(find.text('نشطة'), findsOneWidget);
      expect(find.text('ST-2026-000003'), findsAtLeastNWidgets(1));
      expect(find.text('الرصيد:'), findsAtLeastNWidgets(1));

      // أسماء التبويبات الخمسة
      expect(find.text('الضيف'), findsOneWidget);
      expect(find.text('الفاتورة'), findsOneWidget);
      expect(find.text('الطلبات'), findsOneWidget);
      expect(find.text('الرسائل'), findsOneWidget);
      expect(find.text('الإجراءات'), findsOneWidget);

      // تبويب الضيف (الحالي): الهوية + لقطة السعر + الطلبات الخاصة
      expect(find.text('998877'), findsOneWidget);
      expect(find.text('لقطة سعر الليالي (عند الحجز)'), findsOneWidget);
      expect(find.text('المجموع + الضريبة'), findsOneWidget);
      // Text.rich يدمج «💬 طلبات خاصة: …» في نص واحد — المطابقة بالاحتواء
      expect(find.textContaining('طلبات خاصة'), findsOneWidget);

      // الفاتورة
      await tester.tap(find.text('الفاتورة'));
      await tester.pumpAndSettle();
      expect(find.text('الإجمالي المستحق'), findsOneWidget);
      expect(find.text('المدفوعات'), findsOneWidget);

      // الطلبات (عنوان الطلب من R-05)
      await tester.tap(find.text('الطلبات'));
      await tester.pumpAndSettle();
      expect(find.text('منشفات إضافية'), findsOneWidget);

      // الرسائل (الجلب الكامل يعيد قائمة فارغة)
      await tester.tap(find.text('الرسائل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('لا رسائل بعد'), findsOneWidget);

      // الإجراءات (قسم طلبات التمديد)
      await tester.tap(find.text('الإجراءات'));
      await tester.pumpAndSettle();
      expect(find.text('طلبات التمديد'), findsOneWidget);
      expect(find.text('لا طلبات تمديد'), findsNothing);
    });

    testWidgets('تسجيل دفعة: جسم POST حرفي + توست النجاح بالرصيد الجديد',
        (tester) async {
      final paymentBodies = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_mock(
        paymentBodies: paymentBodies,
        decideBodies: [],
        messageBodies: [],
      )));
      await _openStay(tester, store, initialTab: 'bill');
      await tester.pumpAndSettle();

      expect(find.text('الإجمالي المستحق'), findsOneWidget);

      // فتح الحوار من زر الفاتورة
      await tester.tap(find.text('تسجيل دفعة'));
      await tester.pumpAndSettle();
      expect(find.text('الرصيد الحالي المستحق:'), findsOneWidget);
      // المبلغ المبدوء بالرصيد (65.00 = 6500 سنتًا)
      expect(find.text('65.00'), findsOneWidget);

      await tester.ensureVisible(find.text('تسجيل الدفعة'));
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();

      // جسم POST واحد حرفي (بلا حقل note فارغ)
      expect(paymentBodies, hasLength(1));
      expect(paymentBodies.single['stayId'], 'st_1');
      expect(paymentBodies.single['method'], 'CASH');
      expect(paymentBodies.single['amountCents'], 6500);
      expect(paymentBodies.single.containsKey('note'), isFalse);
      expect(
        paymentBodies.single.keys,
        unorderedEquals(<String>['stayId', 'method', 'amountCents']),
      );

      // توست النجاح: المبلغ + الرصيد الجديد — والحوار أغلق
      expect(find.textContaining('تم تسجيل دفعة'), findsOneWidget);
      expect(find.textContaining('الرصيد الآن: \$0.00'), findsOneWidget);
      expect(find.text('الرصيد الحالي المستحق:'), findsNothing);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('قرار تمديد PENDING: جسم {approve:true} + توست الموافقة',
        (tester) async {
      final decideBodies = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_mock(
        paymentBodies: [],
        decideBodies: decideBodies,
        messageBodies: [],
      )));
      await _openStay(tester, store, initialTab: 'actions');
      await tester.pumpAndSettle();

      expect(find.text('طلبات التمديد'), findsOneWidget);
      expect(find.text('حتى الأحد، 6 سبتمبر 2026'), findsOneWidget);

      final approveButton = find.text('موافقة (\$320.00)');
      await tester.ensureVisible(approveButton);
      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      // جسم POST حرفي بمفتاح واحد
      expect(decideBodies, hasLength(1));
      expect(decideBodies.single['approve'], isTrue);
      expect(decideBodies.single.keys, unorderedEquals(<String>['approve']));

      // توست الموافقة الحرفي
      expect(find.text('تمت الموافقة على التمديد ✅'), findsOneWidget);

      // تصريف مؤقّت إخفاء SnackBar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('إرسال رسالة: جسم {stayId,body} حرفي + ظهور الفقاعة',
        (tester) async {
      final messageBodies = <Map<String, dynamic>>[];
      final store = ReceptionStore(_api(_mock(
        paymentBodies: [],
        decideBodies: [],
        messageBodies: messageBodies,
      )));
      await _openStay(tester, store, initialTab: 'messages');
      await tester.pumpAndSettle();

      expect(find.textContaining('لا رسائل بعد'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'مرحبًا من الاستقبال');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(messageBodies, hasLength(1));
      expect(messageBodies.single['stayId'], 'st_1');
      expect(messageBodies.single['body'], 'مرحبًا من الاستقبال');
      expect(
        messageBodies.single.keys,
        unorderedEquals(<String>['stayId', 'body']),
      );

      // الفقاعة ظهرت والحقل أُفرغ (نص واحد فقط = الفقاعة)
      expect(find.text('مرحبًا من الاستقبال'), findsOneWidget);
    });
  });
}

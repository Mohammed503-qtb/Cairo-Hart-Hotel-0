// ─────────────────────────────────────────────────────────────
// TEST: ReceptionStore — قناة الاستقبال فوق عقد R-01..R-07/R-10/R-22/R-23
// (نفس نمط api_client_test: MockClient + أسرار الأجساد الحرفية)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/core/format.dart' as fmt;
import 'package:cairo_heart_hotel/state/reception_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

void main() {
  test('refreshArrivals يضبط التاريخ المطلوب ويفكك القائمة', () async {
    final dates = <String>[];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/reception/arrivals') {
            dates.add(req.url.queryParameters['date'] ?? '');
            return jsonRes({
              'ok': true,
              'arrivals': [
                {
                  'id': 'rx_01',
                  'bookingReference': 'HTL-1',
                  'status': 'CONFIRMED',
                  'nights': 2,
                  'grandTotalCents': 100,
                  'paidCents': 0,
                  'paymentStatus': 'UNPAID',
                  'guest': {'fullName': 'أحمد', 'phone': '+967'},
                  'roomType': {'id': 'rt', 'name': 'غرفة'},
                }
              ],
            });
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        }),
      ),
    );

    await store.refreshArrivals(date: '2026-09-02');
    expect(dates, contains('2026-09-02'));
    expect(store.arrivalsDate, '2026-09-02');
    expect(store.arrivals, hasLength(1));
    expect(store.arrivals.single.guest.fullName, 'أحمد');
  });

  test('checkIn: جسم R-06 الحرفي (idNumber فقط عند غير الفارغ) + تحديث القوائم',
      () async {
    final requests = <String>[];
    final postBodies = <Map<String, dynamic>>[];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          requests.add('${req.method} ${req.url.path}');
          if (req.method == 'POST' && req.url.path == '/api/reception/check-in') {
            final b = body(req);
            postBodies.add(b);
            return jsonRes({
              'ok': true,
              'stay': {'id': 'st_9', 'reference': 'ST-2026-000004'},
              'roomNumber': '202',
              'guestCode': 'H334469T0',
              'guestName': 'أحمد محمد',
              'guestPhone': '+967771234567',
            });
          }
          // كل تحديثات ما بعد العملية
          if (req.url.path == '/api/reception/dashboard') {
            return jsonRes({
              'ok': true,
              'stats': <String, dynamic>{},
              'arrivals': <Map<String, dynamic>>[],
              'departures': <Map<String, dynamic>>[],
              'pendingRequests': <Map<String, dynamic>>[],
            });
          }
          if (req.url.path == '/api/reception/arrivals') {
            return jsonRes({'ok': true, 'arrivals': <Map<String, dynamic>>[]});
          }
          if (req.url.path == '/api/reception/departures') {
            return jsonRes(
                {'ok': true, 'departures': <Map<String, dynamic>>[]});
          }
          if (req.url.path == '/api/reception/rooms') {
            return jsonRes({'ok': true, 'rooms': <Map<String, dynamic>>[]});
          }
          if (req.url.path == '/api/reception/notifications') {
            return jsonRes({
              'ok': true,
              'notifications': <Map<String, dynamic>>[],
              'unreadCount': 0,
            });
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        }),
      ),
    );

    final result = await store.checkIn(
      reservationId: 'rx_01',
      roomId: 'r_202',
      idNumber: '  9988776  ',
    );
    expect(result.guestCode, 'H334469T0');
    expect(result.stayReference, 'ST-2026-000004');

    // جسم POST واحد حرفي: idNumber مقلّم — لا قيم زائدة
    expect(postBodies, hasLength(1));
    expect(postBodies.single['reservationId'], 'rx_01');
    expect(postBodies.single['roomId'], 'r_202');
    expect(postBodies.single['idNumber'], '9988776');
    expect(postBodies.single.keys,
        unorderedEquals(<String>['reservationId', 'roomId', 'idNumber']));

    // نجاح العملية حدّث كل القوائم (dashboard/arrivals/departures/rooms/notifications)
    expect(
      requests,
      containsAll(<String>[
        'GET /api/reception/dashboard',
        'GET /api/reception/rooms',
        'GET /api/reception/notifications',
      ]),
    );
  });

  test('checkIn بلا idNumber: الحقل غائب تمامًا من الجسم', () async {
    final postBodies = <Map<String, dynamic>>[];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/reception/check-in') {
            postBodies.add(body(req));
            return jsonRes({
              'ok': true,
              'stay': {'id': 'st', 'reference': 'ST'},
              'roomNumber': '1',
              'guestCode': 'H1',
              'guestName': 'س',
              'guestPhone': '+',
            });
          }
          return jsonRes({'ok': true});
        }),
      ),
    );
    await store.checkIn(reservationId: 'rx', roomId: 'r');
    expect(postBodies.single.containsKey('idNumber'), isFalse);
  });

  test('checkOut يرسل confirmOutstanding كما هو (R-07)', () async {
    final bodies = <Map<String, dynamic>>[];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/reception/check-out') {
            bodies.add(body(req));
            return jsonRes(
              {'ok': true, 'closed': true, 'roomNumber': '103', 'balanceCents': 0},
            );
          }
          return jsonRes({'ok': true});
        }),
      ),
    );
    final result = await store.checkOut(stayId: 'st_1', confirmOutstanding: true);
    expect(result.closed, isTrue);
    expect(bodies.single['stayId'], 'st_1');
    expect(bodies.single['confirmOutstanding'], isTrue);
  });

  test('recordPayment: جسم R-12 الحرفي (stayId/method/amountCents/note)',
      () async {
    final bodies = <Map<String, dynamic>>[];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/reception/payments') {
            bodies.add(body(req));
            return jsonRes({
              'ok': true,
              'payment': {'id': 'pay_1', 'method': 'CASH', 'amountCents': 5500},
              'paidCents': 55700,
              'paymentStatus': 'PAID',
              'balanceCents': 0,
            });
          }
          return jsonRes({'ok': true});
        }),
      ),
    );
    await store.recordPayment(
      stayId: 'st_1',
      method: 'CASH',
      amountCents: 5500,
      note: 'تسوية عند الخروج',
    );
    expect(bodies.single['stayId'], 'st_1');
    expect(bodies.single['method'], 'CASH');
    expect(bodies.single['amountCents'], 5500);
    expect(bodies.single['note'], 'تسوية عند الخروج');
  });

  test('loadStayDetail يفكك R-05 المتداخل (bill.balanceCents)', () async {
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/reception/stays/st_1') {
            return jsonRes({
              'ok': true,
              'stay': {
                'id': 'st_1',
                'reference': 'ST-2026-000003',
                'status': 'ACTIVE',
                'checkInAt': '2026-09-01T14:00:00.000Z',
                'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
              },
              'guest': {'id': 'g', 'fullName': 'نورا', 'phone': '+967'},
              'room': {'id': 'rm', 'number': '103', 'floor': 1, 'status': 'OCCUPIED'},
              'roomType': {'id': 'rt', 'name': 'ديلوكس', 'bedConfig': 'مزدوج', 'sizeSqm': 28},
              'reservation': {
                'id': 'rsv',
                'bookingReference': 'HTL-3',
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
                'paidCents': 50200,
                'paymentStatus': 'PARTIALLY_PAID',
              },
              'bill': {
                'stayId': 'st_1',
                'stayReference': 'ST-2026-000003',
                'roomTotalCents': 55200,
                'roomSubtotalCents': 48000,
                'roomTaxCents': 7200,
                'extraCharges': <Map<String, dynamic>>[],
                'extraTotalCents': 0,
                'payments': <Map<String, dynamic>>[],
                'totalChargesCents': 55200,
                'totalPaidCents': 50200,
                'balanceCents': 5000,
                'currency': 'USD',
              },
              'requests': <Map<String, dynamic>>[],
              'extensionRequests': <Map<String, dynamic>>[],
              'roomChangeRequests': <Map<String, dynamic>>[],
              'messages': <Map<String, dynamic>>[],
            });
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        }),
      ),
    );
    final detail = await store.loadStayDetail('st_1');
    expect(detail.guest.fullName, 'نورا');
    expect(detail.bill.balanceCents, 5000);
    expect(detail.bill.roomTotalCents, 55200);
  });

  test('الإشعارات: unreadCount + تعليم المعروض غير المقروء (R-22/R-23)',
      () async {
    final readPosts = <List<dynamic>>[];
    var notificationsReadCount = 0;
    // وهمي stateful: POST read يعلّم فعليًا (كما الخادم الحقيقي)
    final marked = <String>{};
    List<Map<String, dynamic>> currentList() => [
          {
            'id': 'n_1',
            'type': 'REQUEST',
            'title': 'طلب',
            'body': '',
            'read': marked.contains('n_1'),
            'createdAt': '2026-09-02T08:00:00.000Z',
          },
          {
            'id': 'n_2',
            'type': 'CHAT',
            'title': 'رسالة',
            'body': '',
            'read': true,
            'createdAt': '2026-09-02T09:00:00.000Z',
          },
          {
            'id': 'n_3',
            'type': 'PAYMENT',
            'title': 'دفعة',
            'body': '',
            'read': marked.contains('n_3'),
            'createdAt': '2026-09-02T10:00:00.000Z',
          },
        ];
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          if (req.method == 'GET' &&
              req.url.path == '/api/reception/notifications') {
            final list = currentList();
            return jsonRes({
              'ok': true,
              'notifications': list,
              'unreadCount':
                  list.where((n) => n['read'] == false).length,
            });
          }
          if (req.url.path == '/api/reception/notifications/read') {
            notificationsReadCount++;
            final b = body(req);
            readPosts.add(b['ids'] as List<dynamic>);
            for (final id in b['ids'] as List) {
              marked.add('$id');
            }
            return jsonRes({'ok': true, 'updated': (b['ids'] as List).length});
          }
          return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
        }),
      ),
    );

    await store.refreshNotifications();
    expect(store.unreadCount, 2);
    expect(store.notifications, hasLength(3));

    // تعليم المعروض غير المقروء: n_1 وn_3 فقط (لا n_2)
    await store.markVisibleNotificationsRead();
    expect(notificationsReadCount, 1);
    expect(readPosts.single, unorderedEquals(<String>['n_1', 'n_3']));
    expect(store.unreadCount, 0);

    // نداءات لاحقة بلا غير مقروء → لا POST جديد (حرس الدخول)
    await store.markVisibleNotificationsRead();
    expect(notificationsReadCount, 1);
  });

  test('reset يعيد كل الحالة والتواريخ لليوم', () async {
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient(
          (req) async => jsonRes({'ok': true, 'arrivals': <dynamic>[]}),
        ),
      ),
    );
    await store.refreshArrivals(date: '2025-01-01');
    expect(store.arrivalsDate, '2025-01-01');

    store.reset();
    expect(store.arrivalsDate, fmt.todayInputValue());
    expect(store.departuresDate, fmt.todayInputValue());
    expect(store.arrivals, isEmpty);
    expect(store.dashboard, isNull);
    expect(store.unreadCount, 0);
  });

  test('onRealtimeBump يصمت عند فشل التحديث (لا يرمي)', () async {
    final store = ReceptionStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient(
          (req) async => jsonRes({'ok': false, 'error': 'boom'}, status: 500),
        ),
      ),
    );
    await store.onRealtimeBump(); // لا يجب أن يرمي
    await store.onRealtimeNotification(); // ولا هذا
    expect(store.dashboard, isNull);
  });
}

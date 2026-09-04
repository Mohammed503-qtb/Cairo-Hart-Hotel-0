// ─────────────────────────────────────────────────────────────
// TEST: AdminStore — قناة الإدارة فوق عقود A-01..A-34
// (نفس نمط reception_store_test: MockClient + الأجساد الحرفية)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> body(http.Request req) =>
    jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;

void main() {
  AdminStore storeWith(http.Client client) {
    return AdminStore(
      ApiClient(
        baseUrlProvider: () => 'https://hotel.test',
        tokenProvider: () => 'tok-admin',
        onSessionExpired: () {},
        httpClient: client,
      ),
    );
  }

  test('A-03 updateHotel: PATCH بالجسم كما هو + يعيد note الخادم', () async {
    final calls = <String>[];
    final bodies = <Map<String, dynamic>>[];
    final store = storeWith(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.method == 'PATCH' && req.url.path == '/api/admin/hotel') {
        bodies.add(body(req));
        return jsonRes({
          'ok': true,
          'hotel': {
            'id': 'h1',
            'name': 'فندق قلب القاهرة',
            'tagline': 'جديد',
            'currency': 'USD',
            'taxPercent': 15,
          },
          'changedFields': ['tagline'],
          'note': 'تم الحفظ — تغيير الضريبة والأسعار يؤثر على الحجوزات الجديدة فقط',
        });
      }
      if (req.method == 'GET' && req.url.path == '/api/admin/hotel') {
        return jsonRes({
          'ok': true,
          'hotel': {'id': 'h1', 'name': 'فندق قلب القاهرة', 'tagline': 'جديد'},
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    final note = await store.updateHotel({'tagline': 'جديد'});
    expect(calls.first, 'PATCH /api/admin/hotel');
    expect(bodies.single, {'tagline': 'جديد'});
    expect(note, contains('تم الحفظ'));
    expect(store.hotel?.tagline, 'جديد');
  });

  test('A-27 generateCode: الجسم الحرفي + الكود الخام + تحديث القوائم',
      () async {
    final postBodies = <Map<String, dynamic>>[];
    final gets = <String>[];
    final store = storeWith(MockClient((req) async {
      gets.add('${req.method} ${req.url.path}');
      if (req.method == 'POST' && req.url.path == '/api/admin/codes') {
        postBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'codeId': 'c9',
          'code': 'R695693CP',
          'codeMasked': 'R••••••CP',
          'expiresAt': '2026-09-06T00:00:00.000Z',
          'staffName': 'أحمد',
          'days': 3,
          'type': 'RECEPTION',
        }, status: 201);
      }
      if (req.method == 'GET') {
        final path = req.url.path;
        if (path == '/api/admin/codes') return jsonRes({'ok': true, 'codes': []});
        if (path == '/api/admin/staff') return jsonRes({'ok': true, 'staff': []});
        if (path == '/api/admin/dashboard') {
          return jsonRes({'ok': true, 'kpis': {}, 'recentBookings': [], 'roomsByStatus': {}, 'alerts': {}, 'revenueByDay': []});
        }
        if (path == '/api/admin/notifications') {
          return jsonRes({'ok': true, 'notifications': [], 'unreadCount': 0});
        }
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    final result = await store.generateCode(
      type: 'RECEPTION',
      staffId: 'stf_1',
      days: 3,
    );
    expect(postBodies.single,
        {'type': 'RECEPTION', 'staffId': 'stf_1', 'days': 3});
    expect(result.code, 'R695693CP');
    expect(result.days, 3);
    // بعد النجاح: تحديث الأكواد/الطاقم/اللوحة/الإشعارات بصمت
    expect(gets, containsAll([
      'GET /api/admin/codes',
      'GET /api/admin/staff',
      'GET /api/admin/dashboard',
      'GET /api/admin/notifications',
    ]));
  });

  test('A-28 revokeCode: الجسم + يعيد رسالة الخادم', () async {
    final postBodies = <Map<String, dynamic>>[];
    final store = storeWith(MockClient((req) async {
      if (req.method == 'POST' &&
          req.url.path == '/api/admin/codes/revoke') {
        postBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'revoked': true,
          'message': 'تم إبطال كود R••••••CP (أحمد) وإبطال جلساته',
        });
      }
      if (req.method == 'GET') {
        final path = req.url.path;
        if (path == '/api/admin/codes') return jsonRes({'ok': true, 'codes': []});
        if (path == '/api/admin/staff') return jsonRes({'ok': true, 'staff': []});
        if (path == '/api/admin/dashboard') {
          return jsonRes({'ok': true, 'kpis': {}, 'recentBookings': [], 'roomsByStatus': {}, 'alerts': {}, 'revenueByDay': []});
        }
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    final message = await store.revokeCode('c9');
    expect(postBodies.single, {'codeId': 'c9'});
    expect(message, contains('تم إبطال'));
  });

  test('A-26 refreshCodes: فلاتر المخزن تذهب في الاستعلام', () async {
    final queries = <String>[];
    final store = storeWith(MockClient((req) async {
      if (req.url.path == '/api/admin/codes') {
        queries.add(req.url.query);
        return jsonRes({'ok': true, 'codes': []});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    store.codesTypeFilter = 'RECEPTION';
    store.codesStatusFilter = 'ACTIVE';
    await store.refreshCodes();
    expect(queries.single, 'type=RECEPTION&status=ACTIVE');
  });

  test('A-29 refreshReservations: الصفحة + الفلتر + البحث في الاستعلام',
      () async {
    final queries = <String>[];
    final store = storeWith(MockClient((req) async {
      if (req.url.path == '/api/admin/reservations') {
        queries.add(req.url.query);
        return jsonRes({
          'ok': true,
          'items': [],
          'total': 0,
          'page': 2,
          'limit': 20,
          'pages': 1,
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    store.reservationsStatusFilter = 'CONFIRMED';
    store.reservationsQuery = 'خالد';
    await store.refreshReservations(page: 2);
    expect(queries.single,
        'page=2&status=CONFIRMED&q=%D8%AE%D8%A7%D9%84%D8%AF');
    expect(store.reservationsPage, 2);
    expect(store.reservationsPageData?.page, 2);
  });

  test('A-32 refreshAudit: الصفحة والفلتر في الاستعلام', () async {
    final queries = <String>[];
    final store = storeWith(MockClient((req) async {
      if (req.url.path == '/api/admin/audit') {
        queries.add(req.url.query);
        return jsonRes({
          'ok': true,
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 30,
          'pages': 1,
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    store.auditActionFilter = 'CODE_REVOKED';
    store.auditQuery = 'أحمد';
    await store.refreshAudit();
    expect(queries.single,
        'page=1&action=CODE_REVOKED&q=%D8%A3%D8%AD%D9%85%D8%AF');
  });

  test('A-09 createRoom: الجسم الحرفي + notes تُقص', () async {
    final postBodies = <Map<String, dynamic>>[];
    final store = storeWith(MockClient((req) async {
      if (req.method == 'POST' && req.url.path == '/api/admin/rooms') {
        postBodies.add(body(req));
        return jsonRes({
          'ok': true,
          'room': {
            'id': 'rm9',
            'number': '108',
            'floor': 1,
            'status': 'AVAILABLE',
            'roomTypeId': 'rt1',
            'roomTypeName': 'اقتصادية',
          },
        }, status: 201);
      }
      if (req.method == 'GET') {
        final path = req.url.path;
        if (path == '/api/admin/rooms') return jsonRes({'ok': true, 'rooms': []});
        if (path == '/api/admin/dashboard') {
          return jsonRes({'ok': true, 'kpis': {}, 'recentBookings': [], 'roomsByStatus': {}, 'alerts': {}, 'revenueByDay': []});
        }
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    final room = await store.createRoom(
      number: '108',
      floor: 1,
      roomTypeId: 'rt1',
      notes: '  قرب المصعد  ',
    );
    expect(postBodies.single, {
      'number': '108',
      'floor': 1,
      'roomTypeId': 'rt1',
      'notes': 'قرب المصعد',
    });
    expect(room.number, '108');
  });

  test('A-13 createRate: يعيد المعدل وتحذير التداخل الاختياري', () async {
    final store = storeWith(MockClient((req) async {
      if (req.method == 'POST' && req.url.path == '/api/admin/rates') {
        return jsonRes({
          'ok': true,
          'rate': {
            'id': 'rate9',
            'name': 'موسم رأس السنة',
            'roomTypeId': 'rt1',
            'roomTypeName': 'ديلوكس',
            'startDate': '2026-12-25T00:00:00.000Z',
            'endDate': '2027-01-05T00:00:00.000Z',
            'priceCents': 25000,
            'active': true,
          },
          'warning': 'يتداخل مع معدل «الصيف» — المعدل الأحدث بدايةً يسود لكل ليلة',
        }, status: 201);
      }
      if (req.method == 'GET' && req.url.path == '/api/admin/rates') {
        return jsonRes({'ok': true, 'rates': []});
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    final (rate, warning) = await store.createRate({
      'roomTypeId': 'rt1',
      'name': 'موسم رأس السنة',
      'startDate': '2026-12-25',
      'endDate': '2027-01-05',
      'priceCents': 25000,
    });
    expect(rate.name, 'موسم رأس السنة');
    expect(warning, isNotNull);
    expect(warning, contains('يتداخل'));
  });

  test('A-34 refreshNotifications: unreadCount من الخادم', () async {
    final store = storeWith(MockClient((req) async {
      if (req.url.path == '/api/admin/notifications') {
        return jsonRes({
          'ok': true,
          'notifications': [
            {
              'id': 'n1',
              'audience': 'ADMIN',
              'type': 'INFO',
              'title': 'حجز جديد',
              'body': 'HTL-2026-000010',
              'read': false,
              'createdAt': '2026-09-03T00:00:00.000Z',
            }
          ],
          'unreadCount': 1,
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    await store.refreshNotifications();
    expect(store.notifications, hasLength(1));
    expect(store.unreadCount, 1);
    expect(store.notifications.single.audience, 'ADMIN');
  });

  test('reset يمسح كل الحالة بما فيها الفلاتر والصفحات', () async {
    final store = storeWith(MockClient((req) async {
      if (req.url.path == '/api/admin/notifications') {
        return jsonRes({
          'ok': true,
          'notifications': [
            {
              'id': 'n1',
              'audience': 'ADMIN',
              'title': 'عنوان',
              'body': '',
              'read': false,
              'createdAt': '2026-09-03T00:00:00.000Z',
            }
          ],
          'unreadCount': 1,
        });
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    await store.refreshNotifications();
    store.codesTypeFilter = 'ADMIN';
    store.reservationsPage = 5;
    store.auditPage = 3;
    store.reset();
    expect(store.notifications, isEmpty);
    expect(store.unreadCount, 0);
    expect(store.codesTypeFilter, '');
    expect(store.reservationsPage, 1);
    expect(store.auditPage, 1);
  });

  test('DELETE (A-07/A-11/A-14/A-18/A-22) عبر api.delete', () async {
    final methods = <String>[];
    final store = storeWith(MockClient((req) async {
      methods.add('${req.method} ${req.url.path}');
      if (req.method == 'DELETE') {
        return jsonRes({'ok': true, 'deleted': true, 'message': 'تم الحذف'});
      }
      if (req.method == 'GET') {
        final path = req.url.path;
        if (path == '/api/admin/room-types') return jsonRes({'ok': true, 'roomTypes': []});
        if (path == '/api/admin/rooms') return jsonRes({'ok': true, 'rooms': []});
        if (path == '/api/admin/rates') return jsonRes({'ok': true, 'rates': []});
        if (path == '/api/admin/services') return jsonRes({'ok': true, 'services': []});
        if (path == '/api/admin/service-categories') return jsonRes({'ok': true, 'categories': []});
        if (path == '/api/admin/dashboard') {
          return jsonRes({'ok': true, 'kpis': {}, 'recentBookings': [], 'roomsByStatus': {}, 'alerts': {}, 'revenueByDay': []});
        }
      }
      return jsonRes({'ok': false, 'error': 'unmocked'}, status: 404);
    }));

    expect(await store.deleteRoomType('rt9'), 'تم الحذف');
    expect(await store.deleteRoom('rm9'), 'تم الحذف');
    expect(await store.deleteRate('rate9'), 'تم الحذف');
    expect(await store.deleteService('svc9'), 'تم الحذف');
    expect(await store.deleteServiceCategory('cat9'), 'تم الحذف');
    expect(methods, containsAll([
      'DELETE /api/admin/room-types/rt9',
      'DELETE /api/admin/rooms/rm9',
      'DELETE /api/admin/rates/rate9',
      'DELETE /api/admin/services/svc9',
      'DELETE /api/admin/service-categories/cat9',
    ]));
  });
}

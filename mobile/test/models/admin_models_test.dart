// ─────────────────────────────────────────────────────────────
// TEST: Admin Models — تحليل عقد A-01..A-34 (قيم آمنة/سنت/فلاتر)
// ─────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/models/admin.dart';

void main() {
  group('A-01 AdminDashboard', () {
    test('يحلل KPIs والتنبيهات والرسوم والقيم الناقصة بأمان', () {
      final d = AdminDashboard.fromJson({
        'kpis': {
          'arrivalsToday': 3,
          'departuresToday': 1,
          'inHouseStays': 2,
          'inHouseGuests': 4,
          'pendingRequests': 5,
          'urgentRequests': 1,
          'occupancyPercent': 50,
          'totalRooms': 14,
          'occupiedRooms': 7,
          'availableRooms': 5,
          'outOfOrderRooms': 1,
          'revenueMonthCents': 94000,
          'activeGuestCodes': 2,
          'activeStaffCodes': 3,
        },
        'recentBookings': [
          {
            'id': 'r1',
            'reference': 'HTL-2026-000010',
            'guestName': 'سارة',
            'roomTypeName': 'ديلوكس',
            'grandTotalCents': 55200,
            'status': 'CONFIRMED',
            'createdAt': '2026-09-03T10:00:00.000Z',
          }
        ],
        'roomsByStatus': {
          'AVAILABLE': 5,
          'OCCUPIED': 7,
          'OUT_OF_ORDER': 1,
        },
        'alerts': {'staleRequests': 2, 'outOfOrderRooms': 1},
        'revenueByDay': [
          {'date': '2026-09-02', 'totalCents': 10000},
          {'date': '2026-09-03', 'totalCents': 0},
        ],
      });
      expect(d.kpis.inHouseGuests, 4);
      expect(d.kpis.revenueMonthCents, 94000);
      expect(d.recentBookings.single.guestName, 'سارة');
      expect(d.roomsByStatus['OCCUPIED'], 7);
      expect(d.alerts.staleRequests, 2);
      expect(d.revenueByDay, hasLength(2));
    });

    test('payload فارغ لا يرمي', () {
      final d = AdminDashboard.fromJson(const {});
      expect(d.kpis.totalRooms, 0);
      expect(d.recentBookings, isEmpty);
      expect(d.roomsByStatus, isEmpty);
    });
  });

  group('A-02 HotelSettings', () {
    test('يحلل الحقول المعروفة ويتحمل النواقص', () {
      final h = HotelSettings.fromJson({
        'id': 'h1',
        'name': 'فندق قلب القاهرة',
        'currency': 'USD',
        'checkInTime': '14:00',
        'taxPercent': 15,
        'weekendSurchargePercent': 10,
        'minStayNights': 1,
        'maxStayNights': 30,
        'bookingHorizonDays': 365,
        'minAppVersion': '1.2.0',
      });
      expect(h.name, 'فندق قلب القاهرة');
      expect(h.taxPercent, 15);
      expect(h.minAppVersion, '1.2.0');
      expect(h.tagline, '');
    });
  });

  group('A-04 AdminRoomType', () {
    test('amenities/images كقوائم نصية', () {
      final t = AdminRoomType.fromJson({
        'id': 'rt1',
        'name': 'ديلوكس',
        'basePriceCents': 18400,
        'amenities': ['واي فاي', 'تكييف'],
        'images': ['/images/a.jpg'],
        'active': true,
        'roomsCount': 4,
        'reservationsCount': 10,
        'ratesCount': 1,
      });
      expect(t.amenities, hasLength(2));
      expect(t.basePriceCents, 18400);
      expect(t.roomsCount, 4);
    });
  });

  group('A-08 AdminRoom', () {
    test('guestName/expectedCheckOut قابلة للفراغ', () {
      final r = AdminRoom.fromJson({
        'id': 'rm1',
        'number': '107',
        'floor': 1,
        'status': 'AVAILABLE',
        'roomTypeId': 'rt1',
        'roomTypeName': 'اقتصادية',
        'guestName': null,
        'expectedCheckOut': null,
      });
      expect(r.number, '107');
      expect(r.guestName, isNull);
      expect(r.expectedCheckOut, isNull);
    });
  });

  group('A-23/A-26 الطاقم والأكواد', () {
    test('lastCode مفقود = null وموجود = ملخص', () {
      final noCode = AdminStaffMember.fromJson({
        'id': 's1',
        'fullName': 'أحمد',
        'role': 'RECEPTION',
        'active': true,
        'lastCode': null,
      });
      expect(noCode.lastCode, isNull);

      final withCode = AdminStaffMember.fromJson({
        'id': 's2',
        'fullName': 'منى',
        'role': 'ADMIN',
        'active': true,
        'lastCode': {
          'codeMasked': 'A••••••L9',
          'type': 'ADMIN',
          'status': 'ACTIVE',
          'expiresAt': '2026-09-10T00:00:00.000Z',
        },
      });
      expect(withCode.lastCode?.codeMasked, 'A••••••L9');
      expect(withCode.lastCode?.type, 'ADMIN');
    });

    test('A-26 كود ضيف يحمل سياق الإقامة', () {
      final c = AdminAccessCode.fromJson({
        'id': 'c1',
        'codeMasked': 'H••••••K4',
        'type': 'GUEST',
        'status': 'ACTIVE',
        'expiresAt': '2026-09-05T00:00:00.000Z',
        'createdAt': '2026-09-01T00:00:00.000Z',
        'guestName': 'نورا',
        'roomNumber': '103',
        'stayReference': 'ST-2026-000002',
        'lastUsedAt': null,
      });
      expect(c.guestName, 'نورا');
      expect(c.roomNumber, '103');
      expect(c.staffName, isNull);
    });
  });

  group('A-27 GeneratedCodeResult', () {
    test('الكود الخام يُستخرج مرة واحدة', () {
      final g = GeneratedCodeResult.fromJson({
        'codeId': 'c9',
        'code': 'R695693CP',
        'codeMasked': 'R••••••CP',
        'expiresAt': '2026-09-10T00:00:00.000Z',
        'staffName': 'أحمد',
        'days': 3,
        'type': 'RECEPTION',
      });
      expect(g.code, 'R695693CP');
      expect(g.days, 3);
      expect(g.type, 'RECEPTION');
    });
  });

  group('A-29/A-30 الحجوزات', () {
    test('الصفحة تُفكك مع pagination', () {
      final p = ReservationsPageData.fromJson({
        'items': [
          {
            'id': 'res1',
            'reference': 'HTL-2026-000008',
            'guestName': 'خالد',
            'guestPhone': '+967',
            'roomTypeName': 'ديلوكس',
            'checkIn': '2026-09-01T00:00:00.000Z',
            'checkOut': '2026-09-03T00:00:00.000Z',
            'nights': 2,
            'adults': 2,
            'children': 0,
            'grandTotalCents': 55200,
            'paidCents': 27600,
            'paymentStatus': 'PARTIALLY_PAID',
            'status': 'CONFIRMED',
            'source': 'WEBSITE',
            'createdAt': '2026-08-20T00:00:00.000Z',
            'stayId': null,
          }
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
        'pages': 1,
      });
      expect(p.items.single.nights, 2);
      expect(p.total, 1);
      expect(p.pages, 1);
    });

    test('A-30 التفصيل: الضيف والنوع والدفعات ولقطة السعر', () {
      final d = AdminReservationDetail.fromJson({
        'id': 'res1',
        'reference': 'HTL-2026-000421',
        'status': 'CONFIRMED',
        'source': 'WEBSITE',
        'checkIn': '2026-09-01T00:00:00.000Z',
        'checkOut': '2026-09-04T00:00:00.000Z',
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
        'guest': {
          'fullName': 'أحمد محمد',
          'phone': '+967',
          'email': 'a@test',
          'nationality': 'يمني',
        },
        'roomType': {'id': 'rt1', 'name': 'ديلوكس', 'basePriceCents': 16000},
        'payments': [
          {
            'id': 'p1',
            'method': 'CARD',
            'amountCents': 27600,
            'status': 'COMPLETED',
            'createdAt': '2026-08-20T00:00:00.000Z',
          }
        ],
        'stay': null,
        'priceSnapshot': {'nights': []},
      });
      expect(d.guestName, 'أحمد محمد');
      expect(d.roomTypeName, 'ديلوكس');
      expect(d.payments.single.amountCents, 27600);
      expect(d.stay, isNull);
      expect(d.priceSnapshot, isNotEmpty);
    });
  });

  group('A-32 AuditLogItem', () {
    test('details خريطة و يتحمل الفراغ', () {
      final a = AuditLogItem.fromJson({
        'id': 'a1',
        'action': 'CODE_GENERATED',
        'entityType': 'AccessCode',
        'entityId': 'c1',
        'actor': 'المدير',
        'actorRole': 'ADMIN',
        'details': {'type': 'RECEPTION', 'days': 7},
        'createdAt': '2026-09-03T00:00:00.000Z',
      });
      expect(a.action, 'CODE_GENERATED');
      expect(a.details['type'], 'RECEPTION');

      final empty = AuditLogItem.fromJson(const {'id': 'a2'});
      expect(empty.details, isEmpty);
      expect(empty.actor, '');
    });
  });

  group('A-33 AdminReports', () {
    test('الإشغال والإيراد وإحصاءات الطلبات والجنسيات', () {
      final r = AdminReports.fromJson({
        'effectiveRooms': 13,
        'occupancyLast14Days': [
          {'date': '2026-09-03', 'label': '3 سبتمبر', 'percent': 60, 'occupied': 8},
        ],
        'revenueByMonth': [
          {'month': 'أغسطس', 'totalCents': 500000, 'count': 12},
        ],
        'requestsStats': {
          'total': 20,
          'byStatus': [
            {'status': 'NEW', 'count': 2},
            {'status': 'COMPLETED', 'count': 15},
          ],
          'completed': 15,
          'active': 5,
          'avgCompletionMinutes': 42,
          'topServices': [
            {'title': 'تنظيف الغرفة', 'count': 8},
          ],
        },
        'guestsByNationality': [
          {'nationality': 'يمني', 'count': 10},
        ],
      });
      expect(r.effectiveRooms, 13);
      expect(r.occupancyLast14Days.single.percent, 60);
      expect(r.revenueByMonth.single.totalCents, 500000);
      expect(r.requestsStats.avgCompletionMinutes, 42);
      expect(r.requestsStats.byStatus, hasLength(2));
      expect(r.guestsByNationality.single.nationality, 'يمني');
    });

    test('avgCompletionMinutes null مسموح', () {
      final r = AdminReports.fromJson({
        'requestsStats': {'total': 0, 'avgCompletionMinutes': null},
      });
      expect(r.requestsStats.avgCompletionMinutes, isNull);
    });
  });
}

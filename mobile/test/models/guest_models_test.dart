// ─────────────────────────────────────────────────────────────
// TEST: النماذج — تحليل أشكال CONTRACTS.md الحرفية (§1.6 + §4)
// ─────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/models/guest.dart';

void main() {
  group('AuthSession (AUTH-01)', () {
    test('تحليل رد validate', () {
      final s = AuthSession.fromJson(<String, dynamic>{
        'ok': true,
        'token': 'b3f1c2e4-0000',
        'role': 'GUEST',
        'name': 'خالد يوسف',
        'expiresAt': '2026-09-02T22:00:00.000Z',
      });
      expect(s.isGuest, true);
      expect(s.name, 'خالد يوسف');
      expect(s.token, 'b3f1c2e4-0000');
    });
  });

  group('GuestDashboard (G-01)', () {
    test('الأرقام بالسنت + الإقامة + الفندق', () {
      final d = GuestDashboard.fromJson(<String, dynamic>{
        'ok': true,
        'stay': {
          'id': 'st_0002',
          'reference': 'ST-2026-000002',
          'status': 'ACTIVE',
          'checkInAt': '2026-08-31T14:00:00.000Z',
          'expectedCheckOutAt': '2026-09-03T23:59:59.999Z',
          'actualCheckOutAt': null,
          'guestName': 'خالد يوسف',
          'totalNights': 3,
          'remainingNights': 1,
          'room': {
            'id': 'room_201',
            'number': '201',
            'floor': 2,
            'status': 'OCCUPIED',
          },
          'roomType': {
            'id': 'rt_deluxe',
            'name': 'غرفة ديلوكس',
            'bedConfig': 'سرير كبير',
            'sizeSqm': 28,
            'basePriceCents': 16000,
            'amenities': ['واي فاي', 'تكييف'],
            'images': ['/images/rooms/deluxe-1.jpg'],
          },
          'reservation': {
            'id': 'rx_0005',
            'bookingReference': 'HTL-2026-000005',
            'status': 'CHECKED_IN',
            'source': 'WEBSITE',
            'checkIn': '2026-08-31T00:00:00.000Z',
            'checkOut': '2026-09-03T00:00:00.000Z',
            'adults': 2,
            'children': 0,
            'roomsCount': 1,
            'currency': 'USD',
            'subtotalCents': 48000,
            'taxCents': 7200,
            'grandTotalCents': 55200,
            'paidCents': 23500,
            'paymentStatus': 'PARTIALLY_PAID',
            'paymentMethod': 'PAY_AT_HOTEL',
            'specialRequests': null,
            'createdAt': '2026-08-28T08:00:00.000Z',
          },
        },
        'notifications': [
          {
            'id': 'n1',
            'audience': 'GUEST',
            'type': 'INFO',
            'title': 'تم استلام طلبك',
            'body': 'طلبك قيد المعالجة',
            'read': false,
            'createdAt': '2026-09-01T09:12:00.000Z',
          }
        ],
        'unreadCount': 2,
        'activeRequests': 1,
        'balanceCents': 31700,
        'chargesCents': 6500,
        'currency': 'USD',
        'hotel': {
          'name': 'فندق قلب القاهرة — عدن',
          'phone': '+967771234567',
          'whatsapp': '+967771234567',
          'checkInTime': '14:00',
          'checkOutTime': '12:00',
        },
      });
      expect(d.balanceCents, 31700);
      expect(d.stay.room.number, '201');
      expect(d.stay.reservation.grandTotalCents, 55200);
      expect(d.hotel.name, 'فندق قلب القاهرة — عدن');
      expect(d.notifications.first.read, false);
      expect(d.stay.totalNights, 3);
      expect(d.stay.remainingNights, 1);
    });
  });

  group('GuestBill (G-09)', () {
    test('معادلة الرصيد = مجموع + إضافي − مدفوع', () {
      final b = GuestBill.fromJson(<String, dynamic>{
        'stayId': 'st_0002',
        'stayReference': 'ST-2026-000002',
        'roomNumber': '201',
        'roomNights': 3,
        'roomTotalCents': 55200,
        'roomSubtotalCents': 48000,
        'roomTaxCents': 7200,
        'extraCharges': [
          {
            'id': 'ch_01',
            'description': 'غسيل ملابس',
            'amountCents': 6500,
            'category': 'SERVICE',
            'date': '2026-09-01T12:00:00.000Z',
          }
        ],
        'extraTotalCents': 6500,
        'payments': [
          {
            'id': 'pay_001',
            'method': 'CASH',
            'amountCents': 27600,
            'createdAt': '2026-08-31T14:00:00.000Z',
            'recordedBy': 'أحمد الاستقبال',
          }
        ],
        'totalChargesCents': 61700,
        'totalPaidCents': 27600,
        'balanceCents': 34100,
        'currency': 'USD',
      });
      expect(
        b.roomTotalCents + b.extraTotalCents - b.totalPaidCents,
        b.balanceCents,
      );
      expect(b.extraCharges.first.amountCents, 6500);
      expect(b.payments.first.recordedBy, 'أحمد الاستقبال');
    });
  });

  group('ServiceRequestModel (G-04/05)', () {
    test('الحالة والتحديثات والفاعل النشط', () {
      final r = ServiceRequestModel.fromJson(<String, dynamic>{
        'id': 'req_0003',
        'reference': 'REQ-1003',
        'category': 'MAINTENANCE',
        'title': 'المكيف لا يبرد',
        'description': 'المكيف يعمل لكن التبريد ضعيف',
        'priority': 'URGENT',
        'status': 'IN_PROGRESS',
        'assignedTo': 'فريق الصيانة',
        'createdAt': '2026-09-01T09:12:00.000Z',
        'updatedAt': '2026-09-01T10:05:00.000Z',
        'completedAt': null,
        'roomNumber': '201',
        'updates': [
          {
            'id': 'ru_0007',
            'status': 'NEW',
            'note': 'تم استلام الطلب',
            'byName': 'خالد يوسف',
            'byRole': 'GUEST',
            'createdAt': '2026-09-01T09:12:00.000Z',
          }
        ],
      });
      expect(r.isActive, true);
      expect(r.priority, 'URGENT');
      expect(r.updates.first.byRole, 'GUEST');
      expect(r.roomNumber, '201');
    });

    test('الطلب المنتهي ليس نشطًا', () {
      final r = ServiceRequestModel.fromJson(<String, dynamic>{
        'id': 'req_9',
        'status': 'COMPLETED',
        'title': 'x',
        'reference': 'REQ-1009',
        'category': 'OTHER',
        'description': '',
        'priority': 'NORMAL',
        'assignedTo': '',
        'createdAt': '',
        'updatedAt': '',
        'roomNumber': '201',
        'updates': <dynamic>[],
      });
      expect(r.isActive, false);
    });
  });

  group('RoomOptions (G-11)', () {
    test('diffCents سالب = أوفر', () {
      final res = RoomOptionsResult.fromJson(<String, dynamic>{
        'ok': true,
        'rooms': [
          {
            'roomId': 'room_105',
            'number': '105',
            'floor': 1,
            'typeName': 'غرفة مزدوجة',
            'basePriceCents': 12000,
            'diffCents': -4000,
          }
        ],
        'currentRoom': {
          'number': '201',
          'typeName': 'غرفة ديلوكس',
          'basePriceCents': 16000,
        },
      });
      expect(res.rooms.first.diffCents, -4000);
      expect(res.currentRoom.number, '201');
    });
  });
}

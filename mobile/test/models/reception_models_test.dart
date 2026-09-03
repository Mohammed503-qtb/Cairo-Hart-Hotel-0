// ─────────────────────────────────────────────────────────────
// TEST: نماذج قناة الاستقبال — تحليل JSON لعقود R-01..R-07/R-10/R-22
// (نفس نمط guest_models_test: الحساسية للسنت والقيم الافتراضية)
// ─────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/models/reception.dart';

void main() {
  group('ArrivalItem (R-02)', () {
    test('تحليل كامل: ضيف + نوع غرفة + مالي بالسنت', () {
      final a = ArrivalItem.fromJson({
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
        'paymentMethod': 'CARD',
        'specialRequests': 'طابق مرتفع',
        'createdAt': '2026-08-20T10:00:00.000Z',
        'hasStay': false,
        'guest': {
          'id': 'g_1',
          'fullName': 'أحمد محمد',
          'phone': '+967771234567',
          'whatsapp': null,
          'email': 'a@example.com',
          'idNumber': null,
          'nationality': 'يمني',
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
      });
      expect(a.id, 'rx_01');
      expect(a.guest.fullName, 'أحمد محمد');
      expect(a.guest.nationality, 'يمني');
      expect(a.roomType.id, 'rt_deluxe');
      expect(a.grandTotalCents, 55200);
      expect(a.paidCents, 27600);
      expect(a.remainingCents, 27600);
      expect(a.paymentMethod, 'CARD');
      expect(a.specialRequests, 'طابق مرتفع');
      expect(a.hasStay, isFalse);
    });

    test('حقول غائبة → قيم آمنة (نص فارغ وصفر) لا رمي', () {
      final a = ArrivalItem.fromJson(const {});
      expect(a.id, '');
      expect(a.nights, 0);
      expect(a.grandTotalCents, 0);
      expect(a.guest.fullName, '');
      expect(a.roomType.name, '');
      expect(a.remainingCents, 0);
    });
  });

  group('DepartureItem (R-03)', () {
    test('المتأخر والطلبات النشطة والرصيد', () {
      final d = DepartureItem.fromJson({
        'id': 'st_1',
        'reference': 'ST-2026-000003',
        'status': 'ACTIVE',
        'guestName': 'نورا سعيد',
        'guestPhone': '+967771234567',
        'roomNumber': '103',
        'roomTypeName': 'غرفة ديلوكس',
        'checkInAt': '2026-09-01T14:00:00.000Z',
        'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
        'balanceCents': 5000,
        'activeRequests': 2,
        'overdue': true,
      });
      expect(d.overdue, isTrue);
      expect(d.activeRequests, 2);
      expect(d.balanceCents, 5000);
      expect(d.roomNumber, '103');
    });
  });

  group('RoomItem (R-10)', () {
    test('isAvailable فقط لAVAILABLE', () {
      final r = RoomItem.fromJson({
        'id': 'r_201',
        'number': '201',
        'floor': 2,
        'status': 'AVAILABLE',
        'roomTypeId': 'rt_deluxe',
        'roomTypeName': 'غرفة ديلوكس',
        'guestName': null,
        'expectedCheckOutAt': null,
        'activeStayId': null,
      });
      expect(r.isAvailable, isTrue);
      expect(
        RoomItem.fromJson({'status': 'OCCUPIED'}).isAvailable,
        isFalse,
      );
    });
  });

  group('ReceptionDashboard (R-01)', () {
    test('الإحصاءات والقوائم الثلاث', () {
      final d = ReceptionDashboard.fromJson({
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
            'paidCents': 0,
            'grandTotalCents': 55200,
            'paymentStatus': 'UNPAID',
            'checkIn': '2026-09-02T14:00:00.000Z',
            'checkOut': '2026-09-05T12:00:00.000Z',
          }
        ],
        'departures': [
          {
            'stayId': 'st_3',
            'reference': 'ST-2026-000003',
            'guestName': 'نورا سعيد',
            'roomNumber': '103',
            'balanceCents': 5000,
            'status': 'ACTIVE',
            'expectedCheckOutAt': '2026-09-02T12:00:00.000Z',
          }
        ],
        'pendingRequests': [
          {
            'id': 'req_3',
            'reference': 'REQ-1003',
            'roomNumber': '201',
            'guestName': 'خالد يوسف',
            'title': 'المكيف لا يبرد',
            'priority': 'URGENT',
            'status': 'IN_PROGRESS',
            'createdAt': '2026-09-02T08:30:00.000Z',
          }
        ],
      });
      expect(d.stats.occupancyPercent, 21);
      expect(d.stats.urgentRequests, 1);
      expect(d.arrivals, hasLength(1));
      expect(d.arrivals.single.reservationId, 'rx_01');
      expect(d.departures.single.stayId, 'st_3');
      expect(d.pendingRequests.single.title, 'المكيف لا يبرد');
    });
  });

  group('CheckInResult (R-06)', () {
    test('الكود الخام يُحفظ كما هو (مرة واحدة — لا هاش)', () {
      final r = CheckInResult.fromJson({
        'ok': true,
        'stay': {'id': 'st_9', 'reference': 'ST-2026-000004'},
        'roomNumber': '202',
        'guestCode': 'H334469T0',
        'guestName': 'أحمد محمد',
        'guestPhone': '+967771234567',
      });
      expect(r.guestCode, 'H334469T0');
      expect(r.stayReference, 'ST-2026-000004');
      expect(r.roomNumber, '202');
    });
  });

  group('CheckOutResult (R-07)', () {
    test('closed + roomNumber + balanceCents', () {
      final r = CheckOutResult.fromJson(
        {'ok': true, 'closed': true, 'roomNumber': '103', 'balanceCents': 0},
      );
      expect(r.closed, isTrue);
      expect(r.balanceCents, 0);
    });
  });

  group('StayDetailData (R-05)', () {
    Map<String, dynamic> full() => {
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
            'fullName': 'نورا سعيد',
            'phone': '+967771234567',
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
            'bookingReference': 'HTL-2026-000003',
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
            'priceSnapshot': {
              'roomTypeName': 'غرفة ديلوكس',
              'nightly': [
                {'date': '2026-09-01', 'priceCents': 16000, 'rateName': 'أساسي'}
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
              {'description': 'غسيل', 'amountCents': 500, 'category': 'SERVICE'}
            ],
            'extraTotalCents': 500,
            'payments': [
              {
                'id': 'pay_1',
                'method': 'CASH',
                'amountCents': 50200,
                'createdAt': '2026-09-01T15:00:00.000Z',
                'recordedBy': 'أحمد الاستقبال',
              }
            ],
            'totalChargesCents': 55700,
            'totalPaidCents': 50200,
            'balanceCents': 5500,
            'currency': 'USD',
          },
          'requests': [
            {
              'id': 'req_1',
              'reference': 'REQ-1001',
              'category': 'خدمة',
              'title': 'منشفات إضافية',
              'description': null,
              'priority': 'NORMAL',
              'status': 'COMPLETED',
              'assignedTo': null,
              'createdAt': '2026-09-01T16:00:00.000Z',
              'updatedAt': '2026-09-01T17:00:00.000Z',
              'completedAt': '2026-09-01T17:00:00.000Z',
              'stay': {
                'id': 'st_1',
                'reference': 'ST-2026-000003',
                'roomNumber': '103',
                'guestName': 'نورا سعيد',
              },
              'updates': [
                {
                  'id': 'upd_1',
                  'status': 'COMPLETED',
                  'note': 'تم',
                  'byName': 'أحمد الاستقبال',
                  'byRole': 'RECEPTION',
                  'createdAt': '2026-09-01T17:00:00.000Z',
                }
              ],
            }
          ],
          'extensionRequests': [
            {
              'id': 'ext_1',
              'newCheckOut': '2026-09-06',
              'nights': 2,
              'priceCents': 32000,
              'note': 'رحلة متأخرة',
              'status': 'PENDING',
              'decidedBy': null,
              'decidedAt': null,
              'createdAt': '2026-09-02T09:00:00.000Z',
            }
          ],
          'roomChangeRequests': [
            {
              'id': 'rc_1',
              'toRoomId': 'r_202',
              'toRoomNumber': '202',
              'priceDiffCents': 0,
              'reason': 'ضجيج',
              'status': 'PENDING',
              'decidedBy': null,
              'decidedAt': null,
              'createdAt': '2026-09-02T10:00:00.000Z',
            }
          ],
          'messages': [
            {
              'id': 'msg_1',
              'sender': 'GUEST',
              'senderName': 'نورا سعيد',
              'body': 'مرحبًا',
              'createdAt': '2026-09-01T18:00:00.000Z',
            }
          ],
        };

    test('تحليل متداخل كامل: فاتورة + طلبات + تمديد + تغيير + رسائل', () {
      final d = StayDetailData.fromJson(full());
      expect(d.id, 'st_1');
      expect(d.status, 'ACTIVE');
      expect(d.guest.fullName, 'نورا سعيد');
      expect(d.room.number, '103');
      expect(d.roomType.name, 'غرفة ديلوكس');
      expect(d.reservation.grandTotalCents, 55200);
      expect(d.reservation.priceSnapshot?['roomTypeName'], 'غرفة ديلوكس');
      expect(d.bill.balanceCents, 5500);
      expect(d.bill.extraCharges, hasLength(1));
      expect(d.bill.extraCharges.single.amountCents, 500);
      expect(d.bill.payments.single.method, 'CASH');
      expect(d.requests.single.updates.single.byRole, 'RECEPTION');
      expect(d.extensionRequests.single.priceCents, 32000);
      expect(d.roomChangeRequests.single.toRoomNumber, '202');
      expect(d.messages.single.body, 'مرحبًا');
    });

    test('أقسام غائبة → قوائم فارغة بلا رمي (فاتورة صفرية)', () {
      final d = StayDetailData.fromJson({
        'stay': {'id': 'st_2', 'reference': 'ST-2', 'status': 'ACTIVE'},
        'guest': {'fullName': 'س'},
        'room': {'number': '1'},
        'roomType': {'name': 'غرفة'},
      });
      expect(d.requests, isEmpty);
      expect(d.extensionRequests, isEmpty);
      expect(d.roomChangeRequests, isEmpty);
      expect(d.messages, isEmpty);
      expect(d.bill.balanceCents, 0);
      expect(d.actualCheckOutAt, isNull);
    });
  });

  group('InHouseStay (R-04 — نموذج F4-b)', () {
    test('التداخل المتشعّب (guest/room/roomType/reservation)', () {
      final s = InHouseStay.fromJson({
        'id': 'st_1',
        'reference': 'ST-2026-000003',
        'status': 'ACTIVE',
        'checkInAt': '2026-09-01T14:00:00.000Z',
        'expectedCheckOutAt': '2026-09-04T12:00:00.000Z',
        'guest': {'fullName': 'نورا سعيد', 'phone': '+967771234567'},
        'room': {'number': '103', 'floor': 1},
        'roomType': {'name': 'غرفة ديلوكس'},
        'activeRequests': 0,
        'balanceCents': 5000,
        'reservation': {
          'grandTotalCents': 55200,
          'paidCents': 50200,
          'paymentStatus': 'PARTIALLY_PAID',
        },
      });
      expect(s.guestName, 'نورا سعيد');
      expect(s.roomNumber, '103');
      expect(s.roomFloor, 1);
      expect(s.reservationPaymentStatus, 'PARTIALLY_PAID');
      expect(s.balanceCents, 5000);
    });
  });

  group('ReceptionNotification (R-22)', () {
    test('غير المقروء والنوع والعنوان', () {
      final n = ReceptionNotification.fromJson({
        'id': 'n_1',
        'type': 'REQUEST',
        'title': 'طلب جديد',
        'body': 'غرفة 103',
        'read': false,
        'createdAt': '2026-09-02T08:00:00.000Z',
      });
      expect(n.read, isFalse);
      expect(n.type, 'REQUEST');
      expect(n.title, 'طلب جديد');
    });
  });
}

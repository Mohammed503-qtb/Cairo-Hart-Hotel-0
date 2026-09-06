// ─────────────────────────────────────────────────────────────
// TEST: مقاسات الهواتف + الوضع الداكن — دليل فعلي لكل شاشة
// ① الاستجابة: كل شاشات الأدمن/الاستقبال عند 320/360/412/768
//    مع تكبير نص 1.3 (أسوأ حالة) — صفر استثناءات فيض RenderFlex
// ② الأصداف الكاملة (رأس + تنقل سفلي/شريط جانبي) ضيقًا وواسعًا
// ③ الوضع الداكن: كل شاشة تُصيَّر بنصوصها الظاهرة بلا استثناء
// ─────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show ByteData;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';
import 'package:cairo_heart_hotel/screens/admin/admin_shell.dart';
import 'package:cairo_heart_hotel/screens/admin/audit_log_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/dashboard_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/guests_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/hotel_settings_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/rates_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/reports_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/reservations_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/room_types_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/rooms_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/services_screen.dart';
import 'package:cairo_heart_hotel/screens/admin/staff_codes_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/arrivals_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/dashboard_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/departures_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/inhouse_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/reception_shell.dart';
import 'package:cairo_heart_hotel/screens/reception/requests_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/rooms_screen.dart';
import 'package:cairo_heart_hotel/screens/reception/search_screen.dart';
import 'package:cairo_heart_hotel/services/socket_service.dart';
import 'package:cairo_heart_hotel/state/admin_store.dart';
import 'package:cairo_heart_hotel/state/reception_store.dart';
import 'package:cairo_heart_hotel/state/session.dart';
import 'package:cairo_heart_hotel/ui/theme.dart';

http.Response _json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );

final Map<String, String> _hotel = {
  'id': 'h1',
  'name': 'فندق قلب القاهرة',
  'tagline': 'ضيافة تليق بقلب عدن',
  'description': 'وصف',
  'phone': '+967771234567',
  'whatsapp': '+967771234567',
  'email': 'info@hotel.test',
  'address': 'عدن',
  'city': 'عدن',
  'currency': 'USD',
  'checkInTime': '14:00',
  'checkOutTime': '12:00',
};

Map<String, dynamic> _roomType([String id = 'rt1']) => {
      'id': id,
      'name': 'غرفة ديلوكس',
      'nameEn': 'Deluxe',
      'description': 'وصف النوع',
      'capacityAdults': 2,
      'capacityChildren': 1,
      'bedConfig': 'سرير كبير',
      'sizeSqm': 28,
      'basePriceCents': 16000,
      'amenities': ['واي فاي'],
      'images': <String>[],
      'active': true,
      'sortOrder': 0,
      'roomsCount': 4,
      'reservationsCount': 2,
      'ratesCount': 1,
      'createdAt': '2026-08-01T10:00:00.000Z',
    };

Map<String, dynamic> _adminRoom(String id, String number, String status) => {
      'id': id,
      'number': number,
      'floor': 1,
      'status': status,
      'notes': null,
      'roomTypeId': 'rt1',
      'roomTypeName': 'غرفة ديلوكس',
      'guestName': status == 'OCCUPIED' ? 'أحمد محمد' : null,
      'expectedCheckOut': status == 'OCCUPIED' ? '2026-09-06' : null,
      'createdAt': '2026-08-01T10:00:00.000Z',
    };

Map<String, dynamic> _arrival(String id) => {
      'id': id,
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
      'createdAt': '2026-08-20T10:00:00.000Z',
      'hasStay': false,
      'guest': {
        'id': 'g_$id',
        'fullName': 'أحمد محمد',
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
      'specialRequests': 'سرير أطفال',
    };

Map<String, dynamic> _inHouse(String id) => {
      // بنية R-04 الحقيقية من الخادم: guest/room/roomType/reservation متشعبة
      'id': id,
      'reference': 'ST-2026-000001',
      'status': 'ACTIVE',
      'checkInAt': '2026-09-02T14:00:00.000Z',
      'expectedCheckOutAt': '2026-09-05T12:00:00.000Z',
      'guest': {'fullName': 'أحمد محمد', 'phone': '+967771234567'},
      'room': {'number': '101', 'floor': 1},
      'roomType': {'name': 'غرفة ديلوكس'},
      'activeRequests': 1,
      'balanceCents': 12000,
      'reservation': {
        'grandTotalCents': 55200,
        'paidCents': 43200,
        'paymentStatus': 'PARTIALLY_PAID',
      },
    };

Map<String, dynamic> _request(String id) => {
      // بنية R-08 الحقيقية: stay متشعبة (كما يعيدها الخادم)
      'id': id,
      'reference': 'REQ-1000',
      'category': 'HOUSEKEEPING',
      'title': 'تنظيف الغرفة',
      'description': null,
      'priority': 'URGENT',
      'status': 'NEW',
      'assignedTo': null,
      'createdAt': '2026-09-02T15:00:00.000Z',
      'updatedAt': '2026-09-02T15:00:00.000Z',
      'completedAt': null,
      'stay': {
        'id': 'stay_1',
        'reference': 'ST-2026-000001',
        'roomNumber': '101',
        'guestName': 'أحمد محمد',
      },
      'updates': <Map<String, dynamic>>[],
    };

Map<String, dynamic> _recRoom(String id, String number, String status) => {
      'id': id,
      'number': number,
      'floor': 1,
      'status': status,
      'roomTypeId': 'rt1',
      'roomTypeName': 'غرفة ديلوكس',
      'guestName': status == 'OCCUPIED' ? 'أحمد محمد' : null,
      'guestPhone': status == 'OCCUPIED' ? '+967771234567' : null,
      'expectedCheckOutAt': status == 'OCCUPIED' ? '2026-09-05' : null,
      'notes': status == 'OUT_OF_ORDER' ? 'صيانة مكيف' : null,
    };

Map<String, dynamic> _departure(String id, {bool overdue = false}) => {
      'id': id,
      'reference': 'ST-2026-000001',
      'status': 'ACTIVE',
      'guestName': 'أحمد محمد',
      'guestPhone': '+967771234567',
      'roomNumber': '101',
      'roomTypeName': 'غرفة ديلوكس',
      'checkInAt': '2026-09-02T14:00:00.000Z',
      'expectedCheckOutAt': '2026-09-05T12:00:00.000Z',
      'balanceCents': 12000,
      'activeRequests': 0,
      'overdue': overdue,
    };

Map<String, dynamic> _reservation(String id) => {
      'id': id,
      'reference': 'HTL-2026-000421',
      'guestName': 'أحمد محمد',
      'roomTypeName': 'غرفة ديلوكس',
      'grandTotalCents': 55200,
      'status': 'CONFIRMED',
      'createdAt': '2026-08-20T10:00:00.000Z',
    };

Map<String, dynamic> _audit(String id) => {
      'id': id,
      'action': 'RESERVATION_CREATED',
      'entityType': 'Reservation',
      'entityId': 'r1',
      'actor': 'WEBSITE',
      'actorRole': 'WEBSITE',
      'details': {},
      'createdAt': '2026-09-02T15:00:00.000Z',
    };

Map<String, dynamic> _guest(String id) => {
      'id': id,
      'fullName': 'أحمد محمد',
      'phone': '+967771234567',
      'createdAt': '2026-08-20T10:00:00.000Z',
      'reservationsCount': 2,
      'lastReservation': null,
    };

Map<String, dynamic> _service(String id) => {
      'id': id,
      'nameAr': 'إفطار',
      'nameEn': 'Breakfast',
      'categoryId': 'c1',
      'categoryName': 'مطعم',
      'priceCents': 800,
      'durationMin': 30,
      'active': true,
    };

Map<String, dynamic> _rate(String id) => {
      'id': id,
      'name': 'الموسم الصيفي',
      'roomTypeId': 'rt1',
      'roomTypeName': 'غرفة ديلوكس',
      'priceCents': 20000,
      'startDate': '2026-07-01',
      'endDate': '2026-08-31',
      'active': true,
      'createdAt': '2026-06-01T10:00:00.000Z',
    };

Map<String, dynamic> _staff(String id) => {
      'id': id,
      'fullName': 'سالم حسن',
      'role': 'RECEPTION',
      'phone': '+967771234568',
      'active': true,
      'createdAt': '2026-08-01T10:00:00.000Z',
      'lastCode': null,
    };

Map<String, dynamic> _code(String id) => {
      'id': id,
      'type': 'RECEPTION',
      'codeMasked': 'REC-•••-1234',
      'status': 'ACTIVE',
      'createdAt': '2026-09-01T10:00:00.000Z',
      'expiresAt': '2026-09-08T10:00:00.000Z',
      'lastUsedAt': '2026-09-02T10:00:00.000Z',
      'staff': _staff('s1'),
      'stay': null,
    };

/// موك موحد: يخدم كل مسارات الأدمن والاستقبال ببيانات صالحة
http.Client _fakeApi() => MockClient((req) async {
      final p = req.url.path;
      switch (p) {
        // ── مشترك ──
        case '/api/admin/dashboard':
          return _json({
            'ok': true,
            'kpis': {
              'arrivalsToday': 2,
              'departuresToday': 1,
              'inHouseStays': 2,
              'inHouseGuests': 3,
              'pendingRequests': 1,
              'urgentRequests': 1,
              'occupancyPercent': 50,
              'totalRooms': 8,
              'occupiedRooms': 4,
              'availableRooms': 3,
              'outOfOrderRooms': 1,
              'revenueMonthCents': 94000,
              'activeGuestCodes': 2,
              'activeStaffCodes': 2,
            },
            'recentBookings': [_reservation('r1'), _reservation('r2')],
            'roomsByStatus': {
              'AVAILABLE': 3,
              'OCCUPIED': 4,
              'CLEANING': 1,
              'OUT_OF_ORDER': 1,
            },
            'alerts': {'staleRequests': 1, 'outOfOrderRooms': 1},
            'revenueByDay': [
              {'date': '2026-09-01', 'totalCents': 30000},
              {'date': '2026-09-02', 'totalCents': 64000},
            ],
          });
        case '/api/admin/hotel':
          return _json({'ok': true, 'hotel': _hotel});
        case '/api/admin/room-types':
          return _json({
            'ok': true,
            'roomTypes': [_roomType('rt1'), _roomType('rt2')],
          });
        case '/api/admin/rooms':
          return _json({
            'ok': true,
            'rooms': [
              _adminRoom('rm1', '101', 'OCCUPIED'),
              _adminRoom('rm2', '102', 'AVAILABLE'),
              _adminRoom('rm3', '103', 'CLEANING'),
            ],
          });
        case '/api/admin/rates':
          return _json({
            'ok': true,
            'rates': [_rate('rate1'), _rate('rate2')],
          });
        case '/api/admin/services':
          return _json({
            'ok': true,
            'services': [_service('sv1'), _service('sv2')],
          });
        case '/api/admin/service-categories':
          return _json({
            'ok': true,
            'categories': [
              {
                'id': 'c1',
                'nameAr': 'مطعم',
                'nameEn': 'Restaurant',
                'active': true,
                'servicesCount': 2,
              },
            ],
          });
        case '/api/admin/staff':
          return _json({
            'ok': true,
            'staff': [_staff('s1'), _staff('s2')],
          });
        case '/api/admin/codes':
          return _json({
            'ok': true,
            'codes': [_code('cd1'), _code('cd2')],
          });
        case '/api/admin/reservations':
          return _json({
            'ok': true,
            'items': [_reservation('r1'), _reservation('r2')],
            'total': 2,
            'page': 1,
            'pages': 1,
          });
        case '/api/admin/guests':
          return _json({
            'ok': true,
            'guests': [_guest('g1'), _guest('g2')],
          });
        case '/api/admin/audit':
          return _json({
            'ok': true,
            'items': [_audit('a1'), _audit('a2')],
            'total': 2,
            'page': 1,
            'pages': 1,
          });
        case '/api/admin/reports':
          return _json({
            'ok': true,
            'effectiveRooms': 8,
            'occupancyLast14Days': [
              {'date': '2026-08-25', 'occupied': 4, 'total': 8},
              {'date': '2026-08-26', 'occupied': 5, 'total': 8},
            ],
            'revenueByMonth': [
              {'month': '2026-07', 'totalCents': 940000},
              {'month': '2026-08', 'totalCents': 1240000},
            ],
            'requestsStats': {
              'total': 10,
              'completed': 6,
              'cancelled': 2,
              'active': 2,
            },
            'guestsByNationality': [
              {'nationality': 'يمني', 'count': 5},
            ],
          });
        case '/api/admin/notifications':
          return _json({
            'ok': true,
            'notifications': [
              {
                'id': 'n1',
                'audience': 'ADMIN',
                'title': 'حجز جديد',
                'body': 'HTL-2026-000421',
                'read': false,
                'createdAt': '2026-09-02T15:00:00.000Z',
              },
            ],
            'unreadCount': 1,
          });

        // ── الاستقبال ──
        case '/api/reception/dashboard':
          return _json({
            'ok': true,
            'stats': {
              'arrivalsToday': 2,
              'departuresToday': 1,
              'inHouseStays': 2,
              'pendingRequests': 1,
              'urgentRequests': 1,
              'occupancyPercent': 50,
              'totalRooms': 8,
              'occupiedRooms': 4,
            },
            'arrivals': [
              {
                'reservationId': 'r1',
                'bookingReference': 'HTL-2026-000421',
                'guestName': 'أحمد محمد',
                'guestPhone': '+967771234567',
                'roomTypeId': 'rt1',
                'roomTypeName': 'غرفة ديلوكس',
                'nights': 3,
                'paidCents': 27600,
                'grandTotalCents': 55200,
                'paymentStatus': 'PARTIALLY_PAID',
                'checkIn': '2026-09-02',
                'checkOut': '2026-09-05',
              },
            ],
            'departures': [
              {
                'stayId': 'st1',
                'reference': 'ST-2026-000001',
                'guestName': 'أحمد محمد',
                'roomNumber': '101',
                'balanceCents': 12000,
                'status': 'ACTIVE',
                'expectedCheckOutAt': '2026-09-05',
              },
            ],
            'requests': [
              {
                'id': 'req1',
                'reference': 'REQ-1000',
                'roomNumber': '101',
                'guestName': 'أحمد محمد',
                'title': 'تنظيف الغرفة',
                'priority': 'URGENT',
                'status': 'NEW',
                'createdAt': '2026-09-02T15:00:00.000Z',
              },
            ],
          });
        case '/api/reception/arrivals':
          return _json({
            'ok': true,
            'arrivals': [_arrival('a1'), _arrival('a2')],
          });
        case '/api/reception/departures':
          return _json({
            'ok': true,
            'departures': [
              _departure('d1', overdue: true),
              _departure('d2'),
            ],
          });
        case '/api/reception/inhouse':
          return _json({
            'ok': true,
            'stays': [_inHouse('st1'), _inHouse('st2')],
          });
        case '/api/reception/requests':
          return _json({
            'ok': true,
            'requests': [_request('req1'), _request('req2')],
          });
        case '/api/reception/rooms':
          return _json({
            'ok': true,
            'rooms': [
              _recRoom('rm1', '101', 'OCCUPIED'),
              _recRoom('rm2', '102', 'AVAILABLE'),
              _recRoom('rm3', '103', 'DIRTY'),
              _recRoom('rm4', '104', 'OUT_OF_ORDER'),
            ],
          });
        case '/api/reception/notifications':
          return _json({
            'ok': true,
            'notifications': [
              {
                'id': 'n1',
                'title': 'طلب جديد',
                'body': 'تنظيف الغرفة',
                'read': false,
                'createdAt': '2026-09-02T15:00:00.000Z',
              },
            ],
            'unreadCount': 1,
          });
        case '/api/reception/search':
          return _json({
            'ok': true,
            'reservations': [
              {
                'id': 'r1',
                'reference': 'HTL-2026-000421',
                'guestName': 'أحمد محمد',
                'status': 'CONFIRMED',
                'checkIn': '2026-09-02',
                'checkOut': '2026-09-05',
                'paymentStatus': 'PARTIALLY_PAID',
              },
            ],
            'stays': [
              {
                'id': 'st1',
                'reference': 'ST-2026-000001',
                'guestName': 'أحمد محمد',
                'roomNumber': '101',
                'status': 'ACTIVE',
                'balanceCents': 12000,
              },
            ],
          });
        default:
          return _json({'ok': true});
      }
    });

ApiClient _api() => ApiClient(
      baseUrlProvider: () => 'https://hotel.test',
      tokenProvider: () => 'tok-test',
      onSessionExpired: () {},
      httpClient: _fakeApi(),
    );

/// المقاسات المختبرة: هاتف صغير جدًا / شائع / حديث / لوحي
const _sizes = <(String, Size)>[
  ('320px', Size(320, 480)),
  ('360px', Size(360, 640)),
  ('412px', Size(412, 800)),
  ('768px-لوحي', Size(768, 1024)),
];

/// (الشاشة، منشئ الويدجت، نص مفتاحي للاختبار الظهور)
List<(String, Widget Function(AdminStore), String)> get _adminScreens => [
      ('لوحة الأدمن', (s) => AdminDashboardScreen(store: s, onNavigate: (_) {}), 'لوحة التحكم'),
      ('إعدادات الفندق', (s) => HotelSettingsScreen(store: s), 'إعدادات الفندق'),
      ('أنواع الغرف', (s) => RoomTypesScreen(store: s), 'أنواع الغرف'),
      ('غرف الأدمن', (s) => AdminRoomsScreen(store: s), 'الغرف'),
      ('الأسعار', (s) => RatesScreen(store: s), 'الأسعار الموسمية'),
      ('الخدمات', (s) => ServicesScreen(store: s), 'الخدمات'),
      ('الطاقم والأكواد', (s) => StaffCodesScreen(store: s), 'الطاقم والأكواد'),
      ('حجوزات الأدمن', (s) => AdminReservationsScreen(store: s), 'الحجوزات'),
      ('الضيوف', (s) => GuestsScreen(store: s), 'الضيوف'),
      ('التقارير', (s) => ReportsScreen(store: s), 'التقارير'),
      ('سجل التدقيق', (s) => AuditLogScreen(store: s), 'سجل التدقيق'),
    ];

List<(String, Widget Function(ReceptionStore), String)> get _recScreens => [
      ('لوحة الاستقبال', (s) => DashboardScreen(store: s, onGoTab: (_) {}), 'إجراءات سريعة'),
      ('الوصولون', (s) => ArrivalsScreen(store: s), 'أحمد محمد'),
      ('المقيمون', (s) => InHouseScreen(store: s), 'أحمد محمد'),
      ('الطلبات', (s) => RequestsScreen(store: s), 'تنظيف الغرفة'),
      ('المغادرون', (s) => DeparturesScreen(store: s), 'مغادرات متأخرة'),
      ('غرف الاستقبال', (s) => RoomsScreen(store: s), 'حالة الغرف'),
    ];

Widget _wrap(
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  double textScale = 1.0,
}) =>
    MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      locale: const Locale('ar'),
      home: Scaffold(body: child),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    );

void main() {
  // تحميل خط Cairo الحقيقي (Regular/SemiBold/Bold) حتى تكون قياسات
  // النص العربي حقيقية — خط Ahem الافتراضي يقيس كل حرف بعرض كامل
  // (مضخم ~2x للعربية) فيولّد فيضًا وهميًا لا يحدث بالخط الفعلي
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final path in const [
      'assets/fonts/Cairo-Regular.ttf',
      'assets/fonts/Cairo-SemiBold.ttf',
      'assets/fonts/Cairo-Bold.ttf',
    ]) {
      final data = File(path).readAsBytesSync();
      final loader = FontLoader('Cairo')
        ..addFont(Future.value(ByteData.view(data.buffer)));
      await loader.load();
      // mono: المراجع LTR (HTL-/ST-) — خط Ahem يقيس كل محرف بعرض
      // كامل (مضخم ~2x) فيولد فيضًا وهميًا؛ Cairo بأعراض واقعية
      final monoLoader = FontLoader('monospace')
        ..addFont(Future.value(ByteData.view(data.buffer)));
      await monoLoader.load();
    }
  });

  testWidgets('تدريب أولي للموك: كل المسارات تجيب ok', (tester) async {
    final api = _api();
    final json = await api.get('/api/admin/dashboard');
    expect(json['ok'], isTrue);
    final json2 = await api.get('/api/reception/rooms');
    expect(json2['ok'], isTrue);
  });

  group('استجابة شاشات الأدمن — كل المقاسات بتكبير نص 1.3', () {
    for (final (sizeName, size) in _sizes) {
      for (final (name, build, keyText) in _adminScreens) {
        testWidgets('$name عند $sizeName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final store = AdminStore(_api());
          await tester.pumpWidget(
            _wrap(build(store), textScale: 1.3),
          );
          await tester.pumpAndSettle();
          final overflowEx = tester.takeException();
          expect(
            overflowEx,
            isNull,
            reason: 'فيض في $name عند $sizeName:\n'
                '${overflowEx?.toString() ?? ''}',
          );
          expect(find.textContaining(keyText), findsWidgets);
        });
      }
    }
  });

  group('استجابة شاشات الاستقبال — كل المقاسات بتكبير نص 1.3', () {
    for (final (sizeName, size) in _sizes) {
      for (final (name, build, keyText) in _recScreens) {
        testWidgets('$name عند $sizeName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final store = ReceptionStore(_api());
          await tester.pumpWidget(
            _wrap(build(store), textScale: 1.3),
          );
          await tester.pumpAndSettle();
          final overflowEx = tester.takeException();
          expect(
            overflowEx,
            isNull,
            reason: 'فيض في $name عند $sizeName:\n'
                '${overflowEx?.toString() ?? ''}',
          );
          expect(find.textContaining(keyText), findsWidgets);
        });
      }
    }
  });

  group('الأصداف الكاملة — ضيق وواسع', () {
    testWidgets('AdminShell ضيق (360px): تنقل سفلي + لوحة', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = AdminStore(_api());
      await tester.pumpWidget(_wrap(
        AdminShell(
          session: SessionController(),
          store: store,
          realtime: RealtimeService(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('المزيد'), findsOneWidget);
    });

    testWidgets('AdminShell واسع (768px): شريط جانبي', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = AdminStore(_api());
      await tester.pumpWidget(_wrap(
        AdminShell(
          session: SessionController(),
          store: store,
          realtime: RealtimeService(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('لوحة الإدارة'), findsOneWidget);
    });

    testWidgets('ReceptionShell ضيق (360px): تنقل سفلي بستة', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = ReceptionStore(_api());
      await tester.pumpWidget(_wrap(
        ReceptionShell(
          session: SessionController(),
          store: store,
          realtime: RealtimeService(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('الوصولون'), findsOneWidget);
    });

    testWidgets('ReceptionShell واسع (768px): شريط جانبي NavigationRail',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = ReceptionStore(_api());
      await tester.pumpWidget(_wrap(
        ReceptionShell(
          session: SessionController(),
          store: store,
          realtime: RealtimeService(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('الوضع الداكن — كل الشاشات تصير بنصوصها', () {
    for (final (name, build, keyText) in _adminScreens) {
      testWidgets('$name (داكن)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final store = AdminStore(_api());
        await tester.pumpWidget(
          _wrap(build(store), mode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'استثناء تصيير داكن في $name',
        );
        expect(find.textContaining(keyText), findsWidgets);
      });
    }

    for (final (name, build, keyText) in _recScreens) {
      testWidgets('$name (داكن)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final store = ReceptionStore(_api());
        await tester.pumpWidget(
          _wrap(build(store), mode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'استثناء تصيير داكن في $name',
        );
        expect(find.textContaining(keyText), findsWidgets);
      });
    }

    testWidgets('AdminShell كاملًا (داكن 360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(
        AdminShell(
          session: SessionController(),
          store: AdminStore(_api()),
          realtime: RealtimeService(),
        ),
        mode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('لوحة الإدارة'), findsOneWidget);
    });

    testWidgets('ReceptionShell كاملًا (داكن 360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(
        ReceptionShell(
          session: SessionController(),
          store: ReceptionStore(_api()),
          realtime: RealtimeService(),
        ),
        mode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('لوحة الاستقبال'), findsOneWidget);
    });
  });

  group('حوار البحث العام (R-19) — أصغر مقاس وأكبر نص', () {
    testWidgets('showReceptionSearch عند 320px × 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = ReceptionStore(_api());
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showReceptionSearch(context, store: store),
            child: const Text('افتح البحث'),
          ),
        ),
        textScale: 1.3,
      ));
      await tester.tap(find.text('افتح البحث'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('بحث عام'), findsOneWidget);
    });
  });
}

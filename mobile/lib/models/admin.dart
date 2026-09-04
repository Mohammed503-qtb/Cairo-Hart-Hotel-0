// ─────────────────────────────────────────────────────────────
// ADMIN MODELS — نماذج قناة الإدارة (مطابقة لعقود
// CONTRACTS.md A-01..A-34) — صفر عمل خادم في F5: النقل من الويب
// كل الأرقام المالية بالسنت (int) كما يرسلها الخادم
// ─────────────────────────────────────────────────────────────

String _s(Map<String, dynamic> j, String k, [String def = '']) =>
    j[k] is String ? j[k] as String : def;

String? _sn(Map<String, dynamic> j, String k) =>
    j[k] is String ? j[k] as String : null;

int _i(Map<String, dynamic> j, String k, [int def = 0]) {
  final v = j[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

int? _in(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _b(Map<String, dynamic> j, String k, [bool def = false]) =>
    j[k] is bool ? j[k] as bool : def;

Map<String, dynamic>? _m(Map<String, dynamic> j, String k) =>
    j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : null;

List<Map<String, dynamic>> _ml(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<Map<String, dynamic>>().toList();
}

List<String> _sl(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<String>().toList(growable: false);
}

Map<String, int> _countMap(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! Map) return const {};
  final out = <String, int>{};
  v.forEach((key, value) {
    if (key is String) out[key] = _i({'v': value}, 'v');
  });
  return out;
}

// ───────────── A-01 · لوحة تحكم الإدارة ─────────────

class AdminKpis {
  const AdminKpis({
    required this.arrivalsToday,
    required this.departuresToday,
    required this.inHouseStays,
    required this.inHouseGuests,
    required this.pendingRequests,
    required this.urgentRequests,
    required this.occupancyPercent,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.outOfOrderRooms,
    required this.revenueMonthCents,
    required this.activeGuestCodes,
    required this.activeStaffCodes,
  });

  final int arrivalsToday;
  final int departuresToday;
  final int inHouseStays;
  final int inHouseGuests;
  final int pendingRequests;
  final int urgentRequests;
  final int occupancyPercent;
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int outOfOrderRooms;
  final int revenueMonthCents;
  final int activeGuestCodes;
  final int activeStaffCodes;

  static AdminKpis fromJson(Map<String, dynamic> j) => AdminKpis(
        arrivalsToday: _i(j, 'arrivalsToday'),
        departuresToday: _i(j, 'departuresToday'),
        inHouseStays: _i(j, 'inHouseStays'),
        inHouseGuests: _i(j, 'inHouseGuests'),
        pendingRequests: _i(j, 'pendingRequests'),
        urgentRequests: _i(j, 'urgentRequests'),
        occupancyPercent: _i(j, 'occupancyPercent'),
        totalRooms: _i(j, 'totalRooms'),
        occupiedRooms: _i(j, 'occupiedRooms'),
        availableRooms: _i(j, 'availableRooms'),
        outOfOrderRooms: _i(j, 'outOfOrderRooms'),
        revenueMonthCents: _i(j, 'revenueMonthCents'),
        activeGuestCodes: _i(j, 'activeGuestCodes'),
        activeStaffCodes: _i(j, 'activeStaffCodes'),
      );
}

class AdminRecentBooking {
  const AdminRecentBooking({
    required this.id,
    required this.reference,
    required this.guestName,
    required this.roomTypeName,
    required this.grandTotalCents,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String guestName;
  final String roomTypeName;
  final int grandTotalCents;
  final String status;
  final String createdAt;

  static AdminRecentBooking fromJson(Map<String, dynamic> j) =>
      AdminRecentBooking(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        guestName: _s(j, 'guestName'),
        roomTypeName: _s(j, 'roomTypeName'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        status: _s(j, 'status'),
        createdAt: _s(j, 'createdAt'),
      );
}

class AdminAlerts {
  const AdminAlerts({
    required this.staleRequests,
    required this.outOfOrderRooms,
  });

  final int staleRequests;
  final int outOfOrderRooms;

  static AdminAlerts fromJson(Map<String, dynamic> j) => AdminAlerts(
        staleRequests: _i(j, 'staleRequests'),
        outOfOrderRooms: _i(j, 'outOfOrderRooms'),
      );
}

class RevenueDay {
  const RevenueDay({required this.date, required this.totalCents});

  final String date;
  final int totalCents;

  static RevenueDay fromJson(Map<String, dynamic> j) => RevenueDay(
        date: _s(j, 'date'),
        totalCents: _i(j, 'totalCents'),
      );
}

class AdminDashboard {
  const AdminDashboard({
    required this.kpis,
    required this.recentBookings,
    required this.roomsByStatus,
    required this.alerts,
    required this.revenueByDay,
  });

  final AdminKpis kpis;
  final List<AdminRecentBooking> recentBookings;
  final Map<String, int> roomsByStatus;
  final AdminAlerts alerts;
  final List<RevenueDay> revenueByDay;

  static AdminDashboard fromJson(Map<String, dynamic> j) => AdminDashboard(
        kpis: AdminKpis.fromJson(_m(j, 'kpis') ?? const {}),
        recentBookings: _ml(j, 'recentBookings')
            .map(AdminRecentBooking.fromJson)
            .toList(growable: false),
        roomsByStatus: _countMap(j, 'roomsByStatus'),
        alerts: AdminAlerts.fromJson(_m(j, 'alerts') ?? const {}),
        revenueByDay: _ml(j, 'revenueByDay')
            .map(RevenueDay.fromJson)
            .toList(growable: false),
      );
}

// ───────────── A-02/A-03 · إعدادات الفندق ─────────────

class HotelSettings {
  const HotelSettings({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.city,
    required this.currency,
    required this.checkInTime,
    required this.checkOutTime,
    required this.taxPercent,
    required this.weekendSurchargePercent,
    required this.minStayNights,
    required this.maxStayNights,
    required this.bookingHorizonDays,
    required this.cancellationPolicy,
    required this.paymentPolicy,
    required this.childrenPolicy,
    required this.petsPolicy,
    required this.smokingPolicy,
    required this.minAppVersion,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String city;
  final String currency;
  final String checkInTime;
  final String checkOutTime;
  final int taxPercent;
  final int weekendSurchargePercent;
  final int minStayNights;
  final int maxStayNights;
  final int bookingHorizonDays;
  final String cancellationPolicy;
  final String paymentPolicy;
  final String childrenPolicy;
  final String petsPolicy;
  final String smokingPolicy;
  final String minAppVersion;

  static HotelSettings fromJson(Map<String, dynamic> j) => HotelSettings(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        tagline: _s(j, 'tagline'),
        description: _s(j, 'description'),
        phone: _s(j, 'phone'),
        whatsapp: _s(j, 'whatsapp'),
        email: _s(j, 'email'),
        address: _s(j, 'address'),
        city: _s(j, 'city'),
        currency: _s(j, 'currency', 'USD'),
        checkInTime: _s(j, 'checkInTime'),
        checkOutTime: _s(j, 'checkOutTime'),
        taxPercent: _i(j, 'taxPercent'),
        weekendSurchargePercent: _i(j, 'weekendSurchargePercent'),
        minStayNights: _i(j, 'minStayNights'),
        maxStayNights: _i(j, 'maxStayNights'),
        bookingHorizonDays: _i(j, 'bookingHorizonDays'),
        cancellationPolicy: _s(j, 'cancellationPolicy'),
        paymentPolicy: _s(j, 'paymentPolicy'),
        childrenPolicy: _s(j, 'childrenPolicy'),
        petsPolicy: _s(j, 'petsPolicy'),
        smokingPolicy: _s(j, 'smokingPolicy'),
        minAppVersion: _s(j, 'minAppVersion'),
      );
}

// ───────────── A-04..A-07 · أنواع الغرف ─────────────

class AdminRoomType {
  const AdminRoomType({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.capacityAdults,
    required this.capacityChildren,
    required this.bedConfig,
    required this.sizeSqm,
    required this.basePriceCents,
    required this.amenities,
    required this.images,
    required this.active,
    required this.sortOrder,
    required this.roomsCount,
    required this.reservationsCount,
    required this.ratesCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String nameEn;
  final String description;
  final int capacityAdults;
  final int capacityChildren;
  final String bedConfig;
  final int sizeSqm;
  final int basePriceCents;
  final List<String> amenities;
  final List<String> images;
  final bool active;
  final int sortOrder;
  final int roomsCount;
  final int reservationsCount;
  final int ratesCount;
  final String createdAt;

  static AdminRoomType fromJson(Map<String, dynamic> j) => AdminRoomType(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        nameEn: _s(j, 'nameEn'),
        description: _s(j, 'description'),
        capacityAdults: _i(j, 'capacityAdults'),
        capacityChildren: _i(j, 'capacityChildren'),
        bedConfig: _s(j, 'bedConfig'),
        sizeSqm: _i(j, 'sizeSqm'),
        basePriceCents: _i(j, 'basePriceCents'),
        amenities: _sl(j['amenities']),
        images: _sl(j['images']),
        active: _b(j, 'active', true),
        sortOrder: _i(j, 'sortOrder'),
        roomsCount: _i(j, 'roomsCount'),
        reservationsCount: _i(j, 'reservationsCount'),
        ratesCount: _i(j, 'ratesCount'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── A-08..A-11 · الغرف ─────────────

class AdminRoom {
  const AdminRoom({
    required this.id,
    required this.number,
    required this.floor,
    required this.status,
    required this.notes,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.guestName,
    required this.expectedCheckOut,
    required this.createdAt,
  });

  final String id;
  final String number;
  final int floor;
  final String status;
  final String notes;
  final String roomTypeId;
  final String roomTypeName;
  final String? guestName;
  final String? expectedCheckOut;
  final String createdAt;

  static AdminRoom fromJson(Map<String, dynamic> j) => AdminRoom(
        id: _s(j, 'id'),
        number: _s(j, 'number'),
        floor: _i(j, 'floor'),
        status: _s(j, 'status'),
        notes: _s(j, 'notes'),
        roomTypeId: _s(j, 'roomTypeId'),
        roomTypeName: _s(j, 'roomTypeName'),
        guestName: _sn(j, 'guestName'),
        expectedCheckOut: _sn(j, 'expectedCheckOut'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── A-12..A-14 · المعدلات الموسمية ─────────────

class AdminRate {
  const AdminRate({
    required this.id,
    required this.name,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.roomTypeBasePriceCents,
    required this.startDate,
    required this.endDate,
    required this.priceCents,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String roomTypeId;
  final String roomTypeName;
  final int roomTypeBasePriceCents;
  final String startDate;
  final String endDate;
  final int priceCents;
  final bool active;
  final String createdAt;

  static AdminRate fromJson(Map<String, dynamic> j) => AdminRate(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        roomTypeId: _s(j, 'roomTypeId'),
        roomTypeName: _s(j, 'roomTypeName'),
        roomTypeBasePriceCents: _i(j, 'roomTypeBasePriceCents'),
        startDate: _s(j, 'startDate'),
        endDate: _s(j, 'endDate'),
        priceCents: _i(j, 'priceCents'),
        active: _b(j, 'active', true),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── A-15..A-18 · كتالوج الخدمات ─────────────

class AdminService {
  const AdminService({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.priceCents,
    required this.active,
    required this.sortOrder,
    required this.categoryId,
    required this.categoryName,
    required this.categoryKey,
  });

  final String id;
  final String name;
  final String nameEn;
  final String description;
  final int priceCents;
  final bool active;
  final int sortOrder;
  final String categoryId;
  final String categoryName;
  final String categoryKey;

  static AdminService fromJson(Map<String, dynamic> j) => AdminService(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        nameEn: _s(j, 'nameEn'),
        description: _s(j, 'description'),
        priceCents: _i(j, 'priceCents'),
        active: _b(j, 'active', true),
        sortOrder: _i(j, 'sortOrder'),
        categoryId: _s(j, 'categoryId'),
        categoryName: _s(j, 'categoryName'),
        categoryKey: _s(j, 'categoryKey'),
      );
}

// ───────────── A-19..A-22 · أقسام الخدمات ─────────────

class AdminServiceCategory {
  const AdminServiceCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.key,
    required this.icon,
    required this.sortOrder,
    required this.servicesCount,
  });

  final String id;
  final String name;
  final String nameEn;
  final String key;
  final String icon;
  final int sortOrder;
  final int servicesCount;

  static AdminServiceCategory fromJson(Map<String, dynamic> j) =>
      AdminServiceCategory(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        nameEn: _s(j, 'nameEn'),
        key: _s(j, 'key'),
        icon: _s(j, 'icon'),
        sortOrder: _i(j, 'sortOrder'),
        servicesCount: _i(j, 'servicesCount'),
      );
}

// ───────────── A-23..A-25 · الطاقم ─────────────

class StaffCodeSummary {
  const StaffCodeSummary({
    required this.codeMasked,
    required this.type,
    required this.status,
    required this.expiresAt,
  });

  final String codeMasked;
  final String type;
  final String status;
  final String expiresAt;

  static StaffCodeSummary fromJson(Map<String, dynamic> j) =>
      StaffCodeSummary(
        codeMasked: _s(j, 'codeMasked'),
        type: _s(j, 'type'),
        status: _s(j, 'status'),
        expiresAt: _s(j, 'expiresAt'),
      );
}

class AdminStaffMember {
  const AdminStaffMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.phone,
    required this.active,
    required this.createdAt,
    required this.lastCode,
  });

  final String id;
  final String fullName;
  final String role;
  final String phone;
  final bool active;
  final String createdAt;
  final StaffCodeSummary? lastCode;

  static AdminStaffMember fromJson(Map<String, dynamic> j) =>
      AdminStaffMember(
        id: _s(j, 'id'),
        fullName: _s(j, 'fullName'),
        role: _s(j, 'role'),
        phone: _s(j, 'phone'),
        active: _b(j, 'active', true),
        createdAt: _s(j, 'createdAt'),
        lastCode: _m(j, 'lastCode') != null
            ? StaffCodeSummary.fromJson(_m(j, 'lastCode')!)
            : null,
      );
}

// ───────────── A-26 · أكواد الوصول (قائمة) ─────────────

class AdminAccessCode {
  const AdminAccessCode({
    required this.id,
    required this.codeMasked,
    required this.type,
    required this.status,
    required this.expiresAt,
    required this.lastUsedAt,
    required this.createdAt,
    required this.staffName,
    required this.staffRole,
    required this.guestName,
    required this.roomNumber,
    required this.stayReference,
  });

  final String id;
  final String codeMasked;
  final String type;
  final String status;
  final String expiresAt;
  final String? lastUsedAt;
  final String createdAt;
  final String? staffName;
  final String? staffRole;
  final String? guestName;
  final String? roomNumber;
  final String? stayReference;

  static AdminAccessCode fromJson(Map<String, dynamic> j) =>
      AdminAccessCode(
        id: _s(j, 'id'),
        codeMasked: _s(j, 'codeMasked'),
        type: _s(j, 'type'),
        status: _s(j, 'status'),
        expiresAt: _s(j, 'expiresAt'),
        lastUsedAt: _sn(j, 'lastUsedAt'),
        createdAt: _s(j, 'createdAt'),
        staffName: _sn(j, 'staffName'),
        staffRole: _sn(j, 'staffRole'),
        guestName: _sn(j, 'guestName'),
        roomNumber: _sn(j, 'roomNumber'),
        stayReference: _sn(j, 'stayReference'),
      );
}

// ───────────── A-27 · توليد كود (الخام يُعاد مرة واحدة) ─────────────

class GeneratedCodeResult {
  const GeneratedCodeResult({
    required this.codeId,
    required this.code,
    required this.codeMasked,
    required this.expiresAt,
    required this.staffName,
    required this.days,
    required this.type,
  });

  final String codeId;
  final String code;
  final String codeMasked;
  final String expiresAt;
  final String staffName;
  final int days;
  final String type;

  static GeneratedCodeResult fromJson(Map<String, dynamic> j) =>
      GeneratedCodeResult(
        codeId: _s(j, 'codeId'),
        code: _s(j, 'code'),
        codeMasked: _s(j, 'codeMasked'),
        expiresAt: _s(j, 'expiresAt'),
        staffName: _s(j, 'staffName'),
        days: _i(j, 'days'),
        type: _s(j, 'type'),
      );
}

// ───────────── A-29 · قائمة الحجوزات (مُصفّحة) ─────────────

class AdminReservationItem {
  const AdminReservationItem({
    required this.id,
    required this.reference,
    required this.guestName,
    required this.guestPhone,
    required this.roomTypeName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.grandTotalCents,
    required this.paidCents,
    required this.paymentStatus,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.stayId,
  });

  final String id;
  final String reference;
  final String guestName;
  final String guestPhone;
  final String roomTypeName;
  final String checkIn;
  final String checkOut;
  final int nights;
  final int adults;
  final int children;
  final int grandTotalCents;
  final int paidCents;
  final String paymentStatus;
  final String status;
  final String source;
  final String createdAt;
  final String? stayId;

  static AdminReservationItem fromJson(Map<String, dynamic> j) =>
      AdminReservationItem(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
        roomTypeName: _s(j, 'roomTypeName'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
        nights: _i(j, 'nights'),
        adults: _i(j, 'adults'),
        children: _i(j, 'children'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        paidCents: _i(j, 'paidCents'),
        paymentStatus: _s(j, 'paymentStatus'),
        status: _s(j, 'status'),
        source: _s(j, 'source'),
        createdAt: _s(j, 'createdAt'),
        stayId: _sn(j, 'stayId'),
      );
}

class ReservationsPageData {
  const ReservationsPageData({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<AdminReservationItem> items;
  final int total;
  final int page;
  final int pages;

  static ReservationsPageData fromJson(Map<String, dynamic> j) =>
      ReservationsPageData(
        items: _ml(j, 'items')
            .map(AdminReservationItem.fromJson)
            .toList(growable: false),
        total: _i(j, 'total'),
        page: _i(j, 'page'),
        pages: _i(j, 'pages'),
      );
}

// ───────────── A-30 · تفاصيل حجز ─────────────

class AdminReservationDetail {
  const AdminReservationDetail({
    required this.id,
    required this.reference,
    required this.status,
    required this.source,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.roomsCount,
    required this.currency,
    required this.subtotalCents,
    required this.discountCents,
    required this.taxCents,
    required this.grandTotalCents,
    required this.paidCents,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.specialRequests,
    required this.createdAt,
    required this.confirmedAt,
    required this.cancelledAt,
    required this.guestName,
    required this.guestPhone,
    required this.guestEmail,
    required this.guestNationality,
    required this.roomTypeName,
    required this.roomTypeId,
    required this.roomTypeBasePriceCents,
    required this.payments,
    required this.stay,
    required this.priceSnapshot,
  });

  final String id;
  final String reference;
  final String status;
  final String source;
  final String checkIn;
  final String checkOut;
  final int nights;
  final int adults;
  final int children;
  final int roomsCount;
  final String currency;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int grandTotalCents;
  final int paidCents;
  final String paymentStatus;
  final String paymentMethod;
  final String specialRequests;
  final String createdAt;
  final String? confirmedAt;
  final String? cancelledAt;
  final String guestName;
  final String guestPhone;
  final String guestEmail;
  final String guestNationality;
  final String roomTypeId;
  final String roomTypeName;
  final int roomTypeBasePriceCents;
  final List<AdminPaymentItem> payments;
  final AdminStaySummary? stay;
  final Map<String, dynamic> priceSnapshot;

  static AdminReservationDetail fromJson(Map<String, dynamic> j) {
    final guest = _m(j, 'guest') ?? const {};
    final roomType = _m(j, 'roomType') ?? const {};
    return AdminReservationDetail(
      id: _s(j, 'id'),
      reference: _s(j, 'reference'),
      status: _s(j, 'status'),
      source: _s(j, 'source'),
      checkIn: _s(j, 'checkIn'),
      checkOut: _s(j, 'checkOut'),
      nights: _i(j, 'nights'),
      adults: _i(j, 'adults'),
      children: _i(j, 'children'),
      roomsCount: _i(j, 'roomsCount'),
      currency: _s(j, 'currency', 'USD'),
      subtotalCents: _i(j, 'subtotalCents'),
      discountCents: _i(j, 'discountCents'),
      taxCents: _i(j, 'taxCents'),
      grandTotalCents: _i(j, 'grandTotalCents'),
      paidCents: _i(j, 'paidCents'),
      paymentStatus: _s(j, 'paymentStatus'),
      paymentMethod: _s(j, 'paymentMethod'),
      specialRequests: _s(j, 'specialRequests'),
      createdAt: _s(j, 'createdAt'),
      confirmedAt: _sn(j, 'confirmedAt'),
      cancelledAt: _sn(j, 'cancelledAt'),
      guestName: _s(guest, 'fullName'),
      guestPhone: _s(guest, 'phone'),
      guestEmail: _s(guest, 'email'),
      guestNationality: _s(guest, 'nationality'),
      roomTypeId: _s(roomType, 'id'),
      roomTypeName: _s(roomType, 'name'),
      roomTypeBasePriceCents: _i(roomType, 'basePriceCents'),
      payments: _ml(j, 'payments')
          .map(AdminPaymentItem.fromJson)
          .toList(growable: false),
      stay: _m(j, 'stay') != null
          ? AdminStaySummary.fromJson(_m(j, 'stay')!)
          : null,
      priceSnapshot: _m(j, 'priceSnapshot') ?? const {},
    );
  }
}

class AdminPaymentItem {
  const AdminPaymentItem({
    required this.id,
    required this.method,
    required this.amountCents,
    required this.status,
    required this.reference,
    required this.note,
    required this.recordedBy,
    required this.createdAt,
  });

  final String id;
  final String method;
  final int amountCents;
  final String status;
  final String reference;
  final String note;
  final String recordedBy;
  final String createdAt;

  static AdminPaymentItem fromJson(Map<String, dynamic> j) =>
      AdminPaymentItem(
        id: _s(j, 'id'),
        method: _s(j, 'method'),
        amountCents: _i(j, 'amountCents'),
        status: _s(j, 'status'),
        reference: _s(j, 'reference'),
        note: _s(j, 'note'),
        recordedBy: _s(j, 'recordedBy'),
        createdAt: _s(j, 'createdAt'),
      );
}

class AdminStaySummary {
  const AdminStaySummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.checkInAt,
    required this.expectedCheckOutAt,
    required this.actualCheckOutAt,
    required this.roomNumber,
  });

  final String id;
  final String reference;
  final String status;
  final String checkInAt;
  final String expectedCheckOutAt;
  final String? actualCheckOutAt;
  final String roomNumber;

  static AdminStaySummary fromJson(Map<String, dynamic> j) =>
      AdminStaySummary(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        status: _s(j, 'status'),
        checkInAt: _s(j, 'checkInAt'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
        actualCheckOutAt: _sn(j, 'actualCheckOutAt'),
        roomNumber: _s(j, 'roomNumber'),
      );
}

// ───────────── A-31 · الضيوف ─────────────

class AdminGuest {
  const AdminGuest({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.nationality,
    required this.createdAt,
    required this.reservationsCount,
    required this.lastReservation,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String nationality;
  final String createdAt;
  final int reservationsCount;
  final GuestLastReservation? lastReservation;

  static AdminGuest fromJson(Map<String, dynamic> j) => AdminGuest(
        id: _s(j, 'id'),
        fullName: _s(j, 'fullName'),
        phone: _s(j, 'phone'),
        email: _s(j, 'email'),
        nationality: _s(j, 'nationality'),
        createdAt: _s(j, 'createdAt'),
        reservationsCount: _i(j, 'reservationsCount'),
        lastReservation: _m(j, 'lastReservation') != null
            ? GuestLastReservation.fromJson(_m(j, 'lastReservation')!)
            : null,
      );
}

class GuestLastReservation {
  const GuestLastReservation({
    required this.bookingReference,
    required this.checkIn,
    required this.status,
  });

  final String bookingReference;
  final String checkIn;
  final String status;

  static GuestLastReservation fromJson(Map<String, dynamic> j) =>
      GuestLastReservation(
        bookingReference: _s(j, 'bookingReference'),
        checkIn: _s(j, 'checkIn'),
        status: _s(j, 'status'),
      );
}

// ───────────── A-32 · سجل التدقيق (مُصفّح) ─────────────

class AuditLogItem {
  const AuditLogItem({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.actor,
    required this.actorRole,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String actor;
  final String actorRole;
  final Map<String, dynamic> details;
  final String createdAt;

  static AuditLogItem fromJson(Map<String, dynamic> j) => AuditLogItem(
        id: _s(j, 'id'),
        action: _s(j, 'action'),
        entityType: _s(j, 'entityType'),
        entityId: _s(j, 'entityId'),
        actor: _s(j, 'actor'),
        actorRole: _s(j, 'actorRole'),
        details: _m(j, 'details') ?? const {},
        createdAt: _s(j, 'createdAt'),
      );
}

class AuditPageData {
  const AuditPageData({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<AuditLogItem> items;
  final int total;
  final int page;
  final int pages;

  static AuditPageData fromJson(Map<String, dynamic> j) => AuditPageData(
        items: _ml(j, 'items')
            .map(AuditLogItem.fromJson)
            .toList(growable: false),
        total: _i(j, 'total'),
        page: _i(j, 'page'),
        pages: _i(j, 'pages'),
      );
}

// ───────────── A-33 · التقارير ─────────────

class OccupancyDay {
  const OccupancyDay({
    required this.date,
    required this.label,
    required this.percent,
    required this.occupied,
  });

  final String date;
  final String label;
  final int percent;
  final int occupied;

  static OccupancyDay fromJson(Map<String, dynamic> j) => OccupancyDay(
        date: _s(j, 'date'),
        label: _s(j, 'label'),
        percent: _i(j, 'percent'),
        occupied: _i(j, 'occupied'),
      );
}

class RevenueMonth {
  const RevenueMonth({
    required this.month,
    required this.totalCents,
    required this.count,
  });

  final String month;
  final int totalCents;
  final int count;

  static RevenueMonth fromJson(Map<String, dynamic> j) => RevenueMonth(
        month: _s(j, 'month'),
        totalCents: _i(j, 'totalCents'),
        count: _i(j, 'count'),
      );
}

class RequestStatusCount {
  const RequestStatusCount({required this.status, required this.count});

  final String status;
  final int count;

  static RequestStatusCount fromJson(Map<String, dynamic> j) =>
      RequestStatusCount(
        status: _s(j, 'status'),
        count: _i(j, 'count'),
      );
}

class TopServiceCount {
  const TopServiceCount({required this.title, required this.count});

  final String title;
  final int count;

  static TopServiceCount fromJson(Map<String, dynamic> j) =>
      TopServiceCount(
        title: _s(j, 'title'),
        count: _i(j, 'count'),
      );
}

class RequestsStats {
  const RequestsStats({
    required this.total,
    required this.byStatus,
    required this.completed,
    required this.active,
    required this.avgCompletionMinutes,
    required this.topServices,
  });

  final int total;
  final List<RequestStatusCount> byStatus;
  final int completed;
  final int active;
  final int? avgCompletionMinutes;
  final List<TopServiceCount> topServices;

  static RequestsStats fromJson(Map<String, dynamic> j) => RequestsStats(
        total: _i(j, 'total'),
        byStatus: _ml(j, 'byStatus')
            .map(RequestStatusCount.fromJson)
            .toList(growable: false),
        completed: _i(j, 'completed'),
        active: _i(j, 'active'),
        avgCompletionMinutes: _in(j, 'avgCompletionMinutes'),
        topServices: _ml(j, 'topServices')
            .map(TopServiceCount.fromJson)
            .toList(growable: false),
      );
}

class NationalityCount {
  const NationalityCount({
    required this.nationality,
    required this.count,
  });

  final String nationality;
  final int count;

  static NationalityCount fromJson(Map<String, dynamic> j) =>
      NationalityCount(
        nationality: _s(j, 'nationality'),
        count: _i(j, 'count'),
      );
}

class AdminReports {
  const AdminReports({
    required this.effectiveRooms,
    required this.occupancyLast14Days,
    required this.revenueByMonth,
    required this.requestsStats,
    required this.guestsByNationality,
  });

  final int effectiveRooms;
  final List<OccupancyDay> occupancyLast14Days;
  final List<RevenueMonth> revenueByMonth;
  final RequestsStats requestsStats;
  final List<NationalityCount> guestsByNationality;

  static AdminReports fromJson(Map<String, dynamic> j) => AdminReports(
        effectiveRooms: _i(j, 'effectiveRooms'),
        occupancyLast14Days: _ml(j, 'occupancyLast14Days')
            .map(OccupancyDay.fromJson)
            .toList(growable: false),
        revenueByMonth: _ml(j, 'revenueByMonth')
            .map(RevenueMonth.fromJson)
            .toList(growable: false),
        requestsStats:
            RequestsStats.fromJson(_m(j, 'requestsStats') ?? const {}),
        guestsByNationality: _ml(j, 'guestsByNationality')
            .map(NationalityCount.fromJson)
            .toList(growable: false),
      );
}

// ───────────── A-34 · إشعارات الإدارة ─────────────

class AdminNotificationItem {
  const AdminNotificationItem({
    required this.id,
    required this.audience,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String audience;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  static AdminNotificationItem fromJson(Map<String, dynamic> j) =>
      AdminNotificationItem(
        id: _s(j, 'id'),
        audience: _s(j, 'audience'),
        type: _s(j, 'type'),
        title: _s(j, 'title'),
        body: _s(j, 'body'),
        read: _b(j, 'read'),
        createdAt: _s(j, 'createdAt'),
      );
}

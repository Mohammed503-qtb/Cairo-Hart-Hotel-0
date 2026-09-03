// ─────────────────────────────────────────────────────────────
// RECEPTION MODELS — نماذج قناة الاستقبال (مطابقة لعقود
// CONTRACTS.md R-01..R-10 · R-22/R-23 · R-05 · R-06 · R-07)
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

bool _b(Map<String, dynamic> j, String k, [bool def = false]) =>
    j[k] is bool ? j[k] as bool : def;

Map<String, dynamic>? _m(Map<String, dynamic> j, String k) =>
    j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : null;

List<Map<String, dynamic>> _ml(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<Map<String, dynamic>>().toList();
}

// ───────────── R-01 · لوحة التحكم ─────────────

class ReceptionStats {
  const ReceptionStats({
    required this.arrivalsToday,
    required this.departuresToday,
    required this.inHouseStays,
    required this.pendingRequests,
    required this.urgentRequests,
    required this.occupancyPercent,
    required this.totalRooms,
    required this.occupiedRooms,
  });

  final int arrivalsToday;
  final int departuresToday;
  final int inHouseStays;
  final int pendingRequests;
  final int urgentRequests;
  final int occupancyPercent;
  final int totalRooms;
  final int occupiedRooms;

  static ReceptionStats fromJson(Map<String, dynamic> j) => ReceptionStats(
        arrivalsToday: _i(j, 'arrivalsToday'),
        departuresToday: _i(j, 'departuresToday'),
        inHouseStays: _i(j, 'inHouseStays'),
        pendingRequests: _i(j, 'pendingRequests'),
        urgentRequests: _i(j, 'urgentRequests'),
        occupancyPercent: _i(j, 'occupancyPercent'),
        totalRooms: _i(j, 'totalRooms'),
        occupiedRooms: _i(j, 'occupiedRooms'),
      );
}

class DashboardArrival {
  const DashboardArrival({
    required this.reservationId,
    required this.bookingReference,
    required this.guestName,
    required this.guestPhone,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.nights,
    required this.paidCents,
    required this.grandTotalCents,
    required this.paymentStatus,
    required this.checkIn,
    required this.checkOut,
  });

  final String reservationId;
  final String bookingReference;
  final String guestName;
  final String guestPhone;
  final String roomTypeId;
  final String roomTypeName;
  final int nights;
  final int paidCents;
  final int grandTotalCents;
  final String paymentStatus;
  final String checkIn;
  final String checkOut;

  static DashboardArrival fromJson(Map<String, dynamic> j) => DashboardArrival(
        reservationId: _s(j, 'reservationId'),
        bookingReference: _s(j, 'bookingReference'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
        roomTypeId: _s(j, 'roomTypeId'),
        roomTypeName: _s(j, 'roomTypeName'),
        nights: _i(j, 'nights'),
        paidCents: _i(j, 'paidCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        paymentStatus: _s(j, 'paymentStatus'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
      );
}

class DashboardDeparture {
  const DashboardDeparture({
    required this.stayId,
    required this.reference,
    required this.guestName,
    required this.roomNumber,
    required this.balanceCents,
    required this.status,
    required this.expectedCheckOutAt,
  });

  final String stayId;
  final String reference;
  final String guestName;
  final String roomNumber;
  final int balanceCents;
  final String status;
  final String expectedCheckOutAt;

  static DashboardDeparture fromJson(Map<String, dynamic> j) =>
      DashboardDeparture(
        stayId: _s(j, 'stayId'),
        reference: _s(j, 'reference'),
        guestName: _s(j, 'guestName'),
        roomNumber: _s(j, 'roomNumber'),
        balanceCents: _i(j, 'balanceCents'),
        status: _s(j, 'status'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
      );
}

class DashboardRequest {
  const DashboardRequest({
    required this.id,
    required this.reference,
    required this.roomNumber,
    required this.guestName,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String roomNumber;
  final String guestName;
  final String title;
  final String priority;
  final String status;
  final String createdAt;

  static DashboardRequest fromJson(Map<String, dynamic> j) =>
      DashboardRequest(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        roomNumber: _s(j, 'roomNumber'),
        guestName: _s(j, 'guestName'),
        title: _s(j, 'title'),
        priority: _s(j, 'priority'),
        status: _s(j, 'status'),
        createdAt: _s(j, 'createdAt'),
      );
}

class ReceptionDashboard {
  const ReceptionDashboard({
    required this.stats,
    required this.arrivals,
    required this.departures,
    required this.pendingRequests,
  });

  final ReceptionStats stats;
  final List<DashboardArrival> arrivals;
  final List<DashboardDeparture> departures;
  final List<DashboardRequest> pendingRequests;

  static ReceptionDashboard fromJson(Map<String, dynamic> j) =>
      ReceptionDashboard(
        stats: ReceptionStats.fromJson(
            _m(j, 'stats') ?? const <String, dynamic>{}),
        arrivals: _ml(j, 'arrivals')
            .map(DashboardArrival.fromJson)
            .toList(growable: false),
        departures: _ml(j, 'departures')
            .map(DashboardDeparture.fromJson)
            .toList(growable: false),
        pendingRequests: _ml(j, 'pendingRequests')
            .map(DashboardRequest.fromJson)
            .toList(growable: false),
      );
}

// ───────────── R-02 · الوصولون ─────────────

class ArrivalGuestInfo {
  const ArrivalGuestInfo({
    required this.id,
    required this.fullName,
    required this.phone,
    this.whatsapp,
    this.email,
    this.idNumber,
    this.nationality,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? idNumber;
  final String? nationality;

  static ArrivalGuestInfo fromJson(Map<String, dynamic> j) =>
      ArrivalGuestInfo(
        id: _s(j, 'id'),
        fullName: _s(j, 'fullName'),
        phone: _s(j, 'phone'),
        whatsapp: _sn(j, 'whatsapp'),
        email: _sn(j, 'email'),
        idNumber: _sn(j, 'idNumber'),
        nationality: _sn(j, 'nationality'),
      );
}

class ArrivalRoomType {
  const ArrivalRoomType({
    required this.id,
    required this.name,
    required this.basePriceCents,
    required this.capacityAdults,
    required this.capacityChildren,
    required this.bedConfig,
    required this.sizeSqm,
  });

  final String id;
  final String name;
  final int basePriceCents;
  final int capacityAdults;
  final int capacityChildren;
  final String bedConfig;
  final int sizeSqm;

  static ArrivalRoomType fromJson(Map<String, dynamic> j) => ArrivalRoomType(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        basePriceCents: _i(j, 'basePriceCents'),
        capacityAdults: _i(j, 'capacityAdults'),
        capacityChildren: _i(j, 'capacityChildren'),
        bedConfig: _s(j, 'bedConfig'),
        sizeSqm: _i(j, 'sizeSqm'),
      );
}

class ArrivalItem {
  const ArrivalItem({
    required this.id,
    required this.bookingReference,
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
    required this.taxCents,
    required this.grandTotalCents,
    required this.paidCents,
    required this.paymentStatus,
    required this.createdAt,
    required this.hasStay,
    required this.guest,
    required this.roomType,
    this.paymentMethod,
    this.specialRequests,
  });

  final String id;
  final String bookingReference;
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
  final int taxCents;
  final int grandTotalCents;
  final int paidCents;
  final String paymentStatus;
  final String createdAt;
  final bool hasStay;
  final ArrivalGuestInfo guest;
  final ArrivalRoomType roomType;
  final String? paymentMethod;
  final String? specialRequests;

  int get remainingCents => grandTotalCents - paidCents;

  static ArrivalItem fromJson(Map<String, dynamic> j) => ArrivalItem(
        id: _s(j, 'id'),
        bookingReference: _s(j, 'bookingReference'),
        status: _s(j, 'status'),
        source: _s(j, 'source'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
        nights: _i(j, 'nights'),
        adults: _i(j, 'adults'),
        children: _i(j, 'children'),
        roomsCount: _i(j, 'roomsCount'),
        currency: _s(j, 'currency'),
        subtotalCents: _i(j, 'subtotalCents'),
        taxCents: _i(j, 'taxCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        paidCents: _i(j, 'paidCents'),
        paymentStatus: _s(j, 'paymentStatus'),
        createdAt: _s(j, 'createdAt'),
        hasStay: _b(j, 'hasStay'),
        guest: ArrivalGuestInfo.fromJson(
            _m(j, 'guest') ?? const <String, dynamic>{}),
        roomType: ArrivalRoomType.fromJson(
            _m(j, 'roomType') ?? const <String, dynamic>{}),
        paymentMethod: _sn(j, 'paymentMethod'),
        specialRequests: _sn(j, 'specialRequests'),
      );
}

// ───────────── R-03 · المغادرون ─────────────

class DepartureItem {
  const DepartureItem({
    required this.id,
    required this.reference,
    required this.status,
    required this.guestName,
    required this.guestPhone,
    required this.roomNumber,
    required this.roomTypeName,
    required this.checkInAt,
    required this.expectedCheckOutAt,
    required this.balanceCents,
    required this.activeRequests,
    required this.overdue,
  });

  final String id;
  final String reference;
  final String status;
  final String guestName;
  final String guestPhone;
  final String roomNumber;
  final String roomTypeName;
  final String checkInAt;
  final String expectedCheckOutAt;
  final int balanceCents;
  final int activeRequests;
  final bool overdue;

  static DepartureItem fromJson(Map<String, dynamic> j) => DepartureItem(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        status: _s(j, 'status'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
        roomNumber: _s(j, 'roomNumber'),
        roomTypeName: _s(j, 'roomTypeName'),
        checkInAt: _s(j, 'checkInAt'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
        balanceCents: _i(j, 'balanceCents'),
        activeRequests: _i(j, 'activeRequests'),
        overdue: _b(j, 'overdue'),
      );
}

// ───────────── R-04 · المقيمون (نموذج F4-b) ─────────────

class InHouseStay {
  const InHouseStay({
    required this.id,
    required this.reference,
    required this.status,
    required this.checkInAt,
    required this.expectedCheckOutAt,
    required this.guestName,
    required this.guestPhone,
    required this.roomNumber,
    required this.roomFloor,
    required this.roomTypeName,
    required this.activeRequests,
    required this.balanceCents,
    required this.reservationTotalCents,
    required this.reservationPaidCents,
    required this.reservationPaymentStatus,
  });

  final String id;
  final String reference;
  final String status;
  final String checkInAt;
  final String expectedCheckOutAt;
  final String guestName;
  final String guestPhone;
  final String roomNumber;
  final int roomFloor;
  final String roomTypeName;
  final int activeRequests;
  final int balanceCents;
  final int reservationTotalCents;
  final int reservationPaidCents;
  final String reservationPaymentStatus;

  static InHouseStay fromJson(Map<String, dynamic> j) => InHouseStay(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        status: _s(j, 'status'),
        checkInAt: _s(j, 'checkInAt'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
        guestName: _s(_m(j, 'guest') ?? const <String, dynamic>{}, 'fullName'),
        guestPhone: _s(_m(j, 'guest') ?? const <String, dynamic>{}, 'phone'),
        roomNumber: _s(_m(j, 'room') ?? const <String, dynamic>{}, 'number'),
        roomFloor: _i(_m(j, 'room') ?? const <String, dynamic>{}, 'floor'),
        roomTypeName:
            _s(_m(j, 'roomType') ?? const <String, dynamic>{}, 'name'),
        activeRequests: _i(j, 'activeRequests'),
        balanceCents: _i(j, 'balanceCents'),
        reservationTotalCents:
            _i(_m(j, 'reservation') ?? const <String, dynamic>{},
                'grandTotalCents'),
        reservationPaidCents:
            _i(_m(j, 'reservation') ?? const <String, dynamic>{}, 'paidCents'),
        reservationPaymentStatus: _s(
            _m(j, 'reservation') ?? const <String, dynamic>{},
            'paymentStatus'),
      );
}

// ───────────── R-10 · الغرف ─────────────

class RoomItem {
  const RoomItem({
    required this.id,
    required this.number,
    required this.floor,
    required this.status,
    required this.roomTypeId,
    required this.roomTypeName,
    this.notes,
    this.guestName,
    this.expectedCheckOutAt,
    this.activeStayId,
  });

  final String id;
  final String number;
  final int floor;
  final String status;
  final String roomTypeId;
  final String roomTypeName;
  final String? notes;
  final String? guestName;
  final String? expectedCheckOutAt;
  final String? activeStayId;

  bool get isAvailable => status == 'AVAILABLE';

  static RoomItem fromJson(Map<String, dynamic> j) => RoomItem(
        id: _s(j, 'id'),
        number: _s(j, 'number'),
        floor: _i(j, 'floor'),
        status: _s(j, 'status'),
        roomTypeId: _s(j, 'roomTypeId'),
        roomTypeName: _s(j, 'roomTypeName'),
        notes: _sn(j, 'notes'),
        guestName: _sn(j, 'guestName'),
        expectedCheckOutAt: _sn(j, 'expectedCheckOutAt'),
        activeStayId: _sn(j, 'activeStayId'),
      );
}

// ───────────── الفاتورة (BillPublic داخل R-05) ─────────────

class BillLine {
  const BillLine({
    required this.description,
    required this.amountCents,
    this.category,
    this.date,
  });

  final String description;
  final int amountCents;
  final String? category;
  final String? date;

  static BillLine fromJson(Map<String, dynamic> j) => BillLine(
        description: _s(j, 'description'),
        amountCents: _i(j, 'amountCents'),
        category: _sn(j, 'category'),
        date: _sn(j, 'date'),
      );
}

class BillPaymentEntry {
  const BillPaymentEntry({
    required this.id,
    required this.method,
    required this.amountCents,
    required this.createdAt,
    this.recordedBy,
  });

  final String id;
  final String method;
  final int amountCents;
  final String createdAt;
  final String? recordedBy;

  static BillPaymentEntry fromJson(Map<String, dynamic> j) =>
      BillPaymentEntry(
        id: _s(j, 'id'),
        method: _s(j, 'method'),
        amountCents: _i(j, 'amountCents'),
        createdAt: _s(j, 'createdAt'),
        recordedBy: _sn(j, 'recordedBy'),
      );
}

class ReceptionBill {
  const ReceptionBill({
    required this.stayId,
    required this.stayReference,
    required this.roomTotalCents,
    required this.roomSubtotalCents,
    required this.roomTaxCents,
    required this.extraCharges,
    required this.extraTotalCents,
    required this.payments,
    required this.totalChargesCents,
    required this.totalPaidCents,
    required this.balanceCents,
    required this.currency,
  });

  final String stayId;
  final String stayReference;
  final int roomTotalCents;
  final int roomSubtotalCents;
  final int roomTaxCents;
  final List<BillLine> extraCharges;
  final int extraTotalCents;
  final List<BillPaymentEntry> payments;
  final int totalChargesCents;
  final int totalPaidCents;
  final int balanceCents;
  final String currency;

  static ReceptionBill fromJson(Map<String, dynamic> j) => ReceptionBill(
        stayId: _s(j, 'stayId'),
        stayReference: _s(j, 'stayReference'),
        roomTotalCents: _i(j, 'roomTotalCents'),
        roomSubtotalCents: _i(j, 'roomSubtotalCents'),
        roomTaxCents: _i(j, 'roomTaxCents'),
        extraCharges: _ml(j, 'extraCharges')
            .map(BillLine.fromJson)
            .toList(growable: false),
        extraTotalCents: _i(j, 'extraTotalCents'),
        payments: _ml(j, 'payments')
            .map(BillPaymentEntry.fromJson)
            .toList(growable: false),
        totalChargesCents: _i(j, 'totalChargesCents'),
        totalPaidCents: _i(j, 'totalPaidCents'),
        balanceCents: _i(j, 'balanceCents'),
        currency: _s(j, 'currency'),
      );
}

// ───────────── الطلبات وقرارات التمديد/تغيير الغرفة (داخل R-05) ─────────────

class RequestUpdateEntry {
  const RequestUpdateEntry({
    required this.id,
    required this.byName,
    required this.byRole,
    required this.createdAt,
    this.status,
    this.note,
  });

  final String id;
  final String? status;
  final String? note;
  final String byName;
  final String byRole;
  final String createdAt;

  static RequestUpdateEntry fromJson(Map<String, dynamic> j) =>
      RequestUpdateEntry(
        id: _s(j, 'id'),
        status: _sn(j, 'status'),
        note: _sn(j, 'note'),
        byName: _s(j, 'byName'),
        byRole: _s(j, 'byRole'),
        createdAt: _s(j, 'createdAt'),
      );
}

class ReceptionRequestItem {
  const ReceptionRequestItem({
    required this.id,
    required this.reference,
    required this.category,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.stayId,
    required this.stayReference,
    required this.stayRoomNumber,
    required this.stayGuestName,
    required this.updates,
    this.description,
    this.assignedTo,
    this.completedAt,
  });

  final String id;
  final String reference;
  final String category;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? assignedTo;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String stayId;
  final String stayReference;
  final String stayRoomNumber;
  final String stayGuestName;
  final List<RequestUpdateEntry> updates;

  static ReceptionRequestItem fromJson(Map<String, dynamic> j) {
    final stay = _m(j, 'stay') ?? const <String, dynamic>{};
    return ReceptionRequestItem(
      id: _s(j, 'id'),
      reference: _s(j, 'reference'),
      category: _s(j, 'category'),
      title: _s(j, 'title'),
      description: _sn(j, 'description'),
      priority: _s(j, 'priority'),
      status: _s(j, 'status'),
      assignedTo: _sn(j, 'assignedTo'),
      createdAt: _s(j, 'createdAt'),
      updatedAt: _s(j, 'updatedAt'),
      completedAt: _sn(j, 'completedAt'),
      stayId: _s(stay, 'id'),
      stayReference: _s(stay, 'reference'),
      stayRoomNumber: _s(stay, 'roomNumber'),
      stayGuestName: _s(stay, 'guestName'),
      updates: _ml(j, 'updates')
          .map(RequestUpdateEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class ExtensionRequestItem {
  const ExtensionRequestItem({
    required this.id,
    required this.newCheckOut,
    required this.nights,
    required this.priceCents,
    required this.status,
    required this.createdAt,
    this.note,
    this.decidedBy,
    this.decidedAt,
  });

  final String id;
  final String newCheckOut;
  final int nights;
  final int priceCents;
  final String? note;
  final String status;
  final String? decidedBy;
  final String? decidedAt;
  final String createdAt;

  static ExtensionRequestItem fromJson(Map<String, dynamic> j) =>
      ExtensionRequestItem(
        id: _s(j, 'id'),
        newCheckOut: _s(j, 'newCheckOut'),
        nights: _i(j, 'nights'),
        priceCents: _i(j, 'priceCents'),
        note: _sn(j, 'note'),
        status: _s(j, 'status'),
        decidedBy: _sn(j, 'decidedBy'),
        decidedAt: _sn(j, 'decidedAt'),
        createdAt: _s(j, 'createdAt'),
      );
}

class RoomChangeRequestItem {
  const RoomChangeRequestItem({
    required this.id,
    required this.toRoomId,
    required this.toRoomNumber,
    required this.priceDiffCents,
    required this.status,
    required this.createdAt,
    this.reason,
    this.decidedBy,
    this.decidedAt,
  });

  final String id;
  final String toRoomId;
  final String toRoomNumber;
  final int priceDiffCents;
  final String? reason;
  final String status;
  final String? decidedBy;
  final String? decidedAt;
  final String createdAt;

  static RoomChangeRequestItem fromJson(Map<String, dynamic> j) =>
      RoomChangeRequestItem(
        id: _s(j, 'id'),
        toRoomId: _s(j, 'toRoomId'),
        toRoomNumber: _s(j, 'toRoomNumber'),
        priceDiffCents: _i(j, 'priceDiffCents'),
        reason: _sn(j, 'reason'),
        status: _s(j, 'status'),
        decidedBy: _sn(j, 'decidedBy'),
        decidedAt: _sn(j, 'decidedAt'),
        createdAt: _s(j, 'createdAt'),
      );
}

class StayMessage {
  const StayMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String senderName;
  final String body;
  final String createdAt;

  static StayMessage fromJson(Map<String, dynamic> j) => StayMessage(
        id: _s(j, 'id'),
        sender: _s(j, 'sender'),
        senderName: _s(j, 'senderName'),
        body: _s(j, 'body'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── R-05 · تفصيل الإقامة ─────────────

class StayDetailData {
  const StayDetailData({
    required this.id,
    required this.reference,
    required this.status,
    required this.checkInAt,
    required this.expectedCheckOutAt,
    required this.guest,
    required this.room,
    required this.roomType,
    required this.bill,
    required this.requests,
    required this.extensionRequests,
    required this.roomChangeRequests,
    required this.messages,
    required this.reservation,
    this.actualCheckOutAt,
  });

  final String id;
  final String reference;
  final String status;
  final String checkInAt;
  final String expectedCheckOutAt;
  final String? actualCheckOutAt;
  final ArrivalGuestInfo guest;

  /// رقم الغرفة (معرّفها والطابق والحالة والملاحظات)
  final StayRoomInfo room;
  final StayRoomTypeInfo roomType;
  final StayReservationInfo reservation;
  final ReceptionBill bill;
  final List<ReceptionRequestItem> requests;
  final List<ExtensionRequestItem> extensionRequests;
  final List<RoomChangeRequestItem> roomChangeRequests;
  final List<StayMessage> messages;

  static StayDetailData fromJson(Map<String, dynamic> j) => StayDetailData(
        id: _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'id'),
        reference: _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'reference'),
        status: _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'status'),
        checkInAt: _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'checkInAt'),
        expectedCheckOutAt:
            _s(_m(j, 'stay') ?? const <String, dynamic>{},
                'expectedCheckOutAt'),
        actualCheckOutAt:
            _sn(_m(j, 'stay') ?? const <String, dynamic>{}, 'actualCheckOutAt'),
        guest: ArrivalGuestInfo.fromJson(
            _m(j, 'guest') ?? const <String, dynamic>{}),
        room: StayRoomInfo.fromJson(
            _m(j, 'room') ?? const <String, dynamic>{}),
        roomType: StayRoomTypeInfo.fromJson(
            _m(j, 'roomType') ?? const <String, dynamic>{}),
        reservation: StayReservationInfo.fromJson(
            _m(j, 'reservation') ?? const <String, dynamic>{}),
        bill: ReceptionBill.fromJson(
            _m(j, 'bill') ?? const <String, dynamic>{}),
        requests: _ml(j, 'requests')
            .map(ReceptionRequestItem.fromJson)
            .toList(growable: false),
        extensionRequests: _ml(j, 'extensionRequests')
            .map(ExtensionRequestItem.fromJson)
            .toList(growable: false),
        roomChangeRequests: _ml(j, 'roomChangeRequests')
            .map(RoomChangeRequestItem.fromJson)
            .toList(growable: false),
        messages: _ml(j, 'messages')
            .map(StayMessage.fromJson)
            .toList(growable: false),
      );
}

class StayRoomInfo {
  const StayRoomInfo({
    required this.id,
    required this.number,
    required this.floor,
    required this.status,
    this.notes,
  });

  final String id;
  final String number;
  final int floor;
  final String status;
  final String? notes;

  static StayRoomInfo fromJson(Map<String, dynamic> j) => StayRoomInfo(
        id: _s(j, 'id'),
        number: _s(j, 'number'),
        floor: _i(j, 'floor'),
        status: _s(j, 'status'),
        notes: _sn(j, 'notes'),
      );
}

class StayRoomTypeInfo {
  const StayRoomTypeInfo({
    required this.id,
    required this.name,
    required this.bedConfig,
    required this.sizeSqm,
  });

  final String id;
  final String name;
  final String bedConfig;
  final int sizeSqm;

  static StayRoomTypeInfo fromJson(Map<String, dynamic> j) =>
      StayRoomTypeInfo(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        bedConfig: _s(j, 'bedConfig'),
        sizeSqm: _i(j, 'sizeSqm'),
      );
}

/// الحجز داخل تفصيل الإقامة (لقطة السعر الخام للعرض في F4-b)
class StayReservationInfo {
  const StayReservationInfo({
    required this.id,
    required this.bookingReference,
    required this.status,
    required this.source,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.roomsCount,
    required this.currency,
    required this.subtotalCents,
    required this.taxCents,
    required this.grandTotalCents,
    required this.paidCents,
    required this.paymentStatus,
    required this.priceSnapshot,
    this.paymentMethod,
    this.specialRequests,
  });

  final String id;
  final String bookingReference;
  final String status;
  final String source;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int roomsCount;
  final String currency;
  final int subtotalCents;
  final int taxCents;
  final int grandTotalCents;
  final int paidCents;
  final String paymentStatus;
  final String? paymentMethod;
  final String? specialRequests;
  final Map<String, dynamic>? priceSnapshot;

  static StayReservationInfo fromJson(Map<String, dynamic> j) =>
      StayReservationInfo(
        id: _s(j, 'id'),
        bookingReference: _s(j, 'bookingReference'),
        status: _s(j, 'status'),
        source: _s(j, 'source'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
        adults: _i(j, 'adults'),
        children: _i(j, 'children'),
        roomsCount: _i(j, 'roomsCount'),
        currency: _s(j, 'currency'),
        subtotalCents: _i(j, 'subtotalCents'),
        taxCents: _i(j, 'taxCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        paidCents: _i(j, 'paidCents'),
        paymentStatus: _s(j, 'paymentStatus'),
        paymentMethod: _sn(j, 'paymentMethod'),
        specialRequests: _sn(j, 'specialRequests'),
        priceSnapshot: _m(j, 'priceSnapshot'),
      );
}

// ───────────── R-06 · نتيجة تسجيل الوصول ─────────────

class CheckInResult {
  const CheckInResult({
    required this.stayId,
    required this.stayReference,
    required this.roomNumber,
    required this.guestCode,
    required this.guestName,
    required this.guestPhone,
  });

  final String stayId;
  final String stayReference;
  final String roomNumber;

  /// كود الضيف الخام — يُعاد مرة واحدة فقط ولا يُخزَّن أبدًا (عقد R-06)
  final String guestCode;
  final String guestName;
  final String guestPhone;

  static CheckInResult fromJson(Map<String, dynamic> j) => CheckInResult(
        stayId: _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'id'),
        stayReference:
            _s(_m(j, 'stay') ?? const <String, dynamic>{}, 'reference'),
        roomNumber: _s(j, 'roomNumber'),
        guestCode: _s(j, 'guestCode'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
      );
}

// ───────────── R-07 · نتيجة تسجيل الخروج ─────────────

class CheckOutResult {
  const CheckOutResult({
    required this.closed,
    required this.roomNumber,
    required this.balanceCents,
  });

  final bool closed;
  final String roomNumber;
  final int balanceCents;

  static CheckOutResult fromJson(Map<String, dynamic> j) => CheckOutResult(
        closed: _b(j, 'closed'),
        roomNumber: _s(j, 'roomNumber'),
        balanceCents: _i(j, 'balanceCents'),
      );
}

// ───────────── R-22 · إشعارات الاستقبال ─────────────

class ReceptionNotification {
  const ReceptionNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  static ReceptionNotification fromJson(Map<String, dynamic> j) =>
      ReceptionNotification(
        id: _s(j, 'id'),
        type: _s(j, 'type'),
        title: _s(j, 'title'),
        body: _s(j, 'body'),
        read: _b(j, 'read'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── R-19 · البحث العام ─────────────

/// نتيجة حجز في البحث (R-19) — stayId=null يعني لم يُسجَّل وصوله بعد
class SearchReservationItem {
  const SearchReservationItem({
    required this.id,
    required this.bookingReference,
    required this.guestName,
    required this.guestPhone,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.roomTypeName,
    required this.paymentStatus,
    this.stayId,
  });

  final String id;
  final String bookingReference;
  final String guestName;
  final String guestPhone;
  final String status;
  final String checkIn;
  final String checkOut;
  final String roomTypeName;
  final String paymentStatus;
  final String? stayId;

  static SearchReservationItem fromJson(Map<String, dynamic> j) =>
      SearchReservationItem(
        id: _s(j, 'id'),
        bookingReference: _s(j, 'bookingReference'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
        status: _s(j, 'status'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
        roomTypeName: _s(j, 'roomTypeName'),
        paymentStatus: _s(j, 'paymentStatus'),
        stayId: _sn(j, 'stayId'),
      );
}

/// نتيجة إقامة نشطة في البحث (R-19)
class SearchStayItem {
  const SearchStayItem({
    required this.id,
    required this.reference,
    required this.guestName,
    required this.guestPhone,
    required this.roomNumber,
    required this.roomTypeName,
    required this.status,
    required this.expectedCheckOutAt,
  });

  final String id;
  final String reference;
  final String guestName;
  final String guestPhone;
  final String roomNumber;
  final String roomTypeName;
  final String status;
  final String expectedCheckOutAt;

  static SearchStayItem fromJson(Map<String, dynamic> j) => SearchStayItem(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        guestName: _s(j, 'guestName'),
        guestPhone: _s(j, 'guestPhone'),
        roomNumber: _s(j, 'roomNumber'),
        roomTypeName: _s(j, 'roomTypeName'),
        status: _s(j, 'status'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
      );
}

/// نتيجات البحث العام (R-19): {reservations, stays}
class SearchResults {
  const SearchResults({
    required this.reservations,
    required this.stays,
  });

  final List<SearchReservationItem> reservations;
  final List<SearchStayItem> stays;

  static SearchResults fromJson(Map<String, dynamic> j) => SearchResults(
        reservations: _ml(j, 'reservations')
            .map(SearchReservationItem.fromJson)
            .toList(growable: false),
        stays: _ml(j, 'stays')
            .map(SearchStayItem.fromJson)
            .toList(growable: false),
      );
}

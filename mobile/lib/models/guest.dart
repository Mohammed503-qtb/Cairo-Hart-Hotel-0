// ─────────────────────────────────────────────────────────────
// MODELS — نماذج قناة الضيف (مطابقة لأشكال CONTRACTS.md §1.6 + §4)
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

// ───────────── المصادقة (AUTH-01) ─────────────

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.name,
    required this.expiresAt,
  });

  final String token;
  final String role; // GUEST | RECEPTION | ADMIN
  final String name;
  final String expiresAt;

  bool get isGuest => role == 'GUEST';

  static AuthSession fromJson(Map<String, dynamic> j) => AuthSession(
        token: _s(j, 'token'),
        role: _s(j, 'role'),
        name: _s(j, 'name'),
        expiresAt: _s(j, 'expiresAt'),
      );
}

// ───────────── ملخص الفندق (G-01/G-02) ─────────────

class HotelBrief {
  const HotelBrief({
    required this.name,
    this.phone,
    this.whatsapp,
    this.checkInTime = '14:00',
    this.checkOutTime = '12:00',
  });

  final String name;
  final String? phone;
  final String? whatsapp;
  final String checkInTime;
  final String checkOutTime;

  static HotelBrief fromJson(Map<String, dynamic> j) => HotelBrief(
        name: _s(j, 'name', 'الفندق'),
        phone: _sn(j, 'phone'),
        whatsapp: _sn(j, 'whatsapp'),
        checkInTime: _s(j, 'checkInTime', '14:00'),
        checkOutTime: _s(j, 'checkOutTime', '12:00'),
      );
}

class HotelFull extends HotelBrief {
  const HotelFull({
    required super.name,
    super.phone,
    super.whatsapp,
    super.checkInTime,
    super.checkOutTime,
    this.address,
    this.city,
    this.email,
    this.cancellationPolicy,
    this.paymentPolicy,
    this.childrenPolicy,
    this.petsPolicy,
    this.smokingPolicy,
  });

  final String? address;
  final String? city;
  final String? email;
  final String? cancellationPolicy;
  final String? paymentPolicy;
  final String? childrenPolicy;
  final String? petsPolicy;
  final String? smokingPolicy;

  static HotelFull fromJson(Map<String, dynamic> j) => HotelFull(
        name: _s(j, 'name', 'الفندق'),
        phone: _sn(j, 'phone'),
        whatsapp: _sn(j, 'whatsapp'),
        checkInTime: _s(j, 'checkInTime', '14:00'),
        checkOutTime: _s(j, 'checkOutTime', '12:00'),
        address: _sn(j, 'address'),
        city: _sn(j, 'city'),
        email: _sn(j, 'email'),
        cancellationPolicy: _sn(j, 'cancellationPolicy'),
        paymentPolicy: _sn(j, 'paymentPolicy'),
        childrenPolicy: _sn(j, 'childrenPolicy'),
        petsPolicy: _sn(j, 'petsPolicy'),
        smokingPolicy: _sn(j, 'smokingPolicy'),
      );
}

// ───────────── الإقامة (SerializedStay §1.6) ─────────────

class RoomBrief {
  const RoomBrief({
    required this.id,
    required this.number,
    required this.floor,
    required this.status,
  });

  final String id;
  final String number;
  final int floor;
  final String status;

  static RoomBrief fromJson(Map<String, dynamic> j) => RoomBrief(
        id: _s(j, 'id'),
        number: _s(j, 'number'),
        floor: _i(j, 'floor'),
        status: _s(j, 'status'),
      );
}

class RoomTypeBrief {
  const RoomTypeBrief({
    required this.id,
    required this.name,
    required this.bedConfig,
    required this.sizeSqm,
    required this.basePriceCents,
    required this.amenities,
    required this.images,
  });

  final String id;
  final String name;
  final String bedConfig;
  final int sizeSqm;
  final int basePriceCents;
  final List<String> amenities;
  final List<String> images;

  static RoomTypeBrief fromJson(Map<String, dynamic> j) => RoomTypeBrief(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        bedConfig: _s(j, 'bedConfig'),
        sizeSqm: _i(j, 'sizeSqm'),
        basePriceCents: _i(j, 'basePriceCents'),
        amenities: _sl(j, 'amenities'),
        images: _sl(j, 'images'),
      );
}

List<String> _sl(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<String>().toList();
}

class ReservationBrief {
  const ReservationBrief({
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
    required this.paymentMethod,
    this.specialRequests,
    required this.createdAt,
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
  final String paymentMethod;
  final String? specialRequests;
  final String createdAt;

  static ReservationBrief fromJson(Map<String, dynamic> j) => ReservationBrief(
        id: _s(j, 'id'),
        bookingReference: _s(j, 'bookingReference'),
        status: _s(j, 'status'),
        source: _s(j, 'source'),
        checkIn: _s(j, 'checkIn'),
        checkOut: _s(j, 'checkOut'),
        adults: _i(j, 'adults'),
        children: _i(j, 'children'),
        roomsCount: _i(j, 'roomsCount', 1),
        currency: _s(j, 'currency', 'USD'),
        subtotalCents: _i(j, 'subtotalCents'),
        taxCents: _i(j, 'taxCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        paidCents: _i(j, 'paidCents'),
        paymentStatus: _s(j, 'paymentStatus'),
        paymentMethod: _s(j, 'paymentMethod'),
        specialRequests: _sn(j, 'specialRequests'),
        createdAt: _s(j, 'createdAt'),
      );
}

class Stay {
  const Stay({
    required this.id,
    required this.reference,
    required this.status,
    required this.checkInAt,
    required this.expectedCheckOutAt,
    this.actualCheckOutAt,
    required this.guestName,
    required this.room,
    required this.roomType,
    required this.reservation,
    this.totalNights,
    this.remainingNights,
  });

  final String id;
  final String reference;
  final String status; // ACTIVE | CHECKOUT_REQUESTED | CLOSED
  final String checkInAt;
  final String expectedCheckOutAt;
  final String? actualCheckOutAt;
  final String guestName;
  final RoomBrief room;
  final RoomTypeBrief roomType;
  final ReservationBrief reservation;
  final int? totalNights;
  final int? remainingNights;

  static Stay fromJson(Map<String, dynamic> j) => Stay(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        status: _s(j, 'status'),
        checkInAt: _s(j, 'checkInAt'),
        expectedCheckOutAt: _s(j, 'expectedCheckOutAt'),
        actualCheckOutAt: _sn(j, 'actualCheckOutAt'),
        guestName: _s(j, 'guestName'),
        room: RoomBrief.fromJson(_m(j, 'room') ?? const <String, dynamic>{}),
        roomType:
            RoomTypeBrief.fromJson(_m(j, 'roomType') ?? const <String, dynamic>{}),
        reservation: ReservationBrief.fromJson(
            _m(j, 'reservation') ?? const <String, dynamic>{}),
        totalNights: _in(j, 'totalNights'),
        remainingNights: _in(j, 'remainingNights'),
      );
}

// ───────────── لقطة السعر (Quote §1.6 + snapshot G-02) ─────────────

class NightlyRate {
  const NightlyRate({
    required this.date,
    required this.priceCents,
    required this.rateName,
  });

  final String date;
  final int priceCents;
  final String rateName;

  static NightlyRate fromJson(Map<String, dynamic> j) => NightlyRate(
        date: _s(j, 'date'),
        priceCents: _i(j, 'priceCents'),
        rateName: _s(j, 'rateName'),
      );
}

class Quote {
  const Quote({
    required this.nights,
    required this.currency,
    required this.taxPercent,
    required this.nightly,
    required this.subtotalCents,
    this.discountCents = 0,
    required this.taxCents,
    required this.grandTotalCents,
  });

  final int nights;
  final String currency;
  final int taxPercent;
  final List<NightlyRate> nightly;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int grandTotalCents;

  static Quote fromJson(Map<String, dynamic> j) => Quote(
        nights: _i(j, 'nights'),
        currency: _s(j, 'currency', 'USD'),
        taxPercent: _i(j, 'taxPercent'),
        nightly: _ml(j, 'nightly').map(NightlyRate.fromJson).toList(),
        subtotalCents: _i(j, 'subtotalCents'),
        discountCents: _i(j, 'discountCents'),
        taxCents: _i(j, 'taxCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
      );
}

class StaySnapshot {
  const StaySnapshot({
    required this.roomTypeName,
    required this.nightly,
    required this.subtotalCents,
    required this.taxCents,
    required this.grandTotalCents,
    required this.currency,
    required this.taxPercent,
    required this.roomsCount,
    this.cancellationPolicy,
    required this.checkInTime,
    required this.checkOutTime,
    this.bookedAt,
  });

  final String roomTypeName;
  final List<NightlyRate> nightly;
  final int subtotalCents;
  final int taxCents;
  final int grandTotalCents;
  final String currency;
  final int taxPercent;
  final int roomsCount;
  final String? cancellationPolicy;
  final String checkInTime;
  final String checkOutTime;
  final String? bookedAt;

  static StaySnapshot fromJson(Map<String, dynamic> j) => StaySnapshot(
        roomTypeName: _s(j, 'roomTypeName'),
        nightly: _ml(j, 'nightly').map(NightlyRate.fromJson).toList(),
        subtotalCents: _i(j, 'subtotalCents'),
        taxCents: _i(j, 'taxCents'),
        grandTotalCents: _i(j, 'grandTotalCents'),
        currency: _s(j, 'currency', 'USD'),
        taxPercent: _i(j, 'taxPercent'),
        roomsCount: _i(j, 'roomsCount', 1),
        cancellationPolicy: _sn(j, 'cancellationPolicy'),
        checkInTime: _s(j, 'checkInTime', '14:00'),
        checkOutTime: _s(j, 'checkOutTime', '12:00'),
        bookedAt: _sn(j, 'bookedAt'),
      );
}

// ───────────── لوحة الضيف (G-01) ─────────────

class GuestDashboard {
  const GuestDashboard({
    required this.stay,
    required this.notifications,
    required this.unreadCount,
    required this.activeRequests,
    required this.balanceCents,
    required this.chargesCents,
    required this.currency,
    required this.hotel,
  });

  final Stay stay;
  final List<NotificationItem> notifications;
  final int unreadCount;
  final int activeRequests;
  final int balanceCents;
  final int chargesCents;
  final String currency;
  final HotelBrief hotel;

  static GuestDashboard fromJson(Map<String, dynamic> j) => GuestDashboard(
        stay: Stay.fromJson(_m(j, 'stay') ?? const <String, dynamic>{}),
        notifications: _ml(j, 'notifications')
            .map(NotificationItem.fromJson)
            .toList(),
        unreadCount: _i(j, 'unreadCount'),
        activeRequests: _i(j, 'activeRequests'),
        balanceCents: _i(j, 'balanceCents'),
        chargesCents: _i(j, 'chargesCents'),
        currency: _s(j, 'currency', 'USD'),
        hotel: HotelBrief.fromJson(_m(j, 'hotel') ?? const <String, dynamic>{}),
      );
}

class StayDetail {
  const StayDetail({
    required this.stay,
    this.snapshot,
    required this.nights,
    required this.remainingNights,
    this.hotel,
  });

  final Stay stay;
  final StaySnapshot? snapshot;
  final int nights;
  final int remainingNights;
  final HotelFull? hotel;

  static StayDetail fromJson(Map<String, dynamic> j) => StayDetail(
        stay: Stay.fromJson(_m(j, 'stay') ?? const <String, dynamic>{}),
        snapshot: _m(j, 'snapshot') == null
            ? null
            : StaySnapshot.fromJson(_m(j, 'snapshot')!),
        nights: _i(j, 'nights'),
        remainingNights: _i(j, 'remainingNights'),
        hotel: _m(j, 'hotel') == null
            ? null
            : HotelFull.fromJson(_m(j, 'hotel')!),
      );
}

// ───────────── كتالوج الخدمات (G-03) ─────────────

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.categoryKey,
  });

  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String categoryKey;

  static ServiceItem fromJson(Map<String, dynamic> j) => ServiceItem(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        description: _s(j, 'description'),
        priceCents: _i(j, 'priceCents'),
        categoryKey: _s(j, 'categoryKey'),
      );
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.key,
    required this.icon,
    required this.services,
  });

  final String id;
  final String name;
  final String key;
  final String icon;
  final List<ServiceItem> services;

  static ServiceCategory fromJson(Map<String, dynamic> j) => ServiceCategory(
        id: _s(j, 'id'),
        name: _s(j, 'name'),
        key: _s(j, 'key'),
        icon: _s(j, 'icon'),
        services: _ml(j, 'services').map(ServiceItem.fromJson).toList(),
      );
}

// ───────────── طلبات الخدمة (G-04/05/06) ─────────────

class RequestUpdate {
  const RequestUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.byName,
    required this.byRole,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String note;
  final String byName;
  final String byRole;
  final String createdAt;

  static RequestUpdate fromJson(Map<String, dynamic> j) => RequestUpdate(
        id: _s(j, 'id'),
        status: _s(j, 'status'),
        note: _s(j, 'note'),
        byName: _s(j, 'byName'),
        byRole: _s(j, 'byRole'),
        createdAt: _s(j, 'createdAt'),
      );
}

class ServiceRequestModel {
  const ServiceRequestModel({
    required this.id,
    required this.reference,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.roomNumber,
    required this.updates,
  });

  final String id;
  final String reference;
  final String category;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String assignedTo;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String roomNumber;
  final List<RequestUpdate> updates;

  bool get isActive =>
      status != 'COMPLETED' && status != 'CANCELLED' && status != 'REJECTED';

  static ServiceRequestModel fromJson(Map<String, dynamic> j) =>
      ServiceRequestModel(
        id: _s(j, 'id'),
        reference: _s(j, 'reference'),
        category: _s(j, 'category'),
        title: _s(j, 'title'),
        description: _s(j, 'description'),
        priority: _s(j, 'priority', 'NORMAL'),
        status: _s(j, 'status', 'NEW'),
        assignedTo: _s(j, 'assignedTo'),
        createdAt: _s(j, 'createdAt'),
        updatedAt: _s(j, 'updatedAt'),
        completedAt: _sn(j, 'completedAt'),
        roomNumber: _s(j, 'roomNumber'),
        updates: _ml(j, 'updates').map(RequestUpdate.fromJson).toList(),
      );
}

// ───────────── المحادثة (G-07/08) ─────────────

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String sender; // GUEST | RECEPTION
  final String senderName;
  final String body;
  final String createdAt;

  bool get fromGuest => sender == 'GUEST';

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
        id: _s(j, 'id'),
        sender: _s(j, 'sender'),
        senderName: _s(j, 'senderName'),
        body: _s(j, 'body'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── الفاتورة (G-09) ─────────────

class ExtraCharge {
  const ExtraCharge({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.category,
    required this.date,
  });

  final String id;
  final String description;
  final int amountCents;
  final String category;
  final String date;

  static ExtraCharge fromJson(Map<String, dynamic> j) => ExtraCharge(
        id: _s(j, 'id'),
        description: _s(j, 'description'),
        amountCents: _i(j, 'amountCents'),
        category: _s(j, 'category'),
        date: _s(j, 'date'),
      );
}

class PaymentEntry {
  const PaymentEntry({
    required this.id,
    required this.method,
    required this.amountCents,
    required this.createdAt,
    required this.recordedBy,
  });

  final String id;
  final String method;
  final int amountCents;
  final String createdAt;
  final String recordedBy;

  static PaymentEntry fromJson(Map<String, dynamic> j) => PaymentEntry(
        id: _s(j, 'id'),
        method: _s(j, 'method'),
        amountCents: _i(j, 'amountCents'),
        createdAt: _s(j, 'createdAt'),
        recordedBy: _s(j, 'recordedBy'),
      );
}

class GuestBill {
  const GuestBill({
    required this.stayId,
    required this.stayReference,
    required this.roomNumber,
    required this.roomNights,
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
  final String roomNumber;
  final int roomNights;
  final int roomTotalCents;
  final int roomSubtotalCents;
  final int roomTaxCents;
  final List<ExtraCharge> extraCharges;
  final int extraTotalCents;
  final List<PaymentEntry> payments;
  final int totalChargesCents;
  final int totalPaidCents;
  final int balanceCents;
  final String currency;

  static GuestBill fromJson(Map<String, dynamic> j) => GuestBill(
        stayId: _s(j, 'stayId'),
        stayReference: _s(j, 'stayReference'),
        roomNumber: _s(j, 'roomNumber'),
        roomNights: _i(j, 'roomNights'),
        roomTotalCents: _i(j, 'roomTotalCents'),
        roomSubtotalCents: _i(j, 'roomSubtotalCents'),
        roomTaxCents: _i(j, 'roomTaxCents'),
        extraCharges: _ml(j, 'extraCharges').map(ExtraCharge.fromJson).toList(),
        extraTotalCents: _i(j, 'extraTotalCents'),
        payments: _ml(j, 'payments').map(PaymentEntry.fromJson).toList(),
        totalChargesCents: _i(j, 'totalChargesCents'),
        totalPaidCents: _i(j, 'totalPaidCents'),
        balanceCents: _i(j, 'balanceCents'),
        currency: _s(j, 'currency', 'USD'),
      );
}

// ───────────── الإشعارات (G-14/15) ─────────────

class NotificationItem {
  const NotificationItem({
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

  static NotificationItem fromJson(Map<String, dynamic> j) =>
      NotificationItem(
        id: _s(j, 'id'),
        audience: _s(j, 'audience'),
        type: _s(j, 'type'),
        title: _s(j, 'title'),
        body: _s(j, 'body'),
        read: _b(j, 'read'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ───────────── الغرف المتاحة (G-11/12) ─────────────

class RoomOption {
  const RoomOption({
    required this.roomId,
    required this.number,
    required this.floor,
    required this.typeName,
    required this.basePriceCents,
    required this.diffCents,
  });

  final String roomId;
  final String number;
  final int floor;
  final String typeName;
  final int basePriceCents;
  final int diffCents;

  static RoomOption fromJson(Map<String, dynamic> j) => RoomOption(
        roomId: _s(j, 'roomId'),
        number: _s(j, 'number'),
        floor: _i(j, 'floor'),
        typeName: _s(j, 'typeName'),
        basePriceCents: _i(j, 'basePriceCents'),
        diffCents: _i(j, 'diffCents'),
      );
}

class CurrentRoomInfo {
  const CurrentRoomInfo({
    required this.number,
    required this.typeName,
    required this.basePriceCents,
  });

  final String number;
  final String typeName;
  final int basePriceCents;

  static CurrentRoomInfo fromJson(Map<String, dynamic> j) => CurrentRoomInfo(
        number: _s(j, 'number'),
        typeName: _s(j, 'typeName'),
        basePriceCents: _i(j, 'basePriceCents'),
      );
}

class RoomOptionsResult {
  const RoomOptionsResult({required this.rooms, required this.currentRoom});

  final List<RoomOption> rooms;
  final CurrentRoomInfo currentRoom;

  static RoomOptionsResult fromJson(Map<String, dynamic> j) =>
      RoomOptionsResult(
        rooms: _ml(j, 'rooms').map(RoomOption.fromJson).toList(),
        currentRoom: CurrentRoomInfo.fromJson(
            _m(j, 'currentRoom') ?? const <String, dynamic>{}),
      );
}

// ───────────── نتائج الأفعال (G-10/12/13/16) ─────────────

class ExtensionRequestInfo {
  const ExtensionRequestInfo({
    required this.id,
    required this.newCheckOut,
    required this.nights,
    required this.priceCents,
    this.note,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String newCheckOut;
  final int nights;
  final int priceCents;
  final String? note;
  final String status;
  final String createdAt;

  static ExtensionRequestInfo fromJson(Map<String, dynamic> j) =>
      ExtensionRequestInfo(
        id: _s(j, 'id'),
        newCheckOut: _s(j, 'newCheckOut'),
        nights: _i(j, 'nights'),
        priceCents: _i(j, 'priceCents'),
        note: _sn(j, 'note'),
        status: _s(j, 'status', 'PENDING'),
        createdAt: _s(j, 'createdAt'),
      );
}

class ExtensionResult {
  const ExtensionResult({required this.request, required this.quote});

  final ExtensionRequestInfo request;
  final Quote quote;

  static ExtensionResult fromJson(Map<String, dynamic> j) => ExtensionResult(
        request: ExtensionRequestInfo.fromJson(
            _m(j, 'request') ?? const <String, dynamic>{}),
        quote: Quote.fromJson(_m(j, 'quote') ?? const <String, dynamic>{}),
      );
}

class RoomChangeRequestInfo {
  const RoomChangeRequestInfo({
    required this.id,
    required this.toRoomNumber,
    required this.priceDiffCents,
    required this.remainingNights,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String toRoomNumber;
  final int priceDiffCents;
  final int remainingNights;
  final String? reason;
  final String status;
  final String createdAt;

  static RoomChangeRequestInfo fromJson(Map<String, dynamic> j) =>
      RoomChangeRequestInfo(
        id: _s(j, 'id'),
        toRoomNumber: _s(j, 'toRoomNumber'),
        priceDiffCents: _i(j, 'priceDiffCents'),
        remainingNights: _i(j, 'remainingNights'),
        reason: _sn(j, 'reason'),
        status: _s(j, 'status', 'PENDING'),
        createdAt: _s(j, 'createdAt'),
      );
}

class CheckoutResult {
  const CheckoutResult({
    required this.balanceCents,
    required this.chargesCents,
    required this.currency,
  });

  final int balanceCents;
  final int chargesCents;
  final String currency;

  static CheckoutResult fromJson(Map<String, dynamic> j) => CheckoutResult(
        balanceCents: _i(j, 'balanceCents'),
        chargesCents: _i(j, 'chargesCents'),
        currency: _s(j, 'currency', 'USD'),
      );
}

class FeedbackResult {
  const FeedbackResult({
    required this.rating,
    required this.tags,
    required this.comment,
    required this.createdAt,
  });

  final int rating;
  final List<String> tags;
  final String comment;
  final String createdAt;

  static FeedbackResult fromJson(Map<String, dynamic> j) => FeedbackResult(
        rating: _i(j, 'rating'),
        tags: _sl(j, 'tags'),
        comment: _s(j, 'comment'),
        createdAt: _s(j, 'createdAt'),
      );
}

// ─────────────────────────────────────────────────────────────
// ADMIN STORE — حالة وضع الإدارة + نداءات قناة admin
// (A-01..A-34) — صفر HTTP خارج هذا الملف (نمط F1/F4)
// الفلاتر وأرقام الصفحات تقيم في المخزن (تقاوم تنقّل الأقسام)
// لا حالة محلية للمال: كل الأرقام من الخادم بالسنت
// ─────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/admin.dart';

class AdminStore extends ChangeNotifier {
  AdminStore(this.api);

  final ApiClient api;

  // ── A-01 ──
  AdminDashboard? dashboard;

  // ── A-02/A-03 ──
  HotelSettings? hotel;

  // ── A-04 ──
  List<AdminRoomType> roomTypes = const [];

  // ── A-08 ──
  List<AdminRoom> rooms = const [];

  // ── A-12 ──
  List<AdminRate> rates = const [];

  // ── A-15 ──
  List<AdminService> services = const [];

  // ── A-19 ──
  List<AdminServiceCategory> serviceCategories = const [];

  // ── A-23 ──
  List<AdminStaffMember> staff = const [];

  // ── A-26 (الفلاتر تقيم هنا — تقاوم تنقّل الأقسام) ──
  String codesTypeFilter = '';
  String codesStatusFilter = '';
  List<AdminAccessCode> codes = const [];

  // ── A-29 (الفلاتر + رقم الصفحة تقيم هنا) ──
  String reservationsStatusFilter = '';
  String reservationsQuery = '';
  int reservationsPage = 1;
  ReservationsPageData? reservationsPageData;

  // ── A-31 (البحث يقيم هنا) ──
  String guestsQuery = '';
  List<AdminGuest> guests = const [];

  // ── A-32 (الفلتر + البحث + الصفحة تقيم هنا) ──
  String auditActionFilter = '';
  String auditQuery = '';
  int auditPage = 1;
  AuditPageData? auditPageData;

  // ── A-33 ──
  AdminReports? reports;

  // ── A-34 ──
  List<AdminNotificationItem> notifications = const [];
  int unreadCount = 0;

  String? lastError;

  bool _dashboardLoading = false;
  bool get dashboardLoading => _dashboardLoading;

  bool _hotelLoading = false;
  bool get hotelLoading => _hotelLoading;

  bool _roomTypesLoading = false;
  bool get roomTypesLoading => _roomTypesLoading;

  bool _roomsLoading = false;
  bool get roomsLoading => _roomsLoading;

  bool _ratesLoading = false;
  bool get ratesLoading => _ratesLoading;

  bool _servicesLoading = false;
  bool get servicesLoading => _servicesLoading;

  bool _categoriesLoading = false;
  bool get categoriesLoading => _categoriesLoading;

  bool _staffLoading = false;
  bool get staffLoading => _staffLoading;

  bool _codesLoading = false;
  bool get codesLoading => _codesLoading;

  bool _reservationsLoading = false;
  bool get reservationsLoading => _reservationsLoading;

  bool _guestsLoading = false;
  bool get guestsLoading => _guestsLoading;

  bool _auditLoading = false;
  bool get auditLoading => _auditLoading;

  bool _reportsLoading = false;
  bool get reportsLoading => _reportsLoading;

  bool _notificationsLoading = false;
  bool get notificationsLoading => _notificationsLoading;

  /// التحميل الأول: اللوحة + الإشعارات فقط (كما الويب — باقي
  /// الأقسام تُحمّل عند فتحها: كل شاشة تُحدِّث قسمها في initState)
  Future<void> bootstrap() async {
    await Future.wait([
      refreshDashboard().catchError((_) {}),
      refreshNotifications().catchError((_) {}),
    ]);
  }

  // ── A-01 ──
  Future<void> refreshDashboard() async {
    if (_dashboardLoading) return;
    _dashboardLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/dashboard');
      dashboard = AdminDashboard.fromJson(json);
      notifyListeners();
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  // ── A-02 ──
  Future<void> refreshHotel() async {
    if (_hotelLoading) return;
    _hotelLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/hotel');
      hotel = HotelSettings.fromJson(
          _mapOf(json['hotel']) ?? const <String, dynamic>{});
      notifyListeners();
    } finally {
      _hotelLoading = false;
      notifyListeners();
    }
  }

  // ── A-03 · تحديث إعدادات الفندق ──
  /// يرمي ApiError برسالة الخادم الحرفية. يعيد ملاحظة الخادم (note)
  /// ويعيد تحميل الإعدادات بصمت بعد النجاح.
  Future<String> updateHotel(Map<String, dynamic> changes) async {
    final json = await api.patch('/api/admin/hotel', body: changes);
    await refreshHotel();
    return (json['note'] as String?) ?? 'تم الحفظ';
  }

  // ── A-04 ──
  Future<void> refreshRoomTypes() async {
    if (_roomTypesLoading) return;
    _roomTypesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/room-types');
      roomTypes = _listOf(json['roomTypes'])
          .map(AdminRoomType.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _roomTypesLoading = false;
      notifyListeners();
    }
  }

  // ── A-05 · إنشاء نوع غرفة ──
  /// يرمي ApiError برسالة الخادم. يعيد النوع المُنشأ ويحدّث القائمة.
  Future<AdminRoomType> createRoomType(Map<String, dynamic> body) async {
    final json = await api.post('/api/admin/room-types', body: body);
    final created = AdminRoomType.fromJson(
        _mapOf(json['roomType']) ?? const <String, dynamic>{});
    await refreshRoomTypes();
    return created;
  }

  // ── A-06 · تعديل نوع غرفة ──
  Future<AdminRoomType> updateRoomType(
      String id, Map<String, dynamic> body) async {
    final json = await api.patch('/api/admin/room-types/$id', body: body);
    final updated = AdminRoomType.fromJson(
        _mapOf(json['roomType']) ?? const <String, dynamic>{});
    await refreshRoomTypes();
    return updated;
  }

  // ── A-07 · حذف نوع (ناعم إن وُجدت ارتباطات) ──
  Future<String> deleteRoomType(String id) async {
    final json = await api.delete('/api/admin/room-types/$id');
    await refreshRoomTypes();
    return (json['message'] as String?) ?? 'تم الحذف';
  }

  // ── A-08 ──
  Future<void> refreshRooms() async {
    if (_roomsLoading) return;
    _roomsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/rooms');
      rooms = _listOf(json['rooms'])
          .map(AdminRoom.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _roomsLoading = false;
      notifyListeners();
    }
  }

  // ── A-09 · إنشاء غرفة ──
  Future<AdminRoom> createRoom({
    required String number,
    required int floor,
    required String roomTypeId,
    String? notes,
  }) async {
    final json = await api.post('/api/admin/rooms', body: {
      'number': number,
      'floor': floor,
      'roomTypeId': roomTypeId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    final created = AdminRoom.fromJson(
        _mapOf(json['room']) ?? const <String, dynamic>{});
    await _refreshRoomsAndDashboard();
    return created;
  }

  // ── A-10 · تعديل غرفة (OCCUPIED ممنوعة يدويًا — الخادم يرفض) ──
  /// يرمي ApiError برسالة الخادم (مثل «لا يمكن ضبط الغرفة مشغولة
  /// يدويًا…»). تحويل الحالة يبث room:status للطاولات الحية.
  Future<void> updateRoom(String id, Map<String, dynamic> body) async {
    await api.patch('/api/admin/rooms/$id', body: body);
    await _refreshRoomsAndDashboard();
  }

  // ── A-11 · حذف غرفة ──
  Future<String> deleteRoom(String id) async {
    final json = await api.delete('/api/admin/rooms/$id');
    await _refreshRoomsAndDashboard();
    return (json['message'] as String?) ?? 'تم الحذف';
  }

  // ── A-12 ──
  Future<void> refreshRates() async {
    if (_ratesLoading) return;
    _ratesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/rates');
      rates = _listOf(json['rates'])
          .map(AdminRate.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _ratesLoading = false;
      notifyListeners();
    }
  }

  // ── A-13 · إنشاء معدل موسمي ──
  /// يعيد (المعدل، تحذير التداخل إن وُجد — الخادم يسمح بالإنشاء).
  Future<(AdminRate, String?)> createRate(
      Map<String, dynamic> body) async {
    final json = await api.post('/api/admin/rates', body: body);
    final rate = AdminRate.fromJson(
        _mapOf(json['rate']) ?? const <String, dynamic>{});
    final warning = json['warning'] is String ? json['warning'] as String : null;
    await refreshRates();
    return (rate, warning);
  }

  // ── A-14 · حذف معدل ──
  Future<String> deleteRate(String id) async {
    final json = await api.delete('/api/admin/rates/$id');
    await refreshRates();
    return (json['message'] as String?) ?? 'تم الحذف';
  }

  // ── A-15 ──
  Future<void> refreshServices() async {
    if (_servicesLoading) return;
    _servicesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/services');
      services = _listOf(json['services'])
          .map(AdminService.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _servicesLoading = false;
      notifyListeners();
    }
  }

  // ── A-16 ──
  Future<AdminService> createService(Map<String, dynamic> body) async {
    final json = await api.post('/api/admin/services', body: body);
    final created = AdminService.fromJson(
        _mapOf(json['service']) ?? const <String, dynamic>{});
    await refreshServices();
    return created;
  }

  // ── A-17 ──
  Future<AdminService> updateService(
      String id, Map<String, dynamic> body) async {
    final json = await api.patch('/api/admin/services/$id', body: body);
    final updated = AdminService.fromJson(
        _mapOf(json['service']) ?? const <String, dynamic>{});
    await refreshServices();
    return updated;
  }

  // ── A-18 ──
  Future<String> deleteService(String id) async {
    final json = await api.delete('/api/admin/services/$id');
    await refreshServices();
    return (json['message'] as String?) ?? 'تم الحذف';
  }

  // ── A-19 ──
  Future<void> refreshServiceCategories() async {
    if (_categoriesLoading) return;
    _categoriesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/service-categories');
      serviceCategories = _listOf(json['categories'])
          .map(AdminServiceCategory.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  // ── A-20 ──
  Future<AdminServiceCategory> createServiceCategory(
      Map<String, dynamic> body) async {
    final json = await api.post('/api/admin/service-categories', body: body);
    final created = AdminServiceCategory.fromJson(
        _mapOf(json['category']) ?? const <String, dynamic>{});
    await refreshServiceCategories();
    return created;
  }

  // ── A-21 ──
  Future<AdminServiceCategory> updateServiceCategory(
      String id, Map<String, dynamic> body) async {
    final json = await api.patch('/api/admin/service-categories/$id', body: body);
    final updated = AdminServiceCategory.fromJson(
        _mapOf(json['category']) ?? const <String, dynamic>{});
    await refreshServiceCategories();
    return updated;
  }

  // ── A-22 ──
  Future<String> deleteServiceCategory(String id) async {
    final json = await api.delete('/api/admin/service-categories/$id');
    await refreshServiceCategories();
    return (json['message'] as String?) ?? 'تم الحذف';
  }

  // ── A-23 ──
  Future<void> refreshStaff() async {
    if (_staffLoading) return;
    _staffLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/staff');
      staff = _listOf(json['staff'])
          .map(AdminStaffMember.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _staffLoading = false;
      notifyListeners();
    }
  }

  // ── A-24 · إضافة موظف ──
  Future<AdminStaffMember> createStaff({
    required String fullName,
    required String role,
    String? phone,
  }) async {
    final json = await api.post('/api/admin/staff', body: {
      'fullName': fullName,
      'role': role,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    final created = AdminStaffMember.fromJson(
        _mapOf(json['staffMember']) ?? const <String, dynamic>{});
    await refreshStaff();
    return created;
  }

  // ── A-25 · تعديل موظف (التعطيل يبطل كوده وجلساته — الخادم) ──
  Future<AdminStaffMember> updateStaff(
      String id, Map<String, dynamic> body) async {
    final json = await api.patch('/api/admin/staff/$id', body: body);
    final updated = AdminStaffMember.fromJson(
        _mapOf(json['staffMember']) ?? const <String, dynamic>{});
    await refreshStaff();
    return updated;
  }

  // ── A-26 · الأكواد (الفلاتر من المخزن) ──
  Future<void> refreshCodes({String? type, String? status}) async {
    if (_codesLoading) return;
    _codesLoading = true;
    if (type != null) codesTypeFilter = type;
    if (status != null) codesStatusFilter = status;
    notifyListeners();
    try {
      var path = '/api/admin/codes';
      final params = <String>[];
      if (codesTypeFilter.isNotEmpty) params.add('type=$codesTypeFilter');
      if (codesStatusFilter.isNotEmpty) params.add('status=$codesStatusFilter');
      if (params.isNotEmpty) path += '?${params.join('&')}';
      final json = await api.get(path);
      codes = _listOf(json['codes'])
          .map(AdminAccessCode.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _codesLoading = false;
      notifyListeners();
    }
  }

  // ── A-27 · توليد كود (الخام يُعاد مرة واحدة — لا يُخزَّن) ──
  /// يرمي ApiError برسالة الخادم الحرفية (تطابق الدور…).
  /// الخادم يُشعِر الاستقبال فورًا (notification:new).
  Future<GeneratedCodeResult> generateCode({
    required String type,
    required String staffId,
    int days = 7,
  }) async {
    final json = await api.post('/api/admin/codes', body: {
      'type': type,
      'staffId': staffId,
      'days': days,
    });
    final result = GeneratedCodeResult.fromJson(json);
    await Future.wait([
      refreshCodes().catchError((_) {}),
      refreshStaff().catchError((_) {}),
      refreshDashboard().catchError((_) {}),
      refreshNotifications().catchError((_) {}),
    ]);
    return result;
  }

  // ── A-28 · إبطال كود (يشمل أكواد الضيف) ──
  /// يبطل الكود وجميع جلساته فورًا (الخادم). يرمي ApiError
  /// («هذا الكود ملغى بالفعل»…). يعيد رسالة الخادم.
  Future<String> revokeCode(String codeId) async {
    final json = await api.post('/api/admin/codes/revoke', body: {
      'codeId': codeId,
    });
    await Future.wait([
      refreshCodes().catchError((_) {}),
      refreshStaff().catchError((_) {}),
      refreshDashboard().catchError((_) {}),
    ]);
    return (json['message'] as String?) ?? 'تم إبطال الكود';
  }

  // ── A-29 · الحجوزات (مُصفّحة) ──
  Future<void> refreshReservations({
    String? status,
    String? q,
    int? page,
  }) async {
    if (_reservationsLoading) return;
    _reservationsLoading = true;
    if (status != null) reservationsStatusFilter = status;
    if (q != null) reservationsQuery = q;
    if (page != null) reservationsPage = page;
    notifyListeners();
    try {
      var path = '/api/admin/reservations?page=$reservationsPage';
      if (reservationsStatusFilter.isNotEmpty) {
        path += '&status=$reservationsStatusFilter';
      }
      if (reservationsQuery.trim().isNotEmpty) {
        path +=
            '&q=${Uri.encodeQueryComponent(reservationsQuery.trim())}';
      }
      final json = await api.get(path);
      reservationsPageData = ReservationsPageData.fromJson(json);
      notifyListeners();
    } finally {
      _reservationsLoading = false;
      notifyListeners();
    }
  }

  // ── A-30 · تفاصيل حجز (بلا تخزين مؤقت — كنمط R-05) ──
  Future<AdminReservationDetail> loadReservationDetail(String id) async {
    final json = await api.get('/api/admin/reservations/$id');
    return AdminReservationDetail.fromJson(
        _mapOf(json['reservation']) ?? const <String, dynamic>{});
  }

  // ── A-31 · الضيوف ──
  Future<void> refreshGuests({String? q}) async {
    if (_guestsLoading) return;
    _guestsLoading = true;
    if (q != null) guestsQuery = q;
    notifyListeners();
    try {
      var path = '/api/admin/guests';
      if (guestsQuery.trim().isNotEmpty) {
        path += '?q=${Uri.encodeQueryComponent(guestsQuery.trim())}';
      }
      final json = await api.get(path);
      guests = _listOf(json['guests'])
          .map(AdminGuest.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _guestsLoading = false;
      notifyListeners();
    }
  }

  // ── A-32 · سجل التدقيق (مُصفّح) ──
  Future<void> refreshAudit({String? action, String? q, int? page}) async {
    if (_auditLoading) return;
    _auditLoading = true;
    if (action != null) auditActionFilter = action;
    if (q != null) auditQuery = q;
    if (page != null) auditPage = page;
    notifyListeners();
    try {
      var path = '/api/admin/audit?page=$auditPage';
      if (auditActionFilter.isNotEmpty) {
        path += '&action=${Uri.encodeQueryComponent(auditActionFilter)}';
      }
      if (auditQuery.trim().isNotEmpty) {
        path += '&q=${Uri.encodeQueryComponent(auditQuery.trim())}';
      }
      final json = await api.get(path);
      auditPageData = AuditPageData.fromJson(json);
      notifyListeners();
    } finally {
      _auditLoading = false;
      notifyListeners();
    }
  }

  // ── A-33 ──
  Future<void> refreshReports() async {
    if (_reportsLoading) return;
    _reportsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/reports');
      reports = AdminReports.fromJson(json);
      notifyListeners();
    } finally {
      _reportsLoading = false;
      notifyListeners();
    }
  }

  // ── A-34 ──
  Future<void> refreshNotifications() async {
    if (_notificationsLoading) return;
    _notificationsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/admin/notifications');
      notifications = _listOf(json['notifications'])
          .map(AdminNotificationItem.fromJson)
          .toList(growable: false);
      unreadCount = _asInt(json['unreadCount']);
      notifyListeners();
    } finally {
      _notificationsLoading = false;
      notifyListeners();
    }
  }

  // ── مزامنات الأحداث الفورية (تستدعيها AdminShell وفق غرفة admin) ──
  /// حجز جديد / حالة غرفة: تعيد رسم لوحة التحكم (dashKey في الويب)
  Future<void> onRealtimeBump() async {
    await refreshDashboard().catchError((_) {});
  }

  Future<void> onRealtimeNotification() async {
    await refreshNotifications().catchError((_) {});
  }

  void reset() {
    dashboard = null;
    hotel = null;
    roomTypes = const [];
    rooms = const [];
    rates = const [];
    services = const [];
    serviceCategories = const [];
    staff = const [];
    codesTypeFilter = '';
    codesStatusFilter = '';
    codes = const [];
    reservationsStatusFilter = '';
    reservationsQuery = '';
    reservationsPage = 1;
    reservationsPageData = null;
    guestsQuery = '';
    guests = const [];
    auditActionFilter = '';
    auditQuery = '';
    auditPage = 1;
    auditPageData = null;
    reports = null;
    notifications = const [];
    unreadCount = 0;
    lastError = null;
    notifyListeners();
  }

  Future<void> _refreshRoomsAndDashboard() async {
    await Future.wait([
      refreshRooms().catchError((_) {}),
      refreshDashboard().catchError((_) {}),
    ]);
  }

  static Map<String, dynamic>? _mapOf(dynamic v) =>
      v is Map<String, dynamic> ? v : null;

  static List<Map<String, dynamic>> _listOf(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }
}

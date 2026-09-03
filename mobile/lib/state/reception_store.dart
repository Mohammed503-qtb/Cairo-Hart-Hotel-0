// ─────────────────────────────────────────────────────────────
// RECEPTION STORE — حالة وضع الاستقبال + نداءات قناة reception
// (R-01..R-07 · R-10 · R-22/R-23) — كل HTTP هنا فقط (نمط F1)
// لا حالة محلية للمال: كل رصيد من الخادم
// ─────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/format.dart' as fmt;
import '../models/reception.dart';

class ReceptionStore extends ChangeNotifier {
  ReceptionStore(this.api);

  final ApiClient api;

  // ── R-01 ──
  ReceptionDashboard? dashboard;

  // ── R-02 (التاريخ المختار يبقى في المخزن — يقاوم تنقّل التبويبات) ──
  String arrivalsDate = fmt.todayInputValue();
  List<ArrivalItem> arrivals = const [];

  // ── R-03 ──
  String departuresDate = fmt.todayInputValue();
  List<DepartureItem> departures = const [];

  // ── R-10 ──
  List<RoomItem> rooms = const [];

  // ── R-22 ──
  List<ReceptionNotification> notifications = const [];
  int unreadCount = 0;

  String? lastError;

  bool _bootstrapLoading = false;
  bool get bootstrapLoading => _bootstrapLoading;

  bool _arrivalsLoading = false;
  bool get arrivalsLoading => _arrivalsLoading;

  bool _departuresLoading = false;
  bool get departuresLoading => _departuresLoading;

  bool _roomsLoading = false;
  bool get roomsLoading => _roomsLoading;

  bool _notificationsLoading = false;
  bool get notificationsLoading => _notificationsLoading;

  /// التحميل الأول: كل الأقسام بالتوازي — فشل قسم لا يقتل البقية
  Future<void> bootstrap() async {
    if (_bootstrapLoading) return;
    _bootstrapLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await Future.wait([
        refreshDashboard().catchError((_) {}),
        refreshArrivals().catchError((_) {}),
        refreshDepartures().catchError((_) {}),
        refreshRooms().catchError((_) {}),
        refreshNotifications().catchError((_) {}),
      ]);
    } finally {
      _bootstrapLoading = false;
      notifyListeners();
    }
  }

  // ── R-01 ──
  Future<void> refreshDashboard() async {
    final json = await api.get('/api/reception/dashboard');
    dashboard = ReceptionDashboard.fromJson(json);
    notifyListeners();
  }

  // ── R-02 ──
  Future<void> refreshArrivals({String? date}) async {
    if (_arrivalsLoading) return;
    _arrivalsLoading = true;
    if (date != null) arrivalsDate = date;
    notifyListeners();
    try {
      final json =
          await api.get('/api/reception/arrivals?date=$arrivalsDate');
      arrivals =
          (json['arrivals'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(ArrivalItem.fromJson)
              .toList(growable: false);
      notifyListeners();
    } finally {
      _arrivalsLoading = false;
      notifyListeners();
    }
  }

  // ── R-03 ──
  Future<void> refreshDepartures({String? date}) async {
    if (_departuresLoading) return;
    _departuresLoading = true;
    if (date != null) departuresDate = date;
    notifyListeners();
    try {
      final json =
          await api.get('/api/reception/departures?date=$departuresDate');
      departures =
          (json['departures'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DepartureItem.fromJson)
              .toList(growable: false);
      notifyListeners();
    } finally {
      _departuresLoading = false;
      notifyListeners();
    }
  }

  // ── R-10 ──
  Future<void> refreshRooms() async {
    if (_roomsLoading) return;
    _roomsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/reception/rooms');
      rooms = (json['rooms'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RoomItem.fromJson)
          .toList(growable: false);
      notifyListeners();
    } finally {
      _roomsLoading = false;
      notifyListeners();
    }
  }

  // ── R-22 ──
  Future<void> refreshNotifications() async {
    if (_notificationsLoading) return;
    _notificationsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/reception/notifications');
      notifications = (json['notifications'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReceptionNotification.fromJson)
          .toList(growable: false);
      unreadCount = _asInt(json['unreadCount']);
      notifyListeners();
    } finally {
      _notificationsLoading = false;
      notifyListeners();
    }
  }

  // ── R-23 ──
  Future<void> markNotificationsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await api.post(
      '/api/reception/notifications/read',
      body: <String, dynamic>{'ids': ids},
    );
    await refreshNotifications();
  }

  /// تعليم المعروض غير المقروء كمقروء (سلوك الورقة في الويب حرفيًا)
  Future<void> markVisibleNotificationsRead() async {
    final unreadIds =
        notifications.where((n) => !n.read).map((n) => n.id).toList();
    await markNotificationsRead(unreadIds);
  }

  // ── R-05 (يستدعيه معالج الخروج — بلا تخزين مؤقت) ──
  Future<StayDetailData> loadStayDetail(String stayId) async {
    final json = await api.get('/api/reception/stays/$stayId');
    return StayDetailData.fromJson(json);
  }

  // ── R-06 · تسجيل الوصول ──
  /// يرمي ApiError برسالة الخادم الحرفية (المعالج يعرضها).
  /// بعد النجاح يحدّث القوائم المتأثرة بصمت.
  Future<CheckInResult> checkIn({
    required String reservationId,
    required String roomId,
    String? idNumber,
  }) async {
    final body = <String, dynamic>{
      'reservationId': reservationId,
      'roomId': roomId,
      if (idNumber != null && idNumber.trim().isNotEmpty)
        'idNumber': idNumber.trim(),
    };
    final json = await api.post('/api/reception/check-in', body: body);
    final result = CheckInResult.fromJson(json);
    await _refreshAfterOperation();
    return result;
  }

  // ── R-07 · تسجيل الخروج ──
  Future<CheckOutResult> checkOut({
    required String stayId,
    bool confirmOutstanding = false,
  }) async {
    final json = await api.post(
      '/api/reception/check-out',
      body: <String, dynamic>{
        'stayId': stayId,
        'confirmOutstanding': confirmOutstanding,
      },
    );
    final result = CheckOutResult.fromJson(json);
    await _refreshAfterOperation();
    return result;
  }

  // ── R-12 · دفعة (التسوية السريعة في معالج الخروج) ──
  Future<void> recordPayment({
    required String stayId,
    required String method,
    required int amountCents,
    String? note,
  }) async {
    await api.post(
      '/api/reception/payments',
      body: <String, dynamic>{
        'stayId': stayId,
        'method': method,
        'amountCents': amountCents,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  /// بعد أي عملية كاتب (وصول/خروج): تحديث كل القوائم بصمت
  /// (فشل التحديث لا يبطل نجاح العملية نفسها)
  Future<void> _refreshAfterOperation() async {
    await Future.wait([
      refreshDashboard().catchError((_) {}),
      refreshArrivals().catchError((_) {}),
      refreshDepartures().catchError((_) {}),
      refreshRooms().catchError((_) {}),
      refreshNotifications().catchError((_) {}),
    ]);
  }

  // ── مزامنات الأحداث الفورية (تستدعيها ReceptionShell وفق غرفة reception) ──
  Future<void> onRealtimeBump() async {
    await Future.wait([
      refreshDashboard().catchError((_) {}),
      refreshArrivals().catchError((_) {}),
      refreshDepartures().catchError((_) {}),
      refreshRooms().catchError((_) {}),
    ]);
  }

  Future<void> onRealtimeNotification() async {
    await refreshNotifications().catchError((_) {});
  }

  void reset() {
    dashboard = null;
    arrivals = const [];
    departures = const [];
    rooms = const [];
    notifications = const [];
    unreadCount = 0;
    arrivalsDate = fmt.todayInputValue();
    departuresDate = fmt.todayInputValue();
    lastError = null;
    notifyListeners();
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }
}

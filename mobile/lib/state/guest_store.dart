// ─────────────────────────────────────────────────────────────
// GUEST STORE — حالة وضع الضيف + كل نداءات قناة guest (G-01..G-16)
// عزل البيانات عبر الجلسة (stayId من الخادم) — لا حالة محلية للمال
// ─────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/guest.dart';

class GuestStore extends ChangeNotifier {
  GuestStore(this.api);

  final ApiClient api;

  GuestDashboard? dashboard;
  StayDetail? stayDetail;
  List<ServiceCategory> serviceCategories = const [];
  List<ServiceRequestModel> requests = const [];
  List<ChatMessage> messages = const [];
  GuestBill? bill;
  List<NotificationItem> notifications = const [];
  int unreadCount = 0;

  String? stayId;
  String? lastError;

  bool _bootstrapLoading = false;
  bool get bootstrapLoading => _bootstrapLoading;

  bool _requestsLoading = false;
  bool get requestsLoading => _requestsLoading;

  bool _messagesLoading = false;
  bool get messagesLoading => _messagesLoading;

  bool _notificationsLoading = false;
  bool get notificationsLoading => _notificationsLoading;

  bool _servicesLoading = false;
  bool get servicesLoading => _servicesLoading;

  /// التحميل الأول: لوحة الضيف ثم بقية الأقسام بالتوازي
  Future<void> bootstrap() async {
    if (_bootstrapLoading) return;
    _bootstrapLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await refreshDashboard();
      final sid = stayId;
      if (sid != null) {
        await Future.wait([
          refreshStay(),
          refreshServices(),
          refreshRequests(),
          refreshBill(),
          refreshMessages(),
          refreshNotifications(),
        ]);
      }
    } on ApiError catch (e) {
      lastError = e.message;
    } finally {
      _bootstrapLoading = false;
      notifyListeners();
    }
  }

  // ── G-01 ──
  Future<void> refreshDashboard() async {
    final json = await api.get('/api/guest/dashboard');
    dashboard = GuestDashboard.fromJson(json);
    stayId = dashboard?.stay.id;
    notifyListeners();
  }

  // ── G-02 ──
  Future<void> refreshStay() async {
    final json = await api.get('/api/guest/stay');
    stayDetail = StayDetail.fromJson(json);
    notifyListeners();
  }

  // ── G-03 ──
  Future<void> refreshServices() async {
    if (_servicesLoading) return;
    _servicesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/guest/services');
      serviceCategories = _ml(json, 'categories')
          .map(ServiceCategory.fromJson)
          .toList();
      notifyListeners();
    } finally {
      _servicesLoading = false;
      notifyListeners();
    }
  }

  // ── G-04 ──
  Future<void> refreshRequests() async {
    if (_requestsLoading) return;
    _requestsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/guest/requests');
      requests = _ml(json, 'requests')
          .map(ServiceRequestModel.fromJson)
          .toList();
      notifyListeners();
    } finally {
      _requestsLoading = false;
      notifyListeners();
    }
  }

  // ── G-05 ──
  Future<ServiceRequestModel> createRequest({
    required String title,
    required String category,
    String priority = 'NORMAL',
    String? description,
    String? serviceId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'category': category,
      'priority': priority,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (serviceId != null) 'serviceId': serviceId,
    };
    final json = await api.post('/api/guest/requests', body: body);
    final created = ServiceRequestModel.fromJson(
        json['request'] as Map<String, dynamic>);
    await refreshRequests();
    await refreshDashboard();
    return created;
  }

  // ── G-06 ──
  Future<ServiceRequestModel> cancelRequest(String id) async {
    final json = await api.post('/api/guest/requests/$id/cancel');
    final cancelled = ServiceRequestModel.fromJson(
        json['request'] as Map<String, dynamic>);
    await refreshRequests();
    return cancelled;
  }

  // ── G-07 ──
  Future<void> refreshMessages() async {
    if (_messagesLoading) return;
    _messagesLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/guest/messages');
      messages = _ml(json, 'messages').map(ChatMessage.fromJson).toList();
      notifyListeners();
    } finally {
      _messagesLoading = false;
      notifyListeners();
    }
  }

  // ── G-08 ──
  Future<ChatMessage> sendMessage(String body) async {
    final json = await api.post(
      '/api/guest/messages',
      body: <String, dynamic>{'body': body},
    );
    final message =
        ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
    await refreshMessages();
    return message;
  }

  // ── G-09 ──
  Future<void> refreshBill() async {
    final json = await api.get('/api/guest/bill');
    bill = GuestBill.fromJson(_m(json, 'bill') ?? const <String, dynamic>{});
    notifyListeners();
  }

  // ── G-10 ──
  Future<ExtensionResult> requestExtension(String newCheckOut,
      {String? note}) async {
    final json = await api.post(
      '/api/guest/extension',
      body: <String, dynamic>{
        'newCheckOut': newCheckOut,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    await refreshNotifications();
    await refreshDashboard();
    return ExtensionResult.fromJson(json);
  }

  // ── G-11 ──
  Future<RoomOptionsResult> loadRoomOptions() async {
    final json = await api.get('/api/guest/room-options');
    return RoomOptionsResult.fromJson(json);
  }

  // ── G-12 ──
  Future<RoomChangeRequestInfo> requestRoomChange(String toRoomId,
      {String? reason}) async {
    final json = await api.post(
      '/api/guest/room-change',
      body: <String, dynamic>{
        'toRoomId': toRoomId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    await refreshNotifications();
    await refreshDashboard();
    return RoomChangeRequestInfo.fromJson(
        json['request'] as Map<String, dynamic>);
  }

  // ── G-13 ──
  Future<CheckoutResult> requestCheckout() async {
    final json = await api.post('/api/guest/checkout-request');
    await refreshDashboard();
    await refreshStay();
    return CheckoutResult.fromJson(json);
  }

  // ── G-14 ──
  Future<void> refreshNotifications() async {
    if (_notificationsLoading) return;
    _notificationsLoading = true;
    notifyListeners();
    try {
      final json = await api.get('/api/guest/notifications');
      notifications = _ml(json, 'notifications')
          .map(NotificationItem.fromJson)
          .toList();
      unreadCount = 0;
      if (json['unreadCount'] is int) {
        unreadCount = json['unreadCount'] as int;
      } else if (json['unreadCount'] is num) {
        unreadCount = (json['unreadCount'] as num).toInt();
      }
      notifyListeners();
    } finally {
      _notificationsLoading = false;
      notifyListeners();
    }
  }

  // ── G-15 ──
  Future<void> markAllNotificationsRead() async {
    await api.post('/api/guest/notifications/read');
    await refreshNotifications();
    await refreshDashboard();
  }

  // ── G-16 ──
  Future<FeedbackResult> submitFeedback({
    required int rating,
    List<String>? tags,
    String? comment,
  }) async {
    final json = await api.post(
      '/api/guest/feedback',
      body: <String, dynamic>{
        'rating': rating,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return FeedbackResult.fromJson(
        json['feedback'] as Map<String, dynamic>);
  }

  // ── مزامنات الأحداث الفورية (تستدعيها GuestShell وفق F2) ──
  Future<void> onRealtimeNotification() async {
    await refreshNotifications();
    await refreshDashboard();
  }

  Future<void> onRealtimeRequestUpdated() async => refreshRequests();

  Future<void> onRealtimeStayUpdated() async {
    await refreshDashboard();
    await refreshStay();
  }

  Future<void> onRealtimeChatMessage() async => refreshMessages();

  void reset() {
    dashboard = null;
    stayDetail = null;
    serviceCategories = const [];
    requests = const [];
    messages = const [];
    bill = null;
    notifications = const [];
    unreadCount = 0;
    stayId = null;
    lastError = null;
    notifyListeners();
  }
}

// مساعدات JSON محلية (نفس دلالات models)
Map<String, dynamic>? _m(Map<String, dynamic> j, String k) =>
    j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : null;

List<Map<String, dynamic>> _ml(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<Map<String, dynamic>>().toList();
}

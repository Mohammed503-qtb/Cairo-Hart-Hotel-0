// ─────────────────────────────────────────────────────────────
// SESSION — إدارة الجلسة (توكن Bearer) وفق عقد §1.2.1
// restore عند الإطلاق → renew → أو شاشة الكود
// ─────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../core/api_client.dart';
import '../models/guest.dart';

enum AppStatus { booting, loggedOut, loggingIn, authenticated }

class SessionController extends ChangeNotifier {
  SessionController() {
    api = ApiClient(
      baseUrlProvider: () => AppConfig.baseUrl,
      tokenProvider: () => _session?.token,
      onSessionExpired: _expire,
    );
  }

  late final ApiClient api;

  AppStatus _status = AppStatus.booting;
  AppStatus get status => _status;

  AuthSession? _session;
  AuthSession? get session => _session;

  String? _lastError;
  String? get lastError => _lastError;

  bool get isGuest => _session?.isGuest ?? false;

  /// الاسترجاع عند الإطلاق: إن وُجد توكن → renew (سياسة §1.2.1)
  Future<void> restore() async {
    final token = AppConfig.prefs.getString(AppConfig.kSessionToken);
    final role = AppConfig.prefs.getString(AppConfig.kSessionRole);
    if (token == null || token.isEmpty || role == null) {
      _status = AppStatus.loggedOut;
      notifyListeners();
      return;
    }
    _session = AuthSession(
      token: token,
      role: role,
      name: AppConfig.prefs.getString(AppConfig.kSessionName) ?? '',
      expiresAt: AppConfig.prefs.getString(AppConfig.kSessionExpires) ?? '',
    );
    final renewed = await api.tryRenew();
    if (renewed) {
      _status = AppStatus.authenticated;
      notifyListeners();
      return;
    }
    // الجلسة ميتة (401 من renew) — مسح محلي والعودة لشاشة الكود
    await _clearStored();
    _session = null;
    _status = AppStatus.loggedOut;
    notifyListeners();
  }

  /// الدخول بكود الوصول (AUTH-01) — رسائل الأخطاء الحرفية تصل للشاشة
  Future<AuthSession> login(String code) async {
    _status = AppStatus.loggingIn;
    _lastError = null;
    notifyListeners();
    try {
      final json = await api.postRaw(
        '/api/auth/validate',
        <String, dynamic>{'code': code},
      );
      final session = AuthSession.fromJson(json);
      _session = session;
      await _persist(session);
      _status = AppStatus.authenticated;
      _lastError = null;
      notifyListeners();
      return session;
    } catch (err) {
      _status = AppStatus.loggedOut;
      _lastError = err is ApiError
          ? err.message
          : 'حدث خطأ غير متوقع';
      notifyListeners();
      rethrow;
    }
  }

  /// التجديد عند العودة للمقدمة (سياسة §1.2.1 البند 1)
  Future<void> renewOnForeground() async {
    if (_session == null) return;
    final ok = await api.tryRenew();
    if (!ok) {
      _expire();
    }
  }

  /// تسجيل الخروج — يبطل كل جلسات الكود (AUTH-02) ثم مسح محلي دائمًا
  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout');
    } catch (_) {
      // ينتهي محليًا في كل الأحوال — كما في الويب
    }
    await _clearStored();
    _session = null;
    _status = AppStatus.loggedOut;
    notifyListeners();
  }

  void _expire() {
    if (_session == null && _status == AppStatus.loggedOut) return;
    _session = null;
    _status = AppStatus.loggedOut;
    notifyListeners();
    // مسح غير متزامن بلا انتظار
    _clearStored();
  }

  Future<void> _persist(AuthSession s) async {
    await AppConfig.prefs.setString(AppConfig.kSessionToken, s.token);
    await AppConfig.prefs.setString(AppConfig.kSessionRole, s.role);
    await AppConfig.prefs.setString(AppConfig.kSessionName, s.name);
    await AppConfig.prefs.setString(AppConfig.kSessionExpires, s.expiresAt);
  }

  Future<void> _clearStored() async {
    await AppConfig.prefs.remove(AppConfig.kSessionToken);
    await AppConfig.prefs.remove(AppConfig.kSessionRole);
    await AppConfig.prefs.remove(AppConfig.kSessionName);
    await AppConfig.prefs.remove(AppConfig.kSessionExpires);
  }
}

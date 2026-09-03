// ─────────────────────────────────────────────────────────────
// CONFIG — إعدادات التطبيق (عنوان الخادم + البيئة)
// API_BASE_URL عبر --dart-define أو إدخال المستخدم من شاشة الدخول
// ─────────────────────────────────────────────────────────────
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// عنوان أساسي مخبوز وقت البناء (--dart-define=API_BASE_URL=https://…)
  static const String _bakedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _kBaseUrlKey = 'cairo_base_url';

  static String? _storedBaseUrl;
  static SharedPreferences? _prefs;

  /// تهيئة التخزين — تُستدعى مرة واحدة عند الإطلاق
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _storedBaseUrl = _prefs!.getString(_kBaseUrlKey);
  }

  static SharedPreferences get prefs {
    final p = _prefs;
    if (p == null) {
      throw StateError('AppConfig.init() must be awaited before use');
    }
    return p;
  }

  /// عنوان الخادم الفعال: المخبوز أولاً وإلا المخزَّن من إدخال المستخدم
  static String get baseUrl {
    if (_bakedBaseUrl.isNotEmpty) return _bakedBaseUrl;
    return _storedBaseUrl ?? '';
  }

  static bool get hasBaseUrl => baseUrl.isNotEmpty;

  /// هل يستطيع المستخدم تغيير العنوان؟ (فقط عندما لا يوجد عنوان مخبوز)
  static bool get canEditBaseUrl => _bakedBaseUrl.isEmpty;

  static Future<void> setBaseUrl(String value) async {
    final cleaned = normalizeBaseUrl(value);
    _storedBaseUrl = cleaned;
    await prefs.setString(_kBaseUrlKey, cleaned);
  }

  /// تنظيف العنوان: إضافة https:// عند غيابه وإزالة الشرطات الختامية
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// مفاتيح تخزين الجلسة (توكن/دور/اسم/انتهاء) — وفق H3
  static const String kSessionToken = 'session_token';
  static const String kSessionRole = 'session_role';
  static const String kSessionName = 'session_name';
  static const String kSessionExpires = 'session_expires_at';

  /// Realtime — وفق العقد: socket.io على المسار "/" مع XTransformPort=3002
  static const String realtimePort = '3002';
}

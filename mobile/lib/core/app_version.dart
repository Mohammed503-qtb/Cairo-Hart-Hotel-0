// ─────────────────────────────────────────────────────────────
// APP VERSION — حارس الحد الأدنى لإصدار التطبيق (F6)
// PUB-07: GET /api/public/app-config { minAppVersion }
// الإصدار يُدمج وقت البناء عبر --dart-define=APP_VERSION=x.y.z
// (CI يستخرجه من pubspec.yaml) — الافتراضي 0.0.0 = أقدم إصدار:
// أي فرض من الخادم سيحجبه (اتجاه آمن fail-closed تجاه القيمة).
// الفحص عند الإطلاق فقط، والفشل في الوصول للنقطة = متسامح
// (fail-open: التطبيق يُكمل — أخطاء الاتصال الحقيقية تظهر عند الدخول).
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:http/http.dart' as http;

/// إصدار هذا البناء (يُدمج من pubspec.yaml في CI)
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.0.0',
);

/// صفحة إصدارات GitHub (APKs الموقّعة) — ثابتة للمستودع
const String kReleasesUrl =
    'https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-0/releases';

/// مسار النقطة العامة (بلا مصادقة — PUB-07)
const String kAppConfigPath = '/api/public/app-config';

/// مقارنة دلالية ثلاثية: -1 إذا a < b · 0 تساوي · 1 إذا a > b
/// الجزء غير الرقمي يُعامل 0 (تسامح مع تشوهات الشكل)
int compareSemver(String a, String b) {
  final pa = _parse(a);
  final pb = _parse(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] < pb[i]) return -1;
    if (pa[i] > pb[i]) return 1;
  }
  return 0;
}

List<int> _parse(String v) {
  final parts = v.trim().split('.');
  return [
    _part(parts, 0),
    _part(parts, 1),
    _part(parts, 2),
  ];
}

int _part(List<String> parts, int i) {
  if (i >= parts.length) return 0;
  return int.tryParse(parts[i].trim()) ?? 0;
}

/// هل هذا البناء بحاجة لتحديث إجباري وفق حد الخادم؟
/// فراغ/بلا قيمة = لا فرض.
bool needsUpdate(String minVersion, [String appVersion = kAppVersion]) {
  if (minVersion.trim().isEmpty) return false;
  return compareSemver(appVersion, minVersion) < 0;
}

/// جلب minAppVersion من PUB-07 — null يعني: لا قيمة/خطأ/انتهاء مهلة
/// (كل الفشلات متسامحة: الحارس لا يعرقل التشغيل عند تعذر الفحص)
Future<String?> fetchMinAppVersion(
  String baseUrl, {
  http.Client? httpClient,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final client = httpClient ?? http.Client();
  final ownsClient = httpClient == null;
  try {
    final res = await client
        .get(Uri.parse('$baseUrl$kAppConfigPath'))
        .timeout(timeout);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map && body['ok'] == true) {
      final v = body['minAppVersion'];
      if (v is String) return v;
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    if (ownsClient) client.close();
  }
}

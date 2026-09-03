// ─────────────────────────────────────────────────────────────
// API CLIENT — عميل HTTP فوق مغلف ok/fail الموحد
// + 401 → renew تلقائي → إعادة المحاولة مرة واحدة → وإلا خروج
// وفق CONTRACTS.md §1.1 + §1.2.1 (سياسة العميل المحمول)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:http/http.dart' as http;

/// خطأ API: حالة + رسالة عربية حرفية من الخادم
class ApiError implements Exception {
  ApiError(this.status, this.message);

  /// 0 = خطأ شبكة/اتصال
  final int status;
  final String message;

  bool get isNetwork => status == 0;

  @override
  String toString() => message;
}

/// 401 نهائي: الجلسة ميتة — امسح التوكن واعرض شاشة الكود
class SessionExpiredError extends ApiError {
  SessionExpiredError()
      : super(401, 'جلسة غير صالحة أو منتهية — سجّل الدخول من جديد');
}

class ApiClient {
  ApiClient({
    required this.baseUrlProvider,
    required this.tokenProvider,
    required this.onSessionExpired,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String Function() baseUrlProvider;
  final String? Function() tokenProvider;
  final void Function() onSessionExpired;
  final http.Client _http;

  Map<String, String> _headers({bool withBody = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    if (withBody) h['Content-Type'] = 'application/json';
    return h;
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool isRetry = false,
  }) async {
    http.Response res;
    try {
      final uri = Uri.parse('${baseUrlProvider()}$path');
      final headers = _headers(withBody: body != null);
      final encoded = body == null ? null : jsonEncode(body);
      res = switch (method) {
        'GET' => await _http.get(uri, headers: headers),
        'POST' => await _http.post(uri, headers: headers, body: encoded),
        'PATCH' => await _http.patch(uri, headers: headers, body: encoded),
        _ => throw StateError('unsupported method $method'),
      };
    } catch (_) {
      throw ApiError(0, 'تعذر الاتصال بالخادم — تحقق من اتصالك وعنوان الخادم');
    }

    final json = _decode(res.bodyBytes);

    // ── 401: تجديد تلقائي مرة واحدة ثم إعادة المحاولة (سياسة §1.2.1) ──
    if (res.statusCode == 401 &&
        !isRetry &&
        path != '/api/auth/validate' &&
        path != '/api/auth/renew' &&
        path != '/api/auth/logout') {
      final renewed = await tryRenew();
      if (renewed) {
        return _send(method, path, body: body, isRetry: true);
      }
      onSessionExpired();
      throw SessionExpiredError();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (json == null) {
        throw ApiError(res.statusCode, 'استجابة غير متوقعة من الخادم');
      }
      if (json['ok'] == false) {
        throw ApiError(
          res.statusCode,
          (json['error'] as String?) ?? 'حدث خطأ غير متوقع',
        );
      }
      return json;
    }

    final msg = (json?['error'] as String?) ?? 'حدث خطأ غير متوقع';
    throw ApiError(res.statusCode, msg);
  }

  /// POST /api/auth/renew — يمدّد نفس التوكن (لا يصدر جديدًا)
  Future<bool> tryRenew() async {
    final token = tokenProvider();
    if (token == null || token.isEmpty) return false;
    try {
      final uri = Uri.parse('${baseUrlProvider()}/api/auth/renew');
      final res = await _http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) return false;
      final json = _decode(res.bodyBytes);
      return json != null && json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// طلب خام بلا مغلف — يستخدمه login (validate) مع رسائل الأخطاء الحرفية
  Future<Map<String, dynamic>> postRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response res;
    try {
      final uri = Uri.parse('${baseUrlProvider()}$path');
      res = await _http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw ApiError(0, 'تعذر الاتصال بالخادم — تحقق من اتصالك وعنوان الخادم');
    }
    final json = _decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (json == null) {
        throw ApiError(res.statusCode, 'استجابة غير متوقعة من الخادم');
      }
      if (json['ok'] == false) {
        throw ApiError(
          res.statusCode,
          (json['error'] as String?) ?? 'حدث خطأ غير متوقع',
        );
      }
      return json;
    }
    throw ApiError(
      res.statusCode,
      (json?['error'] as String?) ?? 'حدث خطأ غير متوقع',
    );
  }

  static Map<String, dynamic>? _decode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}

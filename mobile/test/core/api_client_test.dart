// ─────────────────────────────────────────────────────────────
// TEST: ApiClient — مغلف ok/fail + سياسة 401→renew→retry (§1.2.1)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/api_client.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('المغلف الموحد', () {
    test('نجاح ok=true يعيد الجسم', () async {
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => 'tok-1',
        onSessionExpired: () {},
        httpClient: MockClient(
          (req) async => jsonRes({'ok': true, 'hello': 'world'}),
        ),
      );
      final res = await client.get('/api/x');
      expect(res['hello'], 'world');
    });

    test('فشل ok=false يرمي ApiError برسالة الخادم الحرفية', () async {
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => null,
        onSessionExpired: () {},
        httpClient: MockClient(
          (req) async => jsonRes(
            {'ok': false, 'error': 'كود غير صالح. تحقق من الكود وأعد المحاولة'},
            status: 400,
          ),
        ),
      );
      await expectLater(
        client.postRaw('/api/auth/validate', {'code': 'X'}),
        throwsA(
          isA<ApiError>()
              .having((e) => e.status, 'status', 400)
              .having(
                (e) => e.message,
                'message',
                'كود غير صالح. تحقق من الكود وأعد المحاولة',
              ),
        ),
      );
    });

    test('خطأ شبكة → رسالة الاتصال + status=0', () async {
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => null,
        onSessionExpired: () {},
        httpClient: MockClient((req) async => throw Exception('boom')),
      );
      try {
        await client.get('/api/x');
        fail('should throw');
      } on ApiError catch (e) {
        expect(e.isNetwork, true);
        expect(e.message, contains('تعذر الاتصال بالخادم'));
      }
    });
  });

  group('سياسة 401 (§1.2.1)', () {
    test('401 → renew ناجح → إعادة المحاولة بالنفس الطلب', () async {
      final calls = <String>[];
      var token = 'tok-old';
      var renewed = false;
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => token,
        onSessionExpired: () => fail('يجب ألا تُستدعى'),
        httpClient: MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          if (req.url.path == 'api/guest/dashboard') {
            final auth = req.headers['authorization'];
            if (renewed && auth == 'Bearer tok-old') {
              return jsonRes({'ok': true, 'data': 1});
            }
            return jsonRes(
              {
                'ok': false,
                'error': 'جلسة غير صالحة أو منتهية — سجّل الدخول من جديد',
              },
              status: 401,
            );
          }
          if (req.url.path == 'api/auth/renew') {
            renewed = true;
            return jsonRes({
              'ok': true,
              'expiresAt': '2026-09-02T22:00:00.000Z',
            });
          }
          return jsonRes({'ok': false}, status: 404);
        }),
      );
      final res = await client.get('/api/guest/dashboard');
      expect(res['data'], 1);
      // الطلب نفسه أعيد مرة بعد renew (مرتان للـ dashboard)
      expect(calls.where((c) => c.contains('dashboard')).length, 2);
      expect(calls.where((c) => c.contains('renew')).length, 1);
      expect(token, 'tok-old'); // نفس التوكن (H3: renew لا يصدر جديدًا)
    });

    test('401 وrenew يفشل → SessionExpiredError + onSessionExpired', () async {
      var expiredCalled = false;
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => 'tok-dead',
        onSessionExpired: () => expiredCalled = true,
        httpClient: MockClient((req) async {
          if (req.url.path == 'api/auth/renew') {
            return jsonRes(
              {
                'ok': false,
                'error': 'جلسة غير صالحة أو منتهية — سجّل الدخول من جديد',
              },
              status: 401,
            );
          }
          return jsonRes({'ok': false, 'error': 'x'}, status: 401);
        }),
      );
      await expectLater(
        client.get('/api/guest/bill'),
        throwsA(isA<SessionExpiredError>()),
      );
      expect(expiredCalled, true);
    });

    test('401 على auth/validate نفسه لا يمس التدفق (رسالة حرفية)', () async {
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => null,
        onSessionExpired: () => fail('لا تجديد لمسار الدخول'),
        httpClient: MockClient(
          (req) async => jsonRes(
            {'ok': false, 'error': 'انتهت إقامتك ولم يعد بإمكانك استخدام هذا الكود'},
            status: 400,
          ),
        ),
      );
      await expectLater(
        client.postRaw('/api/auth/validate', {'code': 'H000000AA'}),
        throwsA(
          isA<ApiError>().having(
            (e) => e.message,
            'message',
            'انتهت إقامتك ولم يعد بإمكانك استخدام هذا الكود',
          ),
        ),
      );
    });

    test('429 يمر كما هو (ليس خروجًا)', () async {
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => 't',
        onSessionExpired: () => fail('429 ليس خروجًا'),
        httpClient: MockClient(
          (req) async => jsonRes(
            {'ok': false, 'error': 'محاولات كثيرة جدًا. أعد المحاولة بعد 42 ثانية'},
            status: 429,
          ),
        ),
      );
      await expectLater(
        client.post('/api/guest/requests', body: {'x': 1}),
        throwsA(isA<ApiError>().having((e) => e.status, 'status', 429)),
      );
    });
  });

  group('الطلبات', () {
    test('POST يرسل JSON بالترويسة الصحيحة والBearer', () async {
      String? ctype;
      String? auth;
      Object? sentBody;
      final client = ApiClient(
        baseUrlProvider: () => 'https://hotel.example.com',
        tokenProvider: () => 'tok-9',
        onSessionExpired: () {},
        httpClient: MockClient((req) async {
          ctype = req.headers['content-type'];
          auth = req.headers['authorization'];
          sentBody = jsonDecode(utf8.decode(req.bodyBytes));
          return jsonRes({'ok': true});
        }),
      );
      await client.post('/api/guest/messages', body: {'body': 'مرحبًا'});
      expect(ctype, 'application/json');
      expect(auth, 'Bearer tok-9');
      expect(sentBody, {'body': 'مرحبًا'});
    });
  });
}

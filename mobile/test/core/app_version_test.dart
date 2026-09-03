// ─────────────────────────────────────────────────────────────
// TEST: app_version — مقارنة دلالية + قرار التحديث + جلب PUB-07
// (F6-minAppVersion · Task 18)
// ─────────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cairo_heart_hotel/core/app_version.dart';

http.Response jsonRes(Object body, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('compareSemver', () {
    test('أصغر/أكبر/مساوٍ بالمكونات', () {
      expect(compareSemver('1.0.0', '1.0.0'), 0);
      expect(compareSemver('1.0.0', '1.0.1'), -1);
      expect(compareSemver('1.1.0', '1.0.9'), 1);
      expect(compareSemver('2.0.0', '10.0.0'), -1); // رقمي لا معجمي
      expect(compareSemver('1.10.0', '1.9.0'), 1); // 10 > 9
      expect(compareSemver('0.0.1', '0.0.2'), -1);
    });

    test('أشكال مشوهة تُعامل 0 (تسامح) — لا رمي أبدًا', () {
      expect(compareSemver('abc', '0.0.0'), 0);
      expect(compareSemver('', '0.0.0'), 0);
      expect(compareSemver('1', '1.0.0'), 0);
      expect(compareSemver('1.2', '1.2.0'), 0);
      expect(compareSemver(' 1.2.3 ', '1.2.3'), 0);
    });
  });

  group('needsUpdate', () {
    test('فراغ أو بلا قيمة = لا فرض أبدًا', () {
      expect(needsUpdate('', '0.0.0'), isFalse);
      expect(needsUpdate('   ', '0.0.0'), isFalse);
    });

    test('إصدار أقل من الحد = تحديث مطلوب', () {
      expect(needsUpdate('1.2.0', '1.1.9'), isTrue);
      expect(needsUpdate('2.0.0', '1.9.9'), isTrue);
    });

    test('مساوٍ أو أعلى = لا تحديث', () {
      expect(needsUpdate('1.2.0', '1.2.0'), isFalse);
      expect(needsUpdate('1.2.0', '1.2.1'), isFalse);
      expect(needsUpdate('1.2.0', '2.0.0'), isFalse);
    });

    test('الافتراض 0.0.0: أي حد غير فارغ يحجب (اتجاه آمن fail-closed)', () {
      expect(needsUpdate('1.0.0', kAppVersion), isTrue);
    });
  });

  group('fetchMinAppVersion (PUB-07)', () {
    test('نجاح: يعيد القيمة من جسم ok', () async {
      final v = await fetchMinAppVersion(
        'https://hotel.example.com',
        httpClient: MockClient(
          (req) async => jsonRes({'ok': true, 'minAppVersion': '1.2.3'}),
        ),
      );
      expect(v, '1.2.3');
    });

    test('الطلب يذهب للمسار الصحيح بلا توكن', () async {
      Uri? captured;
      final v = await fetchMinAppVersion(
        'https://hotel.example.com',
        httpClient: MockClient((req) async {
          captured = req.url;
          return jsonRes({'ok': true, 'minAppVersion': ''});
        }),
      );
      expect(v, '');
      expect(captured!.path, kAppConfigPath);
    });

    test('فشل متسامح: 500 / ok=false / جسم غير JSON → null', () async {
      for (final res in [
        jsonRes({'ok': false, 'error': 'x'}, status: 500),
        jsonRes({'ok': false, 'error': 'x'}),
        http.Response.bytes(utf8.encode('not json'), 200),
      ]) {
        final v = await fetchMinAppVersion(
          'https://hotel.example.com',
          httpClient: MockClient((req) async => res),
        );
        expect(v, isNull);
      }
    });

    test('خطأ شبكة → null (لا رمي)', () async {
      final v = await fetchMinAppVersion(
        'https://hotel.example.com',
        httpClient: MockClient(
          (req) async => throw Exception('network down'),
        ),
      );
      expect(v, isNull);
    });
  });
}

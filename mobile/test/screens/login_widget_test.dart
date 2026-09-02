// ─────────────────────────────────────────────────────────────
// TEST: شاشة الدخول — عرض أساسي + تطبيع الكود (نقل code-login.tsx)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cairo_heart_hotel/config.dart';
import 'package:cairo_heart_hotel/screens/login_screen.dart';
import 'package:cairo_heart_hotel/state/session.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppConfig.init();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(session: SessionController())),
    );
  }

  testWidgets('تعرض العنوان وحقلي الكود والزر', (tester) async {
    await pumpLogin(tester);
    expect(find.text('فندق قلب القاهرة'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    expect(find.text('أدخل كود الدخول'), findsOneWidget);
  });

  testWidgets('زر الدخول معطّل مع كود فارغ', (tester) async {
    await pumpLogin(tester);
    final button = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(button.enabled, isFalse);
  });

  testWidgets('إعدادات الخادم تظهر تلقائيًا عند غياب العنوان المخبوز',
      (tester) async {
    // API_BASE_URL غير مخبوز في الاختبار → الإعدادات مفتوحة
    await pumpLogin(tester);
    expect(find.text('عنوان الخادم'), findsOneWidget);
  });
}

// ─────────────────────────────────────────────────────────────
// TEST: PrivacyScreen — الخصوصية وحول التطبيق (F8 — Task 24-f)
// العرض الكامل: الإصدار + أقسام السياسة الستة + سطر المرجع
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/core/app_version.dart';
import 'package:cairo_heart_hotel/screens/shared/privacy_screen.dart';
import 'package:cairo_heart_hotel/ui/theme.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: buildLightTheme(),
      locale: const Locale('ar'),
      home: child,
    );

void main() {
  testWidgets('تعرض العنوان والإصدار واسم الفندق', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyScreen()));

    expect(find.text('الخصوصية وحول التطبيق'), findsOneWidget);
    expect(find.text('فندق قلب القاهرة — عدن'), findsOneWidget);
    expect(find.text('تطبيق الضيف — الإصدار $kAppVersion'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsWidgets);
  });

  testWidgets('تعرض أقسام السياسة الستة كاملة (مرآة v1.0)', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyScreen()));

    const sections = [
      'البيانات التي نجمعها',
      'كيف نستخدمها',
      'المشاركة مع الأطراف',
      'الاحتفاظ',
      'حقوقك',
      'الأمان',
    ];
    for (final s in sections) {
      expect(find.text(s), findsOneWidget, reason: 'قسم مفقود: $s');
    }

    // عينات جوهرية من النص — لا يختفي بند مهم صامتًا
    expect(find.textContaining('لا يُخزَّن أبدًا'), findsOneWidget);
    expect(find.textContaining('لا معرّفات إعلانات'), findsOneWidget);
    expect(find.textContaining('الدفع نقدي في الفندق'), findsOneWidget);
    expect(find.textContaining('يموت حتمًا عند إتمام الخروج'), findsOneWidget);
    expect(find.textContaining('إذن الإنترنت فقط'), findsOneWidget);
  });

  testWidgets('سطر المرجع والإصدار التاريخي للسياسة ظاهران', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyScreen()));

    expect(find.text('سياسة الخصوصية — الإصدار 1.0 (2026-09-05)'), findsOneWidget);
    expect(find.textContaining('النسخة العربية هي المرجع المعتمد'), findsOneWidget);
  });

  testWidgets('قابل للتمرير كاملًا (ListView — بلا قصّ في الشاشات القصيرة)', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyScreen()));

    // آخر عنصر نصي في الشاشة يجب أن يصبح مرئيًا بعد التمرير
    await tester.ensureVisible(find.textContaining('النسخة العربية هي المرجع المعتمد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('النسخة العربية هي المرجع المعتمد'), findsOneWidget);
  });
}

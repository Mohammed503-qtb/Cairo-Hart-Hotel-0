// ─────────────────────────────────────────────────────────────
// TEST: UpdateRequiredScreen — شاشة حجب التحديث (F6)
// العرض + زر إعادة المحاولة (نسخ الرابط يعتمد قناة منصة — يُغطى يدويًا)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/core/app_version.dart';
import 'package:cairo_heart_hotel/screens/update_required_screen.dart';
import 'package:cairo_heart_hotel/ui/theme.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: buildLightTheme(),
      locale: const Locale('ar'),
      home: child,
    );

void main() {
  testWidgets('تعرض العنوان والحد المطلوب ورابط الإصدارات', (tester) async {
    await tester.pumpWidget(wrap(
      UpdateRequiredScreen(minVersion: '2.0.0', onRetry: () {}),
    ));

    expect(find.text('يتوفر تحديث مطلوب'), findsOneWidget);
    expect(find.text('الحد الأدنى المطلوب'), findsOneWidget);
    expect(find.text('2.0.0'), findsOneWidget);
    expect(find.text('إصدارك الحالي'), findsOneWidget);
    expect(find.text(kReleasesUrl), findsOneWidget);
    expect(find.text('نسخ رابط الإصدارات'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('زر «إعادة المحاولة» يستدعي onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(wrap(
      UpdateRequiredScreen(minVersion: '2.0.0', onRetry: () => retried++),
    ));

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('لا يوجد أي مسار خروج آخر من الشاشة (حجب كامل)', (tester) async {
    await tester.pumpWidget(wrap(
      UpdateRequiredScreen(minVersion: '9.9.9', onRetry: () {}),
    ));
    // الأزرار الوحيدة: نسخ الرابط + إعادة المحاولة — لا «تخطٍ» ولا رجوع
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    expect(find.text('تخطي'), findsNothing);
  });
}

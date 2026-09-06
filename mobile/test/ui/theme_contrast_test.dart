// ─────────────────────────────────────────────────────────────
// TEST: تباين الثيم (WCAG) — دليل فعلي بأرقام
// يصيّر الرقائق/البطاقات الحقيقية في الوضعين الفاتح والداكن
// ويقيس نسبة التباين بين لون النص ولون الخلفية الفعلية
// (المكافئ: فحص dark:text-* في globals.css الخاص بالموقع)
// ─────────────────────────────────────────────────────────────
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/screens/reception/reception_bits.dart';
import 'package:cairo_heart_hotel/ui/theme.dart';
import 'package:cairo_heart_hotel/ui/widgets.dart';

/// الإضاءة النسبية WCAG (sRGB خطي)
double _luminance(Color c) {
  double chan(int v) {
    final s = v / 255.0;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * chan(c.red) + 0.7152 * chan(c.green) + 0.0722 * chan(c.blue);
}

/// نسبة التباين WCAG بين لونين
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// يركّب لونًا شفافًا فوق قاعدة (كما يُرسم فعليًا في Flutter)
Color composite(Color over, Color base) {
  final a = over.alpha / 255.0;
  final inv = 1 - a;
  return Color.fromARGB(
    255,
    (over.red * a + base.red * inv).round(),
    (over.green * a + base.green * inv).round(),
    (over.blue * a + base.blue * inv).round(),
  );
}

/// القاعدة الواقعية التي تجلس فوقها الرقائق: بطاقة داكنة/فاتحة
const Color _darkCardBase = Color(0xFF16233A); // dark surface (AppCard)
const Color _lightCardBase = Color(0xFFFFFFFF); // light surface

/// يمشي شجرة العناصر صعودًا حتى أول خلفية مرسومة
Color? _bgOf(Element el) {
  Color? found;
  el.visitAncestorElements((node) {
    final w = node.widget;
    if (w is Container) {
      final d = w.decoration;
      if (d is BoxDecoration && d.color != null) {
        found = d.color;
        return false;
      }
      if (w.color != null) {
        found = w.color;
        return false;
      }
    }
    if (w is ColoredBox) {
      found = w.color;
      return false;
    }
    if (w is Material && w.color != null) {
      found = w.color;
      return false;
    }
    return true;
  });
  return found;
}

Color? _textColorOf(Element el) {
  final w = el.widget;
  if (w is Text) {
    return w.style?.color ??
        (w.style == null ? DefaultTextStyle.of(el).style.color : null);
  }
  return null;
}

Future<void> _pump(
  WidgetTester tester,
  Brightness brightness,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ar'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// قياس تباين شريحة StatusChip من قيمها المُصيَّرة فعليًا
/// (الخلفية الشفافة تُركَّب فوق قاعدة البطاقة كالرسم الحقيقي)
(StatusChip, double) _measureChip(
  WidgetTester tester,
  Brightness brightness,
) {
  final chip = tester.widget<StatusChip>(find.byType(StatusChip));
  final base =
      brightness == Brightness.dark ? _darkCardBase : _lightCardBase;
  final bg = composite(chip.background, base);
  final ratio = contrast(chip.foreground, bg);
  return (chip, ratio);
}

void main() {
  final modes = <(String, Brightness)>[
    ('الوضع الفاتح', Brightness.light),
    ('الوضع الداكن', Brightness.dark),
  ];

  for (final (modeName, brightness) in modes) {
    // العتبات: الفاتح 3.0 (ويب الموقع نفسه 3.0-4.9 في الفاتح — التكافؤ
    // هو الهدف، وكل ما دون 3.0 مكسور مثل CLEANING 1.86) · الداكن 4.0
    // (ويب الموقع في الداكن 4-10 بألوانه الفاتحة — الرقائق تقاس بعد
    // تركيب الصبغة الشفافة 15% فوق بطاقة داكنة #16233A كالرسم الحقيقي)
    final textBar = brightness == Brightness.dark ? 4.0 : 3.0;

    group('تباين الرقائق — $modeName', () {
      testWidgets('stayStatus: ACTIVE', (tester) async {
        await _pump(
          tester,
          brightness,
          Builder(builder: (ctx) => StatusChip.stayStatus(ctx, 'ACTIVE')),
        );
        final (chip, ratio) = _measureChip(tester, brightness);
        expect(
          ratio,
          greaterThan(textBar),
          reason:
              'stayStatus ACTIVE في $modeName: تباين ${ratio.toStringAsFixed(2)}:1 '
              '(نص ${chip.foreground} على ${chip.background}) — أقل من $textBar:1',
        );
      });

      testWidgets('paymentStatus: PAID/PARTIALLY_PAID', (tester) async {
        for (final status in ['PAID', 'PARTIALLY_PAID']) {
          await _pump(
            tester,
            brightness,
            Builder(
              builder: (ctx) => StatusChip.paymentStatus(ctx, status),
            ),
          );
          final (chip, ratio) = _measureChip(tester, brightness);
          expect(
            ratio,
            greaterThan(textBar),
            reason:
                'paymentStatus $status في $modeName: ${ratio.toStringAsFixed(2)}:1 '
                '(نص ${chip.foreground} على ${chip.background})',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('reservationStatus: كل الحالات الملوّنة', (tester) async {
        for (final status in [
          'PENDING',
          'CONFIRMED',
          'CHECKED_IN',
          'COMPLETED',
          'NO_SHOW',
        ]) {
          await _pump(
            tester,
            brightness,
            Builder(
              builder: (ctx) => StatusChip.reservationStatus(ctx, status),
            ),
          );
          final (chip, ratio) = _measureChip(tester, brightness);
          expect(
            ratio,
            greaterThan(textBar),
            reason:
                'reservationStatus $status في $modeName: ${ratio.toStringAsFixed(2)}:1 '
                '(نص ${chip.foreground} على ${chip.background})',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('extensionStatus: PENDING/APPROVED/REJECTED', (tester) async {
        for (final status in ['PENDING', 'APPROVED', 'REJECTED']) {
          await _pump(
            tester,
            brightness,
            Builder(
              builder: (ctx) => StatusChip.extensionStatus(ctx, status),
            ),
          );
          final (chip, ratio) = _measureChip(tester, brightness);
          expect(
            ratio,
            greaterThan(textBar),
            reason:
                'extensionStatus $status في $modeName: ${ratio.toStringAsFixed(2)}:1 '
                '(نص ${chip.foreground} على ${chip.background})',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('roomStatus: كل الحالات الملوّنة', (tester) async {
        for (final status in [
          'AVAILABLE',
          'OCCUPIED',
          'RESERVED',
          'CLEANING',
          'DIRTY',
        ]) {
          await _pump(
            tester,
            brightness,
            Builder(builder: (ctx) => StatusChip.roomStatus(ctx, status)),
          );
          final (chip, ratio) = _measureChip(tester, brightness);
          expect(
            ratio,
            greaterThan(textBar),
            reason:
                'roomStatus $status في $modeName: ${ratio.toStringAsFixed(2)}:1 '
                '(نص ${chip.foreground} على ${chip.background})',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('requestStatus: كل الحالات الملوّنة', (tester) async {
        for (final status in [
          'NEW',
          'ACKNOWLEDGED',
          'ASSIGNED',
          'IN_PROGRESS',
          'WAITING',
          'COMPLETED',
          'REJECTED',
        ]) {
          await _pump(
            tester,
            brightness,
            Builder(builder: (ctx) => StatusChip.requestStatus(ctx, status)),
          );
          final (chip, ratio) = _measureChip(tester, brightness);
          expect(
            ratio,
            greaterThan(textBar),
            reason:
                'requestStatus $status في $modeName: ${ratio.toStringAsFixed(2)}:1 '
                '(نص ${chip.foreground} على ${chip.background})',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    });

    group('تباين KpiCard — $modeName', () {
      // قيمة KPI: 26px w900 → نص كبير: عتبة 3.0
      for (final tone in KpiTone.values) {
        testWidgets('tone ${tone.name}', (tester) async {
          await _pump(
            tester,
            brightness,
            KpiCard(icon: Icons.bed, label: 'المقيمون', value: 5, tone: tone),
          );
          final valueEl = find.byType(Text).evaluate().firstWhere(
                (el) => ((el.widget as Text).style?.fontSize ?? 14) >= 20,
                orElse: () => throw StateError('نص قيمة KPI غير موجود'),
              );
          final fg = _textColorOf(valueEl);
          final bg = _bgOf(valueEl);
          expect(fg, isNotNull, reason: 'لون قيمة KPI غير قابل للاستخراج');
          expect(bg, isNotNull, reason: 'خلفية KPI غير قابلة للاستخراج');
          final ratio = contrast(fg!, bg!);
          expect(
            ratio,
            greaterThan(3.0),
            reason:
                'KpiCard tone ${tone.name} في $modeName: قيمة $fg على $bg '
                '= ${ratio.toStringAsFixed(2)}:1 < 3:1',
          );
        });
      }
    });

    group('تباين MoneyText — $modeName', () {
      for (final (cents, label) in [
        (50000, 'مستحق danger'),
        (-20000, 'سالب warning'),
        (0, 'صفر success'),
      ]) {
        testWidgets('colored $label', (tester) async {
          await _pump(tester, brightness, MoneyText(cents, colored: true));
          final el = find.byType(Text).evaluate().single;
          final fg = _textColorOf(el);
          final bg = _bgOf(el) ??
              (brightness == Brightness.dark
                  ? const Color(0xFF0E1726)
                  : const Color(0xFFF6F8FB));
          final ratio = contrast(fg!, bg);
          expect(
            ratio,
            greaterThan(3.0),
            reason:
                'MoneyText($cents) في $modeName: $fg على $bg = '
                '${ratio.toStringAsFixed(2)}:1 < 3:1',
          );
        });
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TEST: format — نفس مخرجات src/lib/format.ts (H2-a جمّدها)
// ─────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_heart_hotel/core/format.dart';

void main() {
  group('formatMoney', () {
    test('دولار بلا كسور', () {
      expect(formatMoney(27600), r'$276.00');
    });

    test('دولار بكسور', () {
      expect(formatMoney(55200), r'$552.00');
      expect(formatMoney(6505), r'$65.05');
    });

    test('فواصل الآلاف', () {
      expect(formatMoney(123450), r'$1,234.50');
      expect(formatMoney(12345000), r'$123,450.00');
      expect(formatMoney(100), r'$1.00');
    });

    test('صفر وسالب (مطابقة الويب: $-5.00)', () {
      expect(formatMoney(0), r'$0.00');
      expect(formatMoney(-500), r'$-5.00');
    });

    test('عملة أخرى', () {
      expect(formatMoney(6500, currency: 'YER'), '65.00 YER');
    });
  });

  group('formatDateAr / الوقت', () {
    test('تاريخ عربي', () {
      expect(formatDateAr('2026-09-10T00:00:00.000Z'), contains('سبتمبر'));
      expect(formatDateAr('2026-09-10T00:00:00.000Z'), startsWith('10 '));
    });

    test('وقت 12 ساعة ص/م', () {
      final iso = DateTime(2026, 9, 1, 14, 30).toIso8601String();
      expect(formatTimeAr(iso), '2:30 م');
      final isoAm = DateTime(2026, 9, 1, 2, 5).toIso8601String();
      expect(formatTimeAr(isoAm), '2:05 ص');
    });

    test('فراغ وnull آمن', () {
      expect(formatDateAr(null), '—');
      expect(formatTimeAr(''), '—');
    });
  });

  group('timeAgoAr', () {
    final now = DateTime(2026, 9, 2, 12, 0, 0);

    test('الآن', () {
      expect(timeAgoAr(now.toIso8601String(), now: now), 'الآن');
    });

    test('دقائق وساعات وأيام', () {
      expect(
        timeAgoAr(now.subtract(const Duration(minutes: 5)).toIso8601String(),
            now: now),
        'منذ 5 دقيقة',
      );
      expect(
        timeAgoAr(now.subtract(const Duration(hours: 3)).toIso8601String(),
            now: now),
        'منذ 3 ساعة',
      );
      expect(
        timeAgoAr(now.subtract(const Duration(days: 2)).toIso8601String(),
            now: now),
        'منذ 2 يوم',
      );
    });
  });

  group('التسميات العربية', () {
    test('حالات الطلب (تبدأ NEW — MACHINE=§12.3)', () {
      expect(label(requestStatusLabels, 'NEW'), 'جديد');
      expect(label(requestStatusLabels, 'IN_PROGRESS'), 'قيد التنفيذ');
      expect(label(requestStatusLabels, 'COMPLETED'), 'مكتمل');
    });

    test('حالات الدفع والإقامة', () {
      expect(label(paymentStatusLabels, 'PARTIALLY_PAID'), 'مدفوع جزئيًا');
      expect(label(stayStatusLabels, 'CHECKOUT_REQUESTED'), 'طُلب الخروج');
    });

    test('مجهول يعيد البديل', () {
      expect(label(requestStatusLabels, 'UNKNOWN_X', fallback: '؟'), '؟');
    });
  });

  group('أدوات التاريخ', () {
    test('todayInputValue صيغة YYYY-MM-DD', () {
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(todayInputValue()), true);
    });

    test('addDaysInput', () {
      expect(addDaysInput('2026-09-02', 3), '2026-09-05');
    });

    test('nightsBetween', () {
      expect(nightsBetween('2026-09-01', '2026-09-04'), 3);
    });
  });
}

// ─────────────────────────────────────────────────────────────
// RECEPTION BITS — عناصر عرض مشتركة لشاشات الاستقبال (F4)
// منقولة حرفيًا من src/components/reception/bits.tsx + عناصر الويب
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/format.dart' as fmt;
import '../../ui/theme.dart';

/// شارة مونوسبيس LTR للمراجع (HTL-… / ST-… / REQ-…) — RefCode في الويب
class RefCodeText extends StatelessWidget {
  const RefCodeText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// مبلغ ملوّن: أحمر للرصيد المستحق — أخضر للصفر — أصفر للسالب — MoneyAmount
class MoneyText extends StatelessWidget {
  const MoneyText(this.cents, {super.key, this.colored = false});

  final int cents;
  final bool colored;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (colored) {
      color = cents > 0
          ? AppColors.danger
          : cents < 0
              ? AppColors.warning
              : AppColors.success;
    }
    return Text(
      fmt.formatMoney(cents),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: 14,
        fontWeight: colored ? FontWeight.w800 : FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      ),
    );
  }
}

/// صندوق معلومة (تسمية فوق قيمة) — InfoBox في الويب
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// بطاقة KPI قابلة للنقر (لوحة التحكم) — KpiCard في الويب
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.onTap,
    this.tone = KpiTone.primary,
  });

  final IconData icon;
  final String label;
  final int value;
  final String? sub;
  final VoidCallback? onTap;
  final KpiTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (tone) {
      KpiTone.primary => (
          scheme.primary,
          scheme.primary.withValues(alpha: 0.08),
        ),
      KpiTone.coral => (
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.08),
        ),
      KpiTone.success => (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.08),
        ),
      KpiTone.warning => (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.10),
        ),
      KpiTone.urgent => (
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.10),
        ),
    };
    final body = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: body,
      ),
    );
  }
}

enum KpiTone { primary, coral, success, warning, urgent }

/// صف حقل التاريخ مع منتقي — شريط التاريخ في الوصولين/المغادرين
class DateFieldRow extends StatelessWidget {
  const DateFieldRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'التاريخ:',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final initial = DateTime.tryParse('${value}T00:00:00') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    final m = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    onChanged('${picked.year}-$m-$day');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        ActionChip(
          avatar: const Icon(Icons.calendar_month_rounded, size: 16),
          label: Text(value),
          onPressed: () => _pick(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fmt.formatDateWithDayAr(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// رأس قسم مع أيقونة اختيارية وعنصر إجراء — SectionTitle في الويب
class ReceptionSectionTitle extends StatelessWidget {
  const ReceptionSectionTitle(
    this.text, {
    super.key,
    this.icon,
    this.iconColor,
    this.action,
  });

  final String text;
  final IconData? icon;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ───────────── مساعدات واتساب (قرار W0: wa.me بلا مزود) ─────────────

/// تنسيق رقم هاتف لمشاركة واتساب — normalizePhone في الويب
String normalizePhone(String phone) => phone.replaceAll(RegExp(r'[^\d]'), '');

/// رابط wa.me لرسالة كود الضيف عند الوصول — نفس نص الويب حرفيًا
String? buildWhatsappCheckInUrl({
  required String phone,
  required String roomNumber,
  required String guestCode,
}) {
  final digits = normalizePhone(phone);
  if (digits.isEmpty) return null;
  final text =
      'أهلًا بك في فندق قلب القاهرة ❤️\nغرفتك: $roomNumber\nكود تطبيق الفندق: $guestCode — افتح التطبيق وأدخل الكود';
  return 'https://wa.me/$digits?text=${Uri.encodeComponent(text)}';
}

/// هوياكل تحميل (مقابل Skeleton في الويب)
Widget loadingBlocks(int count, {double height = 120}) {
  return Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        _placeholderBox(height),
        const SizedBox(height: 10),
      ],
    ],
  );
}

Widget _placeholderBox(double height) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0x11000000),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

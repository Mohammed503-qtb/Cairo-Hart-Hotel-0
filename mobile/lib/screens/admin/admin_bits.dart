// ─────────────────────────────────────────────────────────────
// ADMIN BITS — عناصر عرض مشتركة لشاشات الإدارة (F5)
// منقولة من src/components/admin/shared.tsx + عناصر الويب
// + إعادة تصدير عناصر الاستقبال العامة (مصدر واحد للحقيقة)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../ui/theme.dart';
import '../reception/reception_bits.dart'
    show KpiCard, KpiTone, RefCodeText, MoneyText, InfoBox, loadingBlocks;

export '../reception/reception_bits.dart'
    show KpiCard, KpiTone, RefCodeText, MoneyText, InfoBox, loadingBlocks;

/// رأس قسم الإدارة — SectionTitle في الويب (بنفس سلوك الاستقبال)
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(
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

/// عرض الكود الخام المولَّد (A-27 — يُعاد مرة واحدة فقط):
/// كبير monospace بحدود ذهبية + تحذير «انسخه الآن» + زر نسخ —
/// نفس معالجة الويب حرفيًا (staff-codes.tsx)
class RawCodeBox extends StatelessWidget {
  const RawCodeBox({super.key, required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        const SnackBar(content: Text('تم نسخ الكود إلى الحافظة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            code,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_rounded,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'انسخه الآن — لن يظهر مرة أخرى',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('نسخ الكود'),
          ),
        ],
      ),
    );
  }
}

/// شريط أعمدة (مقابل BarChart في recharts بالويب):
/// قيم مع تسميات أعلى الأعمدة — يُستخدم في لوحة التحكم والتقارير
class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.bars,
    this.height = 160,
    this.barColor,
    this.valueFormatter,
  });

  /// (التسمية، القيمة) — مرتّبة كما هي
  final List<(String, double)> bars;
  final double height;
  final Color? barColor;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = barColor ?? scheme.primary;
    final maxVal = bars.fold<double>(0, (a, b) => a > b.$2 ? a : b.$2);
    return SizedBox(
      height: height,
      child: bars.isEmpty
          ? Center(
              child: Text(
                'لا توجد بيانات',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final (label, value) = bars[i];
                        final h =
                            maxVal <= 0 ? 2.0 : (value / maxVal) * (height - 26);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (valueFormatter != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  valueFormatter!(value),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            Container(
                              width: double.infinity,
                              height: h,
                              decoration: BoxDecoration(
                                color: value > 0
                                    ? color
                                    : color.withValues(alpha: 0.25),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

/// صندوق تحذير/تنبيه صغير (مقابل التنبيهات في dashboard.tsx)
class AdminAlertBox extends StatelessWidget {
  const AdminAlertBox({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.warning,
    this.background = AppColors.warningContainer,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة إشعار الإدارة (جرس الإدارة — A-34، بادئ «إدارة/استقبال»)
class AdminNotificationCard extends StatelessWidget {
  const AdminNotificationCard({super.key, required this.item});

  final AdminNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = item.audience == 'ADMIN';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? scheme.primary.withValues(alpha: 0.12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAdmin ? 'إدارة' : 'استقبال',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isAdmin ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.body,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            fmt.timeAgoAr(item.createdAt),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

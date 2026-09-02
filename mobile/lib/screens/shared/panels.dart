// ─────────────────────────────────────────────────────────────
// PANELS — لوحات مشتركة صغيرة (نقل أجزاء bits.tsx)
// GoldBanner + BalanceBanner + DashedNote (ملاحظة الفراغ المتقطعة)
// + SkeletonBox (هيكل تحميل) — كل نصوص الويب منقولة حرفيًا
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../ui/theme.dart';

/// لافتة بحالة (نقل Banner من bits.tsx — نغمتا gold/warning فقط)
class _PanelBanner extends StatelessWidget {
  const _PanelBanner({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.title,
    this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// لافتة ذهبية إخبارية (نقل GoldBanner — أيقونة Info وحدود gold/40)
class GoldBanner extends StatelessWidget {
  const GoldBanner({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return _PanelBanner(
      icon: Icons.info_outline,
      iconColor: AppColors.gold,
      borderColor: const Color(0x66D4A843), // gold/40
      backgroundColor: const Color(0x1AD4A843), // gold/10
      title: title,
      body: body,
    );
  }
}

/// لافتة الرصيد المستحق (نقل BalanceBanner — نغمة تحذيرية)
class BalanceBanner extends StatelessWidget {
  const BalanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PanelBanner(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      borderColor: Color(0x66B25E09), // warning/40
      backgroundColor: Color(0x1AB25E09), // warning/10
      title: 'لديك رصيد مستحق على الإقامة',
      body: 'يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة.',
    );
  }
}

/// ملاحظة فراغ بحدود متقطعة (مقابل p بنمط border-dashed في الويب)
class DashedNote extends StatelessWidget {
  const DashedNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _DashedBorderPainter(color: scheme.outline, radius: 15),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.7,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// رسّام حدود متقطعة حول مستطيل دائري الزوايا
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, this.radius = 15});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// هيكل تحميل (مقابل Skeleton في الويب) — صندوق رمادي دائري الزوايا
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS — مكونات مشتركة لكل شاشات التطبيق (مقابل مكونات الويب)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import 'theme.dart';

/// بطاقة موحدة (مقابل Card في الويب)
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color ?? theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: border ?? BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// عنوان قسم
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

/// شريحة حالة ملونة (مقابل Badge في الويب)
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  /// زوج (نص، خلفية) المتطابق مع الويب حرفيًا في الوضعين:
  /// الفاتح → النغمة الغامقة فوق الحاوية الفاتحة الصلبة
  /// الداكن → النغمة الفاتحة فوق صبغة 15% منها (bg-X/15 في
  /// dark:text-X بالموقع — توكنات #4ADE80/#FBBF24/#F87171/#8FB3E3)
  static (Color, Color) _chip(
    BuildContext context,
    Color lightFg,
    Color lightBg,
    Color darkToken,
  ) {
    return Theme.of(context).colorScheme.brightness == Brightness.dark
        ? (darkToken, AppColors.darkTint(darkToken))
        : (lightFg, lightBg);
  }

  /// حالات طلب الخدمة (نفس ألوان الويب المعنوية)
  factory StatusChip.requestStatus(BuildContext context, String status) {
    final c = requestStatusChipColors(context, status);
    return StatusChip(
      label: fmt.label(fmt.requestStatusLabels, status),
      foreground: c.$1,
      background: c.$2,
    );
  }

  factory StatusChip.stayStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final pair = switch (status) {
      'ACTIVE' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'CHECKOUT_REQUESTED' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: fmt.label(fmt.stayStatusLabels, status),
      foreground: pair.$1,
      background: pair.$2,
    );
  }

  factory StatusChip.paymentStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final pair = switch (status) {
      'PAID' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'PARTIALLY_PAID' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'UNPAID' => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: fmt.label(fmt.paymentStatusLabels, status),
      foreground: pair.$1,
      background: pair.$2,
    );
  }

  factory StatusChip.reservationStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final pair = switch (status) {
      'PENDING' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'CONFIRMED' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'CHECKED_IN' => _chip(
          context, AppColors.info, AppColors.infoContainer, AppColors.infoDark),
      'COMPLETED' => _chip(
          context, AppColors.info, AppColors.infoContainer, AppColors.infoDark),
      'NO_SHOW' => _chip(
          context, AppColors.danger, AppColors.dangerContainer, AppColors.dangerDark),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: fmt.label(fmt.reservationStatusLabels, status),
      foreground: pair.$1,
      background: pair.$2,
    );
  }

  factory StatusChip.roomStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final pair = switch (status) {
      'AVAILABLE' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'OCCUPIED' => _chip(
          context, AppColors.danger, AppColors.dangerContainer, AppColors.dangerDark),
      'RESERVED' => _chip(
          context, AppColors.info, AppColors.infoContainer, AppColors.infoDark),
      // الويب: text-[#8a6d1f] فوق bg-gold/15 · الداكن: dark:text-gold
      'CLEANING' => _chip(
          context, AppColors.goldDark, AppColors.goldContainer, AppColors.gold),
      'DIRTY' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'OUT_OF_ORDER' => (
          scheme.brightness == Brightness.light
              ? const Color(0xFF444444)
              : scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest
        ),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: fmt.label(fmt.roomStatusLabels, status),
      foreground: pair.$1,
      background: pair.$2,
    );
  }

  factory StatusChip.extensionStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final pair = switch (status) {
      'PENDING' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'APPROVED' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'REJECTED' => _chip(
          context, AppColors.danger, AppColors.dangerContainer, AppColors.dangerDark),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: fmt.label(fmt.extensionStatusLabels, status),
      foreground: pair.$1,
      background: pair.$2,
    );
  }

  factory StatusChip.priority(BuildContext context, String priority) {
    final urgent = priority == 'URGENT';
    return StatusChip(
      label: fmt.label(fmt.priorityLabels, priority),
      foreground: urgent ? Colors.white : Theme.of(context).colorScheme.onSurface,
      background: urgent ? AppColors.danger : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  static (Color, Color) requestStatusChipColors(
    BuildContext context,
    String status,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final light = scheme.brightness == Brightness.light;
    return switch (status) {
      'NEW' => _chip(
          context, AppColors.info, AppColors.infoContainer, AppColors.infoDark),
      'ACKNOWLEDGED' => _chip(
          context, AppColors.info, AppColors.infoContainer, AppColors.infoDark),
      'ASSIGNED' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'IN_PROGRESS' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'WAITING' => _chip(
          context, AppColors.warning, AppColors.warningContainer, AppColors.warningDark),
      'COMPLETED' => _chip(
          context, AppColors.success, AppColors.successContainer, AppColors.successDark),
      'CANCELLED' => (
          light ? scheme.onSurfaceVariant : scheme.onSurface,
          scheme.surfaceContainerHighest
        ),
      'REJECTED' => _chip(
          context, AppColors.danger, AppColors.dangerContainer, AppColors.dangerDark),
      _ => (
          light ? scheme.onSurfaceVariant : scheme.onSurface,
          scheme.surfaceContainerHighest
        ),
    };
  }
}

/// مؤشر تحميل مركزي (مقابل GuestLoading في الويب)
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.text = 'جارٍ التحميل…'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة خطأ مع إعادة المحاولة (مقابل ErrorState في الويب)
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حالة فراغ
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط تنبيه عائم (مقابل toast في الويب)
void showAppToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  final scheme = Theme.of(context).colorScheme;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: error ? scheme.onErrorContainer : scheme.onInverseSurface,
        ),
      ),
      backgroundColor:
          error ? scheme.errorContainer : scheme.inverseSurface,
    ),
  );
}

/// صف معلومة (تسمية + قيمة) — مقابل عناصر القوائم في الويب
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.labelText,
    required this.value,
    this.copyable = false,
  });

  final String labelText;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

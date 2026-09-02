// ─────────────────────────────────────────────────────────────
// WIDGETS — مكونات مشتركة لكل شاشات التطبيق (مقابل مكونات الويب)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../core/format.dart';
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

  /// حالات طلب الخدمة (نفس ألوان الويب المعنوية)
  factory StatusChip.requestStatus(BuildContext context, String status) {
    final c = requestStatusChipColors(context, status);
    return StatusChip(
      label: label(requestStatusLabels, status),
      foreground: c.$1,
      background: c.$2,
    );
  }

  factory StatusChip.stayStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      'ACTIVE' => (AppColors.success, AppColors.successContainer),
      'CHECKOUT_REQUESTED' => (AppColors.warning, AppColors.warningContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: label(stayStatusLabels, status),
      foreground: scheme.brightness == Brightness.light ? fg : scheme.onSurface,
      background: bg,
    );
  }

  factory StatusChip.paymentStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      'PAID' => (AppColors.success, AppColors.successContainer),
      'PARTIALLY_PAID' => (AppColors.warning, AppColors.warningContainer),
      'UNPAID' => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return StatusChip(
      label: label(paymentStatusLabels, status),
      foreground: scheme.brightness == Brightness.light ? fg : scheme.onSurface,
      background: bg,
    );
  }

  factory StatusChip.priority(BuildContext context, String priority) {
    final urgent = priority == 'URGENT';
    return StatusChip(
      label: label(priorityLabels, priority),
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
      'NEW' => (AppColors.info, AppColors.infoContainer),
      'ACKNOWLEDGED' => (AppColors.info, AppColors.infoContainer),
      'ASSIGNED' => (AppColors.warning, AppColors.warningContainer),
      'IN_PROGRESS' => (AppColors.warning, AppColors.warningContainer),
      'WAITING' => (AppColors.warning, AppColors.warningContainer),
      'COMPLETED' => (AppColors.success, AppColors.successContainer),
      'CANCELLED' => (
          light ? scheme.onSurfaceVariant : scheme.onSurface,
          scheme.surfaceContainerHighest
        ),
      'REJECTED' => (AppColors.danger, AppColors.dangerContainer),
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
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        color: error
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onInverseSurface,
      ),
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

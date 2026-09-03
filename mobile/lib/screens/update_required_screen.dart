// ─────────────────────────────────────────────────────────────
// UPDATE REQUIRED — شاشة الحجب عند إصدار أقل من حد الخادم (F6)
// كاملة الحجب: لا يمكن تجاوزها إلا بتحديث التطبيق (أو رفع الحد
// من الأدمن ثم «إعادة المحاولة»). الرابط قابل للنسخ عبر الحافظة
// (بلا حزم خارجية — Clipboard من flutter/services).
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_version.dart';
import '../ui/widgets.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({
    super.key,
    required this.minVersion,
    required this.onRetry,
  });

  /// الحد الأدنى الذي فرضه الخادم (للعرض)
  final String minVersion;

  /// إعادة فحص PUB-07 (بعد رفع الحد من الأدمن مثلًا)
  final VoidCallback onRetry;

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kReleasesUrl));
    if (context.mounted) {
      showAppToast(context, 'تم نسخ رابط الإصدارات — افتحه في المتصفح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    semanticLabel: 'شعار فندق قلب القاهرة',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'يتوفر تحديث مطلوب',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هذا الإصدار من التطبيق لم يعد مدعومًا. حدّث التطبيق إلى أحدث إصدار من صفحة الإصدارات ثم عد وافتحه من جديد.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoRow(
                          labelText: 'إصدارك الحالي',
                          value: kAppVersion,
                        ),
                        InfoRow(
                          labelText: 'الحد الأدنى المطلوب',
                          value: minVersion,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'حمّل أحدث نسخة (APK) من:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          kReleasesUrl,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _copyLink(context),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ رابط الإصدارات'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

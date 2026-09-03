// ─────────────────────────────────────────────────────────────
// ROLE PLACEHOLDER — كود طاقم (استقبال/إدارة) في تطبيق الضيف
// وضع الاستقبال والإدارة قادمان في F4/F5 — حتى ذلك الحين: الويب
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../state/session.dart';
import '../ui/widgets.dart';

class RolePlaceholder extends StatelessWidget {
  const RolePlaceholder({super.key, required this.session});

  final SessionController session;

  String get _roleName {
    switch (session.session?.role) {
      case 'RECEPTION':
        return 'الاستقبال';
      case 'ADMIN':
        return 'الإدارة';
      default:
        return 'الطاقم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      semanticLabel: 'شعار فندق قلب القاهرة',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أهلًا ${session.session?.name ?? ''}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تم الدخول بصلاحية $_roleName',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.tablet_mac_rounded,
                      size: 44,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'وضع $_roleName في التطبيق قادم في تحديث لاحق.\n'
                      'حتى ذلك الحين استخدم لوحة الويب من الفندق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.8,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => session.logout(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIVACY SCREEN — سياسة الخصوصية + حول التطبيق (F8 — Task 24-f)
//
// شاشة ثابتة (بلا شبكة): مرآة موجزة للمصدر النصي الحقيقي
// docs/PRIVACY_POLICY.md v1.0 (2026-09-05) + إصدار التطبيق
// (kAppVersion المدمج وقت البناء). تُفتح من زر الدرع في هيكل
// الضيف — والمتجر يتطلب إمكانية الوصول للسياسة من داخل التطبيق.
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../ui/widgets.dart';

class _PolicySection {
  const _PolicySection(this.title, this.items);
  final String title;
  final List<String> items;
}

const List<_PolicySection> _kSections = [
  _PolicySection('البيانات التي نجمعها', [
    'بيانات التعريف: اسم الضيف ورقم هاتفه عند الحجز — بلا إنشاء حساب ولا كلمة مرور ولا ربط بحسابات التواصل.',
    'كود الدخول: كود قصير (H للضيوف · R/A للطاقم) يُخزَّن بصمته المجزأة SHA-256 فقط — الكود الخام لا يُخزَّن أبدًا وينتهي بانتهاء الإقامة أو إبطاله.',
    'بيانات الإقامة والفوترة: الغرفة والليالي والضرائب والرسوم والمدفوعات — الدفع نقدي في الفندق، ولا نجمع بيانات بطاقات بنكية.',
    'الرسائل وطلبات الخدمة بينك وبين الاستقبال — لخدمة إقامتك الجارية حصرًا.',
    'سجل تدقيق تشغيلي (الوقت + الدور + نوع الفعل) — لا يتضمن محتوى جهازك.',
    'إعدادات الجهاز: لا شيء — لا معرّفات إعلانات، لا تتبُّع، لا موقع جغرافي، ولا أي جهة خارجية.',
  ]),
  _PolicySection('كيف نستخدمها', [
    'حصرًا لتشغيل حجزك وإقامتك: الوصول والبحث وإصدار الكود، الطلبات والمحادثة، الفوترة والتسوية، والعمليات الداخلية للفندق.',
    'لا استخدام تسويقيًا أو إعلانيًا إطلاقًا — لا رسائل ترويجية ولا ملفات تعريف ولا قرارات آلية.',
  ]),
  _PolicySection('المشاركة مع الأطراف', [
    'لا نشارك بياناتك مع أي طرف ثالث في النسخة الحالية — لا بيع ولا تأجير ولا خدمات سحابية خارجية.',
    'الاستثناء الوحيد: الجهات الرسمية عند طلب قانوني ملزِم صريح وفي حدوده فقط.',
  ]),
  _PolicySection('الاحتفاظ', [
    'بيانات الحجز والإقامة والفوترة: سنتان افتراضيًا وفق سياسة المحاسبة.',
    'سجلات التدقيق: 12 شهرًا ثم تُحذف.',
    'الجلسات: تنتهي بإبطال الكود أو انتهائه أو الخروج — وكود الضيف يموت حتمًا عند إتمام الخروج.',
  ]),
  _PolicySection('حقوقك', [
    'لك طلب نسخة من بياناتك أو تصحيحها أو حذفها (بما لا يخالف الالتزامات المحاسبية) عبر التواصل مع الفندق — يكفي رقم الحجز/الهاتف لإثبات الملكية.',
  ]),
  _PolicySection('الأمان', [
    'اتصال كامل عبر HTTPS · أكواد مجزأة أحادية الاتجاه · خمس محاولات دخول فاشلة بالدقيقة ثم قفل مؤقت · صلاحيات حسب الدور مع تدقيق كل فعل حساس.',
    'وصول التطبيق إلى جهازك: إذن الإنترنت فقط — وروابط واتساب/الهاتف/البريد لا تُفتح إلا بضغطك أنت.',
  ]),
];

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخصوصية وحول التطبيق'),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ── حول التطبيق ──
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          semanticLabel: 'شعار فندق قلب القاهرة',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'فندق قلب القاهرة — عدن',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'تطبيق الضيف — الإصدار $kAppVersion',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.shield_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── نص السياسة (مرآة docs/PRIVACY_POLICY.md v1.0) ──
              Text(
                'سياسة الخصوصية — الإصدار 1.0 (2026-09-05)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final s in _kSections) ...[
                SectionTitle(s.title),
                const SizedBox(height: 6),
                ...s.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'أي تغيير على هذه السياسة يُعلَن بترقيم تاريخي. النسخة العربية هي المرجع المعتمد.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

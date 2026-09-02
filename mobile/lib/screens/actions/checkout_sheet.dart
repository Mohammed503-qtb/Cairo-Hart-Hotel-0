// ─────────────────────────────────────────────────────────────
// CHECKOUT SHEET — طلب تسجيل الخروج (نقل checkout-dialog.tsx — G-13)
// ملخص الرصيد الحالي + تحذير التسوية + تأكيد
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'sheet_frame.dart';

/// صفيحة طلب الخروج — تُفتح عبر showCheckoutSheet في actions.dart
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key, required this.store});

  final GuestStore store;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  bool _sending = false;

  Future<void> _submit() async {
    if (_sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      // G-13 — الإقامة تنتقل إلى CHECKOUT_REQUESTED والبطاقات تتحدث عبر المخزن
      final res = await widget.store.requestCheckout();
      if (!mounted) {
        return;
      }
      final currency = widget.store.dashboard?.currency ?? 'USD';
      final description = res.balanceCents > 0
          ? 'يرجى تسوية الرصيد (${formatMoney(res.balanceCents, currency: currency)}) لدى الاستقبال'
          : 'سيجهّز الاستقبال مغادرتك خلال دقائق';
      showAppToast(context, 'تم إرسال طلب الخروج ✅\n$description');
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      icon: Icons.north_east_rounded,
      title: 'طلب تسجيل الخروج',
      description: 'سيُبلَغ الاستقبال لتجهيز مغادرتك الآن',
      footer: _footer(),
      // الرصيد يُقرأ حيًّا من لوحة الضيف كما في الويب (guest.dashboard)
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          final balance = widget.store.dashboard?.balanceCents ?? 0;
          final currency = widget.store.dashboard?.currency ?? 'USD';
          final due = balance > 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: due ? AppColors.warningContainer : AppColors.successContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: due ? AppColors.warning : AppColors.success,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رصيد إقامتك الحالي',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // المبلغ لاتيني — LTR كما في الويب (dir="ltr")
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.centerStart,
                    child: Text(
                      formatMoney(balance, currency: currency),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: due ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (due)
                  // تحذير التسوية (نفس نص الويب مع أيقونة التنبيه)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'يرجى تسوية الرصيد لدى الاستقبال قبل الخروج.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'حسابك مسوّى — لا مستحقات عليك',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// صف الأزرار: رجوع + تأكيد طلب الخروج (busy أثناء الإرسال)
  Widget _footer() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed:
                _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('رجوع'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 8,
          child: FilledButton(
            onPressed: _sending ? null : _submit,
            // ويب: مؤشر انشغال قبل النص أثناء الإرسال فقط
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sending) ...[
                  sheetBusyIndicator,
                  const SizedBox(width: 8),
                ],
                const Text('تأكيد طلب الخروج'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

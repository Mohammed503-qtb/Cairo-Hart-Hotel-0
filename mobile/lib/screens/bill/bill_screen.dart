// ─────────────────────────────────────────────────────────────
// BILL — تبويب «الفاتورة» (نقل حرفي لـ guest-bill.tsx — G-09)
// رأس الفاتورة + جدول البنود (إقامة الغرفة + الرسوم الإضافية)
// + المدفوعات + الإجماليات (لون البطاقة بحسب إشارة الرصيد)
// + زر طلب تسجيل الخروج (ذهبي — معطل عند وجود طلب قائم)
// كل المبالغ بالسنت تُعرض كما أرسلها الخادم — لا حسابات محلية
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../actions/actions.dart';
import '../shared/panels.dart';

/// تبويب «الفاتورة» — نقطة الدخول الثابتة (يستهلكها GuestShell)
class BillScreen extends StatelessWidget {
  const BillScreen({super.key, required this.store});

  final GuestStore store;

  /// سحب للتحديث/إعادة المحاولة — رسالة ApiError تظهر توستًا حرفيًا
  Future<void> _refreshBill(BuildContext context) async {
    try {
      await store.refreshBill();
    } on ApiError catch (e) {
      if (context.mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // الرحلة: تحميل أولي → خطأ/فراغ → المحتوى (كما في الويب)
        if (store.bootstrapLoading && store.bill == null) {
          return const LoadingView();
        }
        final bill = store.bill;
        if (bill == null) {
          return ErrorRetryView(
            message: 'تعذر تحميل الفاتورة\nحدث خطأ في الاتصال — أعد المحاولة',
            onRetry: () => _refreshBill(context),
          );
        }
        // طلب خروج قائم؟ (من حالة الإقامة في لوحة الضيف — كالويب)
        final requestedCheckout =
            store.dashboard?.stay.status == 'CHECKOUT_REQUESTED';
        return RefreshIndicator(
          onRefresh: () => _refreshBill(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _BillHeaderCard(bill: bill),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'بنود الفاتورة',
                child: _ChargesSection(store: store, bill: bill),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'المدفوعات',
                child: _PaymentsSection(bill: bill),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'الإجماليات',
                child: _TotalsSection(bill: bill),
              ),
              const SizedBox(height: 20),
              _CheckoutButton(
                store: store,
                requestedCheckout: requestedCheckout,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────── رأس الفاتورة ──

/// رأس الفاتورة: «فاتورة إقامتك» + المرجع والغرفة + أيقونة الإيصال
class _BillHeaderCard extends StatelessWidget {
  const _BillHeaderCard({required this.bill});

  final GuestBill bill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      // تدرج primary/5 الفاتح في الويب → صبغة أساسية خفيفة
      color: scheme.primary.withAlpha(13),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فاتورة إقامتك',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // dir=auto في الويب: المرجع لاتيني أولًا → فقرة LTR
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${bill.stayReference} — الغرفة ${bill.roomNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // دائرة الإيصال (bg-accent text-primary)
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 22,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── البنود ──

/// البنود: جدول (البند/التاريخ/المبلغ) — صف إقامة الغرفة مميز
/// بخلفية accent/40 ثم بنود الرسوم الإضافية
class _ChargesSection extends StatelessWidget {
  const _ChargesSection({required this.store, required this.bill});

  final GuestStore store;
  final GuestBill bill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final head = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    // تاريخ الغرفة من لوحة الضيف (fallback: اليوم — كما في الويب)
    final roomDate = formatDateAr(
      store.dashboard?.stay.checkInAt ?? DateTime.now().toIso8601String(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('البنود'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            // جدول داخلي بإطار مدوّر (border border-border/70 في الويب)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // رأس الجدول (bg-muted/60)
                Container(
                  color: scheme.surfaceContainerHighest.withAlpha(153),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text('البند', style: head)),
                      Expanded(flex: 4, child: Text('التاريخ', style: head)),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text('المبلغ', style: head),
                        ),
                      ),
                    ],
                  ),
                ),
                // صف إقامة الغرفة (bg-accent/40 — مميز كالويب)
                Container(
                  color: scheme.surfaceContainerHighest.withAlpha(102),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إقامة الغرفة (${bill.roomNights} ${bill.roomNights == 1 ? 'ليلة' : 'ليالٍ'})',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'يشمل الضريبة ${formatMoney(bill.roomTaxCents, currency: bill.currency)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            roomDate,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatMoney(
                                bill.roomTotalCents,
                                currency: bill.currency,
                              ),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // بنود الرسوم الإضافية (وصف + تصنيف + تاريخ + مبلغ)
                for (final c in bill.extraCharges)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.description,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                label(
                                  chargeCategoryLabels,
                                  c.category,
                                  fallback: c.category,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              formatDateAr(c.date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                formatMoney(
                                  c.amountCents,
                                  currency: bill.currency,
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── المدفوعات ──

/// المدفوعات: فراغ متقطع عند غيابها أو بطاقات دفع بفواصل
/// (محفظة خضراء + طريقة الدفع + التاريخ/المسجِّل + المبلغ)
class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection({required this.bill});

  final GuestBill bill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (bill.payments.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('المدفوعات'),
          SizedBox(height: 12),
          DashedNote('لا مدفوعات مسجلة بعد'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('المدفوعات'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < bill.payments.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(color: scheme.outlineVariant),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // دائرة المحفظة (bg-success/10 text-success)
                      // (SizedBox+DecoratedBox+Center — مكافئة Container الدائرية)
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label(
                                paymentMethodLabels,
                                bill.payments[i].method,
                                fallback: bill.payments[i].method,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // التاريخ + المسجِّل إن وُجد (شرط الويب)
                            Text(
                              '${formatDateAr(bill.payments[i].createdAt)}${bill.payments[i].recordedBy.isNotEmpty ? ' — ${bill.payments[i].recordedBy}' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // +المبلغ (أخضر LTR كما في الويب)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '+${formatMoney(bill.payments[i].amountCents, currency: bill.currency)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── الإجماليات ──

/// الإجماليات: بطاقة ملونة بحسب إشارة الرصيد
/// (موجب → أحمر destructive · صفر/سالب → أخضر success كالويب)
class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.bill});

  final GuestBill bill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = bill.balanceCents > 0;
    final accent = due ? AppColors.danger : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('الإجماليات'),
        AppCard(
          color: accent.withAlpha(13), // destructive/5 أو success/5
          border: BorderSide(color: accent.withAlpha(77)), // /30
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TotalRow(
                label: 'إجمالي المستحقات',
                value: formatMoney(
                  bill.totalChargesCents,
                  currency: bill.currency,
                ),
              ),
              const SizedBox(height: 10),
              _TotalRow(
                label: 'إجمالي المدفوع',
                value: formatMoney(
                  bill.totalPaidCents,
                  currency: bill.currency,
                ),
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'المتبقي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // الرصيد بخط كبير (text-2xl) بلون الإشارة
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      formatMoney(
                        bill.balanceCents,
                        currency: bill.currency,
                      ),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                due
                    ? 'يرجى تسوية الرصيد لدى الاستقبال قبل المغادرة'
                    : 'حسابك مسوّى — شكرًا لك 💛',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// صف إجمالي: تسمية + قيمة LTR (tone success اختياري كما في الويب)
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color ?? scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── زر الخروج ──

/// زر طلب تسجيل الخروج: ذهبي بحجم كبير — رمادي معطّل عند وجود
/// طلب قائم (openDialog('checkout') في الويب → صفيحة G-13)
class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({required this.store, required this.requestedCheckout});

  final GuestStore store;
  final bool requestedCheckout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48, // h-12
      child: FilledButton.icon(
        onPressed: requestedCheckout
            ? null
            : () => showCheckoutSheet(context, store),
        style: FilledButton.styleFrom(
          // ذهبي بنص داكن — أو bg-muted text-muted-foreground عند التعطيل
          backgroundColor: AppColors.gold,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          foregroundColor: const Color(0xFF2A2110),
          disabledForegroundColor: scheme.onSurfaceVariant,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        icon: const Icon(Icons.north_east_rounded, size: 20),
        label: Text(
          requestedCheckout ? 'طلب الخروج قيد المعالجة' : 'طلب تسجيل الخروج',
        ),
      ),
    );
  }
}

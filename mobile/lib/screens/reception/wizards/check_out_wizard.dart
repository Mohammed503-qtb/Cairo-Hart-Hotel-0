// ─────────────────────────────────────────────────────────────
// CHECK-OUT WIZARD — معالج تسجيل الخروج (3 خطوات + نجاح)
// نقل حرفي لـ check-out-wizard.tsx فوق ReceptionStore:
// مراجعة الإقامة → تسوية الرصيد (دفعة سريعة/تأكيد مع رصيد) → التأكيد
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart' as fmt;
import '../../../models/reception.dart';
import '../../../state/reception_store.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets.dart';
import '../reception_bits.dart';

/// ليالي بين تاريخَي ISO كاملين (نقل nightsBetweenDates في الويب).
/// fmt.nightsBetween يعمل على قيم input فقط (YYYY-MM-DD) — لذا مساعد محلي.
int _nightsBetweenIso(String a, String b) {
  final d1 = fmt.tryParseDate(a);
  final d2 = fmt.tryParseDate(b);
  if (d1 == null || d2 == null) return 0;
  final day1 = DateTime(d1.year, d1.month, d1.day);
  final day2 = DateTime(d2.year, d2.month, d2.day);
  final nights = day2.difference(day1).inDays;
  return nights < 0 ? 0 : nights;
}

/// فتح معالج تسجيل الخروج — التوقيع عقد مع الشاشات (لا تغيّره)
Future<void> showCheckOutWizard(
  BuildContext context, {
  required ReceptionStore store,
  required String stayId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CheckOutWizardDialog(store: store, stayId: stayId),
  );
}

class _CheckOutWizardDialog extends StatefulWidget {
  const _CheckOutWizardDialog({required this.store, required this.stayId});

  final ReceptionStore store;
  final String stayId;

  @override
  State<_CheckOutWizardDialog> createState() => _CheckOutWizardDialogState();
}

class _CheckOutWizardDialogState extends State<_CheckOutWizardDialog> {
  static const List<String> _stepTitles = [
    'مراجعة الإقامة',
    'تسوية الرصيد',
    'التأكيد النهائي',
  ];

  int step = 0;
  StayDetailData? detail;
  String? error;
  bool loading = false;
  bool payLoading = false;
  bool closed = false;
  String payMethod = 'CASH';
  bool _paymentJustRecorded = false;
  final payAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    payAmountController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    StayDetailData? loaded;
    String? loadError;
    try {
      loaded = await widget.store.loadStayDetail(widget.stayId);
    } on ApiError catch (e) {
      loadError = e.message;
    }
    if (!mounted) return;
    setState(() {
      detail = loaded;
      error = loadError;
    });
    if (loaded != null && loaded.bill.balanceCents > 0) {
      // ملء مبلغ الدفعة بالرصيد المتبقي (نفس سلوك الويب)
      payAmountController.text =
          (loaded.bill.balanceCents / 100).toStringAsFixed(2);
    }
    // توست نجاح الدفعة يُعرض مرة واحدة بعد تحديث البيانات
    final justPaid = _paymentJustRecorded;
    _paymentJustRecorded = false;
    if (justPaid) {
      showAppToast(
        context,
        'تم تسجيل دفعة ${fmt.label(fmt.paymentMethodLabels, payMethod)} ✅',
      );
    }
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(payAmountController.text.trim());
    if (amount == null || amount <= 0) {
      showAppToast(context, 'أدخل مبلغًا صحيحًا', error: true);
      return;
    }
    final amountCents = (amount * 100).round();
    setState(() => payLoading = true);
    try {
      await widget.store.recordPayment(
        stayId: widget.stayId,
        method: payMethod,
        amountCents: amountCents,
        note: 'تسوية عند الخروج',
      );
      _paymentJustRecorded = true;
      await _reload();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذر تسجيل الدفعة — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => payLoading = false);
    }
  }

  Future<void> _doCheckOut({required bool confirmOutstanding}) async {
    setState(() => loading = true);
    try {
      await widget.store.checkOut(
        stayId: widget.stayId,
        confirmOutstanding: confirmOutstanding,
      );
      if (!mounted) return;
      setState(() => closed = true);
      showAppToast(context, 'تم تسجيل الخروج بنجاح ✅');
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذر تسجيل الخروج — ${e.message}', error: true);
      }
      await _reload();
      if (mounted) setState(() => step = 1);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// تأكيد الخروج مع رصيد — AlertDialog كما في الويب
  Future<void> _confirmCheckOutWithBalance(int balance) async {
    final d = detail;
    if (d == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('تأكيد الخروج مع رصيد غير مسدد؟'),
        content: Text(
          'سيتم إغلاق إقامة ${d.guest.fullName} مع بقاء رصيد مستحق '
          '${fmt.formatMoney(balance)} على الحساب. لا يمكن تسجيل دفعات على '
          'الإقامة بعد إغلاقها.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('نعم، أكّد الخروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _doCheckOut(confirmOutstanding: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: closed ? _SuccessView(detail: detail) : _buildSteps(),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (error != null) ...[
          const SizedBox(height: 12),
          _NoticeBox(
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            child: Text(error!),
          ),
        ],
        const SizedBox(height: 12),
        if (detail == null)
          loadingBlocks(2, height: 110)
        else if (step == 0)
          _buildStep0()
        else if (step == 1)
          _buildStep1()
        else
          _buildStep2(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.flight_takeoff_rounded, size: 20, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'تسجيل خروج${detail != null ? ' — ${detail!.guest.fullName}' : ''}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < _stepTitles.length; i++)
              _StepChip(
                label: '${i + 1}. ${_stepTitles[i]}',
                active: i == step,
                done: i < step,
              ),
          ],
        ),
      ],
    );
  }

  /// الخطوة 1: مراجعة الإقامة + ملخص الفاتورة
  Widget _buildStep0() {
    final d = detail!;
    final scheme = Theme.of(context).colorScheme;
    final value = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface);
    final roomNum = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: scheme.onSurface);
    Widget divider() =>
        Divider(height: 1, indent: 12, endIndent: 12, color: scheme.outlineVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(children: [
          _Row(label: 'الضيف', child: Text(d.guest.fullName, style: value)),
          divider(),
          _Row(
            label: 'الغرفة',
            child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(d.room.number, textDirection: TextDirection.ltr, style: roomNum),
              Text('· ${d.roomType.name}', style: value),
            ]),
          ),
          divider(),
          _Row(
            label: 'الإقامة',
            child: Text(
              '${fmt.formatDateWithDayAr(d.checkInAt)} ← '
              '${fmt.formatDateWithDayAr(d.expectedCheckOutAt)} '
              '(${_nightsBetweenIso(d.checkInAt, d.expectedCheckOutAt)} ليالٍ)',
              style: value,
            ),
          ),
          divider(),
          _Row(label: 'الحالة', child: StatusChip.stayStatus(context, d.status)),
        ]),
      ),
      const SizedBox(height: 12),
      _MiniBill(bill: d.bill),
      const SizedBox(height: 16),
      _buttonsRow(
        cancel: () => Navigator.of(context).pop(),
        next: () => setState(() => step = 1),
      ),
    ]);
  }

  /// الخطوة 2: تسوية الرصيد — دفعة سريعة أو تأكيد مع الرصيد أو مسددة
  Widget _buildStep1() {
    final balance = detail!.bill.balanceCents;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MiniBill(bill: detail!.bill),
      const SizedBox(height: 12),
      if (balance > 0) ...[
        _NoticeBox(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('يوجد رصيد غير مسدد '),
            MoneyText(balance),
            const Text(' — سجّل دفعة أو أكّد الخروج مع الرصيد'),
          ]),
        ),
        const SizedBox(height: 12),
        _buildQuickPayment(),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          OutlinedButton(
            onPressed: () => setState(() => step = 0),
            child: const Text('رجوع'),
          ),
          FilledButton.icon(
            onPressed: () => _confirmCheckOutWithBalance(balance),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.warning_amber_rounded, size: 18),
            label: const Text('تأكيد الخروج مع الرصيد'),
          ),
        ]),
      ] else ...[
        const _NoticeBox(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          child: Text('الفاتورة مسددة بالكامل ✅ — لا رصيد مستحق'),
        ),
        const SizedBox(height: 12),
        _buttonsRow(
          cancel: () => setState(() => step = 0),
          cancelLabel: 'رجوع',
          next: () => setState(() => step = 2),
        ),
      ],
    ]);
  }

  /// بطاقة الدفعة السريعة (R-12) — طريقة + مبلغ + تسجيل
  Widget _buildQuickPayment() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.payments_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'دفعة سريعة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CASH', label: Text('نقدًا')),
              ButtonSegment(value: 'CARD', label: Text('بطاقة')),
              ButtonSegment(value: 'TRANSFER', label: Text('حوالة')),
            ],
            selected: {payMethod},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => payMethod = s.first),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: payAmountController,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: payLoading ? null : _recordPayment,
            child: payLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تسجيل'),
          ),
        ]),
      ]),
    );
  }

  /// الخطوة 3: التأكيد النهائي — بنود التأثير
  Widget _buildStep2() {
    final d = detail!;
    final scheme = Theme.of(context).colorScheme;
    final balance = d.bill.balanceCents;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('سيتم تنفيذ ما يلي:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      _EffectCard(
        icon: Icons.flight_takeoff_rounded,
        iconColor: AppColors.danger,
        child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('إغلاق الإقامة '),
          RefCodeText(d.reference, color: scheme.onSurface),
        ]),
      ),
      const SizedBox(height: 8),
      _EffectCard(
        icon: Icons.cleaning_services_rounded,
        iconColor: AppColors.warning,
        child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('الغرفة '),
          Text(
            d.room.number,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
          ),
          const Text(' تصبح «تحتاج تنظيف»'),
        ]),
      ),
      const SizedBox(height: 8),
      const _EffectCard(
        icon: Icons.key_rounded,
        iconColor: AppColors.danger,
        child: Text('انتهاء صلاحية كود تطبيق الضيف فورًا'),
      ),
      if (balance > 0) ...[
        const SizedBox(height: 8),
        _EffectCard(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
          warning: true,
          child: Text('الخروج مع رصيد ${fmt.formatMoney(balance)}'),
        ),
      ],
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
        OutlinedButton(
          onPressed: loading ? null : () => setState(() => step = 1),
          child: const Text('رجوع'),
        ),
        FilledButton.icon(
          onPressed: loading ? null : () => _doCheckOut(confirmOutstanding: balance > 0),
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text('تأكيد الخروج'),
        ),
      ]),
    ]);
  }

  /// صف أزرار (إلغاء/رجوع + متابعة) — Wrap يلتف على الشاشات الضيقة
  Widget _buttonsRow({
    required VoidCallback cancel,
    required VoidCallback next,
    String cancelLabel = 'إلغاء',
  }) {
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
      OutlinedButton(onPressed: cancel, child: Text(cancelLabel)),
      FilledButton(onPressed: next, child: const Text('متابعة')),
    ]);
  }
}

/// صف «تسمية: قيمة» في مراجعة الإقامة (Row في الويب)
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ]),
    );
  }
}

/// ملخص الفاتورة (MiniBill في الويب)
class _MiniBill extends StatelessWidget {
  const _MiniBill({required this.bill});

  final ReceptionBill bill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(String label, Widget value, {bool muted = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: muted ? FontWeight.w600 : FontWeight.w800,
            color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        value,
      ]),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.receipt_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          const Text('ملخص الفاتورة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        row('إجمالي الغرفة', MoneyText(bill.roomTotalCents), muted: true),
        if (bill.extraCharges.isNotEmpty)
          row('بنود إضافية (${bill.extraCharges.length})', MoneyText(bill.extraTotalCents), muted: true),
        const Divider(height: 14),
        row('الإجمالي المستحق', MoneyText(bill.totalChargesCents)),
        row('المدفوع', MoneyText(bill.totalPaidCents, colored: true), muted: true),
        const Divider(height: 14),
        // الرصيد: صف مميز (font-extrabold text-base في الويب)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              'الرصيد',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface),
            ),
            MoneyText(bill.balanceCents, colored: true),
          ]),
        ),
      ]),
    );
  }
}

/// صندوق تنبيه موحد (خطأ/رصيد/مسددة) — bg 10% + إطار 40%
class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.icon, required this.color, required this.child});

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: child),
        ]),
      ),
    );
  }
}

/// بند تأثير في التأكيد النهائي (li في الويب)
class _EffectCard extends StatelessWidget {
  const _EffectCard({
    required this.icon,
    required this.iconColor,
    required this.child,
    this.warning = false,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warning ? AppColors.warning.withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: warning ? AppColors.warning.withValues(alpha: 0.40) : scheme.outlineVariant,
        ),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: warning ? AppColors.warning : scheme.onSurface,
            ),
            child: child,
          ),
        ),
      ]),
    );
  }
}

/// شارة خطوة معالج (pill في الويب: حالية coral / منجزة success / باقية خافتة)
class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.active, required this.done});

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = active
        ? (AppColors.danger, Colors.white)
        : done
            ? (AppColors.success.withValues(alpha: 0.15), AppColors.success)
            : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// شاشة النجاح بعد إغلاق الإقامة (closed في الويب — تحل محل كل المحتوى)
class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.detail});

  final StayDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = detail;
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.success),
      ),
      const SizedBox(height: 12),
      const Text('تم تسجيل الخروج ✅', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      DefaultTextStyle(
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('إقامة '),
            RefCodeText(d?.reference ?? '', color: scheme.onSurface),
            const Text(' أُغلقت — الغرفة '),
            Text(
              d?.room.number ?? '',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: scheme.onSurface),
            ),
            const Text(' تحتاج تنظيفًا — انتهت صلاحية كود الضيف'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تم'),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

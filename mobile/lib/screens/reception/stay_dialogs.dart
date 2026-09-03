// ─────────────────────────────────────────────────────────────
// STAY DIALOGS — حوارا الدفعة والبند لتفصيل الإقامة (R-12/R-13)
// نقل حرفي لـ payment-dialog.tsx + charge-dialog.tsx فوق
// ReceptionStore (كل HTTP في المخزن فقط — نمط F1)
// كل حوار يعيد true عند النجاح ليعيد المتصل تحميل تفصيل الإقامة
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// حوار تسجيل دفعة على إقامة (نقدًا/بطاقة/حوالة) — عقد الواجهة:
/// يعيد true عند نجاح التسجيل (المتصل يعيد التحميل)، وfalse عند الإلغاء.
Future<bool> showPaymentDialog(
  BuildContext context, {
  required ReceptionStore store,
  required String stayId,
  required int balanceCents,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PaymentDialog(
      store: store,
      stayId: stayId,
      balanceCents: balanceCents,
    ),
  ).then((v) => v ?? false);
}

/// حوار إضافة بند لفاتورة إقامة (خدمة/إضافي/غرامة) — true عند النجاح.
Future<bool> showChargeDialog(
  BuildContext context, {
  required ReceptionStore store,
  required String stayId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ChargeDialog(store: store, stayId: stayId),
  ).then((v) => v ?? false);
}

// ───────────── حوار الدفعة (R-12) ─────────────

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.store,
    required this.stayId,
    required this.balanceCents,
  });

  final ReceptionStore store;
  final String stayId;
  final int balanceCents;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _method = 'CASH';
  bool _loading = false;
  late final TextEditingController _amount;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    // المبلغ يبدأ بالرصيد المستحق بمنزلتين (كما الويب)
    _amount = TextEditingController(
      text: (widget.balanceCents / 100).toStringAsFixed(2),
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // تحويل المبلغ للسنت (كما الويب): parse → ×100 → round
    final amountCents =
        ((double.tryParse(_amount.text.trim()) ?? 0) * 100).round();
    if (amountCents <= 0) {
      showAppToast(context, 'أدخل مبلغًا صحيحًا أكبر من صفر', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final note = _note.text.trim();
      final newBalance = await widget.store.recordPayment(
        stayId: widget.stayId,
        method: _method,
        amountCents: amountCents,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      showAppToast(
        context,
        'تم تسجيل دفعة ${fmt.formatMoney(amountCents)} ✅\n'
        'الرصيد الآن: ${fmt.formatMoney(newBalance)}',
      );
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذر تسجيل الدفعة — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(
                  Icons.payments_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                const Text(
                  'تسجيل دفعة',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ]),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'الرصيد الحالي المستحق:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    fmt.formatMoney(widget.balanceCents),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // محدد الطريقة: القيم الإنجليزية في الجسم (CASH/CARD/TRANSFER)
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CASH', label: Text('نقدًا')),
                    ButtonSegment(value: 'CARD', label: Text('بطاقة')),
                    ButtonSegment(value: 'TRANSFER', label: Text('حوالة')),
                  ],
                  selected: {_method},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _method = s.first),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(labelText: 'المبلغ (USD)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  hintText: 'مثال: دفعة عند الخروج',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('تسجيل الدفعة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── حوار البند (R-13) ─────────────

class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog({required this.store, required this.stayId});

  final ReceptionStore store;
  final String stayId;

  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  String _category = 'SERVICE';
  bool _loading = false;
  late final TextEditingController _description;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController();
    _amount = TextEditingController();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _description.text.trim();
    if (description.length < 3) {
      showAppToast(context, 'أدخل وصفًا للبند (3 أحرف على الأقل)', error: true);
      return;
    }
    // تحويل المبلغ للسنت (كما الويب): parse → ×100 → round
    final amountCents =
        ((double.tryParse(_amount.text.trim()) ?? 0) * 100).round();
    if (amountCents <= 0) {
      showAppToast(context, 'أدخل مبلغًا صحيحًا أكبر من صفر', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.store.addCharge(
        stayId: widget.stayId,
        description: description,
        amountCents: amountCents,
        category: _category,
      );
      if (!mounted) return;
      showAppToast(context, 'تمت إضافة البند للفاتورة ✅');
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذر إضافة البند — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(
                  Icons.playlist_add_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                const Text(
                  'إضافة بند للفاتورة',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                'سيظهر البند في فاتورة الضيف فورًا مع إشعار له',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'مثال: ميني بار — خدمة غرف',
                ),
              ),
              const SizedBox(height: 12),
              // الفئة: القيمة الإنجليزية في الجسم (SERVICE/EXTRA/PENALTY)
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'SERVICE',
                      label: Text(fmt.label(fmt.chargeCategoryLabels, 'SERVICE')),
                    ),
                    ButtonSegment(
                      value: 'EXTRA',
                      label: Text(fmt.label(fmt.chargeCategoryLabels, 'EXTRA')),
                    ),
                    ButtonSegment(
                      value: 'PENALTY',
                      label:
                          Text(fmt.label(fmt.chargeCategoryLabels, 'PENALTY')),
                    ),
                  ],
                  selected: {_category},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _category = s.first),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ (USD)',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('إضافة البند'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

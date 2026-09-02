// ─────────────────────────────────────────────────────────────
// EXTENSION SHEET — طلب تمديد الإقامة (نقل extension-dialog.tsx — G-10)
// الخروج الحالي + التاريخ الجديد (DatePicker عربي) + الليالي + ملاحظة
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../state/guest_store.dart';
import '../../ui/widgets.dart';
import 'sheet_frame.dart';

/// مفتاح اليوم YYYY-MM-DD بالتوقيت المحلي (نفس dayKey في الويب)
String? _dayKeyLocal(String? iso) {
  final d = tryParseDate(iso)?.toLocal();
  if (d == null) {
    return null;
  }
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

/// تحليل مفتاح يوم إلى منتصف ليل محلي
DateTime? _parseKey(String? key) =>
    key == null ? null : DateTime.tryParse('${key}T00:00:00');

/// مفتاح يوم من تاريخ محلي
String _keyOf(DateTime d) {
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

/// صفيحة تمديد الإقامة — تُفتح عبر showExtensionSheet في actions.dart
class ExtensionSheet extends StatefulWidget {
  const ExtensionSheet({super.key, required this.store});

  final GuestStore store;

  @override
  State<ExtensionSheet> createState() => _ExtensionSheetState();
}

class _ExtensionSheetState extends State<ExtensionSheet> {
  late final TextEditingController _noteController;
  String? _expectedKey; // مفتاح يوم الخروج المتوقع
  String? _newCheckOut; // مفتاح اليوم الجديد المختار
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    // الخروج المتوقع من لوحة الضيف (نفس guest.dashboard?.stay في الويب)
    _expectedKey =
        _dayKeyLocal(widget.store.dashboard?.stay.expectedCheckOutAt);
    // القيمة الابتدائية = أول يوم بعد الخروج الحالي (نفس minKey في الويب)
    _newCheckOut = _minKey;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// أول يوم مسموح = الخروج الحالي + 1 (min في حقل التاريخ بالويب)
  String? get _minKey =>
      _expectedKey == null ? null : addDaysInput(_expectedKey!, 1);

  /// الليالي المحسوبة من الخروج الحالي إلى التاريخ الجديد
  int get _nights {
    final expected = _expectedKey;
    final selected = _newCheckOut;
    if (expected == null || selected == null) {
      return 0;
    }
    return nightsBetween(expected, selected);
  }

  /// فتح منتقي التاريخ العربي (الحد الأدنى = بعد الخروج الحالي كما في الويب)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = _parseKey(_minKey) ?? now;
    final last = DateTime(now.year + 1, now.month, now.day);
    var initial = first;
    if (initial.isBefore(first)) {
      initial = first;
    }
    if (initial.isAfter(last)) {
      initial = last;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'تاريخ الخروج الجديد',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _newCheckOut = _keyOf(picked));
  }

  Future<void> _submit() async {
    final newCheckOut = _newCheckOut;
    if (newCheckOut == null || _sending) {
      return;
    }
    // تحقق محلي مطابق للويب: التاريخ بعد الخروج الحالي
    if (_nights < 1) {
      showAppToast(context, 'اختر تاريخًا بعد الخروج الحالي', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final res = await widget.store.requestExtension(
        newCheckOut,
        note: _noteController.text,
      );
      if (!mounted) {
        return;
      }
      // نفس نص النجاح في الويب (العنوان + الوصف في Toast واحد)
      showAppToast(
        context,
        'تم إرسال طلب التمديد ✅\n'
        'التكلفة التقديرية ${formatMoney(res.quote.grandTotalCents, currency: res.quote.currency)} '
        'لـ ${res.quote.nights} ${res.quote.nights == 1 ? 'ليلة' : 'ليالٍ'} — '
        'بانتظار موافقة الاستقبال',
      );
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
    final scheme = Theme.of(context).colorScheme;
    final nights = _nights;
    return SheetFrame(
      icon: Icons.update_rounded,
      title: 'تمديد الإقامة',
      description: 'طلبك يخضع لتوفر الغرفة وموافقة الاستقبال',
      footer: _footer(),
      // بطاقة الخروج الحالي تقرأ الحالة الحية من المخزن كما في الويب
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final stay = widget.store.dashboard?.stay;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الخروج الحالي (بطاقة قمر كما في الويب)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.nightlight_round,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الخروج الحالي',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formatDateAr(stay?.expectedCheckOutAt),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SheetLabel('تاريخ الخروج الجديد'),
              // حقل تاريخ قابل للنقر يفتح المنتقي العربي
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _newCheckOut == null
                              ? '—'
                              : formatDateAr(_newCheckOut),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _newCheckOut == null
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (nights > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '$nights ${nights == 1 ? 'ليلة إضافية' : 'ليالٍ إضافية'} — '
                  'التكلفة التقديرية تُحسب عند الإرسال',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const SheetLabel('ملاحظة (اختياري)'),
              TextField(
                controller: _noteController,
                maxLines: 2,
                minLines: 2,
                maxLength: 300,
                enabled: !_sending,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'سبب التمديد أو أي تفاصيل...',
                  counterText: '',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// صف أزرار الحوار: إلغاء + إرسال الطلب (busy أثناء الإرسال)
  Widget _footer() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed:
                _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: FilledButton.icon(
            onPressed: (_sending || _newCheckOut == null) ? null : _submit,
            icon: _sending ? sheetBusyIndicator : mirroredSendIcon(),
            label: const Text('إرسال الطلب'),
          ),
        ),
      ],
    );
  }
}

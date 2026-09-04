// ─────────────────────────────────────────────────────────────
// ADMIN RATES SCREEN — الأسعار الموسمية (A-12..A-14)
// نقل حرفي لـ sections/rates.tsx: تجميع المعدلات حسب نوع الغرفة
// + بطاقة معدل (الاسم/النطاق/السعر/نشط + مقارنة بالسعر الأساسي)
// + إضافة معدل (السعر بالدولار → سنت، النتيجة تحمل تحذير التداخل
// ويظهر توست تحذيري لكن الإنشاء نجح) + حذف بتأكيد
// صفر HTTP هنا: كل نداء عبر AdminStore (نمط F1/F4)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  String? _error;
  bool _busy = false;

  AdminStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// عند الفتح: refreshRates ثم refreshRoomTypes (الأنواع مطلوبة
  /// لحوار الإنشاء وتجميع المجموعات). فشل الأنواع صامت كالويب.
  Future<void> _refresh() async {
    try {
      await store.refreshRates();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      await _refreshTypesQuietly();
      return;
    }
    await _refreshTypesQuietly();
    if (!mounted) return;
    setState(() => _error = null);
  }

  Future<void> _refreshTypesQuietly() async {
    try {
      await store.refreshRoomTypes();
    } catch (_) {
      // الأنواع تُعاد المحاولة عند فتح الشاشة ثانية
    }
  }

  /// حذف معدل بتأكيد حرفي ثم DELETE برسالة الخادم
  Future<void> _confirmDelete(AdminRate rate) async {
    final scheme = Theme.of(context).colorScheme;
    final start = rate.startDate.length >= 10
        ? rate.startDate.substring(0, 10)
        : rate.startDate;
    final end = rate.endDate.length >= 10
        ? rate.endDate.substring(0, 10)
        : rate.endDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('حذف معدل «${rate.name}»؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'النطاق '),
                  TextSpan(
                    text: '$start → $end',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: ' لنوع «${rate.roomTypeName}» — الحجوزات '
                        'الجديدة ستعود للسعر الأساسي.',
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الحجوزات التي حُجزت أثناء هذا المعدل تحتفظ بلقطة سعرها.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final message = await store.deleteRate(rate.id);
      if (!mounted) return;
      showAppToast(context, message);
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذّر تنفيذ العملية — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateDialog([String? roomTypeId]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RateDialog(store: store, presetTypeId: roomTypeId),
    );
  }

  // ───────────── البناء ─────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final rates = store.rates;
        final types = store.roomTypes;
        final groups = _groupedRates(types, rates);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'الأسعار الموسمية',
                icon: Icons.calendar_month_rounded,
                iconColor: scheme.primary,
                action: FilledButton.icon(
                  onPressed: types.isEmpty ? null : _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة معدل'),
                ),
              ),
              Text(
                'معدلات خاصة بنطاق زمني لكل نوع غرفة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              // لافتة شرح التسعير (rounded border-primary في الويب)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'السعر النهائي لليلة = المعدل الموسمي المطابق وإلا '
                        'السعر الأساسي للنوع، مع زيادة نهاية الأسبوع % '
                        '(من إعدادات الفندق) على ليالي الجمعة والسبت للحجوزات '
                        'الجديدة. الحجوزات القديمة محفوظة بلقطات سعرها وقت '
                        'الحجز.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null && rates.isEmpty)
                AppCard(
                  child: ErrorRetryView(
                    message: _error!,
                    onRetry: _refresh,
                  ),
                )
              else if (store.ratesLoading && rates.isEmpty)
                _ratesSkeleton(context)
              else if (groups.isEmpty)
                const AppCard(
                  child: EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'لا توجد أنواع غرف',
                  ),
                )
              else
                for (final group in groups) ...[
                  _typeCard(context, group),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  /// تجميع المعدلات حسب النوع — byType في الويب (مع مجموعات
  /// الأنواع المحذوفة من قائمة الأنواع إن وُجدت معدلات يتيمة)
  List<({String id, String name, int basePriceCents, List<AdminRate> rates})>
      _groupedRates(List<AdminRoomType> types, List<AdminRate> rates) {
    final groups = <String,
        ({String id, String name, int basePriceCents, List<AdminRate> rates})>{};
    for (final t in types) {
      groups[t.id] = (
        id: t.id,
        name: t.name,
        basePriceCents: t.basePriceCents,
        rates: <AdminRate>[],
      );
    }
    for (final r in rates) {
      final group = groups[r.roomTypeId];
      if (group != null) {
        group.rates.add(r);
      } else {
        groups[r.roomTypeId] = (
          id: r.roomTypeId,
          name: r.roomTypeName,
          basePriceCents: r.roomTypeBasePriceCents,
          rates: [r],
        );
      }
    }
    return groups.values.toList(growable: false);
  }

  Widget _typeCard(
    BuildContext context,
    ({String id, String name, int basePriceCents, List<AdminRate> rates})
        group,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '(الأساس: ${fmt.formatMoney(group.basePriceCents)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _openCreateDialog(group.id),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('معدل'),
              ),
            ],
          ),
          if (group.rates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'لا توجد معدلات موسمية — يُستخدم السعر الأساسي دائمًا',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < group.rates.length; i++) ...[
              if (i > 0) Divider(color: scheme.outlineVariant, height: 1),
              _rateRow(context, group.rates[i], group.basePriceCents),
            ],
        ],
      ),
    );
  }

  /// بطاقة معدل: الاسم/النطاق (من-إلى)/السعر/نشط + مقارنة بالأساس
  Widget _rateRow(BuildContext context, AdminRate rate, int basePriceCents) {
    final scheme = Theme.of(context).colorScheme;
    final delta = rate.priceCents - basePriceCents;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rate.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (rate.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'نشط',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'من ${fmt.formatDateAr(rate.startDate)} '
                  'إلى ${fmt.formatDateAr(rate.endDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (delta != 0)
                  Text(
                    delta > 0
                        ? 'أعلى من الأساس بـ ${fmt.formatMoney(delta)}'
                        : 'أقل من الأساس بـ ${fmt.formatMoney(-delta)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(rate.priceCents),
              Text(
                'لليلة',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'حذف ${rate.name}',
            onPressed: _busy ? null : () => _confirmDelete(rate),
            color: scheme.error,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

// ───────────── عناصر خاصة بالملف ─────────────

/// هياكل تحميل (بطاقات المعدلات في الويب)
Widget _ratesSkeleton(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      for (var i = 0; i < 3; i++) ...[
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

/// توست تحذيري ذهبي (toast border-warning في الويب) — الإنشاء نجح
/// لكن الخادم أعاد تحذير تداخل
void _showWarningToast(BuildContext context, String warning) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'أُنشئ المعدل مع تحذير — $warning',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A3A0D),
        ),
      ),
      backgroundColor: AppColors.goldContainer,
    ),
  );
}

// ───────────── حوار إضافة معدل موسمي ─────────────

class _RateDialog extends StatefulWidget {
  const _RateDialog({required this.store, this.presetTypeId});

  final AdminStore store;
  final String? presetTypeId;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late String _roomTypeId;
  late final TextEditingController _name;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late final TextEditingController _price;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _roomTypeId = widget.presetTypeId ??
        (widget.store.roomTypes.isNotEmpty
            ? widget.store.roomTypes.first.id
            : '');
    // الافتراضي كما الويب: اليوم → اليوم + 30
    final today = fmt.todayInputValue();
    _name = TextEditingController();
    _startDate = TextEditingController(text: today);
    _endDate = TextEditingController(text: fmt.addDaysInput(today, 30));
    _price = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _price.dispose();
    super.dispose();
  }

  /// منتقي التاريخ — يحافظ على صيغة YYYY-MM-DD
  Future<void> _pickDate(TextEditingController controller) async {
    final initial =
        DateTime.tryParse('${controller.text}T00:00:00') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 3),
    );
    if (picked == null) return;
    final m = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    controller.text = '${picked.year}-$m-$day';
  }

  /// dateInputToISO في الويب: نهاية اليوم للمغادرة
  String? _dateInputToIso(String v, {required bool endOfDay}) {
    final t = v.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) return null;
    return '$t${endOfDay ? 'T23:59:59.000Z' : 'T00:00:00.000Z'}';
  }

  Future<void> _submit() async {
    if (_roomTypeId.isEmpty) {
      showAppToast(context, 'اختر نوع الغرفة', error: true);
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'اسم المعدل مطلوب', error: true);
      return;
    }
    // تحويل الدولار للسنت (كما الويب): parse → ×100 → round
    final cents =
        ((double.tryParse(_price.text.trim()) ?? 0) * 100).round();
    if (cents <= 0) {
      showAppToast(context, 'أدخل سعرًا صحيحًا بالدولار', error: true);
      return;
    }
    final start = _dateInputToIso(_startDate.text, endOfDay: false);
    final end = _dateInputToIso(_endDate.text, endOfDay: true);
    if (start == null || end == null) {
      showAppToast(context, 'اختر نطاق التاريخين', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      // النتيجة (rate, warning): التحذير لا يمنع الإنشاء
      final (_, warning) = await widget.store.createRate({
        'roomTypeId': _roomTypeId,
        'name': name,
        'startDate': start,
        'endDate': end,
        'priceCents': cents,
      });
      if (!mounted) return;
      if (warning != null && warning.isNotEmpty) {
        _showWarningToast(context, warning);
      } else {
        showAppToast(context, 'تمت إضافة المعدل');
      }
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppToast(
          context,
          'تعذّر تنفيذ العملية — ${e.message}',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final types = widget.store.roomTypes;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة معدل موسمي',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'سعر خاص لنوع غرفة خلال نطاق زمني',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'نوع الغرفة *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                  color: scheme.surfaceContainerHighest,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: types.any((t) => t.id == _roomTypeId)
                        ? _roomTypeId
                        : null,
                    hint: Text(
                      'اختر النوع',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      for (final t in types)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setState(() => _roomTypeId = v ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم المعدل *',
                  hintText: 'الموسم الصيفي',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dateField(
                      controller: _startDate,
                      label: 'من *',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateField(
                      controller: _endDate,
                      label: 'إلى *',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(
                  labelText: 'السعر لليلة (\$) *',
                  hintText: '180',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عند التداخل الزمني مع معدل آخر لنفس النوع، يسود المعدل '
                'الأحدث بدايةً لكل ليلة — وسيظهر لك تحذير.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(),
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
                        : const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إضافة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.ltr,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: 'اختيار التاريخ',
          icon: const Icon(Icons.calendar_month_rounded, size: 20),
          onPressed: () => _pickDate(controller),
        ),
      ),
    );
  }
}

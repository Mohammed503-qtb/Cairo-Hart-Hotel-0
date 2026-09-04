// ─────────────────────────────────────────────────────────────
// SERVICES SCREEN — الخدمات والأقسام (A-15..A-22)
// نقل حرفي لـ services.tsx: قسمان (الخدمات / الأقسام) + فلتر
// بالقسم + بطاقات بالاسم/السعر/القسم/الفعالية + إضافة/تعديل/
// حذف بتأكيد — الجسد الحرفي: خدمة {name,nameEn,description,
// priceCents,categoryId,active} وقسم {name,key,icon,sortOrder}
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

/// مفاتيح أقسام الخدمات — CATEGORY_KEYS في الويب (نفس التسميات)
const Map<String, String> _categoryKeys = {
  'HOUSEKEEPING': 'تنظيف (HOUSEKEEPING)',
  'MAINTENANCE': 'صيانة (MAINTENANCE)',
  'GUEST_SERVICES': 'ضيافة (GUEST_SERVICES)',
  'OTHER': 'أخرى (OTHER)',
};

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  /// 0 = الخدمات · 1 = الأقسام — الافتراضي «services» كالويب
  int _tab = 0;
  String _catFilter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    // جلب القائمتين معًا (كما يحمّل تبويب الخدمات في الويب useLoader
    // مرتين) — فشل إحداهما لا يلغي الأخرى
    final errors = <String>[];
    await Future.wait([
      widget.store.refreshServices().catchError((Object e) {
        errors.add(e is ApiError ? e.message : 'حدث خطأ غير متوقع');
      }),
      widget.store.refreshServiceCategories().catchError((Object e) {
        errors.add(e is ApiError ? e.message : 'حدث خطأ غير متوقع');
      }),
    ]);
    if (!mounted) return;
    final err = errors.isEmpty ? null : errors.first;
    setState(() => _error = err);
    if (err != null) showAppToast(context, err, error: true);
  }

  // ── A-15..A-18 · عمليات الخدمات (كل HTTP عبر المخزن) ──

  Future<void> _toggleActive(AdminService s) async {
    try {
      await widget.store.updateService(s.id, {'active': !s.active});
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  Future<void> _openServiceDialog(AdminService? editing) async {
    if (editing == null && widget.store.serviceCategories.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ServiceDialog(
        store: widget.store,
        categories: widget.store.serviceCategories,
        editing: editing,
      ),
    );
  }

  Future<void> _confirmDeleteService(AdminService target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف خدمة «${target.name}»؟'),
        content: const Text.rich(
          TextSpan(
            style: TextStyle(height: 1.6),
            children: [
              TextSpan(
                  text: 'إن كانت الخدمة مرتبطة بطلبات سابقة فسيتم '),
              TextSpan(
                text: 'تعطيلها',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                  text:
                      ' بدل حذفها للحفاظ على السجلات. الخدمات غير المرتبطة تُحذف نهائيًا.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // رسالة الخادم الحرفية (تعطيل ناعم إن وُجدت طلبات مرتبطة)
      final message = await widget.store.deleteService(target.id);
      if (mounted) showAppToast(context, message);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  // ── A-19..A-22 · عمليات الأقسام ──

  Future<void> _openCategoryDialog(AdminServiceCategory? editing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(
        store: widget.store,
        editing: editing,
      ),
    );
  }

  Future<void> _confirmDeleteCategory(AdminServiceCategory target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف قسم «${target.name}»؟'),
        content: const Text.rich(
          TextSpan(
            style: TextStyle(height: 1.6),
            children: [
              TextSpan(text: 'الحذف متاح فقط للأقسام '),
              TextSpan(
                text: 'بدون خدمات نشطة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                  text:
                      ' وبلا طلبات مرتبطة — وإلا يُرفض الحذف حفاظًا على السجلات.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // الخادم يرفض الحذف إن وُجدت خدمات نشطة — رسالته الحرفية تظهر
      final message = await widget.store.deleteServiceCategory(target.id);
      if (mounted) showAppToast(context, message);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الخدمات',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    'كتالوج الخدمات التي يطلبها الضيوف خلال الإقامة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('الخدمات'),
                          icon: Icon(Icons.room_service_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('الأقسام'),
                          icon: Icon(Icons.folder_open_rounded, size: 18),
                        ),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (s) =>
                          setState(() => _tab = s.first),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? _servicesTab(context, store)
                  : _categoriesTab(context, store),
            ),
          ],
        );
      },
    );
  }

  // ───────────── تبويب الخدمات ─────────────

  Widget _servicesTab(BuildContext context, AdminStore store) {
    final services = store.services;
    final categories = store.serviceCategories;
    final filtered = services
        .where((s) => _catFilter == 'all' || s.categoryId == _catFilter)
        .toList(growable: false);

    final Widget content;
    if (_error != null && services.isEmpty && categories.isEmpty) {
      content = ErrorRetryView(message: _error!, onRetry: _refresh);
    } else if (store.servicesLoading && services.isEmpty) {
      content = _tableSkeleton();
    } else if (filtered.isEmpty) {
      content = EmptyState(
        icon: Icons.room_service_rounded,
        title: 'لا توجد خدمات',
        subtitle: 'أضف خدمات يطلبها الضيوف من تطبيق الإقامة',
      );
    } else {
      content = Column(
        children: [
          for (final s in filtered) ...[
            _serviceCard(context, s),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _categoryFilterRow(categories),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${filtered.length} خدمة',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: categories.isEmpty
                    ? null
                    : () => _openServiceDialog(null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة خدمة'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _categoryFilterRow(List<AdminServiceCategory> categories) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: const Text('كل الأقسام'),
              selected: _catFilter == 'all',
              onSelected: (_) => setState(() => _catFilter = 'all'),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: _catFilter == c.id,
                onSelected: (_) => setState(() => _catFilter = c.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, AdminService s) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Opacity(
        opacity: s.active ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      if (s.nameEn.isNotEmpty)
                        Text(
                          s.nameEn,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: s.active,
                  onChanged: (_) => _toggleActive(s),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    s.categoryName,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                if (s.priceCents == 0)
                  const Text(
                    'مجاني',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  )
                else
                  MoneyText(s.priceCents),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'تعديل ${s.name}',
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _openServiceDialog(s),
                ),
                IconButton(
                  tooltip: 'حذف ${s.name}',
                  icon: Icon(Icons.delete_rounded,
                      size: 20, color: scheme.error),
                  onPressed: () => _confirmDeleteService(s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── تبويب الأقسام ─────────────

  Widget _categoriesTab(BuildContext context, AdminStore store) {
    final categories = store.serviceCategories;

    final Widget content;
    if (_error != null && categories.isEmpty) {
      content = ErrorRetryView(message: _error!, onRetry: _refresh);
    } else if (store.categoriesLoading && categories.isEmpty) {
      content = _tableSkeleton();
    } else if (categories.isEmpty) {
      content = const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'لا توجد أقسام',
      );
    } else {
      content = LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 900
              ? 3
              : (c.maxWidth >= 600 ? 2 : 1);
          final w = (c.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final cat in categories)
                SizedBox(width: w, child: _categoryCard(context, cat)),
            ],
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              Text(
                '${categories.length} قسم',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _openCategoryDialog(null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة قسم'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _categoryCard(BuildContext context, AdminServiceCategory c) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    if (c.key.isNotEmpty)
                      Text(
                        c.key,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${c.servicesCount} خدمة',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (c.icon.isNotEmpty)
                _metaChip(context, Icons.category_rounded, c.icon,
                    ltr: true),
              _metaChip(context, Icons.sort_rounded,
                  'الترتيب: ${c.sortOrder}'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _openCategoryDialog(c),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('تعديل'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: scheme.error,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _confirmDeleteCategory(c),
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(BuildContext context, IconData icon, String text,
      {bool ltr = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          textDirection: ltr ? TextDirection.ltr : null,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _tableSkeleton() {
    return Column(
      children: [
        for (var i = 0; i < 6; i++) ...[
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x11000000),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ───────────────── حوار خدمة (إضافة/تعديل) ─────────────────

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({
    required this.store,
    required this.categories,
    this.editing,
  });

  final AdminStore store;
  final List<AdminServiceCategory> categories;
  final AdminService? editing;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late String _categoryId;
  late bool _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _nameEn = TextEditingController(text: e?.nameEn ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    // centsToDollarsInput في الويب — الفارغ عند الصفر (مجانية)
    _price = TextEditingController(
        text: (e != null && e.priceCents != 0)
            ? (e.priceCents / 100).toStringAsFixed(2)
            : '');
    _categoryId = e?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'اسم الخدمة مطلوب', error: true);
      return;
    }
    if (_categoryId.isEmpty) {
      showAppToast(context, 'اختر القسم', error: true);
      return;
    }
    // الإدخال بالدولار عشريًا والإرسال بالسنت int (×100 round آمنة)
    final priceRaw = _price.text.trim();
    int cents = 0;
    if (priceRaw.isNotEmpty) {
      final n = double.tryParse(priceRaw);
      if (n == null || n.isNaN || n.isInfinite || n < 0 || n > 1e9) {
        showAppToast(context, 'أدخل سعرًا صحيحًا بالدولار (0 لمجانية)',
            error: true);
        return;
      }
      cents = (n * 100).round();
    }
    final body = <String, dynamic>{
      'name': name,
      'nameEn': _nameEn.text,
      'description': _description.text,
      'priceCents': cents,
      'categoryId': _categoryId,
      'active': _active,
    };
    setState(() => _busy = true);
    try {
      final editing = widget.editing;
      if (editing != null) {
        await widget.store.updateService(editing.id, body);
      } else {
        await widget.store.createService(body);
      }
      if (!mounted) return;
      showAppToast(
          context, editing != null ? 'تم تحديث الخدمة' : 'تمت إضافة الخدمة');
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.editing != null
                    ? 'تعديل: ${widget.editing!.name}'
                    : 'إضافة خدمة',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'ستظهر للضيوف في تطبيق الإقامة حسب قسمها',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('service-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'الاسم *',
                  hintText: 'توصيل مطعم',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameEn,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'الاسم (إنجليزي)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 2,
                minLines: 2,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoryId.isEmpty ? null : _categoryId,
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v ?? ''),
                decoration:
                    const InputDecoration(labelText: 'القسم *'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('service-price'),
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: r'السعر ($) — اتركه فارغًا للمجانية',
                  hintText: '5',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(width: 8),
                  Text(_active ? 'نشطة' : 'معطّلة'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(widget.editing != null ? 'حفظ' : 'إضافة'),
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

// ───────────────── حوار قسم (إضافة/تعديل) ─────────────────

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.store, this.editing});

  final AdminStore store;
  final AdminServiceCategory? editing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _icon;
  late final TextEditingController _sortOrder;
  late String _key;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _icon = TextEditingController(text: e?.icon ?? '');
    _sortOrder = TextEditingController(
        text: e != null ? '${e.sortOrder}' : '0');
    _key = e?.key ?? 'OTHER';
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'اسم القسم مطلوب', error: true);
      return;
    }
    final body = <String, dynamic>{
      'name': name,
      'key': _key,
      'icon': _icon.text,
      'sortOrder': int.tryParse(_sortOrder.text.trim()) ?? 0,
    };
    setState(() => _busy = true);
    try {
      final editing = widget.editing;
      if (editing != null) {
        await widget.store.updateServiceCategory(editing.id, body);
      } else {
        await widget.store.createServiceCategory(body);
      }
      if (!mounted) return;
      showAppToast(
          context, editing != null ? 'تم تحديث القسم' : 'تمت إضافة القسم');
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.editing != null
                    ? 'تعديل: ${widget.editing!.name}'
                    : 'إضافة قسم',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'الأقسام تُصنّف الخدمات في تطبيق الضيف والاستقبال',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('category-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم القسم *',
                  hintText: 'خدمات إضافية',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'المفتاح *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final e in _categoryKeys.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _key == e.key,
                      onSelected: (_) => setState(() => _key = e.key),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('category-icon'),
                      controller: _icon,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'الأيقونة (lucide)',
                        hintText: 'sparkles',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('category-sort'),
                      controller: _sortOrder,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration:
                          const InputDecoration(labelText: 'الترتيب'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(widget.editing != null ? 'حفظ' : 'إضافة'),
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

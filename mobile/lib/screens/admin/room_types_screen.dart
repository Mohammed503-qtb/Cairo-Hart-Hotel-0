// ─────────────────────────────────────────────────────────────
// ADMIN ROOM TYPES SCREEN — أنواع الغرف (A-04..A-07)
// نقل حرفي لـ sections/room-types.tsx: بطاقة نوع (صورة/نشط/سعر
// أساسي/سعة/سرير/مساحة/مرافق/عدد الغرف والحجوزات والمعدلات)
// + نموذج كامل للإضافة/التعديل (بالمال بالدولار → سنت)
// + حذف ناعم إن وُجدت ارتباطات (رسالة الخادم تُعرض)
// صفر HTTP هنا: كل نداء عبر AdminStore (نمط F1/F4)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

/// خيارات الصور — IMAGE_CHOICES في الويب حرفيًا
const List<String> _imageChoices = [
  '/images/room-single.png',
  '/images/room-double.png',
  '/images/room-deluxe.png',
  '/images/room-family.png',
  '/images/facility-lobby.png',
  '/images/facility-restaurant.png',
  '/images/facility-terrace.png',
  '/images/gallery-corridor.png',
];

class RoomTypesScreen extends StatefulWidget {
  const RoomTypesScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<RoomTypesScreen> createState() => _RoomTypesScreenState();
}

class _RoomTypesScreenState extends State<RoomTypesScreen> {
  String? _error;
  bool _busy = false;

  AdminStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await store.refreshRoomTypes();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _error = null);
  }

  // ───────────── العمليات (كلها عبر المتجر) ─────────────

  /// تبديل التفعيل — PATCH بجسم {active} فقط (toggleActive في الويب)
  Future<void> _toggleActive(AdminRoomType type) async {
    setState(() => _busy = true);
    try {
      await store.updateRoomType(type.id, {'active': !type.active});
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذّر تنفيذ العملية — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// حذف/تعطيل — الخادم يقرر (حذف ناعم إن وُجدت ارتباطات)
  Future<void> _confirmDelete(AdminRoomType type) async {
    final scheme = Theme.of(context).colorScheme;
    final linked =
        type.roomsCount > 0 || type.reservationsCount > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('حذف نوع «${type.name}»؟'),
        content: Text(
          linked
              ? 'هذا النوع مرتبط بـ ${type.roomsCount} غرفة '
                  'و${type.reservationsCount} حجز — سيتم تعطيله '
                  '(إخفاؤه من الحجز) بدلًا من حذفه للحفاظ على سجلات الحجوزات.'
              : 'لا توجد ارتباطات — سيتم حذف النوع نهائيًا.',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final message = await store.deleteRoomType(type.id);
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

  Future<void> _openForm([AdminRoomType? editing]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RoomTypeFormDialog(store: store, editing: editing),
    );
  }

  // ───────────── البناء ─────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final types = store.roomTypes;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'أنواع الغرف',
                icon: Icons.bed_rounded,
                iconColor: scheme.primary,
                action: FilledButton.icon(
                  onPressed: _busy ? null : () => _openForm(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة نوع'),
                ),
              ),
              Text(
                '${types.length} نوع — السعر الأساسي لكل نوع + المزايا والصور',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null && types.isEmpty)
                AppCard(
                  child: ErrorRetryView(
                    message: _error!,
                    onRetry: _refresh,
                  ),
                )
              else if (store.roomTypesLoading && types.isEmpty)
                _typesSkeleton(context)
              else if (types.isEmpty)
                const AppCard(
                  child: EmptyState(
                    icon: Icons.bed_rounded,
                    title: 'لا توجد أنواع غرف',
                    subtitle: 'أضف أول نوع غرفة ليظهر في الموقع ومحرك الحجز',
                  ),
                )
              else
                LayoutBuilder(builder: (context, c) {
                  const spacing = 10.0;
                  final columns = c.maxWidth >= 900
                      ? 3
                      : (c.maxWidth >= 620 ? 2 : 1);
                  final cardWidth =
                      (c.maxWidth - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final type in types)
                        SizedBox(
                          width: cardWidth,
                          child: _RoomTypeCard(
                            type: type,
                            busy: _busy,
                            onToggleActive: () => _toggleActive(type),
                            onEdit: () => _openForm(type),
                            onDelete: () => _confirmDelete(type),
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ───────────── عناصر خاصة بالملف ─────────────

/// هياكل تحميل (بطاقات الأنواع في الويب)
Widget _typesSkeleton(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      for (var i = 0; i < 4; i++) ...[
        Container(
          height: 150,
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

/// معاينة صورة نوع — Image.network مع بديل أيقونة (ImageOff في الويب).
/// في بيئة بلا عنوان خادم (الاختبارات) يظهر البديل مباشرة.
Widget _imagePreview(BuildContext context, String? path) {
  final scheme = Theme.of(context).colorScheme;
  Widget fallback() => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 30,
          color: scheme.onSurfaceVariant,
        ),
      );
  if (path == null || path.isEmpty || !AppConfig.hasBaseUrl) {
    return fallback();
  }
  return Image.network(
    '${AppConfig.baseUrl}$path',
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => fallback(),
    loadingBuilder: (context, child, progress) =>
        progress == null ? child : fallback(),
  );
}

/// بطاقة نوع غرفة واحدة — بطاقة الويب كاملة
class _RoomTypeCard extends StatelessWidget {
  const _RoomTypeCard({
    required this.type,
    required this.busy,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminRoomType type;
  final bool busy;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerImage = type.images.isNotEmpty ? type.images.first : null;
    return Opacity(
      opacity: type.active ? 1 : 0.6,
      child: AppCard(
        padding: EdgeInsets.zero,
        border: BorderSide(color: scheme.outlineVariant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الصورة + شارة النشاط (absolute top-left في الويب)
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _imagePreview(context, headerImage),
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: type.active
                          ? AppColors.success
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.active ? 'نشط' : 'معطّل',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: type.active
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                              type.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (type.nameEn.isNotEmpty)
                              Text(
                                type.nameEn,
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
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
                          Text(
                            fmt.formatMoney(type.basePriceCents),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  // السعة / المساحة / الغرف الفعلية (سطر الويب)
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${type.capacityAdults} بالغ + '
                          '${type.capacityChildren} طفل',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (type.sizeSqm > 0) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.straighten_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${type.sizeSqm} م²',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (type.bedConfig.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      type.bedConfig,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // عدد الغرف والحجوزات والمعدلات المرتبطة
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _countChip(
                        context,
                        Icons.door_front_door_rounded,
                        '${type.roomsCount} غرفة فعلية',
                      ),
                      _countChip(
                        context,
                        Icons.content_paste_rounded,
                        '${type.reservationsCount} حجز',
                      ),
                      _countChip(
                        context,
                        Icons.calendar_month_rounded,
                        '${type.ratesCount} معدل',
                      ),
                    ],
                  ),
                  if (type.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final a in type.amenities.take(4))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              a,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (type.amenities.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '+${type.amenities.length - 4}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: scheme.outlineVariant, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: type.active,
                        onChanged: busy ? null : (_) => onToggleActive(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          type.active ? 'معروض' : 'مخفي',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'تعديل ${type.name}',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      ),
                      IconButton(
                        tooltip: 'حذف ${type.name}',
                        onPressed: onDelete,
                        color: scheme.error,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ───────────── حوار إضافة/تعديل نوع غرفة (نموذج كامل) ─────────────

class _RoomTypeFormDialog extends StatefulWidget {
  const _RoomTypeFormDialog({required this.store, this.editing});

  final AdminStore store;
  final AdminRoomType? editing;

  @override
  State<_RoomTypeFormDialog> createState() => _RoomTypeFormDialogState();
}

class _RoomTypeFormDialogState extends State<_RoomTypeFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _description;
  late final TextEditingController _bedConfig;
  late final TextEditingController _sizeSqm;
  late final TextEditingController _basePrice;
  late final TextEditingController _sortOrder;
  late final TextEditingController _amenityInput;

  late String _capacityAdults;
  late String _capacityChildren;
  late List<String> _amenities;
  late List<String> _images;
  late bool _active;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _name = TextEditingController(text: editing?.name ?? '');
    _nameEn = TextEditingController(text: editing?.nameEn ?? '');
    _description = TextEditingController(text: editing?.description ?? '');
    _bedConfig = TextEditingController(text: editing?.bedConfig ?? '');
    _sizeSqm = TextEditingController(
      text: editing == null || editing.sizeSqm == 0
          ? ''
          : '${editing.sizeSqm}',
    );
    // centsToDollarsInput في الويب: (cents / 100).toFixed(2)
    _basePrice = TextEditingController(
      text: editing == null
          ? ''
          : (editing.basePriceCents / 100).toStringAsFixed(2),
    );
    _sortOrder =
        TextEditingController(text: '${editing?.sortOrder ?? 0}');
    _amenityInput = TextEditingController();
    _capacityAdults = '${editing?.capacityAdults ?? 2}';
    _capacityChildren = '${editing?.capacityChildren ?? 0}';
    _amenities = [...? editing?.amenities];
    _images = [...? editing?.images];
    _active = editing?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _description.dispose();
    _bedConfig.dispose();
    _sizeSqm.dispose();
    _basePrice.dispose();
    _sortOrder.dispose();
    _amenityInput.dispose();
    super.dispose();
  }

  void _addAmenity() {
    final v = _amenityInput.text.trim();
    if (v.isNotEmpty && !_amenities.contains(v)) {
      setState(() => _amenities = [..._amenities, v]);
    }
    _amenityInput.clear();
  }

  void _toggleImage(String path) {
    setState(() {
      _images = _images.contains(path)
          ? _images.where((x) => x != path).toList(growable: true)
          : [..._images, path];
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'اسم النوع مطلوب', error: true);
      return;
    }
    // تحويل الدولار للسنت (كما الويب): parse → ×100 → round
    final cents =
        ((double.tryParse(_basePrice.text.trim()) ?? 0) * 100).round();
    if (cents <= 0) {
      showAppToast(context, 'أدخل سعرًا أساسيًا صحيحًا بالدولار', error: true);
      return;
    }
    final body = <String, dynamic>{
      'name': name,
      'nameEn': _nameEn.text,
      'description': _description.text,
      'capacityAdults': int.tryParse(_capacityAdults) ?? 2,
      'capacityChildren': int.tryParse(_capacityChildren) ?? 0,
      'bedConfig': _bedConfig.text,
      'sizeSqm': int.tryParse(_sizeSqm.text.trim()) ?? 0,
      'basePriceCents': cents,
      'amenities': _amenities,
      'images': _images,
      'sortOrder': int.tryParse(_sortOrder.text.trim()) ?? 0,
      'active': _active,
    };
    setState(() => _loading = true);
    try {
      final editing = widget.editing;
      if (editing != null) {
        await widget.store.updateRoomType(editing.id, body);
        if (!mounted) return;
        showAppToast(context, 'تم تحديث نوع الغرفة');
      } else {
        await widget.store.createRoomType(body);
        if (!mounted) return;
        showAppToast(context, 'تمت إضافة نوع الغرفة');
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
    final editing = widget.editing;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing != null ? 'تعديل: ${editing.name}' : 'إضافة نوع غرفة',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                editing != null
                    ? 'عدّل بيانات النوع — التغييرات تظهر في الموقع فورًا'
                    : 'نوع جديد سيظهر في محرك الحجز على الموقع',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'الاسم (عربي) *',
                        hintText: 'غرفة اقتصادية',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nameEn,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'الاسم (إنجليزي)',
                        hintText: 'Economy Room',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _capacityField(
                      context,
                      label: 'البالغون (1-8)',
                      value: _capacityAdults,
                      count: 8,
                      from: 1,
                      onChanged: (v) =>
                          setState(() => _capacityAdults = v ?? '2'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _capacityField(
                      context,
                      label: 'الأطفال (0-6)',
                      value: _capacityChildren,
                      count: 7,
                      from: 0,
                      onChanged: (v) =>
                          setState(() => _capacityChildren = v ?? '0'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bedConfig,
                      decoration: const InputDecoration(
                        labelText: 'تجهيز السرير',
                        hintText: 'سرير ملكي واحد',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _sizeSqm,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المساحة (م²)',
                        hintText: '22',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _basePrice,
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: const InputDecoration(
                        labelText: 'السعر الأساسي لليلة ($) *',
                        hintText: '50',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _sortOrder,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الترتيب',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // المزايا — tag input كما الويب
              const Text(
                'المزايا (اكتب ثم Enter)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amenityInput,
                      onSubmitted: (_) => _addAmenity(),
                      decoration: const InputDecoration(
                        hintText: 'واي فاي مجاني',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addAmenity,
                    child: const Text('إضافة'),
                  ),
                ],
              ),
              if (_amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in _amenities)
                        InputChip(
                          label: Text(a),
                          onDeleted: () => setState(
                            () => _amenities =
                                _amenities.where((x) => x != a).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // الصور — نفس اختيارات الويب الثمانية
              const Text(
                'الصور',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in _imageChoices)
                    _imageChoiceTile(
                      context,
                      path: path,
                      selected: _images.contains(path),
                      onToggle: () => _toggleImage(path),
                    ),
                ],
              ),
              if (_images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_images.length} صورة مختارة — الأولى هي الرئيسية',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _active
                          ? 'نشط — يظهر في الموقع'
                          : 'معطّل — مخفي من الحجز',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      editing != null ? 'حفظ التعديلات' : 'إضافة النوع',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// حقل اختيار السعة (Select 1..8 / 0..6 في الويب)
  Widget _capacityField(
    BuildContext context, {
    required String label,
    required String value,
    required int count,
    required int from,
    required ValueChanged<String?> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
              value: value,
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (var n = from; n < from + count; n++)
                  DropdownMenuItem(value: '$n', child: Text('$n')),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// مربع اختيار صورة واحدة (checkbox فوق معاينة في الويب)
  Widget _imageChoiceTile(
    BuildContext context, {
    required String path,
    required bool selected,
    required VoidCallback onToggle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 112,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.gold : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imagePreview(context, path),
              PositionedDirectional(
                top: 4,
                start: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: selected ? AppColors.gold : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

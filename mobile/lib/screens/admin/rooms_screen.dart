// ─────────────────────────────────────────────────────────────
// ADMIN ROOMS SCREEN — الغرف الفعلية (A-08..A-11)
// نقل حرفي لـ sections/rooms.tsx: فلاتر (طابق/حالة/نوع) + بحث برقم
// + بطاقة كل غرفة (الرقم/الطابق/النوع/الحالة/الضيف/الملاحظات)
// + إضافة/تعديل/حذف + تبديل سريع للحالة
// (OCCUPIED لا تُضبط يدويًا إطلاقًا — الخادم يرفضها حرفيًا)
// صفر HTTP هنا: كل نداء عبر AdminStore (نمط F1/F4)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

/// تبديل سريع للحالة (QUICK_STATUSES في الويب)
const List<(String, String)> _quickStatuses = [
  ('AVAILABLE', 'متاحة'),
  ('CLEANING', 'تنظيف جارٍ'),
  ('DIRTY', 'تحتاج تنظيف'),
  ('OUT_OF_ORDER', 'خارج الخدمة'),
];

/// الحالات القابلة للضبط يدويًا (EDITABLE_STATUSES في الويب)
/// — OCCUPIED غائب إطلاقًا: الحجز يتم عبر تسجيل الوصول من الاستقبال
const List<(String, String)> _editableStatuses = [
  ('AVAILABLE', 'متاحة'),
  ('RESERVED', 'محجوزة'),
  ('CLEANING', 'تنظيف جارٍ'),
  ('DIRTY', 'تحتاج تنظيف'),
  ('OUT_OF_ORDER', 'خارج الخدمة'),
];

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  String? _error;
  String _floorFilter = 'all';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _searchQuery = '';
  bool _busy = false;

  AdminStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// عند فتح الشاشة: refreshRooms ثم refreshRoomTypes (الأنواع
  /// مطلوبة لحواري الإنشاء/التعديل). فشل الأنواع صامت كالويب.
  Future<void> _refresh() async {
    try {
      await store.refreshRooms();
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
      // الأنواع اختيارية هنا — تُعاد المحاولة عند فتح الشاشة ثانية
    }
  }

  List<AdminRoom> _filteredRooms() {
    final q = _searchQuery.trim();
    return store.rooms.where((r) {
      if (_floorFilter != 'all' && '${r.floor}' != _floorFilter) {
        return false;
      }
      if (_statusFilter != 'all' && r.status != _statusFilter) return false;
      if (_typeFilter != 'all' && r.roomTypeId != _typeFilter) return false;
      if (q.isNotEmpty && !r.number.contains(q)) return false;
      return true;
    }).toList(growable: false);
  }

  // ───────────── العمليات (كلها عبر المتجر) ─────────────

  /// تبديل سريع: PATCH بجسم {status} فقط — كما quickStatus في الويب
  Future<void> _quickStatus(AdminRoom room, String status) async {
    setState(() => _busy = true);
    try {
      await store.updateRoom(room.id, {'status': status});
      if (!mounted) return;
      showAppToast(
        context,
        'الغرفة ${room.number} → ${fmt.label(fmt.roomStatusLabels, status)}',
      );
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذّر تنفيذ العملية — ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// حذف محمي — تأكيد حرفي ثم DELETE برسالة الخادم
  Future<void> _confirmDelete(AdminRoom room) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('حذف الغرفة ${room.number}؟'),
        content: const Text(
          'الحذف نهائي ولا يتاح إلا للغرف بدون أي سجل إقامات. '
          'إن كانت الغرفة لها تاريخ إقامات فاستخدم حالة «خارج الخدمة» '
          'بدلًا من الحذف للحفاظ على السجلات.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final message = await store.deleteRoom(room.id);
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

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CreateRoomDialog(store: store),
    );
  }

  Future<void> _openEditDialog(AdminRoom room) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditRoomDialog(store: store, room: room),
    );
  }

  // ───────────── البناء ─────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final rooms = store.rooms;
        final occupied =
            rooms.where((r) => r.status == 'OCCUPIED').length;
        final outOfOrder =
            rooms.where((r) => r.status == 'OUT_OF_ORDER').length;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'الغرف',
                icon: Icons.door_front_door_rounded,
                iconColor: scheme.primary,
                action: FilledButton.icon(
                  onPressed: _busy ? null : _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة غرفة'),
                ),
              ),
              Text(
                '${rooms.length} غرفة — $occupied مشغولة · '
                '$outOfOrder خارج الخدمة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null && rooms.isEmpty)
                AppCard(
                  child: ErrorRetryView(
                    message: _error!,
                    onRetry: _refresh,
                  ),
                )
              else if (store.roomsLoading && rooms.isEmpty)
                _tableSkeleton(context)
              else ...[
                _filtersBar(context),
                const SizedBox(height: 12),
                if (_filteredRooms().isEmpty)
                  const AppCard(
                    child: EmptyState(
                      icon: Icons.door_front_door_rounded,
                      title: 'لا توجد غرف مطابقة',
                      subtitle: 'غيّر الفلاتر أو أضف غرفة جديدة',
                    ),
                  )
                else
                  for (final room in _filteredRooms()) ...[
                    _RoomCard(
                      room: room,
                      busy: _busy,
                      onQuickStatus: (status) => _quickStatus(room, status),
                      onEdit: () => _openEditDialog(room),
                      onDelete: () => _confirmDelete(room),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ],
          ),
        );
      },
    );
  }

  /// فلاتر الطابق/الحالة/النوع + بحث برقم الغرفة
  Widget _filtersBar(BuildContext context) {
    final floors = store.rooms.map((r) => r.floor).toSet().toList()
      ..sort();
    final types = store.roomTypes;
    final search = TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      textDirection: TextDirection.ltr,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: const InputDecoration(
        hintText: 'بحث برقم الغرفة…',
        prefixIcon: Icon(Icons.search_rounded, size: 20),
        isDense: true,
      ),
    );
    final status = _selectShell(
      context,
      DropdownButton<String>(
        isExpanded: true,
        value: _statusFilter,
        icon: const Icon(Icons.expand_more_rounded, size: 20),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
          for (final e in fmt.roomStatusLabels.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
      ),
    );
    final floor = _selectShell(
      context,
      DropdownButton<String>(
        isExpanded: true,
        value: _floorFilter,
        icon: const Icon(Icons.expand_more_rounded, size: 20),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('كل الطوابق')),
          for (final f in floors)
            DropdownMenuItem(value: '$f', child: Text('الطابق $f')),
        ],
        onChanged: (v) => setState(() => _floorFilter = v ?? 'all'),
      ),
    );
    final type = _selectShell(
      context,
      DropdownButton<String>(
        isExpanded: true,
        value: _typeFilter,
        icon: const Icon(Icons.expand_more_rounded, size: 20),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('كل الأنواع')),
          for (final t in types)
            DropdownMenuItem(value: t.id, child: Text(t.name)),
        ],
        onChanged: (v) => setState(() => _typeFilter = v ?? 'all'),
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 560;
      if (wide) {
        return Column(
          children: [
            search,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 8),
                Expanded(child: floor),
                const SizedBox(width: 8),
                Expanded(child: type),
              ],
            ),
          ],
        );
      }
      return Column(
        children: [
          search,
          const SizedBox(height: 8),
          status,
          const SizedBox(height: 8),
          floor,
          const SizedBox(height: 8),
          type,
        ],
      );
    });
  }
}

// ───────────── عناصر خاصة بالملف ─────────────

/// إطار قائمة منسدلة (نفس نمط الويب Select)
Widget _selectShell(BuildContext context, Widget child) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outline),
      color: scheme.surfaceContainerHighest,
    ),
    child: DropdownButtonHideUnderline(child: child),
  );
}

/// هياكل تحميل (TableSkeleton في الويب)
Widget _tableSkeleton(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      for (var i = 0; i < 6; i++) ...[
        Container(
          height: 88,
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

/// بطاقة غرفة واحدة — صف الجدول في الويب (الرقم/النوع/الطابق/
/// الحالة/الضيف الحالي وموعد خروجه/الملاحظات + قائمة الإجراءات)
class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.busy,
    required this.onQuickStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminRoom room;
  final bool busy;
  final void Function(String status) onQuickStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final guest = room.guestName;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                room.number,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              StatusChip.roomStatus(context, room.status),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'إجراءات الغرفة ${room.number}',
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                enabled: !busy,
                onSelected: (v) {
                  if (v == 'edit') {
                    onEdit();
                    return;
                  }
                  if (v == 'delete') {
                    onDelete();
                    return;
                  }
                  onQuickStatus(v);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    enabled: false,
                    height: 36,
                    child: Text(
                      'تبديل سريع للحالة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final (value, label) in _quickStatuses)
                    PopupMenuItem<String>(
                      value: value,
                      enabled: !busy && room.status != value,
                      height: 42,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    height: 44,
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('تعديل الغرفة'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    height: 44,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'حذف',
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.bed_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.roomTypeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.layers_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'الطابق ${room.floor}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // الضيف الحالي وموعد الخروج — إن مشغولة (كالويب)
          if (guest != null && guest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (room.expectedCheckOut != null &&
                            room.expectedCheckOut!.isNotEmpty)
                          Text(
                            'خروج: ${fmt.formatDateAr(room.expectedCheckOut)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (room.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    room.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────── حوار إضافة غرفة ─────────────

class _CreateRoomDialog extends StatefulWidget {
  const _CreateRoomDialog({required this.store});

  final AdminStore store;

  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _floor = TextEditingController(text: '1');
  final TextEditingController _notes = TextEditingController();
  String _roomTypeId = '';
  bool _loading = false;

  @override
  void dispose() {
    _number.dispose();
    _floor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final number = _number.text.trim();
    if (number.isEmpty) {
      showAppToast(context, 'رقم الغرفة مطلوب', error: true);
      return;
    }
    if (_roomTypeId.isEmpty) {
      showAppToast(context, 'اختر نوع الغرفة', error: true);
      return;
    }
    final floor = int.tryParse(_floor.text.trim()) ?? 1;
    setState(() => _loading = true);
    try {
      await widget.store.createRoom(
        number: number,
        floor: floor,
        roomTypeId: _roomTypeId,
        notes: _notes.text,
      );
      if (!mounted) return;
      showAppToast(context, 'تمت إضافة الغرفة $number');
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
                'إضافة غرفة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'غرفة فعلية جديدة — تبدأ بحالة «متاحة»',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _number,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رقم الغرفة *',
                  hintText: '107',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _floor,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الطابق (1-30)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'نوع الغرفة *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _selectShell(
                context,
                DropdownButton<String>(
                  isExpanded: true,
                  value: _roomTypeId.isEmpty ? null : _roomTypeId,
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
                      DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.name} — ${t.roomsCount} غرفة'),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _roomTypeId = v ?? _roomTypeId),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'صيانة تكييف…',
                ),
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
}

// ───────────── حوار تعديل غرفة ─────────────

class _EditRoomDialog extends StatefulWidget {
  const _EditRoomDialog({required this.store, required this.room});

  final AdminStore store;
  final AdminRoom room;

  @override
  State<_EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<_EditRoomDialog> {
  late final TextEditingController _floor;
  late final TextEditingController _notes;
  late String _roomTypeId;
  String? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _floor = TextEditingController(text: '${widget.room.floor}');
    _notes = TextEditingController(text: widget.room.notes);
    _roomTypeId = widget.room.roomTypeId;
    // OCCUPIED ليست خيارًا — إن كانت الغرفة مشغولة تبدأ بلا اختيار
    // (كالويب: Select بلا عنصر مطابق) وتبقى قيمتها ترسل كما هي
    _status = _editableStatuses.any((s) => s.$1 == widget.room.status)
        ? widget.room.status
        : null;
  }

  @override
  void dispose() {
    _floor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final floor = int.tryParse(_floor.text.trim()) ?? 1;
    setState(() => _loading = true);
    try {
      await widget.store.updateRoom(widget.room.id, {
        'floor': floor,
        'roomTypeId': _roomTypeId,
        'status': _status ?? widget.room.status,
        'notes': _notes.text,
      });
      if (!mounted) return;
      showAppToast(context, 'تم تحديث الغرفة ${widget.room.number}');
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
    final typeKnown = types.any((t) => t.id == _roomTypeId);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل الغرفة ${widget.room.number}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'لا يمكن ضبط «مشغولة» يدويًا — الحجز يتم عبر تسجيل الوصول',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _floor,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الطابق (1-30)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'نوع الغرفة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _selectShell(
                context,
                DropdownButton<String>(
                  isExpanded: true,
                  value: typeKnown ? _roomTypeId : null,
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
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _roomTypeId = v ?? _roomTypeId),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'الحالة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _selectShell(
                context,
                DropdownButton<String>(
                  isExpanded: true,
                  value: _status,
                  hint: Text(
                    'اختر الحالة',
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
                    // OCCUPIED غائب إطلاقًا عن الخيارات
                    for (final (value, label) in _editableStatuses)
                      DropdownMenuItem(
                        value: value,
                        child: Text(label),
                      ),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
              if (widget.room.status == 'OCCUPIED') ...[
                const SizedBox(height: 6),
                Text(
                  'الغرفة مشغولة حاليًا بتسجيل وصول — تغيير الحالة تجاوز إداري.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'صيانة تكييف…',
                ),
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
                    label: const Text('حفظ'),
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

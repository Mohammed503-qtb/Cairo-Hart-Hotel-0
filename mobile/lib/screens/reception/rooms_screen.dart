// ─────────────────────────────────────────────────────────────
// ROOMS SCREEN — لوحة الغرف مصنفة بالطوابق (R-10/R-11)
// نقل حرفي لـ rooms-view.tsx + room-dialog.tsx (حوار الغرفة في
// نفس الملف) — الانتقالات DIRTY/CLEANING/AVAILABLE/OOO/OCCUPIED
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
import 'stay_detail_screen.dart';

/// دليل الألوان (LEGEND في الويب)
const List<({String status, Color color})> _legend = [
  (status: 'AVAILABLE', color: AppColors.success),
  (status: 'OCCUPIED', color: AppColors.danger),
  (status: 'CLEANING', color: AppColors.gold),
  (status: 'DIRTY', color: AppColors.warning),
  (status: 'OUT_OF_ORDER', color: Color(0xFF262626)),
];

/// ألوان بطاقة الغرفة (ROOM_CARD_STYLE في الويب): خلفية/حد/نص
(Color, Color, Color) _roomCardStyle(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    'AVAILABLE' => (
        AppColors.success.withValues(alpha: 0.10),
        AppColors.success.withValues(alpha: 0.40),
        AppColors.success,
      ),
    'OCCUPIED' => (
        AppColors.danger.withValues(alpha: 0.10),
        AppColors.danger.withValues(alpha: 0.40),
        scheme.onSurface,
      ),
    'RESERVED' => (
        scheme.primary.withValues(alpha: 0.10),
        scheme.primary.withValues(alpha: 0.30),
        scheme.primary,
      ),
    'CLEANING' => (
        AppColors.gold.withValues(alpha: 0.15),
        AppColors.gold.withValues(alpha: 0.40),
        AppColors.goldDark,
      ),
    'DIRTY' => (
        AppColors.warning.withValues(alpha: 0.15),
        AppColors.warning.withValues(alpha: 0.50),
        AppColors.warning,
      ),
    'OUT_OF_ORDER' => (
        const Color(0xE6262626),
        const Color(0xFF171717),
        const Color(0xFFE5E5E5),
      ),
    _ => (
        scheme.surfaceContainerHighest,
        scheme.outlineVariant,
        scheme.onSurface,
      ),
  };
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  /// rooms !== null في الويب — يظهر العدّاد في العنوان
  bool _loaded = false;
  String? _error;

  ReceptionStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    // التحميل الذاتي عند الفراغ فقط (bootstrap قد يكون جلبها أصلًا)
    if (store.rooms.isNotEmpty) {
      _loaded = true;
    } else {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      await store.refreshRooms();
      if (!mounted) return;
      setState(() {
        _error = null;
        _loaded = true;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final rooms = store.rooms;
        // أقسام الطوابق (floors في الويب)
        final floors = <int, List<RoomItem>>{};
        for (final room in rooms) {
          floors.putIfAbsent(room.floor, () => []).add(room);
        }
        final sortedFloors = floors.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        // عدّادات الحالات (counts في الويب)
        final counts = <String, int>{};
        for (final room in rooms) {
          counts[room.status] = (counts[room.status] ?? 0) + 1;
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ReceptionSectionTitle(
                _loaded ? 'حالة الغرف (${rooms.length})' : 'حالة الغرف',
                icon: Icons.grid_view_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              _LegendCard(counts: counts),
              // الخطأ يظهر دائمًا عند وجوده (كما الويب — يعلو الأقسام)
              if (_error != null) ...[
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'تعذر التحميل',
                  subtitle: _error,
                ),
                const SizedBox(height: 12),
              ],
              if (!_loaded && _error == null)
                loadingBlocks(2, height: 130)
              else
                for (final entry in sortedFloors) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.bed_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الطابق ${entry.key}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // شبكة البطاقات (grid-cols-3+ في الويب — Wrap
                  // بعرض ثابت يلتف بعدد أعمدة حسب العرض)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final room in entry.value)
                        _RoomCard(
                          room: room,
                          onTap: () => _showRoomDialog(context, room),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        );
      },
    );
  }

  /// فتح حوار الغرفة — onShowStay يغلق الحوار ثم يفتح تفصيل الإقامة
  /// من سياق الشاشة (كما يفعل RoomsView في الويب)
  Future<void> _showRoomDialog(BuildContext context, RoomItem room) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RoomDialog(
        store: store,
        room: room,
        onShowStay: (stayId) {
          Navigator.of(context).pop();
          showStayDetail(context, store: store, stayId: stayId);
        },
      ),
    );
  }
}

/// دليل الألوان مع العدّادات (Legend في الويب)
class _LegendCard extends StatelessWidget {
  const _LegendCard({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final item in _legend)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  fmt.label(fmt.roomStatusLabels, item.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if ((counts[item.status] ?? 0) > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      '${counts[item.status]}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// بطاقة غرفة واحدة (RoomCard في الويب): عرض ثابت داخل Wrap
class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final RoomItem room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, borderColor, fg) = _roomCardStyle(context, room.status);
    return SizedBox(
      width: 104,
      height: 92,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  room.number,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                ),
                if (room.status == 'OCCUPIED' &&
                    room.guestName != null &&
                    room.guestName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 10, color: fg),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          room.guestName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (room.expectedCheckOutAt != null)
                    Text(
                      'خروج ${fmt.formatDateAr(room.expectedCheckOutAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: fg.withValues(alpha: 0.75),
                      ),
                    ),
                ] else
                  Text(
                    fmt.label(fmt.roomStatusLabels, room.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                if (room.status == 'OUT_OF_ORDER' &&
                    room.notes != null &&
                    room.notes!.isNotEmpty)
                  Text(
                    room.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// حوار الغرفة (room-dialog.tsx): بطاقة ملونة + الانتقالات حسب الحالة
class _RoomDialog extends StatefulWidget {
  const _RoomDialog({
    required this.store,
    required this.room,
    required this.onShowStay,
  });

  final ReceptionStore store;
  final RoomItem room;
  final void Function(String stayId) onShowStay;

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  String? _busy;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// applyStatus: الجسم {status, notes?} → توست + إغلاق الحوار
  Future<void> _applyStatus(String status, {String? extraNotes}) async {
    setState(() => _busy = status);
    try {
      await widget.store.setRoomStatus(
        widget.room.id,
        status,
        notes: extraNotes,
      );
      if (!mounted) return;
      showAppToast(
        context,
        'الغرفة ${widget.room.number}: '
        '${fmt.label(fmt.roomStatusLabels, status)} ✅',
      );
      Navigator.of(context).pop();
    } on ApiError {
      if (!mounted) return;
      setState(() => _busy = null);
      showAppToast(context, 'تعذر تغيير حالة الغرفة', error: true);
    }
  }

  /// تأكيد «اعتماد متاحة» / «خارج الخدمة» (AlertDialog في الويب)
  Future<void> _confirmAndApply({
    required String status,
    String? notes,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(
          status == 'AVAILABLE'
              ? 'اعتماد الغرفة متاحة؟'
              : 'إخراج الغرفة من الخدمة؟',
        ),
        content: Text(
          status == 'AVAILABLE'
              ? 'سيتم اعتماد الغرفة ${widget.room.number} كمتاحة للحجز '
                  'مباشرة دون مرحلة التنظيف.'
              : 'الغرفة ${widget.room.number} لن تُحسب ضمن المخزون المتاح '
                  'حتى إعادتها للخدمة.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('نعم، أكّد'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // الملاحظات تُرسل فقط لإخراج الغرفة من الخدمة (كما الويب)
      await _applyStatus(
        status,
        extraNotes: status == 'OUT_OF_ORDER' ? notes : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final room = widget.room;
    final (bg, borderColor, fg) = _roomCardStyle(context, room.status);
    final occupied =
        room.status == 'OCCUPIED' && room.guestName != null && room.guestName!.isNotEmpty;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الرأس: رقم كبير ببطاقة ملونة + الحالة + النوع/الطابق
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Text(
                      room.number,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fmt.label(fmt.roomStatusLabels, room.status),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${room.roomTypeName} · طابق ${room.floor}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                occupied
                    ? 'مشغولة — ${room.guestName}'
                        '${room.expectedCheckOutAt != null ? ' · خروج ${fmt.formatDateWithDayAr(room.expectedCheckOutAt)}' : ''}'
                    : '${room.roomTypeName} · طابق ${room.floor}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              // بطاقة الضيف إن كانت مشغولة
              if (occupied) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          room.guestName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (room.expectedCheckOutAt != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                fmt.formatDateWithDayAr(
                                    room.expectedCheckOutAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // الملاحظات بتحذير
              if (room.notes != null && room.notes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          room.notes!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // الانتقالات حسب الحالة (نصوص الويب حرفية)
              if (room.status == 'DIRTY')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy != null
                          ? null
                          : () => _applyStatus('CLEANING'),
                      icon: _busy == 'CLEANING'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cleaning_services_rounded,
                              size: 16),
                      label: const Text('بدء التنظيف'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy != null
                          ? null
                          : () => _confirmAndApply(status: 'AVAILABLE'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            scheme.surfaceContainerHighest,
                        foregroundColor: scheme.onSurface,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('متاحة'),
                    ),
                  ],
                )
              else if (room.status == 'CLEANING')
                FilledButton.icon(
                  onPressed: _busy != null
                      ? null
                      : () => _applyStatus('AVAILABLE'),
                  icon: _busy == 'AVAILABLE'
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('اكتمل التنظيف → متاحة'),
                )
              else if (room.status == 'AVAILABLE')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'سبب إخراج الغرفة من الخدمة (اختياري)…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy != null
                          ? null
                          : () => _confirmAndApply(
                                status: 'OUT_OF_ORDER',
                                notes: _notesController.text,
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      icon: _busy == 'OUT_OF_ORDER'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.build_rounded, size: 16),
                      label: const Text('خارج الخدمة'),
                    ),
                  ],
                )
              else if (room.status == 'OUT_OF_ORDER')
                FilledButton.icon(
                  onPressed: _busy != null
                      ? null
                      : () => _applyStatus('AVAILABLE'),
                  icon: _busy == 'AVAILABLE'
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('إعادة للخدمة'),
                )
              else if (room.status == 'OCCUPIED' &&
                  room.activeStayId != null)
                FilledButton.icon(
                  onPressed: () => widget.onShowStay(room.activeStayId!),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurface,
                  ),
                  icon: const Icon(Icons.meeting_room_rounded, size: 16),
                  label: const Text('عرض الإقامة'),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
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

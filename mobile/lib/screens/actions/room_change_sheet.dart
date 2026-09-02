// ─────────────────────────────────────────────────────────────
// ROOM CHANGE SHEET — طلب تغيير الغرفة (نقل room-change-dialog.tsx — G-11/12)
// الغرف المتاحة (رقم/طابق/نوع/فرق السعر) + سبب اختياري
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'sheet_frame.dart';

/// صفيحة تغيير الغرفة — تُفتح عبر showRoomChangeSheet في actions.dart
class RoomChangeSheet extends StatefulWidget {
  const RoomChangeSheet({super.key, required this.store});

  final GuestStore store;

  @override
  State<RoomChangeSheet> createState() => _RoomChangeSheetState();
}

class _RoomChangeSheetState extends State<RoomChangeSheet> {
  List<RoomOption> _rooms = const [];
  CurrentRoomInfo? _current;
  bool _loading = true; // التحميل يبدأ فور الفتح (نفس useEffect في الويب)
  String? _selected;
  late final TextEditingController _reasonController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// G-11: تحميل الغرف المتاحة — الخطأ يُبتلع بصمت (نفس سلوك الويب)
  /// فتظهر حالة «لا غرف متاحة للنقل حاليًا»
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.store.loadRoomOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = res.rooms;
        _current = res.currentRoom;
        _selected = null;
      });
    } catch (_) {
      // تجاهل — نفس الويب: قائمة فارغة عند الفشل
      if (mounted) {
        setState(() => _rooms = const []);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// الغرفة المختارة حاليًا (إن بقيت ضمن القائمة)
  RoomOption? get _selectedRoom {
    final id = _selected;
    if (id == null) {
      return null;
    }
    for (final room in _rooms) {
      if (room.roomId == id) {
        return room;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      // G-12 — فرق السعر يشمل الليالي المتبقية (يحسبه الخادم)
      final request = await widget.store.requestRoomChange(
        selected,
        reason: _reasonController.text,
      );
      if (!mounted) {
        return;
      }
      final diff = request.priceDiffCents;
      final description = diff == 0
          ? 'بدون فرق سعر — بانتظار موافقة الاستقبال'
          : '${diff > 0 ? 'فرق سعر' : 'وفرة'} ${formatMoney(diff.abs())} — '
              'بانتظار موافقة الاستقبال';
      showAppToast(
        context,
        'تم إرسال طلب الانتقال إلى الغرفة ${request.toRoomNumber} ✅\n'
        '$description',
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
    final current = _current;
    // وصف من سطرين كما في الويب: سطر الغرفة الحالية + سطر الموافقة
    final description =
        '${current == null ? 'اختر غرفتك الجديدة' : 'غرفتك الحالية ${current.number} — ${current.typeName}'}\n'
        'الطلب يخضع لموافقة الاستقبال';
    return SheetFrame(
      icon: Icons.swap_horiz_rounded,
      title: 'تغيير الغرفة',
      description: description,
      footer: _footer(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) ...[
            // هياكل تحميل (مقابل Skeleton في الويب)
            _skeletonBox(),
            _skeletonBox(),
            _skeletonBox(),
          ] else if (_rooms.isEmpty)
            // لا غرف متاحة (نفس النص الحرفي للويب)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).outlineVariant),
              ),
              child: Text(
                'لا غرف متاحة للنقل حاليًا — جرّب لاحقًا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            // قائمة الغرف المتاحة (radiogroup في الويب)
            Semantics(
              label: 'الغرف المتاحة',
              child: Column(
                children: [
                  for (final room in _rooms)
                    _RoomOptionTile(
                      room: room,
                      selected: room.roomId == _selected,
                      onTap: () => setState(() => _selected = room.roomId),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const SheetLabel('سبب التغيير (اختياري)'),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            minLines: 2,
            maxLength: 300,
            enabled: !_sending,
            decoration: const InputDecoration(
              hintText: 'مثال: أرغب بإطلالة أفضل...',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox() {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// صف الأزرار: إلغاء + زر الطلب (نصّه يتبع الغرفة المختارة كما في الويب)
  Widget _footer() {
    final selectedRoom = _selectedRoom;
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
            onPressed: (_sending || _selected == null) ? null : _submit,
            icon: _sending
                ? sheetBusyIndicator
                : const Icon(Icons.king_bed_rounded, size: 19),
            label: Text(
              selectedRoom == null
                  ? 'إرسال الطلب'
                  : 'طلب الغرفة ${selectedRoom.number}',
            ),
          ),
        ),
      ],
    );
  }
}

/// بلاطة غرفة واحدة: الرقم + النوع + الطابق + فرق السعر
class _RoomOptionTile extends StatelessWidget {
  const _RoomOptionTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  final RoomOption room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // رقم الغرفة لاتيني — LTR كما في الويب
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  room.number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
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
                    room.typeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'الطابق ${room.floor}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _diffChip(context, room.diffCents),
          ],
        ),
      ),
    );
  }

  /// شريحة فرق السعر: بدون فرق / +سعر / −وفرة (نفس ألوان الويب)
  Widget _diffChip(BuildContext context, int diffCents) {
    final scheme = Theme.of(context).colorScheme;
    final (text, foreground, background) = switch (diffCents) {
      0 => (
          'بدون فرق',
          AppColors.success,
          AppColors.successContainer,
        ),
      > 0 => (
          '+${formatMoney(diffCents)}',
          AppColors.warning,
          AppColors.warningContainer,
        ),
      _ => (
          '−${formatMoney(diffCents.abs())}',
          scheme.primary,
          scheme.primaryContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

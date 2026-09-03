// ─────────────────────────────────────────────────────────────
// REQUEST DETAIL SCREEN — تفاصيل الطلب + الخط الزمني + إجراءات (R-09)
// نقل حرفي لـ request-detail-dialog.tsx كحوار فوق ReceptionStore
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';

/// إجراء استقبال واحد (خريطة ACTIONS في الويب — حرفية:
/// default→Filled · outline→Outlined · destructive→Filled أحمر
/// · secondary→Filled محايد (وCOMPLETED بأخضر) · confirm→حوار تأكيد)
class _ReqAction {
  const _ReqAction(
    this.status,
    this.label,
    this.icon, {
    this.outline = false,
    this.destructive = false,
    this.secondary = false,
    this.success = false,
    this.confirm = false,
  });

  final String status;
  final String label;
  final IconData icon;
  final bool outline;
  final bool destructive;
  final bool secondary;
  final bool success;
  final bool confirm;
}

const Map<String, List<_ReqAction>> _actionsByStatus = {
  'NEW': [
    _ReqAction('ACKNOWLEDGED', 'استلام', Icons.how_to_reg_rounded),
    _ReqAction('ASSIGNED', 'إسناد', Icons.person_add_rounded),
    _ReqAction('REJECTED', 'رفض', Icons.cancel_rounded,
        destructive: true, confirm: true),
    _ReqAction('CANCELLED', 'إلغاء', Icons.block_rounded,
        outline: true, confirm: true),
  ],
  'ACKNOWLEDGED': [
    _ReqAction('ASSIGNED', 'إسناد', Icons.person_add_rounded),
    _ReqAction('IN_PROGRESS', 'بدء التنفيذ', Icons.play_arrow_rounded),
    _ReqAction('CANCELLED', 'إلغاء', Icons.block_rounded,
        outline: true, confirm: true),
  ],
  'ASSIGNED': [
    _ReqAction('IN_PROGRESS', 'بدء التنفيذ', Icons.play_arrow_rounded),
    _ReqAction('WAITING', 'انتظار', Icons.pause_circle_rounded,
        outline: true),
    _ReqAction('CANCELLED', 'إلغاء', Icons.block_rounded,
        outline: true, confirm: true),
  ],
  'IN_PROGRESS': [
    _ReqAction('COMPLETED', 'إكمال', Icons.check_circle_rounded,
        secondary: true, success: true),
    _ReqAction('WAITING', 'انتظار', Icons.pause_circle_rounded,
        outline: true),
    _ReqAction('CANCELLED', 'إلغاء', Icons.block_rounded,
        outline: true, confirm: true),
  ],
  'WAITING': [
    _ReqAction('IN_PROGRESS', 'بدء التنفيذ', Icons.play_arrow_rounded),
    _ReqAction('COMPLETED', 'إكمال', Icons.check_circle_rounded,
        secondary: true, success: true),
    _ReqAction('CANCELLED', 'إلغاء', Icons.block_rounded,
        outline: true, confirm: true),
  ],
};

/// فرق الإسناد (ASSIGNEE_TEAMS في الويب)
const List<String> _assigneeTeams = ['التنظيف', 'الصيانة', 'الاستقبال'];

/// فتح حوار تفاصيل الطلب — التوقيع عقد مع الشاشات (لا تغيّره)
Future<void> showRequestDetail(
  BuildContext context, {
  required ReceptionStore store,
  required String requestId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _RequestDetailDialog(store: store, requestId: requestId),
  );
}

class _RequestDetailDialog extends StatefulWidget {
  const _RequestDetailDialog({
    required this.store,
    required this.requestId,
  });

  final ReceptionStore store;
  final String requestId;

  @override
  State<_RequestDetailDialog> createState() => _RequestDetailDialogState();
}

class _RequestDetailDialogState extends State<_RequestDetailDialog> {
  ReceptionRequestItem? _request;
  String? _error;
  String? _busy;
  String _assignedTo = '';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  ReceptionRequestItem? _findIn(List<ReceptionRequestItem> list) {
    for (final r in list) {
      if (r.id == widget.requestId) return r;
    }
    return null;
  }

  /// الجلب عبر المخزن ثم إيجاد الطلب (load في الويب)
  Future<void> _load() async {
    ReceptionRequestItem? found;
    String? loadError;
    try {
      await widget.store.refreshRequests();
      found = _findIn(widget.store.requests);
      if (found == null) loadError = 'لم يتم العثور على الطلب';
    } on ApiError catch (e) {
      loadError = e.message;
    }
    if (!mounted) return;
    setState(() {
      _request = found;
      _error = loadError;
    });
  }

  List<_ReqAction> get _actions => _request == null
      ? const <_ReqAction>[]
      : (_actionsByStatus[_request!.status] ?? const <_ReqAction>[]);

  bool _needsAssignee(String status) => status == 'ASSIGNED';

  /// applyStatus: الجسم {status, note?, assignedTo?} — المتجر يقصّ ويحذف الفارغ
  Future<void> _applyStatus(String status) async {
    setState(() => _busy = status);
    try {
      final updated = await widget.store.setRequestStatus(
        widget.requestId,
        status,
        note: _noteController.text,
        assignedTo: _assignedTo.isEmpty ? null : _assignedTo,
      );
      if (!mounted) return;
      setState(() {
        _request = updated;
        _busy = null;
        _assignedTo = '';
      });
      _noteController.clear();
      // الويب: توست بعنوان «تم تحديث الطلب ✅» ووصفه عنوان الطلب
      // (توست Flutter نص واحد → دُمجا بفاصل — انظر تقرير 20-b)
      showAppToast(context, 'تم تحديث الطلب ✅ — ${updated.title}');
    } on ApiError {
      if (!mounted) return;
      setState(() => _busy = null);
      showAppToast(context, 'تعذر تحديث الطلب', error: true);
    }
  }

  /// حوار التأكيد الحرفي (AlertDialog في الويب) قبل رفض/إلغاء
  Future<void> _openConfirmDialog(_ReqAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('تأكيد «${action.label}»؟'),
        content: const Text(
          'سيتم إشعار الضيف بهذا القرار ولا يمكن التراجع عن الطلب بعد ذلك.',
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
      await _applyStatus(action.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final req = _request;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان (أحمر إن عاجل + دائرة bolt — الويب: urgent-pulse
              // نبض CSS → هنا أيقونة ثابتة)
              if (req != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: req.priority == 'URGENT'
                              ? AppColors.danger
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    if (req.priority == 'URGENT') ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withValues(alpha: 0.10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // الوصف: مرجع · غرفة/ضيف + شارة حالة + شارة أولوية
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RefCodeText(req.reference),
                    Text(
                      '·',
                      style:
                          TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      'غرفة ${req.stayRoomNumber} — ${req.stayGuestName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    StatusChip.requestStatus(context, req.status),
                    _PriorityBadge(priority: req.priority),
                  ],
                ),
              ] else ...[
                const Text(
                  'تفاصيل الطلب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'جارٍ تحميل تفاصيل الطلب…',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (req == null)
                loadingBlocks(2, height: 64)
              else ...[
                // نص الوصف إن وجد
                if (req.description != null && req.description!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      req.description!,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                // مُسند إلى
                if (req.assignedTo != null && req.assignedTo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مُسند إلى: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          req.assignedTo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                _Timeline(request: req),
                // إجراءات الاستقبال / انتهاء الطلب
                if (_actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildActionsCard(context),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    // الويب: border-dashed — Flutter بلا حد متقطع مبسط
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'الطلب منتهٍ — لا مزيد من الإجراءات',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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

  /// قسم «إجراءات الاستقبال»: ملاحظة + محدد الإسناد + أزرار الحالة
  Widget _buildActionsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actions = _actions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.room_service_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'إجراءات الاستقبال',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'ملاحظة تُضاف للخط الزمني (اختياري)…',
            ),
          ),
          // محدد فريق الإسناد — يظهر فقط إن كان من الإجراءات ASSIGNED
          if (actions.any((a) => _needsAssignee(a.status))) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'إسناد إلى:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 144,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outline),
                      color: scheme.surfaceContainerHighest,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _assignedTo.isEmpty ? null : _assignedTo,
                        hint: Text(
                          'اختر فريقًا',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        items: [
                          for (final team in _assigneeTeams)
                            DropdownMenuItem(
                              value: team,
                              child: Text(
                                team,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _assignedTo = v ?? ''),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions) _buildActionButton(context, action),
            ],
          ),
        ],
      ),
    );
  }

  /// زر إجراء واحد بحسب variant الويب
  Widget _buildActionButton(BuildContext context, _ReqAction action) {
    final scheme = Theme.of(context).colorScheme;
    final disabledByAssignee =
        _needsAssignee(action.status) && _assignedTo.isEmpty;
    final disabled = _busy != null || disabledByAssignee;
    final isBusy = _busy == action.status;
    final icon = isBusy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(action.icon, size: 16);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [icon, const SizedBox(width: 6), Text(action.label)],
    );

    void Function()? onPressed;
    if (!disabled) {
      onPressed = action.confirm
          ? () => _openConfirmDialog(action)
          : () => _applyStatus(action.status);
    }

    final Widget button;
    if (action.destructive) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
        ),
        child: content,
      );
    } else if (action.secondary || action.success) {
      button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: action.success
              ? AppColors.success
              : scheme.surfaceContainerHighest,
          foregroundColor:
              action.success ? Colors.white : scheme.onSurface,
        ),
        child: content,
      );
    } else if (action.outline) {
      button = OutlinedButton(onPressed: onPressed, child: content);
    } else {
      button = FilledButton(onPressed: onPressed, child: content);
    }

    // تلميح «اختر الفريق أولًا» (title في الويب)
    if (disabledByAssignee) {
      return Tooltip(
        message: 'اختر الفريق أولًا',
        child: button,
      );
    }
    return button;
  }
}

/// شارة الأولوية (PriorityBadge في الويب): عاجل أحمر ببرق / عادي محايد
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = priority == 'URGENT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.danger.withValues(alpha: 0.10)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: urgent
              ? AppColors.danger.withValues(alpha: 0.40)
              : scheme.outlineVariant,
        ),
      ),
      child: Text(
        urgent
            ? '⚡ ${fmt.label(fmt.priorityLabels, priority)}'
            : fmt.label(fmt.priorityLabels, priority),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: urgent ? AppColors.danger : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// الخط الزمني (ol مع نقاط على خط عمودي في الويب)
class _Timeline extends StatelessWidget {
  const _Timeline({required this.request});

  final ReceptionRequestItem request;

  String _roleLabel(String role) => switch (role) {
        'RECEPTION' => 'الاستقبال',
        'GUEST' => 'الضيف',
        _ => 'النظام',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCompleted =
        request.completedAt != null && request.completedAt!.isNotEmpty;
    final hasUpdates = request.updates.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخط الزمني',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _TimelineEntry(
            isLast: !hasUpdates && !hasCompleted,
            dot: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(color: scheme.surface, width: 2),
              ),
            ),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'أُنشئ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' · ${fmt.formatDateTimeAr(request.createdAt)}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurface),
                ),
              ],
            ),
          ),
          for (final u in request.updates)
            _TimelineEntry(
              isLast: identical(u, request.updates.last) && !hasCompleted,
              dot: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (u.status != null && u.status!.isNotEmpty)
                        StatusChip.requestStatus(context, u.status!),
                      Text(
                        ' · ${u.byName} (${_roleLabel(u.byRole)}) · '
                        '${fmt.timeAgoAr(u.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (u.note != null && u.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      u.note!,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (hasCompleted)
            _TimelineEntry(
              isLast: true,
              dot: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
              ),
              child: Text(
                'اكتمل · ${fmt.formatDateTimeAr(request.completedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// سطر خط زمني: نقطة + خط واصل عمودي + المحتوى
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.dot,
    required this.child,
    required this.isLast,
  });

  final Widget dot;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: 8,
                bottom: isLast ? 0 : 12,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAFF CODES SCREEN — الطاقم والأكواد (A-23..A-28)
// نقل حرفي لـ sections/staff-codes.tsx: قسمان (الأكواد/الطاقم)
// + فلاتر النوع/الحالة عبر المخزن + توليد كود (الخام مرة واحدة
// عبر RawCodeBox) + إبطال بتأكيد يذكر الجلسات + إضافة/تعديل
// موظف + تفعيل/تعطيل (التعطيل يبطل كوده وجلساته — الخادم)
// صفر HTTP هنا: كل نداء عبر AdminStore (نمط F1/F4/F5)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

/// تسميات أنواع الأكواد — CODE_TYPE_LABELS في الويب
const Map<String, String> _codeTypeLabels = {
  'GUEST': 'ضيف',
  'RECEPTION': 'استقبال',
  'ADMIN': 'إدارة',
};

/// تسميات حالات الأكواد — CODE_STATUS_LABELS في الويب
const Map<String, String> _codeStatusLabels = {
  'ACTIVE': 'فعّال',
  'EXPIRED': 'منتهي',
  'REVOKED': 'ملغي',
  'USED': 'مستخدم',
};

/// تسميات أدوار الطاقم — ROLE_LABELS في الويب
const Map<String, String> _roleLabels = {
  'RECEPTION': 'استقبال',
  'ADMIN': 'إدارة',
  'MANAGER': 'مدير',
};

/// أرجواني «إدارة» — نفس purple-500 في الويب (شارة الدور/الفاعل)
const Color _adminPurple = Color(0xFF6B4FA1);
const Color _adminPurpleBg = Color(0xFFEAE4F6);

class StaffCodesScreen extends StatefulWidget {
  const StaffCodesScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<StaffCodesScreen> createState() => _StaffCodesScreenState();
}

class _StaffCodesScreenState extends State<StaffCodesScreen> {
  /// 0 = الأكواد · 1 = الطاقم — الافتراضي «codes» كالويب
  int _tab = 0;
  String? _error;
  bool _busy = false;

  AdminStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// عند فتح الشاشة: الأكواد + الطاقم معًا (كما يحمّل تبويب
  /// الأكواد في الويب useLoader مرتين) — فشل إحداهما لا يلغي الأخرى
  Future<void> _refresh() async {
    final errors = <String>[];
    await Future.wait([
      store.refreshCodes().catchError((Object e) {
        errors.add(e is ApiError ? e.message : 'حدث خطأ غير متوقع');
      }),
      store.refreshStaff().catchError((Object e) {
        errors.add(e is ApiError ? e.message : 'حدث خطأ غير متوقع');
      }),
    ]);
    if (!mounted) return;
    final err = errors.isEmpty ? null : errors.first;
    setState(() => _error = err);
  }

  // ── A-26 · فلاتر الأكواد (تقيم في المخزن — تقاوم التنقّل) ──

  Future<void> _applyCodeFilters({String? type, String? status}) async {
    try {
      await store.refreshCodes(type: type, status: status);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  // ── A-28 · إبطال كود (يشمل أكواد الضيف) ──

  Future<void> _confirmRevoke(AdminAccessCode code) async {
    final scheme = Theme.of(context).colorScheme;
    final isGuest =
        code.guestName != null && code.guestName!.isNotEmpty;
    final description = isGuest
        ? 'كود ضيف — ${code.guestName} (غرفة ${code.roomNumber ?? '—'}). '
            'سيفقد الضيف وصوله للتطبيق فورًا. لن يمكن التراجع عن الإبطال.'
        : 'كود ${code.type == 'ADMIN' ? 'إدارة' : 'استقبال'} — ${code.staffName ?? code.codeMasked}. '
            'ستنتهي جلساته النشطة فورًا ولن يستطيع الدخول به. '
            'لن يمكن التراجع عن الإبطال.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('إبطال كود ${code.codeMasked}؟'),
        content: Text(
          description,
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
            child: const Text('إبطال الكود'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      // رسالة الخادم الحرفية: «تم إبطال كود … وإبطال جلساته»
      final message = await store.revokeCode(code.id);
      if (!mounted) return;
      showAppToast(context, message);
    } on ApiError catch (e) {
      // «هذا الكود ملغى بالفعل» وغيرها — رسالة الخادم الحرفية
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── A-27 · توليد كود (الخام يُعاد مرة واحدة) ──

  Future<void> _openGenerateDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GenerateCodeDialog(store: store),
    );
  }

  // ── A-25 · تعطيل الموظف يبطل كوده وجلساته — تأكيد أولًا ──

  Future<void> _toggleActive(AdminStaffMember s) async {
    final scheme = Theme.of(context).colorScheme;
    if (s.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: Text('تعطيل ${s.fullName}؟'),
          content: const Text(
            'سيُبطل كوده النشط وجلساته فورًا — لن يستطيع الدخول به '
            'حتى يُفعَّل ويُولَّد له كود جديد.',
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
              child: const Text('تعطيل الموظف'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      await store.updateStaff(s.id, {'active': !s.active});
      if (!mounted) return;
      showAppToast(
        context,
        s.active
            ? 'تم تعطيل الموظف — أُبطل كوده النشط وجلساته فورًا'
            : 'تم تفعيل الموظف',
      );
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStaffDialog(AdminStaffMember? editing) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _StaffDialog(store: store, editing: editing),
    );
  }

  // ───────────── البناء ─────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final Widget content;
        if (_tab == 0) {
          content = _codesTab(context);
        } else {
          content = _staffTab(context);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'الطاقم والأكواد',
                icon: Icons.key_rounded,
                iconColor: scheme.primary,
              ),
              Text(
                'موظفو الفندق وأكواد الدخول — كود فعّال واحد على الأكثر لكل موظف',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('الأكواد'),
                      icon: Icon(Icons.key_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('الطاقم'),
                      icon: Icon(Icons.people_rounded, size: 18),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) =>
                      setState(() => _tab = s.first),
                ),
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        );
      },
    );
  }

  // ───────────── تبويب الأكواد ─────────────

  Widget _codesTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final codes = store.codes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 560;
          final type = _selectShell(
            context,
            DropdownButton<String>(
              isExpanded: true,
              value: store.codesTypeFilter.isEmpty
                  ? 'all'
                  : store.codesTypeFilter,
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('كل الأنواع')),
                for (final e in _codeTypeLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => _applyCodeFilters(
                type: v == 'all' ? '' : v,
              ),
            ),
          );
          final status = _selectShell(
            context,
            DropdownButton<String>(
              isExpanded: true,
              value: store.codesStatusFilter.isEmpty
                  ? 'all'
                  : store.codesStatusFilter,
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              items: [
                const DropdownMenuItem(
                    value: 'all', child: Text('كل الحالات')),
                for (final e in _codeStatusLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => _applyCodeFilters(
                status: v == 'all' ? '' : v,
              ),
            ),
          );
          final filters = wide
              ? Row(
                  children: [
                    Expanded(child: type),
                    const SizedBox(width: 8),
                    Expanded(child: status),
                  ],
                )
              : Column(
                  children: [
                    type,
                    const SizedBox(height: 8),
                    status,
                  ],
                );
          return Column(
            children: [
              filters,
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${codes.length} كود',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
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
                    onPressed: _busy ? null : _openGenerateDialog,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('توليد كود'),
                  ),
                ],
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        if (_error != null && codes.isEmpty && store.staff.isEmpty)
          AppCard(
            child: ErrorRetryView(message: _error!, onRetry: _refresh),
          )
        else if (store.codesLoading && codes.isEmpty)
          _tableSkeleton(context)
        else if (codes.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.key_rounded,
              title: 'لا توجد أكواد مطابقة',
            ),
          )
        else
          for (final code in codes) ...[
            _CodeCard(
              code: code,
              busy: _busy,
              onRevoke: () => _confirmRevoke(code),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  // ───────────── تبويب الطاقم ─────────────

  Widget _staffTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final staff = store.staff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${staff.length} موظف',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
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
              onPressed: _openStaffDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة موظف'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null && staff.isEmpty && store.codes.isEmpty)
          AppCard(
            child: ErrorRetryView(message: _error!, onRetry: _refresh),
          )
        else if (store.staffLoading && staff.isEmpty)
          _tableSkeleton(context)
        else if (staff.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.people_rounded,
              title: 'لا يوجد طاقم',
            ),
          )
        else
          for (final s in staff) ...[
            _StaffCard(
              staff: s,
              busy: _busy,
              onToggle: () => _toggleActive(s),
              onEdit: () => _openStaffDialog(s),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
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

/// شارة صغيرة (Badge outline في الويب) — تعمل في الوضعين
Widget _badge(BuildContext context, String label, Color fg, Color bg) {
  final scheme = Theme.of(context).colorScheme;
  final dark = scheme.brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: dark ? scheme.surfaceContainerHighest : bg,
      borderRadius: BorderRadius.circular(8),
      border: dark
          ? Border.all(color: scheme.outlineVariant)
          : Border.all(color: bg),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: dark ? scheme.onSurfaceVariant : fg,
      ),
    ),
  );
}

/// شارة نوع الكود — CodeTypeBadge في الويب
class _CodeTypeBadge extends StatelessWidget {
  const _CodeTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (type) {
      'GUEST' => (AppColors.gold, AppColors.goldContainer),
      'RECEPTION' => (AppColors.info, AppColors.infoContainer),
      'ADMIN' => (_adminPurple, _adminPurpleBg),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return _badge(context, _codeTypeLabels[type] ?? type, fg, bg);
  }
}

/// شارة حالة الكود — CodeStatusBadge في الويب
class _CodeStatusBadge extends StatelessWidget {
  const _CodeStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      'ACTIVE' => (AppColors.success, AppColors.successContainer),
      'REVOKED' => (AppColors.danger, AppColors.dangerContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return _badge(context, _codeStatusLabels[status] ?? status, fg, bg);
  }
}

/// شارة دور الموظف — StaffRoleBadge في الويب
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (role) {
      'RECEPTION' => (AppColors.info, AppColors.infoContainer),
      'ADMIN' => (_adminPurple, _adminPurpleBg),
      'MANAGER' => (scheme.primary, scheme.primaryContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    return _badge(context, _roleLabels[role] ?? role, fg, bg);
  }
}

/// بطاقة كود واحدة — صف الجدول في الويب (الكود LTR monospace/
/// النوع/السياق: موظف أو ضيف+غرفة أو مرجع إقامة/الانتهاء/آخر
/// استخدام/الحالة + إبطال للأكواد الفعّالة فقط)
class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.code,
    required this.busy,
    required this.onRevoke,
  });

  final AdminAccessCode code;
  final bool busy;
  final VoidCallback onRevoke;

  String _contextText() {
    if (code.staffName != null && code.staffName!.isNotEmpty) {
      return code.staffName!;
    }
    if (code.guestName != null && code.guestName!.isNotEmpty) {
      var text = 'ضيف — ${code.guestName}';
      if (code.roomNumber != null && code.roomNumber!.isNotEmpty) {
        text += ' (غرفة ${code.roomNumber})';
      }
      return text;
    }
    if (code.stayReference != null && code.stayReference!.isNotEmpty) {
      return code.stayReference!;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final revoked = code.status == 'REVOKED';
    return Opacity(
      opacity: revoked ? 0.55 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    code.codeMasked,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CodeTypeBadge(type: code.type),
                const SizedBox(width: 6),
                _CodeStatusBadge(status: code.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _contextText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'ينتهي في: ${fmt.formatDateAr(code.expiresAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    code.lastUsedAt != null && code.lastUsedAt!.isNotEmpty
                        ? 'آخر استخدام: ${fmt.timeAgoAr(code.lastUsedAt)}'
                        : 'آخر استخدام: لم يُستخدم',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (code.status == 'ACTIVE') ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: busy ? null : onRevoke,
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('إبطال'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// بطاقة موظف — بطاقة الويب (الاسم/الدور/الهاتف/مفتاح الفعّالية/
/// تعديل + صندوق «أحدث كود»)
class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });

  final AdminStaffMember staff;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = staff.lastCode;
    return Opacity(
      opacity: staff.active ? 1 : 0.6,
      child: AppCard(
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
                        staff.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(role: staff.role),
                    ],
                  ),
                ),
                Switch(
                  value: staff.active,
                  onChanged: busy ? null : (_) => onToggle(),
                ),
                IconButton(
                  tooltip: 'تعديل ${staff.fullName}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
              ],
            ),
            if (staff.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                staff.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أحدث كود',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (last != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            last.codeMasked,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        _CodeTypeBadge(type: last.type),
                        const SizedBox(width: 6),
                        _CodeStatusBadge(status: last.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ينتهي: ${fmt.formatDateAr(last.expiresAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      'لا يوجد كود — ولّد واحدًا من تبويب الأكواد',
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }
}

// ───────────── حوار توليد كود (A-27) ─────────────

class _GenerateCodeDialog extends StatefulWidget {
  const _GenerateCodeDialog({required this.store});

  final AdminStore store;

  @override
  State<_GenerateCodeDialog> createState() => _GenerateCodeDialogState();
}

class _GenerateCodeDialogState extends State<_GenerateCodeDialog> {
  String _type = 'RECEPTION';
  String _staffId = '';
  int _days = 7;
  GeneratedCodeResult? _generated;
  bool _loading = false;

  /// موظفون فعّالون مطابقون للدور فقط — eligibleStaff في الويب
  /// (الخادم يرفض المعطّل وغير المطابق برسائل حرفية)
  List<AdminStaffMember> get _eligible => widget.store.staff.where((s) {
        if (!s.active) return false;
        if (_type == 'RECEPTION') return s.role == 'RECEPTION';
        return s.role == 'ADMIN' || s.role == 'MANAGER';
      }).toList(growable: false);

  AdminStaffMember? get _selectedStaff {
    for (final s in widget.store.staff) {
      if (s.id == _staffId) return s;
    }
    return null;
  }

  Future<void> _generate() async {
    if (_staffId.isEmpty) {
      showAppToast(context, 'اختر الموظف', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await widget.store.generateCode(
        type: _type,
        staffId: _staffId,
        days: _days,
      );
      if (!mounted) return;
      setState(() => _generated = result);
      showAppToast(
        context,
        'تم توليد الكود — انسخه الآن (لن يظهر الكود الخام مرة أخرى)',
      );
    } on ApiError catch (e) {
      // تطابق الدور/الموظف المعطّل — رسالة الخادم الحرفية
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final generated = _generated;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'توليد كود دخول',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'الكود الخام يظهر مرة واحدة فقط عند التوليد — انسخه فورًا',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (generated != null) ...[
                // النتيجة — الكود الخام مرة واحدة
                Text(
                  'كود ${generated.type == 'ADMIN' ? 'إدارة' : 'استقبال'} — '
                  '${generated.staffName} (${generated.days} يومًا)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                RawCodeBox(code: generated.code),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ينتهي: ${fmt.formatDateTimeAr(generated.expiresAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      'المخزّن: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      generated.codeMasked,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _generate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('توليد آخر'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // النموذج
                const Text(
                  'نوع الكود *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _selectShell(
                  context,
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _type,
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(
                        value: 'RECEPTION',
                        child: Text('استقبال (R…)'),
                      ),
                      DropdownMenuItem(
                        value: 'ADMIN',
                        child: Text('إدارة (A…)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _type = v;
                        _staffId = '';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كود الضيف يُولَّد تلقائيًا عند تسجيل الوصول من الاستقبال',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'الموظف *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _selectShell(
                  context,
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _staffId.isEmpty ? null : _staffId,
                    hint: const Text('اختر الموظف المطابق للدور'),
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    items: _eligible.isEmpty
                        ? const [
                            DropdownMenuItem<String>(
                              value: '_',
                              enabled: false,
                              child: Text('لا يوجد موظفون مطابقون'),
                            ),
                          ]
                        : [
                            for (final s in _eligible)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.fullName} — ${_roleLabels[s.role] ?? s.role}',
                                maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                    onChanged: (v) {
                      if (v == null || v == '_') return;
                      setState(() => _staffId = v);
                    },
                  ),
                ),
                if (_selectedStaff?.lastCode != null &&
                    _selectedStaff!.lastCode!.status == 'ACTIVE') ...[
                  const SizedBox(height: 4),
                  Text(
                    'لدى ${_selectedStaff!.fullName} كود فعّال حاليًا '
                    '(${_selectedStaff!.lastCode!.codeMasked}) — '
                    'يُفضل إبطاله بعد تفعيل الكود الجديد لإبقاء كود فعّال واحد.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'الصلاحية (أيام)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _selectShell(
                  context,
                  DropdownButton<int>(
                    isExpanded: true,
                    value: _days,
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    items: [
                      for (var d = 1; d <= 30; d++)
                        DropdownMenuItem(
                          value: d,
                          child: Text(
                            d == 1
                                ? '1 يوم'
                                : d == 2
                                    ? '2 يومان'
                                    : '$d أيام',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _days = v);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تنتهي الصلاحية نهاية اليوم الأخير',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loading || _staffId.isEmpty
                            ? null
                            : _generate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.key_rounded, size: 18),
                        label: const Text('توليد الكود'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── حوار إضافة/تعديل موظف (A-24/A-25) ─────────────

class _StaffDialog extends StatefulWidget {
  const _StaffDialog({required this.store, required this.editing});

  final AdminStore store;
  final AdminStaffMember? editing;

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late String _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _fullName = TextEditingController(text: editing?.fullName ?? '');
    _phone = TextEditingController(text: editing?.phone ?? '');
    _role = editing?.role ?? 'RECEPTION';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullName.text.trim();
    if (fullName.isEmpty) {
      showAppToast(context, 'اسم الموظف مطلوب', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final editing = widget.editing;
      if (editing != null) {
        // التعديل: الاسم والهاتف فقط (الدور مجمد كالويب)
        await widget.store.updateStaff(editing.id, {
          'fullName': fullName,
          'phone': _phone.text.trim(),
        });
        if (!mounted) return;
        showAppToast(context, 'تم تحديث بيانات الموظف');
      } else {
        await widget.store.createStaff(
          fullName: fullName,
          role: _role,
          phone: _phone.text,
        );
        if (!mounted) return;
        showAppToast(
          context,
          'تمت إضافة الموظف — يمكنك الآن توليد كود دخول له من تبويب الأكواد',
        );
      }
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(
          context,
          'تعذّر تنفيذ العملية — ${e.message}',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.editing;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing != null ? 'تعديل: ${editing.fullName}' : 'إضافة موظف',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                editing != null
                    ? 'تعطيل الموظف لاحقًا يبطل كوده النشط وجلساته فورًا'
                    : 'أضف الموظف ثم ولّد له كود دخول',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل *',
                  hintText: 'محمد الاستقبال',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'الدور *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (editing != null) ...[
                Row(
                  children: [
                    _RoleBadge(role: editing.role),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لا يمكن تغيير الدور بعد الإنشاء حفاظًا على الأكواد المرتبطة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                _selectShell(
                  context,
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _role,
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    items: [
                      for (final e in _roleLabels.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _role = v);
                    },
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'الهاتف',
                  hintText: '+967…',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(editing != null ? 'حفظ' : 'إضافة'),
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
}

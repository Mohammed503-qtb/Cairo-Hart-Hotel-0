// ─────────────────────────────────────────────────────────────
// AUDIT LOG SCREEN — سجل التدقيق (A-32)
// نقل حرفي لـ sections/audit-log.tsx: فلتر إجراء (خيارات ثابتة
// من الويب) + بحث حر (الفاعل/الكيان/المعرّف) + قائمة مصفّحة
// 30/صفحة عبر المخزن + بطاقة سجل (chip إجراء بلال دور الفاعل
// + الكيان + تفاصيل خريطة قراءة-friendly + timeAgoAr)
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

/// AUDIT_ACTIONS في الويب — القائمة والتسميات العربية الحرفية
const List<(String, String)> kAuditActions = [
  ('RESERVATION_CREATED', 'إنشاء حجز'),
  ('RESERVATION_CONFIRMED', 'تأكيد حجز'),
  ('RESERVATION_CANCELLED', 'إلغاء حجز'),
  ('CHECK_IN', 'تسجيل وصول'),
  ('CHECK_OUT', 'تسجيل خروج'),
  ('ROOM_ASSIGNED', 'إسناد غرفة'),
  ('ROOM_CHANGED', 'تعديل غرفة'),
  ('ROOM_TYPE_CHANGED', 'تعديل نوع غرفة'),
  ('RATE_CHANGED', 'تعديل معدل سعر'),
  ('SETTINGS_UPDATED', 'تحديث الإعدادات'),
  ('SERVICE_CATALOG_CHANGED', 'تعديل كتالوج الخدمات'),
  ('STAFF_CHANGED', 'تعديل الطاقم'),
  ('CODE_GENERATED', 'توليد كود'),
  ('CODE_REVOKED', 'إبطال كود'),
  ('CODE_LOGIN', 'دخول بكود'),
  ('CODE_LOGIN_FAILED', 'محاولة دخول فاشلة'),
  ('PAYMENT_RECORDED', 'تسجيل دفعة'),
  ('REQUEST_CREATED', 'إنشاء طلب'),
  ('REQUEST_UPDATED', 'تحديث طلب'),
  ('EXTENSION_REQUESTED', 'طلب تمديد'),
  ('EXTENSION_APPROVED', 'قبول تمديد'),
  ('CHAT_MESSAGE', 'رسالة محادثة'),
  ('CHARGE_ADDED', 'إضافة بند فاتورة'),
  ('CHECKOUT_REQUESTED', 'طلب خروج'),
];

/// ACTION_LABEL_MAP في الويب
final Map<String, String> _actionLabels = {
  for (final (value, label) in kAuditActions) value: label,
};

/// ROLE_LABELS في الويب (audit-log.tsx)
const Map<String, String> _roleLabels = {
  'WEBSITE': 'الموقع',
  'RECEPTION': 'الاستقبال',
  'GUEST': 'ضيف',
  'ADMIN': 'الإدارة',
  'SYSTEM': 'النظام',
};

/// أرجواني «الإدارة» — نفس purple-500 في الويب (AuditRoleBadge)
const Color _adminPurple = Color(0xFF6B4FA1);
const Color _adminPurpleBg = Color(0xFFEAE4F6);

/// أرقام عربية-هندية (toLocaleString('ar-EG') في الويب)
String _arabicNumber(int n) {
  const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n
      .toString()
      .replaceAllMapped(RegExp(r'\d'), (m) => ar[int.parse(m.group(0)!)]);
}

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late final TextEditingController _searchCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    // استمرار البحث الملتزم من المخزن (الفلاتر تقاوم تنقّل الأقسام)
    _searchCtrl = TextEditingController(text: widget.store.auditQuery);
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshAudit();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showAppToast(context, e.message, error: true);
      }
    }
  }

  /// تغيير الفلتر/البحث/الصفحة — كل النداءات عبر المخزن (A-32)
  Future<void> _applyFilters({String? action, String? q, int? page}) async {
    try {
      await widget.store.refreshAudit(action: action, q: q, page: page);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  void _search() {
    _applyFilters(q: _searchCtrl.text.trim(), page: 1);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _applyFilters(q: '', page: 1);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final data = store.auditPageData;
        final items = data?.items ?? const <AuditLogItem>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'سجل التدقيق',
                icon: Icons.receipt_long_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
                action: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('تحديث'),
                ),
              ),
              Text(
                '${data?.total ?? 0} حدث — كل العمليات الحساسة مسجلة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _filtersBar(context),
              const SizedBox(height: 12),
              if (store.auditLoading && data == null)
                _tableSkeleton(context)
              else if (data == null)
                ErrorRetryView(
                  message: _error ?? 'تعذر تحميل سجل التدقيق — تحقق من اتصال الخادم',
                  onRetry: _refresh,
                )
              else if (items.isEmpty)
                const AppCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'لا توجد أحداث مطابقة',
                  ),
                )
              else ...[
                if (store.auditLoading)
                  const LinearProgressIndicator(minHeight: 2),
                for (final log in items) ...[
                  _AuditLogCard(log: log),
                  const SizedBox(height: 8),
                ],
                _pager(context, data),
              ],
            ],
          ),
        );
      },
    );
  }

  // ───────────── الفلاتر: الإجراء + البحث الحر ─────────────

  Widget _filtersBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final action = _selectShell(
      context,
      DropdownButton<String>(
        isExpanded: true,
        value: widget.store.auditActionFilter.isEmpty
            ? 'all'
            : widget.store.auditActionFilter,
        icon: const Icon(Icons.expand_more_rounded, size: 20),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('كل الأفعال')),
          for (final (value, label) in kAuditActions)
            DropdownMenuItem(value: value, child: Text(label)),
        ],
        onChanged: (v) {
          if (v == null) return;
          _applyFilters(action: v == 'all' ? '' : v, page: 1);
        },
      ),
    );
    final search = TextField(
      controller: _searchCtrl,
      onChanged: (_) {
        if (mounted) setState(() {});
      },
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: 'الفاعل / الكيان / المعرّف…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                tooltip: 'مسح البحث',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 560;
      final searchBtn = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        onPressed: _search,
        icon: const Icon(Icons.search_rounded, size: 18),
        label: const Text('بحث'),
      );
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 220, child: action),
            const SizedBox(width: 8),
            Expanded(child: search),
            const SizedBox(width: 8),
            searchBtn,
          ],
        );
      }
      return Column(
        children: [
          action,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 8),
              searchBtn,
            ],
          ),
        ],
      );
    });
  }

  /// عارض الصفحات — Pager في الويب (30/صفحة من الخادم)
  Widget _pager(BuildContext context, AuditPageData d) {
    final scheme = Theme.of(context).colorScheme;
    final small = OutlinedButton.styleFrom(
      minimumSize: const Size(64, 38),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'الإجمالي: ${_arabicNumber(d.total)}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: small,
            onPressed:
                d.page <= 1 ? null : () => _applyFilters(page: d.page - 1),
            icon: const Icon(Icons.chevron_right_rounded, size: 16),
            label: const Text('السابق'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'صفحة ${d.page} من ${d.pages}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          OutlinedButton(
            style: small,
            onPressed:
                d.page >= d.pages ? null : () => _applyFilters(page: d.page + 1),
            child: const Row(
              children: [
                Text('التالي'),
                SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
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
          height: 96,
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

/// شارة الفعل — AuditRoleBadge في الويب (ملونة حسب دور الفاعل)
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.role, required this.label});

  final String role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (role) {
      'WEBSITE' => (AppColors.info, AppColors.infoContainer),
      'RECEPTION' => (scheme.primary, scheme.primaryContainer),
      'GUEST' => (AppColors.gold, AppColors.goldContainer),
      'ADMIN' => (_adminPurple, _adminPurpleBg),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}

/// بطاقة سجل تدقيق — صف الجدول في الويب: chip الفعل (بلون دور
/// الفاعل) + الفاعل ودوره + الكيان + التفاصيل خريطة + الوقت
class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogItem log;

  /// entityId مقتطع إلى 14 محرفًا كما الويب
  String get _shortId =>
      log.entityId.length > 14 ? '${log.entityId.substring(0, 14)}…' : log.entityId;

  /// قيمة مقروءة من أي نوع (سلسلة/منطق/رقم/قائمة)
  String _valueText(Object? v) {
    if (v is String) return v;
    if (v is List) return v.join(', ');
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionLabel = _actionLabels[log.action] ?? log.action;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ActionChip(role: log.actorRole, label: actionLabel),
                    Text(
                      fmt.timeAgoAr(log.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
                  '${log.actor} · ${_roleLabels[log.actorRole] ?? log.actorRole}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                log.entityType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _shortId,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (log.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (final entry in log.details.entries)
                    Text.rich(
                      TextSpan(
                        text: '${entry.key}: ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: _valueText(entry.value),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            fmt.formatDateTimeAr(log.createdAt),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

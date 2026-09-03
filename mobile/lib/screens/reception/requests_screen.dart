// ─────────────────────────────────────────────────────────────
// REQUESTS SCREEN — طلبات الخدمة: فلاتر + العاجل + بطاقات (R-08)
// نقل حرفي لـ requests-view.tsx فوق ReceptionStore:
// النقر على بطاقة يفتح showRequestDetail (R-09)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
import 'request_detail_screen.dart';

/// الحالات المفتوحة (PENDING_SET في الويب)
const List<String> kPendingRequestStatuses = [
  'NEW',
  'ACKNOWLEDGED',
  'ASSIGNED',
  'IN_PROGRESS',
  'WAITING',
];

class _ReqFilter {
  const _ReqFilter(this.key, this.label);

  final String key;
  final String label;
}

/// فلاتر الحالات (FILTERS في الويب حرفيًا)
const List<_ReqFilter> _filters = [
  _ReqFilter('PENDING', 'المعلقة'),
  _ReqFilter('NEW', 'جديد'),
  _ReqFilter('ACKNOWLEDGED', 'قيد الاطلاع'),
  _ReqFilter('ASSIGNED', 'مُسند'),
  _ReqFilter('IN_PROGRESS', 'قيد التنفيذ'),
  _ReqFilter('WAITING', 'انتظار'),
  _ReqFilter('COMPLETED', 'مكتمل'),
  _ReqFilter('CANCELLED', 'ملغي'),
];

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _filter = 'PENDING';
  bool _urgentOnly = false;

  /// requests !== null في الويب — يظهر العدّاد في العنوان
  bool _loaded = false;
  String? _error;

  ReceptionStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    // التحميل الذاتي عند الفراغ فقط (bootstrap قد يكون جلبها أصلًا)
    if (store.requests.isNotEmpty) {
      _loaded = true;
    } else {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      await store.refreshRequests();
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
        final requests = store.requests;
        final filtered = _loaded
            ? requests
                .where((r) {
                  if (_urgentOnly && r.priority != 'URGENT') return false;
                  if (_filter == 'ALL') return true;
                  if (_filter == 'PENDING') {
                    return kPendingRequestStatuses.contains(r.status);
                  }
                  return r.status == _filter;
                })
                .toList(growable: false)
            : const <ReceptionRequestItem>[];
        var pendingCount = 0;
        var urgentCount = 0;
        for (final r in requests) {
          final open = kPendingRequestStatuses.contains(r.status);
          if (open) {
            pendingCount++;
            if (r.priority == 'URGENT') urgentCount++;
          }
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ReceptionSectionTitle(
                _loaded ? 'الطلبات (${filtered.length} معروضة)' : 'الطلبات',
                icon: Icons.room_service_rounded,
                iconColor: AppColors.warning,
              ),
              // فلاتر الحالات (rounded-full في الويب)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FilterChipButton(
                    label: 'الكل (${requests.length})',
                    active: _filter == 'ALL',
                    onTap: () => setState(() => _filter = 'ALL'),
                  ),
                  for (final f in _filters)
                    _FilterChipButton(
                      label: f.label,
                      active: _filter == f.key,
                      onTap: () => setState(() => _filter = f.key),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _UrgentOnlyRow(
                value: _urgentOnly,
                urgentCount: urgentCount,
                pendingCount: pendingCount,
                onChanged: (v) => setState(() => _urgentOnly = v),
              ),
              const SizedBox(height: 12),
              // الخطأ يظهر دائمًا عند وجوده (كما الويب — يعلو القائمة)،
              // والقائمة تبقى عند الخطأ مع بيانات قديمة
              if (_error != null) ...[
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'تعذر التحميل',
                  subtitle: _error,
                ),
                const SizedBox(height: 12),
              ],
              if (!_loaded && _error == null)
                loadingBlocks(4, height: 96)
              else if (_loaded && filtered.isEmpty)
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: _urgentOnly
                      ? 'لا طلبات عاجلة 🎉'
                      : 'لا طلبات بهذا الفلتر',
                  subtitle: _filter == 'PENDING' && !_urgentOnly
                      ? 'كل الطلبات مكتملة'
                      : null,
                ),
              if (_loaded && filtered.isNotEmpty)
                for (final r in filtered) ...[
                  _RequestCard(request: r, store: store),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

/// رقاقة فلتر (FilterChip في الويب): دائرية كاملة الحواف
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// صف «⚡ العاجل فقط» مع مفتاح تبديل وشارة «{n} معلق»
class _UrgentOnlyRow extends StatelessWidget {
  const _UrgentOnlyRow({
    required this.value,
    required this.urgentCount,
    required this.pendingCount,
    required this.onChanged,
  });

  final bool value;
  final int urgentCount;
  final int pendingCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          Expanded(
            // التسمية قابلة للنقر (cursor-pointer في الويب)
            child: GestureDetector(
              onTap: () => onChanged(!value),
              behavior: HitTestBehavior.opaque,
              child: Text(
                '⚡ العاجل فقط ${urgentCount > 0 ? '($urgentCount)' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                '$pendingCount معلق',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة طلب واحدة (نقل RequestCard/button في الويب)
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.store});

  final ReceptionRequestItem request;
  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUrgent = request.priority == 'URGENT';
    final isOpen = kPendingRequestStatuses.contains(request.status);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => showRequestDetail(
          context,
          store: store,
          requestId: request.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent && isOpen
                  ? AppColors.danger.withValues(alpha: 0.40)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // دائرة الأيقونة: bolt أحمر للعاجل المفتوح / رمادي
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUrgent && isOpen
                      ? AppColors.danger.withValues(alpha: 0.10)
                      : scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  isUrgent ? Icons.bolt_rounded : Icons.room_service_rounded,
                  size: 20,
                  color: isUrgent && isOpen
                      ? AppColors.danger
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        StatusChip.requestStatus(context, request.status),
                        // شارة الأولوية إن لم يكن عاجلًا مفتوحًا
                        if (!isUrgent && isOpen)
                          StatusChip.priority(context, request.priority),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'غرفة ${request.stayRoomNumber} — '
                            '${request.stayGuestName} · ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        RefCodeText(request.reference),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // منذ وقت (Clock في الويب)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    fmt.timeAgoAr(request.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
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

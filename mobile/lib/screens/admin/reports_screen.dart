// ─────────────────────────────────────────────────────────────
// REPORTS SCREEN — التقارير (A-33)
// نقل حرفي لـ sections/reports.tsx من store.reports:
// الإشغال آخر 14 يومًا (AdminBarChart بنسبة فوق كل عمود) +
// الإيراد آخر 6 أشهر (بالسنت → fmt.formatMoney) + إحصاءات
// الطلبات (byStatus/active/completed/متوسط الإنجاز/أعلى
// الخدمات) + الضيوف حسب الجنسية (أعلى 5)
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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshReports();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final reports = store.reports;
        final Widget content;
        if (store.reportsLoading && reports == null) {
          content = _skeleton(context);
        } else if (reports == null) {
          content = ErrorRetryView(
            message: _error ?? 'تعذر تحميل التقارير — تحقق من اتصال الخادم',
            onRetry: _refresh,
          );
        } else {
          content = Column(
            children: [
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 640;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _occupancyCard(context, reports),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _revenueCard(context, reports),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _occupancyCard(context, reports),
                    const SizedBox(height: 12),
                    _revenueCard(context, reports),
                  ],
                );
              }),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 640;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _requestsCard(context, reports.requestsStats),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _nationalitiesCard(
                            context, reports.guestsByNationality),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _requestsCard(context, reports.requestsStats),
                    const SizedBox(height: 12),
                    _nationalitiesCard(
                        context, reports.guestsByNationality),
                  ],
                );
              }),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'التقارير',
                icon: Icons.bar_chart_rounded,
                iconColor: scheme.primary,
              ),
              Text(
                'مؤشرات الأداء التشغيلي والمالي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
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

  // ───────────── الإشغال آخر 14 يومًا ─────────────

  Widget _occupancyCard(BuildContext context, AdminReports reports) {
    final occupancy = reports.occupancyLast14Days;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نسبة الإشغال — آخر 14 يومًا',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AdminBarChart(
            height: 170,
            bars: [
              for (final d in occupancy) (d.label, d.percent.toDouble()),
            ],
            // القيمة فوق كل عمود: نسبة الإشغال
            valueFormatter: (v) => '${v.round()}%',
          ),
          const SizedBox(height: 8),
          Text(
            'المحسوبة على ${reports.effectiveRooms} غرفة فعّالة (بدون خارج الخدمة)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── الإيراد آخر 6 أشهر ─────────────

  Widget _revenueCard(BuildContext context, AdminReports reports) {
    final revenue = reports.revenueByMonth;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإيراد — آخر 6 أشهر',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AdminBarChart(
            height: 170,
            barColor: AppColors.gold,
            bars: [
              for (final m in revenue) (m.month, m.totalCents.toDouble()),
            ],
            // بالسنت → تنسيق الأموال الحرفي
            valueFormatter: (v) => fmt.formatMoney(v.round()),
          ),
        ],
      ),
    );
  }

  // ───────────── طلبات الخدمة ─────────────

  Widget _requestsCard(BuildContext context, RequestsStats stats) {
    final scheme = Theme.of(context).colorScheme;
    if (stats.total == 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'طلبات الخدمة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            EmptyState(
              icon: Icons.room_service_rounded,
              title: 'لا توجد طلبات',
            ),
          ],
        ),
      );
    }
    final maxService = stats.topServices.isEmpty
        ? 0
        : stats.topServices
            .map((s) => s.count)
            .reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طلبات الخدمة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _statBoxes(context, stats),
          const SizedBox(height: 12),
          if (stats.byStatus.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in stats.byStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${fmt.label(fmt.requestStatusLabels, s.status)} · ${s.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'أكثر الخدمات طلبًا',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in stats.topServices) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: maxService > 0 ? s.count / maxService : 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  /// صناديق الإحصاءات الأربعة — StatBox في الويب
  Widget _statBoxes(BuildContext context, RequestsStats stats) {
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 480 ? 4 : 2;
      final boxWidth = (c.maxWidth - 8 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: boxWidth,
            child: _StatBox(
              label: 'الإجمالي',
              value: '${stats.total}',
            ),
          ),
          SizedBox(
            width: boxWidth,
            child: _StatBox(
              label: 'مكتمل',
              value: '${stats.completed}',
              color: AppColors.success,
            ),
          ),
          SizedBox(
            width: boxWidth,
            child: _StatBox(
              label: 'نشط',
              value: '${stats.active}',
              color: AppColors.goldDark,
            ),
          ),
          SizedBox(
            width: boxWidth,
            child: _StatBox(
              label: 'متوسط الإنجاز',
              // انتهائي null آمن — '—' كما الويب
              value: stats.avgCompletionMinutes != null
                  ? '${stats.avgCompletionMinutes}د'
                  : '—',
            ),
          ),
        ],
      );
    });
  }

  // ───────────── الضيوف حسب الجنسية (أعلى 5) ─────────────

  Widget _nationalitiesCard(
    BuildContext context,
    List<NationalityCount> nationalities,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final maxNat = nationalities.isEmpty
        ? 0
        : nationalities.map((n) => n.count).reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الضيوف حسب الجنسية (أعلى 5)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (nationalities.isEmpty)
            const EmptyState(
              icon: Icons.public_rounded,
              title: 'لا يوجد ضيوف',
            )
          else
            for (final n in nationalities) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      n.nationality,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${n.count} ضيف',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: maxNat > 0 ? n.count / maxNat : 0,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

// ───────────── عناصر خاصة بالملف ─────────────

/// صندوق إحصاء — StatBox في الويب (قيمة كبيرة + تسمية صغيرة)
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color ?? scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// هياكل تحميل (Skeleton في الويب)
Widget _skeleton(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      for (var i = 0; i < 4; i++) ...[
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

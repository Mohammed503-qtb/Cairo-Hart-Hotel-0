// ─────────────────────────────────────────────────────────────
// DASHBOARD SCREEN — لوحة تحكم الاستقبال اليومية (نقل dashboard-view.tsx)
// بطاقات KPI + إشغال الغرف + وصول/مغادرات اليوم + الطلبات المعلقة
// + إجراءات سريعة — المقيمون وإدارة الطلبات تُفتح مع شاشات F4-b
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
import 'wizards/check_in_wizard.dart';
import 'wizards/check_out_wizard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onGoTab,
  });

  final ReceptionStore store;
  final void Function(int) onGoTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.store.dashboard == null) _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshDashboard();
      if (mounted) setState(() => _error = null);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// سحب التحديث: الخطأ يظهر توستًا (وحالة الخطأ عند غياب البيانات)
  Future<void> _silentRefresh() async {
    try {
      await widget.store.refreshDashboard();
      if (mounted) setState(() => _error = null);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _silentRefresh,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final d = widget.store.dashboard;
          if (d == null) {
            if (_error != null) {
              return _scrollList(
                  ErrorRetryView(message: _error!, onRetry: _refresh));
            }
            return _scrollList(const _DashboardSkeleton());
          }
          return _scrollList(
            _DashboardBody(
                data: d, store: widget.store, onGoTab: widget.onGoTab),
          );
        },
      ),
    );
  }

  ListView _scrollList(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [child],
      );
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.store,
    required this.onGoTab,
  });

  final ReceptionDashboard data;
  final ReceptionStore store;
  final void Function(int) onGoTab;

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final kpiCols = maxWidth >= 700 ? 4 : 2;
      final twoCols = maxWidth >= 900;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kpiGrid(kpiCols, maxWidth, stats),
          const SizedBox(height: 16),
          _occupancyCard(context, stats),
          const SizedBox(height: 16),
          if (twoCols)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _arrivalsSection(context)),
                const SizedBox(width: 16),
                Expanded(child: _departuresSection(context)),
              ],
            )
          else ...[
            _arrivalsSection(context),
            const SizedBox(height: 16),
            _departuresSection(context),
          ],
          const SizedBox(height: 16),
          _requestsSection(context),
          const SizedBox(height: 16),
          _quickActions(),
        ],
      );
    });
  }

  // ── بطاقات KPI ──
  Widget _kpiGrid(int cols, double maxWidth, ReceptionStats stats) {
    const gap = 10.0;
    final width = (maxWidth - gap * (cols - 1)) / cols;
    // KPI المقيمين والطلبات بلا نقرة — شاشتاهما تُفتحان في F4-b
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        SizedBox(
          width: width,
          child: KpiCard(
            icon: Icons.flight_land_rounded,
            label: 'وصول اليوم',
            value: stats.arrivalsToday,
            tone: KpiTone.primary,
            onTap: () => onGoTab(1),
          ),
        ),
        SizedBox(
          width: width,
          child: KpiCard(
            icon: Icons.flight_takeoff_rounded,
            label: 'مغادرة اليوم',
            value: stats.departuresToday,
            tone: KpiTone.coral,
            onTap: () => onGoTab(2),
          ),
        ),
        SizedBox(
          width: width,
          child: KpiCard(
            icon: Icons.groups_rounded,
            label: 'المقيمون الآن',
            value: stats.inHouseStays,
            tone: KpiTone.success,
          ),
        ),
        SizedBox(
          width: width,
          child: KpiCard(
            icon: Icons.room_service_rounded,
            label: 'طلبات معلقة',
            value: stats.pendingRequests,
            tone: stats.urgentRequests > 0 ? KpiTone.urgent : KpiTone.warning,
            sub: stats.urgentRequests > 0
                ? 'منها ${stats.urgentRequests} عاجل ⚡'
                : null,
          ),
        ),
      ],
    );
  }

  // ── الإشغال ──
  Widget _occupancyCard(BuildContext context, ReceptionStats stats) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bed_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            const Text('إشغال الغرف',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${stats.occupancyPercent}%',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary)),
          ]),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: stats.occupancyPercent / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 6),
          Text('${stats.occupiedRooms} مشغولة من ${stats.totalRooms} غرفة',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── وصول اليوم ──
  Widget _arrivalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceptionSectionTitle(
          'وصول اليوم',
          icon: Icons.flight_land_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          action: TextButton(
              onPressed: () => onGoTab(1), child: const Text('الكل')),
        ),
        if (data.arrivals.isEmpty)
          const EmptyState(
              icon: Icons.flight_land_rounded,
              title: 'لا وصولات اليوم 🎉',
              subtitle: 'استرح قليلًا')
        else
          for (final a in data.arrivals) ...[
            _ArrivalRow(store: store, arrival: a),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  // ── مغادرات اليوم ──
  Widget _departuresSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceptionSectionTitle(
          'مغادرات اليوم',
          icon: Icons.flight_takeoff_rounded,
          iconColor: AppColors.danger,
          action: TextButton(
              onPressed: () => onGoTab(2), child: const Text('الكل')),
        ),
        if (data.departures.isEmpty)
          const EmptyState(
              icon: Icons.flight_takeoff_rounded, title: 'لا مغادرات اليوم')
        else
          for (final d in data.departures) ...[
            _DepartureRow(store: store, departure: d),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  // ── الطلبات المعلقة (عرض فقط) ──
  Widget _requestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceptionSectionTitle('طلبات معلقة',
            icon: Icons.room_service_rounded, iconColor: AppColors.warning),
        if (data.pendingRequests.isEmpty)
          const EmptyState(
              icon: Icons.notifications_outlined,
              title: 'لا طلبات معلقة ✨',
              subtitle: 'كل شيء تحت السيطرة')
        else
          // الإدارة والتخصيص يُفتحان مع شاشة الطلبات في F4-b
          for (final r in data.pendingRequests) ...[
            _RequestRow(request: r),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  // ── إجراءات سريعة ──
  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReceptionSectionTitle('إجراءات سريعة'),
        // زرا «لوحة الغرف» و«بحث» يُفتحان مع شاشات F4-b
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => onGoTab(2),
              icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
              label: const Text('المغادرون'),
            ),
          ],
        ),
      ],
    );
  }
}

/// صف وصول اليوم (بطاقة مضغوطة مع زر تسجيل الوصول)
class _ArrivalRow extends StatelessWidget {
  const _ArrivalRow({required this.store, required this.arrival});

  final ReceptionStore store;
  final DashboardArrival arrival;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = arrival;
    final paidPercent =
        ((a.paidCents / (a.grandTotalCents > 0 ? a.grandTotalCents : 1)) * 100)
            .round();
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(a.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            RefCodeText(a.bookingReference),
          ]),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              children: [
                TextSpan(text: '${a.roomTypeName} · ${a.nights} ليالٍ · '),
                TextSpan(
                    text: '$paidPercent%',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
                const TextSpan(text: ' مدفوع'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            StatusChip.paymentStatus(context, a.paymentStatus),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => showCheckInWizard(
                context,
                store: store,
                reservationId: a.reservationId,
                checkInIso: a.checkIn,
              ),
              child: const Text('تسجيل وصول'),
            ),
          ]),
        ],
      ),
    );
  }
}

/// صف مغادرة اليوم (شارة الغرفة + الرصيد + زر تسجيل الخروج)
class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.store, required this.departure});

  final ReceptionStore store;
  final DashboardDeparture departure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = departure;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(d.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text('غرفة ${d.roomNumber}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 6),
            RefCodeText(d.reference),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('الرصيد: ',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),
            MoneyText(d.balanceCents, colored: true),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            // زر الفاتورة يُضاف مع شاشة تفصيل الإقامة في F4-b
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => showCheckOutWizard(
                context,
                store: store,
                stayId: d.stayId,
              ),
              child: const Text('تسجيل خروج'),
            ),
          ]),
        ],
      ),
    );
  }
}

/// صف طلب معلق (قراءة فقط — بلا نقرة حتى F4-b)
class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final DashboardRequest request;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = request;
    final urgent = r.priority == 'URGENT';
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: urgent
                  ? AppColors.danger.withValues(alpha: 0.10)
                  : scheme.surfaceContainerHighest,
            ),
            child: Icon(
              urgent ? Icons.bolt_rounded : Icons.notifications_outlined,
              size: 18,
              color: urgent ? AppColors.danger : scheme.onSurfaceVariant,
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
                    Text(r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    StatusChip.requestStatus(context, r.status),
                    StatusChip.priority(context, r.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Flexible(
                    child: Text(
                        'غرفة ${r.roomNumber} — ${r.guestName} · ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant)),
                  ),
                  RefCodeText(r.reference),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// هيكل تحميل لوحة التحكم (شبكة 2×2 + صندوقان كبيران)
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 700 ? 4 : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
      Widget box(double h) => Container(
            height: h,
            decoration: BoxDecoration(
              color: const Color(0x11000000),
              borderRadius: BorderRadius.circular(12),
            ),
          );
      final twoCols = constraints.maxWidth >= 900;
      return Column(children: [
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 4; i++) SizedBox(width: width, child: box(90)),
          ],
        ),
        const SizedBox(height: 12),
        if (twoCols)
          Row(children: [
            Expanded(child: box(240)),
            const SizedBox(width: 12),
            Expanded(child: box(240)),
          ])
        else ...[
          box(240),
          const SizedBox(height: 12),
          box(240),
        ],
      ]);
    });
  }
}

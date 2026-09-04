// ─────────────────────────────────────────────────────────────
// ADMIN DASHBOARD SCREEN — لوحة تحكم الإدارة (نقل dashboard.tsx)
// 4 KPIs (الإشغال/المقيمون/إيراد الشهر/طلبات معلقة) + حالة الغرف
// (توزيع + مفاتيح ألوان كالويب) + إيراد 14 يومًا + أحدث الحجوزات
// + تنبيهات + الأكواد النشطة → توليد كود — A-01
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.store,
    required this.onNavigate,
  });

  final AdminStore store;
  final void Function(String sectionKey) onNavigate;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshDashboard();
    } catch (_) {
      // الخطأ يظهر من خلال بطاقة الخطأ أدناه
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final d = store.dashboard;
        if (store.dashboardLoading && d == null) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _header(context),
              const SizedBox(height: 12),
              loadingBlocks(5),
            ],
          );
        }
        if (d == null) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ErrorRetryView(
                message: 'تعذر تحميل لوحة التحكم — تحقق من اتصال الخادم',
                onRetry: _refresh,
              ),
            ],
          );
        }
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _header(context),
            if (store.dashboardLoading)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
            _kpis(context, d),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 780;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _revenueCard(context, d)),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: _roomsCard(context, d)),
                  ],
                );
              }
              return Column(
                children: [
                  _roomsCard(context, d),
                  const SizedBox(height: 12),
                  _revenueCard(context, d),
                ],
              );
            }),
            const SizedBox(height: 12),
            _recentBookingsCard(context, d),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _alertsCard(context, d.alerts)),
                const SizedBox(width: 12),
                Expanded(child: _codesCard(context, d.kpis)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return AdminSectionTitle(
      'لوحة التحكم',
      icon: Icons.dashboard_rounded,
      action: OutlinedButton.icon(
        onPressed: widget.store.dashboardLoading ? null : _refresh,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('تحديث'),
      ),
    );
  }

  Widget _kpis(BuildContext context, AdminDashboard d) {
    final k = d.kpis;
    return LayoutBuilder(builder: (context, c) {
      final cross = c.width >= 620 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cross,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          KpiCard(
            icon: Icons.hotel_rounded,
            label: 'الإشغال',
            value: k.occupancyPercent,
            valueText: '${k.occupancyPercent}%',
            sub: '${k.occupiedRooms} مشغولة من ${k.totalRooms} غرفة',
            tone: KpiTone.success,
          ),
          KpiCard(
            icon: Icons.groups_rounded,
            label: 'المقيمون',
            value: k.inHouseGuests,
            sub:
                '${k.inHouseStays} إقامة نشطة · وصول اليوم ${k.arrivalsToday} · مغادرة ${k.departuresToday}',
          ),
          KpiCard(
            icon: Icons.wallet_rounded,
            label: 'إيراد الشهر',
            value: 0,
            valueText: fmt.formatMoney(k.revenueMonthCents),
            sub: 'مدفوعات مكتملة هذا الشهر',
            tone: KpiTone.warning,
          ),
          KpiCard(
            icon: Icons.room_service_rounded,
            label: 'طلبات معلقة',
            value: k.pendingRequests,
            tone: k.urgentRequests > 0 ? KpiTone.coral : KpiTone.primary,
            sub: k.urgentRequests > 0
                ? 'عاجل: ${k.urgentRequests} ⚠'
                : 'لا توجد طلبات عاجلة',
          ),
        ],
      );
    });
  }

  /// لون نقطة الحالة — نفس معاني roomStatusColors في الويب
  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'AVAILABLE' => AppColors.success,
      'OCCUPIED' => AppColors.danger,
      'RESERVED' => AppColors.info,
      'CLEANING' => AppColors.gold,
      'DIRTY' => AppColors.warning,
      'OUT_OF_ORDER' => Theme.of(context).colorScheme.onSurfaceVariant,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  Widget _roomsCard(BuildContext context, AdminDashboard d) {
    final scheme = Theme.of(context).colorScheme;
    final order = [
      'AVAILABLE',
      'OCCUPIED',
      'RESERVED',
      'CLEANING',
      'DIRTY',
      'OUT_OF_ORDER',
    ];
    final total = order.fold<int>(0, (a, s) => a + (d.roomsByStatus[s] ?? 0));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الغرف',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // توزيع شريطي مكدّس (بديل الدائري في الويب بنفس الألوان)
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final s in order)
                      if ((d.roomsByStatus[s] ?? 0) > 0)
                        Expanded(
                          flex: d.roomsByStatus[s]!,
                          child: Container(color: _statusColor(context, s)),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // مفاتيح الألوان — نفس شبكة الويب (عمودان)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            childAspectRatio: 6.5,
            children: [
              for (final s in order)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(context, s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fmt.label(fmt.roomStatusLabels, s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${d.roomsByStatus[s] ?? 0}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueCard(BuildContext context, AdminDashboard d) {
    final scheme = Theme.of(context).colorScheme;
    final bars = d.revenueByDay
        .map((r) => (
              r.date.length >= 10 ? r.date.substring(5, 10) : r.date,
              r.totalCents / 100.0,
            ))
        .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإيراد اليومي (آخر 14 يومًا)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          AdminBarChart(
            bars: bars,
            height: 180,
            barColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _recentBookingsCard(BuildContext context, AdminDashboard d) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionTitle(
          'أحدث الحجوزات',
          icon: Icons.receipt_long_rounded,
        ),
        if (d.recentBookings.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'لا توجد حجوزات بعد',
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < d.recentBookings.length; i++) ...[
                  if (i > 0) Divider(color: scheme.outlineVariant),
                  _bookingTile(context, d.recentBookings[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _bookingTile(BuildContext context, AdminRecentBooking b) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Row(
        children: [
          Expanded(
            child: Text(
              b.guestName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          StatusChip.reservationStatus(context, b.status),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            RefCodeText(
              b.reference,
              color: scheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${b.roomTypeName} · ${fmt.formatMoney(b.grandTotalCents)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              fmt.timeAgoAr(b.createdAt),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertsCard(BuildContext context, AdminAlerts a) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'تنبيهات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdminAlertBox(
            icon: Icons.room_service_rounded,
            text: a.staleRequests > 0
                ? '${a.staleRequests} طلب معلّق منذ أكثر من 30 دقيقة'
                : 'لا توجد طلبات متأخرة',
            color: a.staleRequests > 0
                ? AppColors.warning
                : scheme.onSurfaceVariant,
            background: a.staleRequests > 0
                ? AppColors.warningContainer
                : scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 8),
          AdminAlertBox(
            icon: Icons.build_rounded,
            text: a.outOfOrderRooms > 0
                ? '${a.outOfOrderRooms} غرفة خارج الخدمة'
                : 'كل الغرف فعّالة',
            color: scheme.onSurfaceVariant,
            background: scheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _codesCard(BuildContext context, AdminKpis k) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded,
                  size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                'الأكواد النشطة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _codeRow(context, 'أكواد ضيوف', k.activeGuestCodes),
          Divider(color: scheme.outlineVariant),
          _codeRow(context, 'أكواد طاقم', k.activeStaffCodes),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onNavigate('staff'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('توليد كود'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_back_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeRow(BuildContext context, String label, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '$count',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

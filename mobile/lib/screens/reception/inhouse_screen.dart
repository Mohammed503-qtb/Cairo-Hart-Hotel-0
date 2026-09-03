// ─────────────────────────────────────────────────────────────
// INHOUSE SCREEN — المقيمون الآن (R-04)
// نقل حرفي لـ inhouse-view.tsx فوق ReceptionStore:
// عنوان قسم بعدّاد + بطاقات بشبكة عمودين (sm:grid-cols-2 في الويب)
// + شارات الخروج/الطلبات النشطة/الرصيد + زر التفاصيل
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

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<InHouseScreen> createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> {
  bool _firstLoad = true;
  String? _error;

  ReceptionStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    // تحميل ذاتي عند الفراغ فقط (bootstrap يحمّل بالتوازي — لا تصادم)
    if (store.inHouse.isEmpty) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      await store.refreshInHouse();
      if (!mounted) return;
      setState(() {
        _error = null;
        _firstLoad = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _firstLoad = false;
      });
      // الويب يكتفي بـ EmptyState — التوست هنا نمط المغادرون (19-b) للجوال
      showAppToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final stays = store.inHouse;
        final loading = (store.inHouseLoading || _firstLoad) && stays.isEmpty;
        // العدّاد يظهر عند أول تحميل ناجح/فاشل أو مع بيانات قديمة (كما null→data في الويب)
        final showCount = stays.isNotEmpty || !_firstLoad;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ReceptionSectionTitle(
                'المقيمون الآن${showCount ? ' (${stays.length})' : ''}',
                icon: Icons.groups_rounded,
                iconColor: AppColors.success,
              ),
              // الخطأ مع قائمة فارغة يحل محل البطاقات (EmptyState كما الويب)
              if (_error != null && stays.isEmpty)
                EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'تعذر التحميل',
                  subtitle: _error,
                )
              else if (loading)
                loadingBlocks(3, height: 112)
              else if (stays.isEmpty)
                const EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'لا توجد إقامات نشطة',
                  subtitle: 'سجّل وصول الضيوف ليظهروا هنا',
                )
              else
                _InHouseGrid(stays: stays, store: store),
            ],
          ),
        );
      },
    );
  }
}

/// شبكة البطاقات: عمودان من 640px فأعلى (sm:grid-cols-2) وعمود واحد للجوال
class _InHouseGrid extends StatelessWidget {
  const _InHouseGrid({required this.stays, required this.store});

  final List<InHouseStay> stays;
  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 640;
        final cardWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in stays)
              SizedBox(
                width: cardWidth,
                child: _InHouseCard(stay: s, store: store),
              ),
          ],
        );
      },
    );
  }
}

/// بطاقة مقيم واحد (article في الويب): الاسم + الحالة + المرجع + نوع الغرفة
/// + صندوق الغرفة يمينًا + شارات الخروج/الطلبات/الرصيد + زر التفاصيل
class _InHouseCard extends StatelessWidget {
  const _InHouseCard({required this.stay, required this.store});

  final InHouseStay stay;
  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caption = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    // خروج اليوم أو قبله؟ قص ISO إلى 10 ومقارنة نصية مع اليوم (كما الويب)
    final today = fmt.todayInputValue();
    final checkoutDate = stay.expectedCheckOutAt.length >= 10
        ? stay.expectedCheckOutAt.substring(0, 10)
        : stay.expectedCheckOutAt;
    final dueOrOverdue = checkoutDate.compareTo(today) <= 0;
    return AppCard(
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          stay.guestName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        StatusChip.stayStatus(context, stay.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RefCodeText(stay.reference),
                        Text('· ${stay.roomTypeName}', style: caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RoomBox(number: stay.roomNumber),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CheckoutBadge(
                date: fmt.formatDateAr(stay.expectedCheckOutAt),
                urgent: dueOrOverdue,
              ),
              if (stay.activeRequests > 0)
                _ActiveRequestsBadge(count: stay.activeRequests),
              _BalanceBadge(cents: stay.balanceCents),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => showStayDetail(
                  context,
                  store: store,
                  stayId: stay.id,
                ),
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('التفاصيل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// صندوق الغرفة (bg-primary/8 + border-primary/25 في الويب)
class _RoomBox extends StatelessWidget {
  const _RoomBox({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'الغرفة',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          Text(
            number,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: scheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة تاريخ الخروج (CalendarClock في الويب): حمراء إذا كان اليوم أو قبله
class _CheckoutBadge extends StatelessWidget {
  const _CheckoutBadge({required this.date, required this.urgent});

  final String date;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = urgent ? AppColors.danger : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            'خروج: $date',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة «n طلب نشط» (ConciergeBell في الويب — بلون التحذير)
class _ActiveRequestsBadge extends StatelessWidget {
  const _ActiveRequestsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.room_service_rounded,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            '$count طلب نشط',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة الرصيد الملون (رصيد: + MoneyAmount colored في الويب)
class _BalanceBadge extends StatelessWidget {
  const _BalanceBadge({required this.cents});

  final int cents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'رصيد:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          MoneyText(cents, colored: true),
        ],
      ),
    );
  }
}

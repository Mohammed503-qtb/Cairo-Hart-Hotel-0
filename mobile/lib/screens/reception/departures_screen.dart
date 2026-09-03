// ─────────────────────────────────────────────────────────────
// DEPARTURES SCREEN — المغادرون: مستحقو اليوم + المتأخرون
// نقل حرفي لـ departures-view.tsx فوق ReceptionStore الجاهز
// (R-03 + فتح معالج الخروج R-07/R-12)
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
import 'wizards/check_out_wizard.dart';

/// ليالي بين تاريخَي ISO كاملين (نقل nightsBetweenDates في الويب).
/// fmt.nightsBetween يعمل على قيم input فقط (YYYY-MM-DD) — لذا مساعد محلي.
int _nightsBetweenIso(String a, String b) {
  final d1 = fmt.tryParseDate(a);
  final d2 = fmt.tryParseDate(b);
  if (d1 == null || d2 == null) return 0;
  final day1 = DateTime(d1.year, d1.month, d1.day);
  final day2 = DateTime(d2.year, d2.month, d2.day);
  final nights = day2.difference(day1).inDays;
  return nights < 0 ? 0 : nights;
}

class DeparturesScreen extends StatefulWidget {
  const DeparturesScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends State<DeparturesScreen> {
  String? error;

  ReceptionStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    if (store.departures.isEmpty) {
      _refresh();
    }
  }

  Future<void> _refresh({String? date}) async {
    try {
      await store.refreshDepartures(date: date);
      if (!mounted) return;
      setState(() => error = null);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
      showAppToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final isToday = store.departuresDate == fmt.todayInputValue();
        return RefreshIndicator(
          onRefresh: () => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ReceptionSectionTitle(
                'المغادرون${isToday ? ' اليوم' : ''}',
                icon: Icons.flight_takeoff_rounded,
                iconColor: AppColors.danger,
              ),
              DateFieldRow(
                value: store.departuresDate,
                onChanged: (v) => _refresh(date: v),
              ),
              const SizedBox(height: 12),
              // الخطأ مع قائمة فارغة يحل محل الأقسام (كما في الويب)
              if (error != null && store.departures.isEmpty)
                ErrorRetryView(message: error!, onRetry: () => _refresh())
              else
                _DeparturesBody(store: store),
            ],
          ),
        );
      },
    );
  }
}

/// أقسام المغادرات: المتأخرون ثم مستحقو اليوم (نفس تقسيم الويب)
class _DeparturesBody extends StatelessWidget {
  const _DeparturesBody({required this.store});

  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    if (store.departuresLoading && store.departures.isEmpty) {
      return loadingBlocks(2, height: 110);
    }
    final isToday = store.departuresDate == fmt.todayInputValue();
    final overdue =
        store.departures.where((d) => d.overdue).toList(growable: false);
    final dueToday =
        store.departures.where((d) => !d.overdue).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          const ReceptionSectionTitle(
            'مغادرات متأخرة',
            icon: Icons.alarm_rounded,
            iconColor: AppColors.danger,
          ),
          for (final d in overdue) ...[
            _DepartureCard(dep: d, store: store),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        ReceptionSectionTitle(
          'مستحقو ${isToday ? 'اليوم' : 'هذا اليوم'}',
          icon: Icons.flight_takeoff_rounded,
          iconColor: AppColors.danger,
        ),
        if (dueToday.isEmpty)
          const EmptyState(
            icon: Icons.flight_takeoff_rounded,
            title: 'لا مغادرات مستحقة',
          )
        else
          for (final d in dueToday) ...[
            _DepartureCard(dep: d, store: store),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// بطاقة مغادرة واحدة (نقل DepartureCard في الويب)
class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.dep, required this.store});

  final DepartureItem dep;
  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caption = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    final nights = _nightsBetweenIso(dep.checkInAt, dep.expectedCheckOutAt);
    return AppCard(
      padding: const EdgeInsets.all(14),
      border: dep.overdue
          ? BorderSide(color: AppColors.danger.withValues(alpha: 0.45))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الاسم + شارة الغرفة + متأخر + حالة الإقامة
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                dep.guestName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  'غرفة ${dep.roomNumber}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (dep.overdue) const _OverdueBadge(),
              StatusChip.stayStatus(context, dep.status),
            ],
          ),
          const SizedBox(height: 6),
          // المرجع · نوع الغرفة · الليالي · تاريخ الخروج
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RefCodeText(dep.reference),
              Text('·', style: caption),
              Text(dep.roomTypeName, style: caption),
              Text('·', style: caption),
              Text('${nights} ليالٍ', style: caption),
              Text('·', style: caption),
              Text(
                'خروج: ${fmt.formatDateWithDayAr(dep.expectedCheckOutAt)}',
                style: caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الرصيد + الطلبات النشطة
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'الرصيد:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              MoneyText(dep.balanceCents, colored: true),
              if (dep.activeRequests > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    '${dep.activeRequests} طلب نشط',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // الأزرار: تحت المحتوى (flex-wrap في الويب يلفها على الشاشات الضيقة)
          // الفاتورة (secondary + Receipt في الويب) → تفصيل الإقامة بتبويب الفاتورة
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => showStayDetail(
                  context,
                  store: store,
                  stayId: dep.id,
                  initialTab: 'bill',
                ),
                icon: const Icon(Icons.receipt_rounded, size: 18),
                label: const Text('الفاتورة'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => showCheckOutWizard(
                  context,
                  store: store,
                  stayId: dep.id,
                ),
                icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شارة «متأخر» (bg-danger/10 + نص destructive + أيقونة منبه)
class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.40)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_rounded, size: 12, color: AppColors.danger),
          SizedBox(width: 3),
          Text(
            'متأخر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

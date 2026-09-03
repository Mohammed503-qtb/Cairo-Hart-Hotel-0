// ─────────────────────────────────────────────────────────────
// ARRIVALS SCREEN — وصولو اليوم: منتقي تاريخ + بطاقات + تفاصيل
// + تسجيل الوصول (نقل arrivals-view.tsx حرفيًا)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
import 'wizards/check_in_wizard.dart';

class ArrivalsScreen extends StatefulWidget {
  const ArrivalsScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<ArrivalsScreen> createState() => _ArrivalsScreenState();
}

class _ArrivalsScreenState extends State<ArrivalsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.store.arrivals.isEmpty) _refresh();
  }

  Future<void> _refresh({String? date}) async {
    try {
      await widget.store.refreshArrivals(date: date);
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
    final store = widget.store;
    return RefreshIndicator(
      onRefresh: () => _refresh(),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final isToday = store.arrivalsDate == fmt.todayInputValue();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ReceptionSectionTitle(
                'الوصولون${isToday ? ' اليوم' : ''}',
                icon: Icons.flight_land_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              DateFieldRow(
                value: store.arrivalsDate,
                onChanged: (v) => _refresh(date: v),
              ),
              const SizedBox(height: 12),
              if (_error != null && store.arrivals.isEmpty)
                ErrorRetryView(message: _error!, onRetry: () => _refresh())
              else if (store.arrivalsLoading && store.arrivals.isEmpty)
                loadingBlocks(3, height: 120)
              else if (store.arrivals.isEmpty)
                SizedBox(
                  height: 300,
                  child: EmptyState(
                    icon: Icons.flight_land_rounded,
                    title:
                        'لا وصولات في ${isToday ? 'اليوم' : 'هذا اليوم'} 🎉',
                  ),
                )
              else
                for (final a in store.arrivals) ...[
                  _ArrivalCard(store: store, arrival: a),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// بطاقة وصول واحدة (نقل ArrivalCard في الويب)
class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({required this.store, required this.arrival});

  final ReceptionStore store;
  final ArrivalItem arrival;

  /// فتح حوار التفاصيل — الموافقة على الوصول تفتح المعالج بعد الإغلاق
  Future<void> _openDetail(BuildContext context) async {
    final doCheckIn = await showDialog<bool>(
      context: context,
      builder: (_) => _ArrivalDetailDialog(arrival: arrival),
    );
    if (doCheckIn == true && context.mounted) {
      await showCheckInWizard(
        context,
        store: store,
        reservationId: arrival.id,
        checkInIso: arrival.checkIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = arrival;
    final paidPercent =
        ((a.paidCents / (a.grandTotalCents > 0 ? a.grandTotalCents : 1)) * 100)
            .round();
    final caption = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(a.guest.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    StatusChip.reservationStatus(context, a.status),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RefCodeText(a.bookingReference),
                      Text('· ${a.roomType.name}', style: caption),
                      Text('· ${a.nights} ليالٍ', style: caption),
                      Text(
                        '· ${a.adults} بالغ'
                        '${a.children > 0 ? ' + ${a.children} طفل' : ''}',
                        style: caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _openDetail(context),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('تفاصيل'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: a.status == 'CONFIRMED'
                  ? () => showCheckInWizard(
                        context,
                        store: store,
                        reservationId: a.id,
                        checkInIso: a.checkIn,
                      )
                  : null,
              icon: const Icon(Icons.meeting_room_rounded, size: 18),
              label: const Text('تسجيل الوصول'),
            ),
          ]),
          // ── حالة الدفع ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip.paymentStatus(context, a.paymentStatus),
                    Text.rich(
                      TextSpan(
                        style: caption,
                        children: [
                          const TextSpan(text: 'مدفوع '),
                          TextSpan(
                            text: fmt.formatMoney(a.paidCents),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface),
                          ),
                          TextSpan(
                              text:
                                  ' من ${fmt.formatMoney(a.grandTotalCents)}'),
                          if (a.paymentMethod != null)
                            TextSpan(
                                text:
                                    ' · ${fmt.label(fmt.paymentMethodLabels, a.paymentMethod!)}'),
                        ],
                      ),
                    ),
                    Text('المتبقي: ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant)),
                    MoneyText(a.remainingCents, colored: true),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: paidPercent / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          if (a.specialRequests != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(a.specialRequests!, style: caption),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// حوار تفاصيل الحجز (نقل ArrivalDetailDialog في الويب)
class _ArrivalDetailDialog extends StatelessWidget {
  const _ArrivalDetailDialog({required this.arrival});

  final ArrivalItem arrival;

  @override
  Widget build(BuildContext context) {
    final a = arrival;
    final scheme = Theme.of(context).colorScheme;
    final paidPercent =
        ((a.paidCents / (a.grandTotalCents > 0 ? a.grandTotalCents : 1)) * 100)
            .round();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.guest.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(children: [
                RefCodeText(a.bookingReference),
                const SizedBox(width: 6),
                StatusChip.reservationStatus(context, a.status),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: InfoBox(
                    label: 'الهاتف',
                    child: Text(a.guest.phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'monospace')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InfoBox(
                      label: 'الجنسية',
                      child: Text(a.guest.nationality ?? '—')),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: InfoBox(
                      label: 'المصدر',
                      child: Text(fmt.sourceLabels[a.source] ?? a.source)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InfoBox(
                      label: 'البريد', child: Text(a.guest.email ?? '—')),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${fmt.formatDateWithDayAr(a.checkIn)} ← '
                          '${fmt.formatDateWithDayAr(a.checkOut)} '
                          '(${a.nights} ليالٍ)',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${a.roomType.name} · ${a.roomType.bedConfig} · '
                      '${a.roomType.sizeSqm}م²',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(children: [
                  _totalRow(
                      context, 'المجموع الفرعي', MoneyText(a.subtotalCents)),
                  _totalRow(context, 'الضريبة', MoneyText(a.taxCents)),
                  _totalRow(context, 'الإجمالي', MoneyText(a.grandTotalCents),
                      bold: true),
                  _totalRow(context, 'المدفوع',
                      MoneyText(a.paidCents, colored: true)),
                  _totalRow(
                      context, 'المتبقي', MoneyText(a.remainingCents),
                      bold: true),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: paidPercent / 100,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    color: AppColors.success,
                  ),
                ]),
              ),
              if (a.specialRequests != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote,
                          size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              const TextSpan(
                                text: 'طلبات خاصة: ',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(text: a.specialRequests!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إغلاق'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: a.status == 'CONFIRMED'
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    icon: const Icon(Icons.meeting_room_rounded, size: 18),
                    label: const Text('تسجيل الوصول'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, Widget value,
      {bool bold = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? null : scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        value,
      ]),
    );
  }
}

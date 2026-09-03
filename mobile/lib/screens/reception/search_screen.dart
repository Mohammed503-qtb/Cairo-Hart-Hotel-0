// ─────────────────────────────────────────────────────────────
// SEARCH SCREEN — البحث العام الفوري (debounce 350ms) — R-19
// نقل حرفي لـ search-dialog.tsx فوق ReceptionStore:
// النقر على حجز/إقامة يغلق البحث ويفتح تفصيل الإقامة أو معالج الوصول
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
import 'stay_detail_screen.dart';
import 'wizards/check_in_wizard.dart';

/// فتح حوار البحث العام — التوقيع عقد مع الشاشات (لا تغيّره)
Future<void> showReceptionSearch(
  BuildContext context, {
  required ReceptionStore store,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SearchDialog(store: store),
  );
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.store});

  final ReceptionStore store;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  SearchResults? _results;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  /// مؤقت debounce 350ms يُلغى عند كل تغيير (useEffect في الويب)
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    SearchResults results;
    try {
      results = await widget.store.search(query);
    } catch (_) {
      // فشل البحث → نتائج فارغة (كما الويب: catch → قوائم فارغة)
      results = SearchResults(
        reservations: const <SearchReservationItem>[],
        stays: const <SearchStayItem>[],
      );
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  /// onSelectStay في الويب: إغلاق البحث ثم فتح تفصيل الإقامة
  void _openStay(String stayId) {
    Navigator.of(context).pop();
    showStayDetail(context, store: widget.store, stayId: stayId);
  }

  /// onSelectReservation: إقامة قائمة → تفصيلها، وإلا معالج الوصول
  void _openReservation(SearchReservationItem reservation) {
    Navigator.of(context).pop();
    if (reservation.stayId != null) {
      showStayDetail(
        context,
        store: widget.store,
        stayId: reservation.stayId!,
      );
    } else {
      showCheckInWizard(
        context,
        store: widget.store,
        reservationId: reservation.id,
        checkInIso: reservation.checkIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _queryController.text.trim();
    final results = _results;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'بحث عام',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'بالمرجع، اسم الضيف، الهاتف، أو رقم الغرفة',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryController,
                onChanged: _onQueryChanged,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'HTL-2026-000421 / خالد / 201 / 967…',
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              if (query.length < 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'اكتب حرفين على الأقل للبحث…',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (_loading && results == null)
                loadingBlocks(2, height: 56)
              else if (results != null) ...[
                if (results.reservations.isEmpty &&
                    results.stays.isEmpty)
                  EmptyState(
                    icon: Icons.search_rounded,
                    title: 'لا نتائج مطابقة',
                    subtitle: 'بحث عن «$query»',
                  ),
                // الحجوزات
                if (results.reservations.isNotEmpty) ...[
                  _SectionLabel(
                    icon: Icons.calendar_month_rounded,
                    text: 'الحجوزات (${results.reservations.length})',
                  ),
                  for (final reservation in results.reservations) ...[
                    _ReservationCard(
                      reservation: reservation,
                      onTap: () => _openReservation(reservation),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 8),
                ],
                // الإقامات النشطة
                if (results.stays.isNotEmpty) ...[
                  _SectionLabel(
                    icon: Icons.person_outline_rounded,
                    text: 'الإقامات النشطة (${results.stays.length})',
                  ),
                  for (final stay in results.stays) ...[
                    _StayCard(stay: stay, onTap: () => _openStay(stay.id)),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// عنوان قسم نتائج (p مع أيقونة في الويب)
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة نتيجة حجز (نقل بطاقة reservation في الويب)
class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onTap});

  final SearchReservationItem reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    reservation.guestName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  RefCodeText(reservation.bookingReference),
                  StatusChip.reservationStatus(context, reservation.status),
                  StatusChip.paymentStatus(context, reservation.paymentStatus),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${reservation.roomTypeName} · '
                    '${fmt.formatDateAr(reservation.checkIn)} ← '
                    '${fmt.formatDateAr(reservation.checkOut)} · ',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    reservation.guestPhone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
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

/// بطاقة نتيجة إقامة نشطة (نقل بطاقة stay في الويب)
class _StayCard extends StatelessWidget {
  const _StayCard({required this.stay, required this.onTap});

  final SearchStayItem stay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                      'غرفة ${stay.roomNumber}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  RefCodeText(stay.reference),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${stay.roomTypeName} · خروج '
                    '${fmt.formatDateAr(stay.expectedCheckOutAt)} · ',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    stay.guestPhone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
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

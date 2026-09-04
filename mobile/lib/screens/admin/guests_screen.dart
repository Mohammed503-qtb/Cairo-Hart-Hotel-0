// ─────────────────────────────────────────────────────────────
// GUESTS SCREEN — الضيوف (A-31)
// نقل حرفي لـ sections/guests.tsx: حقل بحث (الاسم/الهاتف/البريد)
// عبر المخزن + بطاقة ضيف (الاسم/الهاتف/البريد/الجنسية/تاريخ
// الإنشاء/عدد الحجوزات + آخر حجز {bookingReference, checkIn,
// status} بشارة StatusChip.reservationStatus) — الحقول الفارغة
// تُعرض بأمان ('—')
// صفر HTTP هنا: كل نداء عبر AdminStore (نمط F1/F4/F5)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  late final TextEditingController _searchCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    // استمرار البحث الملتزم من المخزن (البحث يقيم في المخزن)
    _searchCtrl = TextEditingController(text: widget.store.guestsQuery);
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshGuests();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showAppToast(context, e.message, error: true);
      }
    }
  }

  /// البحث الحر — عبر المخزن (A-31): q يقيم في المخزن
  Future<void> _applySearch(String q) async {
    try {
      await widget.store.refreshGuests(q: q);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  void _search() {
    _applySearch(_searchCtrl.text.trim());
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _applySearch('');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final guests = store.guests;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AdminSectionTitle(
                'الضيوف',
                icon: Icons.people_rounded,
                iconColor: scheme.primary,
              ),
              Text(
                '${guests.length} ضيف في السجل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _searchBar(context),
              const SizedBox(height: 12),
              if (store.guestsLoading && guests.isEmpty)
                _tableSkeleton(context)
              else if (_error != null && guests.isEmpty)
                ErrorRetryView(message: _error!, onRetry: _refresh)
              else if (guests.isEmpty)
                const AppCard(
                  child: EmptyState(
                    icon: Icons.people_rounded,
                    title: 'لا يوجد ضيوف مطابقون',
                  ),
                )
              else
                for (final g in guests) ...[
                  _GuestCard(guest: g),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _searchBar(BuildContext context) {
    final search = TextField(
      controller: _searchCtrl,
      onChanged: (_) {
        if (mounted) setState(() {});
      },
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: 'اسم / هاتف / بريد…',
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
    final searchBtn = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      onPressed: _search,
      icon: const Icon(Icons.search_rounded, size: 18),
      label: const Text('بحث'),
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 480) {
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 8),
            searchBtn,
          ],
        );
      }
      return Column(
        children: [
          search,
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: searchBtn),
        ],
      );
    });
  }
}

// ───────────── عناصر خاصة بالملف ─────────────

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

/// بطاقة ضيف — صف الجدول في الويب (الضيف/الهاتف/البريد/
/// الجنسية/الحجوزات/آخر حجز) + تاريخ الإنشاء — الفارغ '—'
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.guest});

  final AdminGuest guest;

  String _orDash(String? v) =>
      v == null || v.isEmpty ? '—' : v;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = guest.lastReservation;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (guest.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${guest.reservationsCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.email_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _orDash(guest.email),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                Icons.flag_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _orDash(guest.nationality),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.event_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'أُضيف: ${fmt.formatDateAr(guest.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: last != null
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              last.bookingReference,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fmt.formatDateAr(last.checkIn),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.reservationStatus(context, last.status),
                    ],
                  )
                : Text(
                    '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

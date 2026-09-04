// ─────────────────────────────────────────────────────────────
// RESERVATIONS SCREEN — الحجوزات (A-29/A-30)
// نقل حرفي لـ reservations.tsx: فلتر الحالة السبع + بحث (مرجع/
// اسم/هاتف) + قائمة مصفّحة 20/صفحة + بطاقة الحجز + صفحة تفاصيل
// كاملة (A-30) بلقطة السعر حرفيًا كما الويب: ليالٍ بسعر كل ليلة
// + الضريبة + سياسة الإلغاء وقت الحجز — snapshot خريطة خام
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/admin.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';

/// ليالي لقطة السعر من snapshot['nightly'] — {date, rateName,
/// priceCents} (نفس شكل الويب في reservations.tsx)
List<({String date, String rateName, int priceCents})> _snapshotNights(
    Map<String, dynamic> snapshot) {
  final raw = snapshot['nightly'];
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>)
        (
          date: item['date'] is String ? item['date'] as String : '',
          rateName:
              item['rateName'] is String ? item['rateName'] as String : '',
          priceCents:
              item['priceCents'] is num ? (item['priceCents'] as num).toInt() : 0,
        ),
  ];
}

int _snapCents(Map<String, dynamic> snapshot, String key) {
  final v = snapshot[key];
  if (v is num) return v.toInt();
  return 0;
}

String? _snapStr(Map<String, dynamic> snapshot, String key) =>
    snapshot[key] is String ? snapshot[key] as String : null;

num? _snapNum(Map<String, dynamic> snapshot, String key) =>
    snapshot[key] is num ? snapshot[key] as num : null;

/// أرقام عربية-هندية (toLocaleString('ar-EG') في الويب)
String _arabicNumber(int n) {
  const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n
      .toString()
      .replaceAllMapped(RegExp(r'\d'), (m) => ar[int.parse(m.group(0)!)]);
}

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  late final TextEditingController _searchCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    // استمرار البحث الملتزم من المخزن (الفلاتر تقاوم تنقّل الأقسام)
    _searchCtrl =
        TextEditingController(text: widget.store.reservationsQuery);
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshReservations();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        showAppToast(context, e.message, error: true);
      }
    }
  }

  /// تغيير الفلاتر/الصفحة — كل النداءات عبر المخزن (A-29)
  Future<void> _applyFilters({String? status, String? q, int? page}) async {
    try {
      await widget.store.refreshReservations(status: status, q: q, page: page);
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

  Future<void> _openDetail(AdminReservationItem r) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReservationDetailPage(
          store: widget.store,
          reservationId: r.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final data = store.reservationsPageData;
        final items = data?.items ?? const <AdminReservationItem>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _header(context, data?.total ?? 0),
              const SizedBox(height: 12),
              _filtersRow(context),
              const SizedBox(height: 12),
              if (store.reservationsLoading && data == null)
                _tableSkeleton()
              else if (data == null)
                ErrorRetryView(
                  message: _error ?? 'تعذر تحميل الحجوزات — تحقق من اتصال الخادم',
                  onRetry: _refresh,
                )
              else if (items.isEmpty)
                EmptyState(
                  icon: Icons.content_paste_rounded,
                  title: 'لا توجد حجوزات مطابقة',
                  subtitle: 'غيّر الفلاتر أو مصطلح البحث',
                )
              else ...[
                if (store.reservationsLoading)
                  const LinearProgressIndicator(minHeight: 2),
                for (final r in items) ...[
                  _reservationCard(context, r),
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

  // ───────────── الرأس والفلاتر ─────────────

  Widget _header(BuildContext context, int total) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الحجوزات',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '$total حجز — كل القنوات',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _statusFilter(context),
            const SizedBox(width: 8),
            Expanded(child: _searchField(context)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: _search,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('بحث'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ],
    );
  }

  /// فلتر الحالة — Select في الويب: «كل الحالات» + السبع
  Widget _statusFilter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = widget.store.reservationsStatusFilter;
    final currentLabel = current.isEmpty
        ? 'كل الحالات'
        : (fmt.reservationStatusLabels[current] ?? current);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: PopupMenuButton<String>(
        initialValue: current.isEmpty ? null : current,
        onSelected: (v) => _applyFilters(status: v, page: 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLabel,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 18),
            ],
          ),
        ),
        itemBuilder: (_) => [
          const PopupMenuItem(value: '', child: Text('كل الحالات')),
          for (final e in fmt.reservationStatusLabels.entries)
            PopupMenuItem(value: e.key, child: Text(e.value)),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final showClear = _searchCtrl.text.isNotEmpty;
    return TextField(
      controller: _searchCtrl,
      onSubmitted: (_) => _search(),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'مرجع / اسم الضيف / هاتف…',
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: showClear
            ? IconButton(
                tooltip: 'مسح البحث',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _clearSearch,
              )
            : null,
      ),
    );
  }

  // ───────────── القائمة ─────────────

  Widget _reservationCard(BuildContext context, AdminReservationItem r) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(r),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RefCodeText(r.reference, color: scheme.primary),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Text(
                        fmt.label(fmt.sourceLabels, r.source,
                            fallback: r.source),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r.guestPhone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      r.roomTypeName,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      '${fmt.formatDateAr(r.checkIn)} ← ${fmt.formatDateAr(r.checkOut)}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      '${r.nights} ليالٍ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip.reservationStatus(context, r.status),
                    StatusChip.paymentStatus(context, r.paymentStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MoneyText(r.grandTotalCents),
                    if (r.paidCents > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        'مدفوع: ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        fmt.formatMoney(r.paidCents),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.chevron_left_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pager(BuildContext context, ReservationsPageData d) {
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
          Text(
            'الإجمالي: ${_arabicNumber(d.total)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
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

  Widget _tableSkeleton() {
    return Column(
      children: [
        for (var i = 0; i < 6; i++) ...[
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0x11000000),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ───────────────── صفحة تفاصيل الحجز (A-30) ─────────────────
// قرار جوال موثَّق (نمط stay_detail_screen): حوار الويب
// max-h-90vh يفيض على الجوال — الصفحة الكاملة أدق للمس

class _ReservationDetailPage extends StatefulWidget {
  const _ReservationDetailPage({
    required this.store,
    required this.reservationId,
  });

  final AdminStore store;
  final String reservationId;

  @override
  State<_ReservationDetailPage> createState() =>
      _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<_ReservationDetailPage> {
  AdminReservationDetail? _detail;
  String? _error;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// loadReservationDetail بلا تخزين مؤقت (كنمط R-05/A-30)
  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    try {
      final d = await widget.store.loadReservationDetail(
        widget.reservationId,
      );
      if (!mounted) return;
      setState(() {
        _detail = d;
        _error = null;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      _reloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = _detail;
    return Scaffold(
      appBar: AppBar(
        title: r == null
            ? const Text('…')
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.reference,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusChip.reservationStatus(context, r.status),
                    const SizedBox(width: 6),
                    StatusChip.paymentStatus(context, r.paymentStatus),
                  ],
                ),
              ),
      ),
      body: r == null
          ? (Column(
              children: [
                if (_error != null)
                  Expanded(
                    child: ErrorRetryView(
                      message: _error!,
                      onRetry: _reload,
                    ),
                  )
                else
                  const Expanded(child: LoadingView()),
              ],
            ))
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'أُنشئ ${fmt.formatDateTimeAr(r.createdAt)} — '
                    '${fmt.label(fmt.sourceLabels, r.source, fallback: r.source)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _guestSection(context, r),
                  const SizedBox(height: 12),
                  _snapshotSection(context, r),
                  const SizedBox(height: 12),
                  _paymentsSection(context, r),
                  if (r.stay != null) ...[
                    const SizedBox(height: 12),
                    _staySection(context, r.stay!),
                  ],
                ],
              ),
            ),
    );
  }

  // ───────────── بيانات الضيف ─────────────

  Widget _sectionTitle(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _infoPair(Widget a, Widget b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 8),
          Expanded(child: b),
        ],
      ),
    );
  }

  Widget _guestSection(BuildContext context, AdminReservationDetail r) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.person_rounded, 'بيانات الضيف'),
          const SizedBox(height: 12),
          _infoPair(
            InfoBox(label: 'الاسم', child: Text(r.guestName)),
            InfoBox(
              label: 'الهاتف',
              child: Text(
                r.guestPhone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          _infoPair(
            InfoBox(label: 'البريد', child: Text(r.guestEmail)),
            InfoBox(
                label: 'الجنسية', child: Text(r.guestNationality)),
          ),
          _infoPair(
            InfoBox(label: 'النوع', child: Text(r.roomTypeName)),
            InfoBox(
                label: 'الضيوف',
                child: Text('${r.adults} بالغ + ${r.children} طفل')),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InfoBox(
              label: 'الليالي',
              child: Text(
                '${r.nights} (${fmt.formatDateAr(r.checkIn)} ← '
                '${fmt.formatDateAr(r.checkOut)})',
              ),
            ),
          ),
          InfoBox(
            label: 'طريقة الدفع',
            child: Text(
              r.paymentMethod.isEmpty
                  ? '—'
                  : fmt.label(fmt.paymentMethodLabels, r.paymentMethod),
            ),
          ),
          if (r.specialRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 12, height: 1.6),
                  children: [
                    const TextSpan(
                      text: 'طلبات خاصة: ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: r.specialRequests),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────── لقطة السعر وقت الحجز ─────────────

  Widget _snapshotSection(BuildContext context, AdminReservationDetail r) {
    final scheme = Theme.of(context).colorScheme;
    final snap = r.priceSnapshot;
    final currency = r.currency;
    final nights = _snapshotNights(snap);
    final bookedAt = _snapStr(snap, 'bookedAt');
    final taxPercent = _snapNum(snap, 'taxPercent');
    final subtotal = _snapCents(snap, 'subtotalCents');
    final discount = _snapCents(snap, 'discountCents');
    final taxCents = _snapCents(snap, 'taxCents');
    final grandTotal = _snapCents(snap, 'grandTotalCents');
    final cancellationPolicy = _snapStr(snap, 'cancellationPolicy');
    final checkInTime = _snapStr(snap, 'checkInTime');
    final checkOutTime = _snapStr(snap, 'checkOutTime');

    final headerBits = <String>[
      if (bookedAt != null && bookedAt.isNotEmpty)
        'حُجز في ${fmt.formatDateTimeAr(bookedAt)}',
      if (taxPercent != null) 'ضريبة $taxPercent%',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              context, Icons.receipt_long_rounded, 'لقطة السعر وقت الحجز'),
          if (headerBits.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              headerBits.join(' · '),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (nights.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد تفاصيل ليالٍ محفوظة',
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            )
          else
            Table(
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: scheme.outlineVariant),
              ),
              children: [
                TableRow(
                  children: [
                    _tableHead(context, 'الليلة'),
                    _tableHead(context, 'المعدل'),
                    _tableHead(context, 'السعر'),
                  ],
                ),
                for (final n in nights)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          fmt.formatDateAr(n.date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          n.rateName.isEmpty ? 'السعر الأساسي' : n.rateName,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          fmt.formatMoney(n.priceCents, currency: currency),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final half = (c.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: half,
                    child: _snapshotTotal(
                        context, 'المجموع الفرعي', subtotal, currency),
                  ),
                  SizedBox(
                    width: half,
                    child:
                        _snapshotTotal(context, 'الخصم', discount, currency),
                  ),
                  SizedBox(
                    width: half,
                    child: _snapshotTotal(
                      context,
                      'الضريبة${taxPercent != null ? ' ($taxPercent%)' : ''}',
                      taxCents,
                      currency,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: _snapshotTotal(
                      context,
                      'الإجمالي',
                      grandTotal,
                      currency,
                      emphasized: true,
                    ),
                  ),
                ],
              );
            },
          ),
          if (cancellationPolicy != null ||
              checkInTime != null ||
              checkOutTime != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cancellationPolicy != null &&
                      cancellationPolicy.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(
                            text: 'سياسة الإلغاء وقت الحجز: ',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: cancellationPolicy),
                        ],
                      ),
                    ),
                  if ((checkInTime != null && checkInTime.isNotEmpty) ||
                      (checkOutTime != null && checkOutTime.isNotEmpty)) ...[
                    if (cancellationPolicy != null &&
                        cancellationPolicy.isNotEmpty)
                      const SizedBox(height: 4),
                    Text(
                      [
                        if (checkInTime != null && checkInTime.isNotEmpty)
                          'تسجيل الوصول $checkInTime',
                        if (checkOutTime != null && checkOutTime.isNotEmpty)
                          'المغادرة $checkOutTime',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableHead(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _snapshotTotal(
    BuildContext context,
    String label,
    int cents,
    String currency, {
    bool emphasized = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fmt.formatMoney(cents, currency: currency),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: emphasized ? 15 : 13,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
              color: emphasized ? scheme.primary : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── المدفوعات ─────────────

  Widget _paymentsSection(BuildContext context, AdminReservationDetail r) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                    context, Icons.payments_rounded, 'المدفوعات'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outline),
                ),
                child: Text(
                  'المدفوع ${fmt.formatMoney(r.paidCents)} من '
                  '${fmt.formatMoney(r.grandTotalCents)}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (r.payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد مدفوعات مسجلة',
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < r.payments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fmt.label(fmt.paymentMethodLabels,
                                    r.payments[i].method,
                                    fallback: r.payments[i].method),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${fmt.formatDateTimeAr(r.payments[i].createdAt)}'
                                '${r.payments[i].recordedBy.isNotEmpty ? ' · ${r.payments[i].recordedBy}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          fmt.formatMoney(r.payments[i].amountCents),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: r.payments[i].status == 'COMPLETED'
                                ? AppColors.success
                                : scheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ───────────── الإقامة المرتبطة ─────────────

  Widget _staySection(BuildContext context, AdminStaySummary stay) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: scheme.primary.withValues(alpha: 0.05),
      border: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              context, Icons.meeting_room_rounded, 'الإقامة المرتبطة'),
          const SizedBox(height: 12),
          _infoPair(
            InfoBox(
              label: 'المرجع',
              child: RefCodeText(stay.reference,
                  color: scheme.primary),
            ),
            InfoBox(
              label: 'الغرفة',
              child: Text(
                stay.roomNumber,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _infoPair(
            InfoBox(
              label: 'الحالة',
              child: Text(
                fmt.stayStatusLabels[stay.status] ?? stay.status,
              ),
            ),
            InfoBox(
              label: 'المغادرة المتوقعة',
              child: Text(
                fmt.formatDateAr(stay.expectedCheckOutAt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

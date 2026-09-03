// ─────────────────────────────────────────────────────────────
// STAY DETAIL SCREEN — تفصيل الإقامة الكامل (R-05)
// نقل حرفي لـ stay-detail-dialog.tsx (603 سطرًا) كصفحة كاملة:
// قرار جوال موثَّق — حوار الويب max-h-92vh يفيض على الجوال،
// فالمس الأدق صفحة Navigator.push بتبويبات قابلة للتمرير
// (الضيف / الفاتورة / الطلبات / الرسائل / الإجراءات)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';
// تفصيل الطلب — الوكيل الموازي 20-b (العقد المجمد:
// showRequestDetail(context, store:, requestId:)). الملف شقيق في
// screens/reception/ (نفس نمط القشرة والشاشات) — تقريري يوثّق هذا.
import 'request_detail_screen.dart';
import 'stay_dialogs.dart';
import 'wizards/check_out_wizard.dart';

/// فتح صفحة تفصيل الإقامة — العقد المجمد (الوكيل الرئيسي + 20-b يعتمدانه)
Future<void> showStayDetail(
  BuildContext context, {
  required ReceptionStore store,
  required String stayId,
  String initialTab = 'guest', // guest|bill|requests|messages|actions
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _StayDetailPage(
        store: store,
        stayId: stayId,
        initialTab: initialTab,
      ),
    ),
  );
}

/// ليالي بين تاريخَي ISO كاملين (نقل nightsBetweenDates في الويب).
/// fmt.nightsBetween يعمل على قيم input فقط — وR-05 يرسل ISO كاملًا.
int _nightsBetweenIso(String a, String b) {
  final d1 = fmt.tryParseDate(a);
  final d2 = fmt.tryParseDate(b);
  if (d1 == null || d2 == null) return 0;
  final day1 = DateTime(d1.year, d1.month, d1.day);
  final day2 = DateTime(d2.year, d2.month, d2.day);
  final nights = day2.difference(day1).inDays;
  return nights < 0 ? 0 : nights;
}

/// ليالي لقطة السعر من priceSnapshot.nightly (بنفس شكل الويب)
List<({String date, String rateName, int priceCents})> _snapshotNights(
    Map<String, dynamic>? snapshot) {
  final raw = snapshot?['nightly'];
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>)
        (
          date: item['date'] is String ? item['date'] as String : '',
          rateName: item['rateName'] is String
              ? item['rateName'] as String
              : '',
          priceCents:
              item['priceCents'] is num ? (item['priceCents'] as num).toInt() : 0,
        ),
  ];
}

/// الطلبات المنتهية: نقطة حمراء على تبويب الطلبات إن وُجد طلب غير منتهٍ
const List<String> _closedRequestStatuses = [
  'COMPLETED',
  'CANCELLED',
  'REJECTED',
];

class _StayDetailPage extends StatefulWidget {
  const _StayDetailPage({
    required this.store,
    required this.stayId,
    required this.initialTab,
  });

  final ReceptionStore store;
  final String stayId;
  final String initialTab;

  @override
  State<_StayDetailPage> createState() => _StayDetailPageState();
}

class _StayDetailPageState extends State<_StayDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StayDetailData? _detail;
  String? _error;
  bool _reloading = false;

  int get _initialTabIndex => switch (widget.initialTab) {
        'bill' => 1,
        'requests' => 2,
        'messages' => 3,
        'actions' => 4,
        _ => 0,
      };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _initialTabIndex,
    );
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// إعادة تحميل التفصيل (loadStayDetail بلا تخزين مؤقت كما الويب)
  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    StayDetailData? loaded;
    String? loadError;
    try {
      loaded = await widget.store.loadStayDetail(widget.stayId);
    } on ApiError catch (e) {
      loadError = e.message;
    }
    _reloading = false;
    if (!mounted) return;
    setState(() {
      if (loaded != null) _detail = loaded;
      _error = loadError;
    });
  }

  void _goToMessages() {
    _tabController.animateTo(3);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = _detail;
    final caption = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                detail?.guest.fullName ?? 'تفاصيل الإقامة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 8),
              _RoomBadge(detail.room.number),
              const SizedBox(width: 6),
              StatusChip.stayStatus(context, detail.status),
            ],
          ],
        ),
      ),
      body: detail == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(child: loadingBlocks(2, height: 120)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // سطر الوصف: المرجع · نوع الغرفة · الرصيد
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RefCodeText(detail.reference),
                      Text('·', style: caption),
                      Text(detail.roomType.name, style: caption),
                      Text('·', style: caption),
                      const Text(
                        'الرصيد:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      MoneyText(detail.bill.balanceCents, colored: true),
                    ],
                  ),
                ),
                // فشل إعادة التحميل مع بيانات قديمة: سطر الخطأ يظهر والتبويبات تبقى
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      height: 56,
                      icon: const Icon(Icons.person_rounded, size: 16),
                      text: 'الضيف',
                    ),
                    Tab(
                      height: 56,
                      icon: const Icon(Icons.receipt_rounded, size: 16),
                      text: 'الفاتورة',
                    ),
                    Tab(
                      height: 56,
                      icon: _TabIcon(
                        Icons.room_service_rounded,
                        showDot: detail.requests.any(
                          (r) => !_closedRequestStatuses.contains(r.status),
                        ),
                      ),
                      text: 'الطلبات',
                    ),
                    Tab(
                      height: 56,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                      ),
                      text: 'الرسائل',
                    ),
                    Tab(
                      height: 56,
                      icon: const Icon(Icons.build_rounded, size: 16),
                      text: 'الإجراءات',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _GuestTab(detail: detail),
                      _BillTab(
                        detail: detail,
                        store: widget.store,
                        onChanged: _reload,
                      ),
                      _RequestsTab(detail: detail, store: widget.store),
                      _MessagesTab(
                        store: widget.store,
                        stayId: widget.stayId,
                        embedded: detail.messages,
                      ),
                      _ActionsTab(
                        detail: detail,
                        store: widget.store,
                        onChanged: _reload,
                        onChat: _goToMessages,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ───────────── تبويب الضيف ─────────────

class _GuestTab extends StatelessWidget {
  const _GuestTab({required this.detail});

  final StayDetailData detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = detail.reservation;
    final snapshot = _snapshotNights(r.priceSnapshot);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // شبكة معلومات الضيف (grid-cols-2 في الويب)
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            final width = twoColumns
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'الاسم',
                    child: Text(detail.guest.fullName),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'الهاتف',
                    child: Text(
                      detail.guest.phone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'الجنسية',
                    child: Text(detail.guest.nationality ?? '—'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'رقم الهوية',
                    child: Text(
                      detail.guest.idNumber ?? '—',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'الغرفة',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detail.room.number,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(' · طابق ${detail.room.floor}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: InfoBox(
                    label: 'نوع الغرفة',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bed_rounded, size: 14, color: scheme.primary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(detail.roomType.name)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // صندوق الحجز
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RefCodeText(r.bookingReference, color: scheme.onSurface),
                  _OutlineChip(fmt.label(fmt.sourceLabels, r.source)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${fmt.formatDateWithDayAr(r.checkIn)} ← '
                      '${fmt.formatDateWithDayAr(r.checkOut)} '
                      '(${_nightsBetweenIso(r.checkIn, r.checkOut)} ليالٍ · '
                      '${r.adults} بالغ'
                      '${r.children > 0 ? ' + ${r.children} طفل' : ''})',
                      style: TextStyle(
                        fontSize: 12,
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
                    Icons.phone_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail.guest.phone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'وصول فعلي: ${fmt.formatDateTimeAr(detail.checkInAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (snapshot.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SnapshotBox(nights: snapshot, totalCents: r.grandTotalCents),
        ],
        if ((r.specialRequests ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.40),
              ),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '💬 '),
                  const TextSpan(
                    text: 'طلبات خاصة: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: r.specialRequests!),
                ],
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// لقطة سعر الليالي (عند الحجز) — قائمة قابلة للتمرير + المجموع مع الضريبة
class _SnapshotBox extends StatelessWidget {
  const _SnapshotBox({required this.nights, required this.totalCents});

  final List<({String date, String rateName, int priceCents})> nights;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('لقطة سعر الليالي (عند الحجز)'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final n in nights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${fmt.formatDateAr(n.date)} · ${n.rateName}',
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
                          fmt.formatMoney(n.priceCents),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'المجموع + الضريبة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              MoneyText(totalCents),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────── تبويب الفاتورة ─────────────

class _BillTab extends StatelessWidget {
  const _BillTab({
    required this.detail,
    required this.store,
    required this.onChanged,
  });

  final StayDetailData detail;
  final ReceptionStore store;
  final Future<void> Function() onChanged;

  Future<void> _openPaymentDialog(BuildContext context) async {
    final done = await showPaymentDialog(
      context,
      store: store,
      stayId: detail.id,
      balanceCents: detail.bill.balanceCents,
    );
    if (done && context.mounted) onChanged();
  }

  Future<void> _openChargeDialog(BuildContext context) async {
    final done = await showChargeDialog(
      context,
      store: store,
      stayId: detail.id,
    );
    if (done && context.mounted) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bill = detail.bill;
    final closed = detail.status == 'CLOSED';
    Widget row(String label, Widget value, {bool muted = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: muted ? FontWeight.w600 : FontWeight.w800,
                    color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ),
              value,
            ],
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // مربع الأرصدة (space-y-1.5 + border-t في الويب)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('إجمالي الغرفة (شامل الضريبة)', MoneyText(bill.roomTotalCents),
                  muted: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'المجموع الفرعي ${fmt.formatMoney(bill.roomSubtotalCents)} '
                  '+ ضريبة ${fmt.formatMoney(bill.roomTaxCents)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              row('بنود إضافية', MoneyText(bill.extraTotalCents), muted: true),
              const Divider(height: 14),
              row('الإجمالي المستحق', MoneyText(bill.totalChargesCents)),
              row('إجمالي المدفوع', MoneyText(bill.totalPaidCents, colored: true),
                  muted: true),
              const Divider(height: 14),
              // صف الرصيد الأضخم الملوّن (text-base font-black في الويب)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الرصيد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    MoneyText(bill.balanceCents, colored: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (bill.extraCharges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('البنود الإضافية'),
                for (final c in bill.extraCharges)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _OutlineChip(fmt.label(
                                fmt.chargeCategoryLabels,
                                c.category ?? 'EXTRA',
                              )),
                              Text(
                                c.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((c.date ?? '').isNotEmpty)
                                Text(
                                  ' · ${fmt.formatTimeAr(c.date)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        MoneyText(c.amountCents),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (bill.payments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('المدفوعات'),
                for (final p in bill.payments)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _OutlineChip(
                                fmt.label(fmt.paymentMethodLabels, p.method),
                              ),
                              Text(
                                fmt.formatDateTimeAr(p.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((p.recordedBy ?? '').isNotEmpty)
                                Text(
                                  ' · ${p.recordedBy}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _MoneySuccess(p.amountCents),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // الزران معطّلان إذا كانت الإقامة مغلقة (كما الويب)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: closed ? null : () => _openPaymentDialog(context),
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text('تسجيل دفعة'),
            ),
            OutlinedButton.icon(
              onPressed: closed ? null : () => _openChargeDialog(context),
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: const Text('إضافة بند'),
            ),
          ],
        ),
      ],
    );
  }
}

/// مبلغ أخضر عريض (text-success font-bold في الويب — لمدفوعات الفاتورة)
class _MoneySuccess extends StatelessWidget {
  const _MoneySuccess(this.cents);

  final int cents;

  @override
  Widget build(BuildContext context) {
    return Text(
      fmt.formatMoney(cents),
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.success,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ───────────── تبويب الطلبات ─────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.detail, required this.store});

  final StayDetailData detail;
  final ReceptionStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (detail.requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [_DashedBox('لا توجد طلبات لهذه الإقامة')],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final r in detail.requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showRequestDetail(
                  context,
                  store: store,
                  requestId: r.id,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          StatusChip.requestStatus(context, r.status),
                          StatusChip.priority(context, r.priority),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RefCodeText(r.reference),
                          Text(
                            '· آخر تحديث ${fmt.formatDateTimeAr(r.updatedAt)}',
                            style: TextStyle(
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
            ),
          ),
      ],
    );
  }
}

// ───────────── تبويب الرسائل ─────────────

class _MessagesTab extends StatefulWidget {
  const _MessagesTab({
    required this.store,
    required this.stayId,
    required this.embedded,
  });

  final ReceptionStore store;
  final String stayId;
  final List<StayMessage> embedded;

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  List<StayMessage>? _all;
  late final List<StayMessage> _embedded;
  late final TextEditingController _body;
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // لقطة المدمجة عند أول بناء (كما state الويب لا تتغير مع إعادة التحميل)
    _embedded = widget.embedded;
    _body = TextEditingController();
    _loadAll();
    _scheduleScrollToBottom();
  }

  @override
  void dispose() {
    _body.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// الجلب الكامل للرسائل — عند الفشل نبقى على المدمجة (نفس سكوت الويب)
  Future<void> _loadAll() async {
    try {
      final messages = await widget.store.loadStayMessages(widget.stayId);
      if (!mounted) return;
      setState(() => _all = messages);
      _scheduleScrollToBottom();
    } on ApiError {
      // fallback: رسائل detail المدمجة
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent > 0) {
        _scroll.jumpTo(position.maxScrollExtent);
      }
    });
  }

  List<StayMessage> get _list => _all ?? _embedded;

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await widget.store.sendMessage(
        stayId: widget.stayId,
        body: text,
      );
      if (!mounted) return;
      setState(() {
        // نفس سلوك الويب: الإضافة إلى القائمة الكاملة (all ?? [])
        _all = [...(_all ?? const <StayMessage>[]), message];
      });
      _body.clear();
      _scheduleScrollToBottom();
    } on ApiError {
      if (mounted) {
        showAppToast(context, 'تعذر إرسال الرسالة', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _list;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: list.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا رسائل بعد — ابدأ المحادثة 👋',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final bubbleMaxWidth =
                            constraints.maxWidth * 0.80;
                        return ListView(
                          controller: _scroll,
                          children: [
                            for (final m in list)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MessageBubble(
                                  message: m,
                                  maxWidth: bubbleMaxWidth,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // حقل الإدخال + زر الإرسال (Enter يرسل — TextInputAction.send)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _body,
                  maxLines: 2,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة للضيف…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: (_sending || _body.text.trim().isEmpty)
                    ? null
                    : _send,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// فقاعة رسالة: الاستقبال بلون primary ونصه الفاتح / الضيف بطاقة بحد
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.maxWidth});

  final StayMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReception = message.sender == 'RECEPTION';
    return Align(
      alignment: isReception
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isReception ? scheme.primary : scheme.surface,
            border:
                isReception ? null : Border.all(color: scheme.outlineVariant),
            borderRadius: isReception
                ? const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${message.senderName} · ${fmt.formatTimeAr(message.createdAt)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isReception
                      ? scheme.onPrimary.withValues(alpha: 0.70)
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isReception ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── تبويب الإجراءات ─────────────

class _ActionsTab extends StatefulWidget {
  const _ActionsTab({
    required this.detail,
    required this.store,
    required this.onChanged,
    required this.onChat,
  });

  final StayDetailData detail;
  final ReceptionStore store;
  final Future<void> Function() onChanged;
  final VoidCallback onChat;

  @override
  State<_ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<_ActionsTab> {
  String? _busy;

  Future<void> _decideExtension(String requestId, bool approve) async {
    setState(() => _busy = 'ext-$requestId');
    try {
      await widget.store.decideExtension(requestId, approve: approve);
      if (!mounted) return;
      showAppToast(
        context,
        approve ? 'تمت الموافقة على التمديد ✅' : 'تم رفض طلب التمديد',
      );
      await widget.onChanged();
    } on ApiError {
      if (mounted) showAppToast(context, 'تعذر البت في الطلب', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _decideRoomChange(String requestId, bool approve) async {
    setState(() => _busy = 'rc-$requestId');
    try {
      await widget.store.decideRoomChange(requestId, approve: approve);
      if (!mounted) return;
      showAppToast(
        context,
        approve ? 'تم تغيير الغرفة ✅' : 'تم رفض طلب تغيير الغرفة',
      );
      await widget.onChanged();
    } on ApiError {
      if (mounted) showAppToast(context, 'تعذر البت في الطلب', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _openCheckOutWizard() async {
    await showCheckOutWizard(
      context,
      store: widget.store,
      stayId: widget.detail.id,
    );
    // إعادة التحميل بعد المعالج كي تعكس الصفحة إغلاق الإقامة إن حدث
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = widget.detail;
    final stayClosed = detail.status == 'CLOSED';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (stayClosed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Center(
              child: Text(
                'الإقامة مغلقة — لا إجراءات متاحة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const _SectionLabel('طلبات التمديد', icon: Icons.event_rounded),
        if (detail.extensionRequests.isEmpty)
          const _DashedBox('لا طلبات تمديد')
        else
          for (final e in detail.extensionRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ExtensionCard(
                ext: e,
                busy: _busy,
                onDecide: _decideExtension,
              ),
            ),
        const SizedBox(height: 8),
        const _SectionLabel(
          'طلبات تغيير الغرفة',
          icon: Icons.meeting_room_rounded,
        ),
        if (detail.roomChangeRequests.isEmpty)
          const _DashedBox('لا طلبات تغيير غرفة')
        else
          for (final c in detail.roomChangeRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RoomChangeCard(
                change: c,
                roomNumber: detail.room.number,
                busy: _busy,
                onDecide: _decideRoomChange,
              ),
            ),
        if (!stayClosed) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.onChat,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                ),
                label: const Text('محادثة'),
              ),
              FilledButton.icon(
                onPressed: _openCheckOutWizard,
                icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
                label: const Text('تسجيل خروج'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// بطاقة طلب تمديد: الحالة + «حتى {تاريخ}» + الليالي + السعر + ملاحظة
class _ExtensionCard extends StatelessWidget {
  const _ExtensionCard({
    required this.ext,
    required this.busy,
    required this.onDecide,
  });

  final ExtensionRequestItem ext;
  final String? busy;
  final Future<void> Function(String requestId, bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = busy == 'ext-${ext.id}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip.extensionStatus(context, ext.status),
                    Text(
                      'حتى ${fmt.formatDateWithDayAr(ext.newCheckOut)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '(${ext.nights} ${ext.nights == 1 ? 'ليلة' : 'ليالٍ'})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              MoneyText(ext.priceCents),
            ],
          ),
          if ((ext.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📝 ${ext.note}',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (ext.status == 'PENDING') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        busy == null ? () => onDecide(ext.id, true) : null,
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('موافقة (${fmt.formatMoney(ext.priceCents)})'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        busy == null ? () => onDecide(ext.id, false) : null,
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة طلب تغيير غرفة: من X إلى Y + فرق السعر + السبب + القرار
class _RoomChangeCard extends StatelessWidget {
  const _RoomChangeCard({
    required this.change,
    required this.roomNumber,
    required this.busy,
    required this.onDecide,
  });

  final RoomChangeRequestItem change;
  final String roomNumber;
  final String? busy;
  final Future<void> Function(String requestId, bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = change;
    final isBusy = busy == 'rc-${c.id}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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
              StatusChip.extensionStatus(context, c.status),
              const Text(
                'من',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                roomNumber,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'إلى',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                c.toRoomNumber,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (c.priceDiffCents > 0)
                _OutlineChip(
                  '+ ${fmt.formatMoney(c.priceDiffCents)}',
                  foreground: AppColors.warning,
                  borderColor: AppColors.warning.withValues(alpha: 0.40),
                ),
            ],
          ),
          if ((c.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📝 ${c.reason}',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (c.status == 'PENDING') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: busy == null ? () => onDecide(c.id, true) : null,
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('موافقة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        busy == null ? () => onDecide(c.id, false) : null,
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────── عناصر مشتركة داخل الملف ─────────────

/// شارة «غرفة n» في شريط التطبيق (Badge font-mono في الويب)
class _RoomBadge extends StatelessWidget {
  const _RoomBadge(this.number);

  final String number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        'غرفة $number',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// أيقونة تبويب مع نقطة حمراء (شارة الطلبات غير المنتهية)
class _TabIcon extends StatelessWidget {
  const _TabIcon(this.icon, {this.showDot = false});

  final IconData icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    if (!showDot) return Icon(icon, size: 16);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

/// شارة مخططة صغيرة (Badge variant="outline" في الويب)
class _OutlineChip extends StatelessWidget {
  const _OutlineChip(this.label, {this.foreground, this.borderColor});

  final String label;
  final Color? foreground;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    final bc = borderColor ?? scheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bc),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// عنوان قسم صغير مع أيقونة اختيارية (p.font-bold.text-xs في الويب)
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// صندوق متقطّع فارغ (border-dashed في الويب — إطار مصمت مقبول في Flutter)
class _DashedBox extends StatelessWidget {
  const _DashedBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHECK-IN WIZARD — معالج تسجيل الوصول (4 خطوات) — نقل check-in-wizard.tsx
// تحقق الضيف → تعيين غرفة (نفس النوع ومتاحة) → تأكيد → كود الضيف
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart' as fmt;
import '../../../models/reception.dart';
import '../../../state/reception_store.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets.dart';
import '../reception_bits.dart';

/// فتح معالج تسجيل الوصول — التوقيع الثابت المستخدم من شاشات الاستقبال
Future<void> showCheckInWizard(
  BuildContext context, {
  required ReceptionStore store,
  required String reservationId,
  required String checkInIso,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CheckInWizardDialog(
      store: store,
      reservationId: reservationId,
      checkInIso: checkInIso,
    ),
  );
}

class _CheckInWizardDialog extends StatefulWidget {
  const _CheckInWizardDialog({
    required this.store,
    required this.reservationId,
    required this.checkInIso,
  });

  final ReceptionStore store;
  final String reservationId;
  final String checkInIso;

  @override
  State<_CheckInWizardDialog> createState() => _CheckInWizardDialogState();
}

class _CheckInWizardDialogState extends State<_CheckInWizardDialog> {
  static const List<String> _stepTitles = [
    'التحقق من الضيف',
    'تعيين الغرفة',
    'التأكيد النهائي',
    'تم تسجيل الوصول',
  ];

  int _step = 0;
  ArrivalItem? _arrival;
  List<RoomItem>? _rooms;
  String? _roomId;
  String? _error;
  bool _loading = false;
  CheckInResult? _result;
  bool _copied = false;
  final TextEditingController _waController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _loadArrival();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _waController.dispose();
    _idController.dispose();
    super.dispose();
  }

  /// جلب بيانات الحجز من وصولات يوم الوصول (dateKey كما في الويب)
  Future<void> _loadArrival() async {
    final d = DateTime.tryParse(widget.checkInIso) ?? DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final dateKey = '${d.year}-$mm-$dd';
    try {
      await widget.store.refreshArrivals(date: dateKey);
      if (!mounted) return;
      final found = widget.store.arrivals
          .where((a) => a.id == widget.reservationId)
          .toList(growable: false);
      setState(() {
        if (found.isEmpty) {
          _arrival = null;
          _error =
              'لم يتم العثور على الحجز في وصولات هذا اليوم — قد يكون سُجّل دخوله بالفعل';
        } else {
          _arrival = found.first;
          _error = null;
        }
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  /// الغرف: بيانات المخزن إن وُجدت وإلا تحديث جديد — ثم تعيين محلي
  Future<void> _ensureRooms() async {
    if (widget.store.rooms.isNotEmpty) {
      if (mounted) setState(() => _rooms = widget.store.rooms);
      return;
    }
    try {
      await widget.store.refreshRooms();
    } on ApiError catch (_) {
      if (mounted) showAppToast(context, 'تعذر تحميل الغرف', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _rooms = widget.store.rooms);
  }

  Future<void> _submit() async {
    if (_roomId == null) return;
    setState(() => _loading = true);
    try {
      final result = await widget.store.checkIn(
        reservationId: widget.reservationId,
        roomId: _roomId!,
        idNumber: _idController.text,
      );
      if (!mounted) return;
      _waController.text = result.guestPhone;
      setState(() {
        _result = result;
        _step = 3;
      });
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, 'تعذر تسجيل الوصول — ${e.message}', error: true);
      }
      // عد لخطوة الغرفة — ربما تغيّرت الحالة
      try {
        await widget.store.refreshRooms();
      } catch (_) {/* تحديث الغرف هنا غير حرج */}
      if (!mounted) return;
      setState(() {
        _roomId = null;
        _rooms = widget.store.rooms;
        _step = 1;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyCode() async {
    final code = _result?.guestCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    showAppToast(context, 'تم نسخ الكود ✅');
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _sendWhatsapp() async {
    final result = _result;
    if (result == null) return;
    final url = buildWhatsappCheckInUrl(
      phone: _waController.text,
      roomNumber: result.roomNumber,
      guestCode: result.guestCode,
    );
    if (url == null) {
      showAppToast(context, 'أدخل رقم واتساب صحيحًا أولًا', error: true);
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showAppToast(context, 'تعذر فتح واتساب', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              if (_error != null && _step != 3) ...[
                const SizedBox(height: 10),
                _errorBox(_error!),
              ],
              if (_step == 0) _buildStep0(context),
              if (_step == 1) _buildStep1(context),
              if (_step == 2) _buildStep2(context),
              if (_step == 3 && _result != null) _buildStep3(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.meeting_room_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تسجيل وصول'
              '${_arrival != null ? ' — ${_arrival!.guest.fullName}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < _stepTitles.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: i == _step
                      ? scheme.primary
                      : i < _step
                          ? AppColors.success.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${i + 1}. ${_stepTitles[i]}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: i == _step
                        ? scheme.onPrimary
                        : i < _step
                            ? AppColors.success
                            : scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _errorBox(
    String message, {
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsBox(BuildContext context, List<Widget> rows) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _goldBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  const TextSpan(
                      text: 'طلبات خاصة: ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── الخطوة 1: التحقق من الضيف ──
  Widget _buildStep0(BuildContext context) {
    final a = _arrival;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        if (a == null) ...[
          // هيكل تحميل (Skeleton في الويب)
          Container(
              height: 64,
              decoration: BoxDecoration(
                  color: const Color(0x11000000),
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 8),
          Container(
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0x11000000),
                  borderRadius: BorderRadius.circular(10))),
        ] else ...[
          _detailsBox(
            context,
            [
              _Row('الاسم', Text(a.guest.fullName)),
              _Row(
                'الهاتف',
                Text(a.guest.phone,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontFamily: 'monospace')),
              ),
              _Row(
                'الحجز',
                Row(mainAxisSize: MainAxisSize.min, children: [
                  RefCodeText(a.bookingReference),
                  const SizedBox(width: 6),
                  StatusChip.reservationStatus(context, a.status),
                ]),
              ),
              _Row(
                'المواعيد',
                Text(
                    '${fmt.formatDateWithDayAr(a.checkIn)} ← ${fmt.formatDateWithDayAr(a.checkOut)} (${a.nights} ليالٍ)'),
              ),
              _Row(
                'نوع الغرفة',
                Text(
                    '${a.roomType.name} · ${a.adults} بالغ${a.children > 0 ? ' + ${a.children} طفل' : ''}'),
              ),
              _Row(
                'الإجمالي / المدفوع',
                Row(mainAxisSize: MainAxisSize.min, children: [
                  MoneyText(a.grandTotalCents),
                  const SizedBox(width: 4),
                  const Text(' / '),
                  const SizedBox(width: 4),
                  MoneyText(a.paidCents, colored: true),
                  const SizedBox(width: 6),
                  StatusChip.paymentStatus(context, a.paymentStatus),
                ]),
              ),
            ],
          ),
          if (a.specialRequests != null) ...[
            const SizedBox(height: 10),
            _goldBox(a.specialRequests!),
          ],
          if (a.paidCents < a.grandTotalCents) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'متبقٍّ مستحق ${fmt.formatMoney(a.grandTotalCents - a.paidCents)}'
                    ' — يمكن تسجيل الدفعة بعد الوصول',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _idController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الهوية / جواز السفر (اختياري)',
              hintText: 'مثال: 9988776',
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: (a == null || a.status != 'CONFIRMED')
                  ? null
                  : () {
                      setState(() => _step = 1);
                      _ensureRooms();
                    },
              icon: const Icon(Icons.how_to_reg_rounded, size: 18),
              label: const Text('متابعة'),
            ),
          ],
        ),
      ],
    );
  }

  // ── الخطوة 2: تعيين الغرفة ──
  Widget _buildStep1(BuildContext context) {
    final a = _arrival;
    final scheme = Theme.of(context).colorScheme;
    final rooms = _rooms;
    final rtId = a?.roomType.id;
    final available = (rooms ?? const <RoomItem>[])
        .where((r) => r.status == 'AVAILABLE' && r.roomTypeId == rtId)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            children: [
              const TextSpan(text: 'الغرف '),
              const TextSpan(
                  text: 'المتاحة',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.success)),
              const TextSpan(text: ' من نوع '),
              TextSpan(
                  text: a?.roomType.name ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const TextSpan(text: ' فقط — اختر غرفة:'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (rooms == null)
          _roomsSkeleton()
        else if (available.isEmpty)
          _errorBox(
            'لا توجد غرف متاحة من هذا النوع حاليًا — راجع لوحة الغرف',
            icon: Icons.person_off_rounded,
          )
        else
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              for (final r in available)
                _RoomTile(
                  room: r,
                  selected: _roomId == r.id,
                  onTap: () => setState(() => _roomId = r.id),
                ),
            ],
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed:
                  _roomId == null ? null : () => setState(() => _step = 2),
              child: const Text('متابعة'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roomsSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final w = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                width: w,
                height: 70,
                decoration: BoxDecoration(
                    color: const Color(0x11000000),
                    borderRadius: BorderRadius.circular(10)),
              ),
          ],
        );
      },
    );
  }

  // ── الخطوة 3: التأكيد النهائي ──
  Widget _buildStep2(BuildContext context) {
    final a = _arrival;
    if (a == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    RoomItem? selectedRoom;
    final rooms = _rooms;
    final roomId = _roomId;
    if (rooms != null && roomId != null) {
      for (final r in rooms) {
        if (r.id == roomId) selectedRoom = r;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        _detailsBox(
          context,
          [
            _Row('الضيف', Text(a.guest.fullName)),
            _Row('نوع الغرفة', Text(a.roomType.name)),
            _Row(
              'الغرفة المختارة',
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  selectedRoom?.number ?? '—',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success),
                ),
                Text(' (طابق ${selectedRoom?.floor ?? 0})'),
              ]),
            ),
            _Row('الوصول', Text(fmt.formatDateWithDayAr(a.checkIn))),
            _Row('المغادرة المتوقعة', Text(fmt.formatDateWithDayAr(a.checkOut))),
            _Row('الإجمالي', MoneyText(a.grandTotalCents)),
            _Row('المدفوع', MoneyText(a.paidCents, colored: true)),
            _Row('المتبقي', MoneyText(a.grandTotalCents - a.paidCents)),
            if (_idController.text.trim().isNotEmpty)
              _Row(
                'رقم الهوية',
                Text(_idController.text.trim(),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontFamily: 'monospace')),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سيتم توليد كود تطبيق خاص بالضيف صالح حتى نهاية يوم المغادرة',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('رجوع'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('تأكيد تسجيل الوصول'),
            ),
          ],
        ),
      ],
    );
  }

  // ── الخطوة 4: النجاح + كود الضيف ──
  Widget _buildStep3(BuildContext context) {
    final result = _result!;
    final scheme = Theme.of(context).colorScheme;
    final caption = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 14),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15)),
          child: Icon(Icons.check_circle_rounded,
              size: 40, color: AppColors.success),
        ),
        const SizedBox(height: 12),
        const Text('تم تسجيل الوصول ✅',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('إقامة ', style: caption),
            RefCodeText(result.stayReference),
            Text(' — غرفة ', style: caption),
            Text(result.roomNumber,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success)),
            Text(' — ${result.guestName}', style: caption),
          ],
        ),
        const SizedBox(height: 14),
        // بطاقة الكود السوداء (نفس الألوان في الوضعين الفاتح والداكن)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF424242)),
          ),
          child: Column(children: [
            const Text('كود تطبيق الضيف — يظهر مرة واحدة فقط',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 6),
            SelectableText(
              result.guestCode,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  color: Color(0xFFD4A843)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
          const SizedBox(width: 6),
          Text(
            'احتفظ بالكود الآن — لن يمكن استرجعه لاحقًا',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم الواتساب المُرسَل إليه — قابل للتعديل', style: caption),
              const SizedBox(height: 6),
              TextField(
                controller: _waController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(hintText: '+9677XXXXXXXX'),
              ),
              const SizedBox(height: 6),
              Text(
                'افتراضيًا هاتف الضيف من الحجز — عدّله إن كان رقم واتساب الضيف '
                'مختلفًا قبل الإرسال.',
                style: TextStyle(
                    fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _copyCode,
              icon: Icon(
                  _copied ? Icons.check_circle_rounded : Icons.copy,
                  size: 18),
              label: const Text('نسخ الكود'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: _sendWhatsapp,
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('إرسال واتساب'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تم'),
            ),
          ],
        ),
      ],
    );
  }
}

/// صف تفاصيل داخل صندوق (تسمية 100 + قيمة) — Row في الويب
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: DefaultTextStyle(
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface),
            child: value,
          ),
        ),
      ]),
    );
  }
}

/// بلاطة اختيار غرفة (متاحة من نفس النوع)
class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  final RoomItem room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: selected ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: selected ? 1 : 0.3),
            width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  room.number,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success),
                ),
                const SizedBox(height: 2),
                Text('الطابق ${room.floor}',
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant)),
                if (selected)
                  Icon(Icons.check, size: 14, color: AppColors.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

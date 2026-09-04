// ─────────────────────────────────────────────────────────────
// HOTEL SETTINGS SCREEN — إعدادات الفندق (A-02/A-03)
// نقل حرفي لـ hotel-settings.tsx: نموذج الحقول الحرفية كاملة
// (يشمل minAppVersion من F6 — x.y.z أو فارغ) + بطاقة معلومات
// ذهبية + حفظ PATCH بالحقول المتغيرة فقط (الأرقام int) عبر
// store.updateHotel ثم note الخادم toast + التحقق العميلي
// الأساسي برسائل الخادم الحرفية عند الخطأ
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../state/admin_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class HotelSettingsScreen extends StatefulWidget {
  const HotelSettingsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<HotelSettingsScreen> createState() => _HotelSettingsScreenState();
}

/// الحقول الرقمية وحدودها — NUM_LIMITS في الويب (نفس التسميات)
const Map<String, (int, int, String)> _numLimits = {
  'taxPercent': (0, 100, 'الضريبة %'),
  'weekendSurchargePercent': (0, 100, 'زيادة نهاية الأسبوع %'),
  'minStayNights': (1, 30, 'أقل ليالٍ'),
  'maxStayNights': (1, 60, 'أقصى ليالٍ'),
  'bookingHorizonDays': (1, 730, 'أفق الحجز (يوم)'),
};

/// ترتيب مفاتيح النموذج الحرفي — كما في initial (useMemo) بالويب
const List<String> _fieldKeys = [
  'name', 'tagline', 'description', 'phone', 'whatsapp', 'email',
  'address', 'city', 'currency', 'checkInTime', 'checkOutTime',
  'taxPercent', 'weekendSurchargePercent', 'minStayNights',
  'maxStayNights', 'bookingHorizonDays', 'cancellationPolicy',
  'paymentPolicy', 'childrenPolicy', 'petsPolicy', 'smokingPolicy',
  'minAppVersion',
];

/// السياسات النصية الخمس — نفس أزواج الويب (المفتاح، التسمية)
const List<(String, String)> _policyFields = [
  ('cancellationPolicy', 'سياسة الإلغاء'),
  ('paymentPolicy', 'سياسة الدفع'),
  ('childrenPolicy', 'سياسة الأطفال'),
  ('petsPolicy', 'سياسة الحيوانات الأليفة'),
  ('smokingPolicy', 'سياسة التدخين'),
];

final RegExp _timeRe = RegExp(r'^\d{2}:\d{2}$');
final RegExp _semVerRe = RegExp(r'^\d+\.\d+\.\d+$');

class _HotelSettingsScreenState extends State<HotelSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    String? err;
    try {
      await widget.store.refreshHotel();
    } on ApiError catch (e) {
      err = e.message;
    }
    if (!mounted) return;
    if (err != null) showAppToast(context, err, error: true);
    setState(() => _error = err);
    // أول تحميل فقط: بناء المتحكمات من بيانات الفندق (كما يهيّئ
    // الويب نموذجه عند أول توفر للبيانات — إعادة الجلب اللاحقة
    // تحافظ على تعديلات المستخدم كما يحفظ الويب حالة form)
    if (_controllers.isEmpty) _syncControllers();
  }

  /// القيم الأولية من الفندق (مطابقة String(hotel[key] ?? '') بالويب)
  Map<String, String>? _initialMap() {
    final h = widget.store.hotel;
    if (h == null) return null;
    return {
      'name': h.name,
      'tagline': h.tagline,
      'description': h.description,
      'phone': h.phone,
      'whatsapp': h.whatsapp,
      'email': h.email,
      'address': h.address,
      'city': h.city,
      'currency': h.currency,
      'checkInTime': h.checkInTime,
      'checkOutTime': h.checkOutTime,
      'taxPercent': '${h.taxPercent}',
      'weekendSurchargePercent': '${h.weekendSurchargePercent}',
      'minStayNights': '${h.minStayNights}',
      'maxStayNights': '${h.maxStayNights}',
      'bookingHorizonDays': '${h.bookingHorizonDays}',
      'cancellationPolicy': h.cancellationPolicy,
      'paymentPolicy': h.paymentPolicy,
      'childrenPolicy': h.childrenPolicy,
      'petsPolicy': h.petsPolicy,
      'smokingPolicy': h.smokingPolicy,
      'minAppVersion': h.minAppVersion,
    };
  }

  /// مزامنة المتحكمات مع قيم الفندق — بعد الحفظ (كالويب: setForm(null)
  /// + reload) وعند أول توفر للبيانات. لا تُستدعى أثناء بناء مرفق
  /// بمستمعين إلا من مسارات ما بعد await (آمنة).
  void _syncControllers() {
    final init = _initialMap();
    if (init == null) return;
    for (final k in _fieldKeys) {
      final c = _controllers[k] ??= TextEditingController();
      final v = init[k] ?? '';
      if (c.text != v) c.text = v;
    }
  }

  bool get _dirty {
    final init = _initialMap();
    if (init == null || _controllers.isEmpty) return false;
    for (final k in _fieldKeys) {
      if ((init[k] ?? '') != (_controllers[k]?.text ?? '')) return true;
    }
    return false;
  }

  String _value(String k) => _controllers[k]?.text ?? '';

  /// التحقق العميلي الأساسي — رسائل الخادم الحرفية نفسها
  String? _validate() {
    if (_value('name').trim().isEmpty) {
      return 'اسم الفندق لا يمكن أن يكون فارغًا';
    }
    if (_value('currency').trim().isEmpty) {
      return 'العملة لا يمكن أن تكون فارغة';
    }
    if (!_timeRe.hasMatch(_value('checkInTime')) ||
        !_timeRe.hasMatch(_value('checkOutTime'))) {
      return 'صيغة الوقت يجب أن تكون HH:MM (مثال: 14:00)';
    }
    final minApp = _value('minAppVersion').trim();
    if (minApp.isNotEmpty && !_semVerRe.hasMatch(minApp)) {
      return 'صيغة إصدار التطبيق يجب أن تكون ثلاثية رقمية (مثال: 1.2.0)';
    }
    for (final e in _numLimits.entries) {
      final raw = _value(e.key).trim();
      // الفارغ لا يُرسل أصلًا (كما الويب: NaN يُهمل)
      if (raw.isEmpty) continue;
      final n = int.tryParse(raw);
      if (n == null || n < e.value.$1 || n > e.value.$2) {
        return switch (e.key) {
          'minStayNights' => 'أقل عدد ليالٍ يجب أن يكون بين 1 و 30',
          'maxStayNights' => 'أقصى عدد ليالٍ يجب أن يكون بين 1 و 60',
          'bookingHorizonDays' => 'أفق الحجز يجب أن يكون بين 1 و 730 يومًا',
          _ => 'النسبة يجب أن تكون بين 0 و 100',
        };
      }
    }
    final minStay = int.tryParse(_value('minStayNights').trim());
    final maxStay = int.tryParse(_value('maxStayNights').trim());
    if (minStay != null && maxStay != null && maxStay < minStay) {
      return 'أقصى عدد ليالٍ يجب أن يكون أكبر من أو يساوي أقل عدد ليالٍ';
    }
    return null;
  }

  /// جسم PATCH: الحقول المتغيرة فقط — الأرقام int (كما الويب حرفيًا)
  Map<String, dynamic> _changedPayload() {
    final init = _initialMap() ?? const <String, String>{};
    final payload = <String, dynamic>{};
    for (final k in _fieldKeys) {
      final v = _value(k);
      if (v != (init[k] ?? '')) {
        if (_numLimits.containsKey(k)) {
          final n = int.tryParse(v);
          if (n != null) payload[k] = n;
        } else {
          payload[k] = v;
        }
      }
    }
    return payload;
  }

  Future<void> _save() async {
    if (_saving) return;
    final err = _validate();
    if (err != null) {
      showAppToast(context, err, error: true);
      return;
    }
    final payload = _changedPayload();
    setState(() => _saving = true);
    try {
      // note الخادم حرفيًا («تغيير الضريبة والأسعار يؤثر على الحجوزات
      // الجديدة فقط…») — المخزن يعيد تحميل الإعدادات بعد النجاح
      final note = await widget.store.updateHotel(payload);
      if (!mounted) return;
      _syncControllers();
      showAppToast(context, note);
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    // أول توفر للبيانات: بناء المتحكمات قبل رسم أي حقل (لا مستمعين
    // بعد) — يمنع وميض نموذج فارغ قبل اكتمال الجلب
    if (store.hotel != null && _controllers.isEmpty) _syncControllers();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hasHotel = store.hotel != null;
        final Widget body;
        if (!hasHotel && _error != null) {
          body = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ErrorRetryView(message: _error!, onRetry: _refresh),
            ],
          );
        } else if (!hasHotel) {
          body = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _header(context, dirty: false, enabled: false),
              const SizedBox(height: 12),
              _skeletonCards(),
            ],
          );
        } else {
          body = _formList(context);
        }
        return RefreshIndicator(onRefresh: _refresh, child: body);
      },
    );
  }

  // ───────────── عناصر البناء ─────────────

  Widget _header(BuildContext context,
      {required bool dirty, required bool enabled}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إعدادات الفندق',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'بيانات الفندق وحدود الحجز والسياسات — مصدر الحقيقة لكل القنوات',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 8),
            _saveButton(dirty: dirty),
          ],
        ],
      ),
    );
  }

  Widget _saveButton({required bool dirty, String idleLabel = 'حفظ'}) {
    return FilledButton.icon(
      onPressed: dirty && !_saving ? _save : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded, size: 18),
      label: Text(dirty ? 'حفظ التغييرات' : idleLabel),
    );
  }

  /// بطاقة التحذير الذهبية — نفس نص الويب حرفيًا
  Widget _goldNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noticeColor = scheme.brightness == Brightness.light
        ? AppColors.goldDark
        : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: noticeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                  color: noticeColor,
                ),
                children: const [
                  TextSpan(
                      text: 'التغييرات على الضريبة وزيادة نهاية الأسبوع تؤثر على '),
                  TextSpan(
                    text: 'الحجوزات الجديدة فقط',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                      text: ' — الحجوزات القديمة تحتفظ بلقطة سعرها وقت الحجز.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _formList(BuildContext context) {
    final dirty = _dirty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _header(context, dirty: dirty, enabled: true),
        const SizedBox(height: 8),
        _goldNotice(context),
        const SizedBox(height: 12),
        if (widget.store.hotelLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _sectionCard(
          context,
          icon: Icons.hotel_rounded,
          title: 'المعلومات الأساسية',
          children: [
            _fieldGrid([
              _field('اسم الفندق *', 'name'),
              _field('العملة', 'currency', hint: 'USD', ltr: true),
            ]),
            const SizedBox(height: 12),
            _field('الشعار التسويقي', 'tagline',
                hint: 'ضيافة راقية في قلب المدينة'),
            const SizedBox(height: 12),
            _field('الوصف', 'description', maxLines: 4),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          icon: Icons.phone_rounded,
          title: 'التواصل والموقع',
          children: [
            _fieldGrid([
              _field('الهاتف', 'phone',
                  ltr: true, keyboard: TextInputType.phone),
              _field('واتساب', 'whatsapp',
                  ltr: true, keyboard: TextInputType.phone),
            ]),
            const SizedBox(height: 12),
            _fieldGrid([
              _field('البريد الإلكتروني', 'email',
                  ltr: true, keyboard: TextInputType.emailAddress),
              _field('المدينة', 'city'),
            ]),
            const SizedBox(height: 12),
            _field('العنوان', 'address'),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          icon: Icons.tune_rounded,
          title: 'حدود الحجز والأسعار',
          children: [
            _fieldGrid([
              _field('وقت تسجيل الوصول', 'checkInTime',
                  ltr: true, hint: '14:00'),
              _field('وقت المغادرة', 'checkOutTime',
                  ltr: true, hint: '12:00'),
              for (final e in _numLimits.entries)
                _field(
                  '${e.value.$3} (${e.value.$1}-${e.value.$2})',
                  e.key,
                  ltr: true,
                  keyboard: TextInputType.number,
                ),
            ]),
            const SizedBox(height: 10),
            Text(
              'زيادة نهاية الأسبوع تُطبق على ليالي الجمعة والسبت للحجوزات الجديدة.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          icon: Icons.smartphone_rounded,
          title: 'تطبيق الضيف (Flutter)',
          children: [
            SizedBox(
              width: 280,
              child: _field('أقل إصدار مسموح للتطبيق', 'minAppVersion',
                  hint: 'مثال: 1.2.0', ltr: true),
            ),
            const SizedBox(height: 8),
            Text(
              'اتركه فارغًا لإلغاء الفرض. عند تعيينه: تطبيق الضيف بإصدار أقل '
              'يُحجب عند الإطلاق بشاشة «تحديث مطلوب» حتى يُحدَّث من صفحة '
              'الإصدارات. يُستخدم عند بطلان إصدار قائم (كسر عقد) — لا يؤثر '
              'على الويب إطلاقًا.',
              style: TextStyle(
                fontSize: 11,
                height: 1.7,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          icon: Icons.description_rounded,
          title: 'السياسات',
          children: [
            _fieldGrid([
              for (final (k, label) in _policyFields)
                _field(label, k, maxLines: 3),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _saveButton(dirty: dirty, idleLabel: 'لا توجد تغييرات'),
          ],
        ),
      ],
    );
  }

  Widget _skeletonCards() {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0x11000000),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// حقل نموذج — تسمية فوق حقل إدخال (Label + Input في الويب)
  Widget _field(
    String label,
    String key, {
    String? hint,
    int maxLines = 1,
    bool ltr = false,
    TextInputType? keyboard,
  }) {
    final controller = _controllers[key];
    if (controller == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: ValueKey('hotel-$key'),
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : null,
          keyboardType: keyboard,
          textDirection: ltr ? TextDirection.ltr : null,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  /// شبكة أعمدة مرنة (grid md:grid-cols-2 في الويب) — حقلان في
  /// الضيق وتلقائيًا أكثر في العرض الواسع
  Widget _fieldGrid(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final f in fields) SizedBox(width: half, child: f),
          ],
        );
      },
    );
  }
}

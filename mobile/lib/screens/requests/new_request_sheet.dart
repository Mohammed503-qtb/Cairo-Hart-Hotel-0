// ─────────────────────────────────────────────────────────────
// NEW REQUEST SHEET — إنشاء طلب خدمة (نقل request-dialog.tsx — G-05)
// العنوان (≥3 أحرف بتحقق محلي) + الوصف الاختياري + الأولوية
// القسم يُشتق من الخدمة المسبقة (أو OTHER لطلب خاص) كما في الويب
// حرفيًا: الويب لا يملك منتقي قسم — preset الخدمة يحدده دومًا
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../actions/sheet_frame.dart';

/// تسميات أقسام الطلبات (نصوص الويب حرفيًا — تُشارك مع شاشة التفاصيل)
const Map<String, String> requestCategoryLabels = {
  'HOUSEKEEPING': 'خدمات التنظيف',
  'MAINTENANCE': 'الصيانة',
  'GUEST_SERVICES': 'خدمات الضيافة',
  'OTHER': 'طلب خاص',
};

/// فتح صفيحة إنشاء طلب (isScrollControlled + مساحة لوحة المفاتيح كحوارات 13-b)
/// [presetService] خدمة من الكتالوج تملأ الحقول كما في الويب (العنوان =
/// اسمها والقسم = قسمها)، أو null لطلب خاص خارج الكتالوج (OTHER فارغ)
Future<void> showNewRequestSheet(
  BuildContext context,
  GuestStore store, {
  ServiceItem? presetService,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) => Padding(
      // رفع الصفيحة فوق لوحة المفاتيح عند الكتابة
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: NewRequestSheet(store: store, presetService: presetService),
    ),
  );
}

/// صفيحة إنشاء طلب خدمة
class NewRequestSheet extends StatefulWidget {
  const NewRequestSheet({
    super.key,
    required this.store,
    this.presetService,
  });

  final GuestStore store;
  final ServiceItem? presetService;

  @override
  State<NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<NewRequestSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  /// القسم والخدمة يُشتقان عند الفتح ولا يتغيران (preset الويب يحددهما)
  late final String _category;
  late final String? _serviceId;
  String _priority = 'NORMAL';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final preset = widget.presetService;
    // التعبئة المسبقة كما في الويب: العنوان من الخدمة فقط، والوصف يبدأ
    // فارغًا والأولوية NORMAL عند كل فتح (State جديد كـ useEffect [preset])
    _serviceId = preset?.id;
    _category = preset?.categoryKey ?? 'OTHER';
    _titleController = TextEditingController(text: preset?.name ?? '');
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) {
      return;
    }
    final title = _titleController.text.trim();
    // تحقق محلي بنص الويب نفسه (العنوان ≥ 3 أحرف)
    if (title.length < 3) {
      showAppToast(
        context,
        'اكتب عنوانًا للطلب (3 أحرف على الأقل)',
        error: true,
      );
      return;
    }
    setState(() => _sending = true);
    try {
      // G-05 — المخزن يحدّث قائمة الطلبات واللوحة تلقائيًا بعد الإنشاء
      await widget.store.createRequest(
        title: title,
        category: _category,
        priority: _priority,
        description: _descriptionController.text,
        serviceId: _serviceId,
      );
      if (!mounted) {
        return;
      }
      // نص النجاح في الويب (العنوان + الوصف) بسطرين للـ toast
      showAppToast(
        context,
        _priority == 'URGENT'
            ? 'تم إرسال طلبك العاجل 🔔\nيظهر الآن في «طلباتي» مع حالته لحظة بلحظة'
            : 'تم إرسال طلبك\nيظهر الآن في «طلباتي» مع حالته لحظة بلحظة',
      );
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      // رسالة الخادم الحرفية كما تنص قواعد المهمة
      showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      icon: Icons.room_service_rounded,
      // عنوان الحوار في الويب: تسمية القسم (أو «طلب خدمة» كاحتياط)
      title: label(requestCategoryLabels, _category, fallback: 'طلب خدمة'),
      description: 'يصل طلبك للاستقبال فورًا وسيتولى التعامل معه',
      footer: _footer(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetLabel('عنوان الطلب'),
          TextField(
            controller: _titleController,
            enabled: !_sending,
            maxLength: 80,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثال: تنظيف الغرفة',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          const SheetLabel('تفاصيل إضافية (اختياري)'),
          TextField(
            controller: _descriptionController,
            enabled: !_sending,
            maxLines: 3,
            minLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'أضف أي تفاصيل تساعد الفريق...',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          const SheetLabel('الأولوية'),
          Row(
            children: [
              Expanded(
                child: _priorityOption(
                  'NORMAL',
                  label(priorityLabels, 'NORMAL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _priorityOption(
                  'URGENT',
                  label(priorityLabels, 'URGENT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// زر أولوية (عادي/عاجل) بألوان الويب: primary للعادي
  /// وdestructive للعاجل مع أيقونة Zap
  Widget _priorityOption(String value, String text) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _priority == value;
    final urgent = value == 'URGENT';
    final activeColor = urgent ? AppColors.danger : scheme.primary;
    return InkWell(
      onTap: _sending ? null : () => setState(() => _priority = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : scheme.outline,
          ),
          color: selected ? activeColor.withAlpha(26) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (urgent) ...[
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: selected ? activeColor : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? activeColor : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// صف أزرار الحوار: إلغاء + إرسال الطلب (busy أثناء الإرسال)
  Widget _footer() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending ? sheetBusyIndicator : mirroredSendIcon(),
            label: const Text('إرسال الطلب'),
          ),
        ),
      ],
    );
  }
}

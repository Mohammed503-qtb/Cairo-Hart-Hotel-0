// ─────────────────────────────────────────────────────────────
// FEEDBACK SHEET — تقييم الإقامة (نقل feedback-dialog.tsx — G-16)
// نجوم 1-5 قابلة للنقر + وسوم سريعة + تعليق (upsert لكل إقامة)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'sheet_frame.dart';

/// الوسوم السريعة (منقولة حرفيًا من الويب)
const List<String> _quickTags = [
  'نظافة',
  'طاقم ممتاز',
  'راحة',
  'إفطار',
  'يحتاج تحسينًا',
];

/// تسميات النجوم (نفس ترتيب الويب)
const List<String> _ratingLabels = [
  '',
  'ضعيف',
  'مقبول',
  'جيد',
  'جيد جدًا',
  'ممتاز!',
];

/// صفيحة التقييم — تُفتح عبر showFeedbackSheet في actions.dart
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key, required this.store});

  final GuestStore store;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int _rating = 0;
  int _hover = 0; // معاينة التحويم (نفس hover في الويب على سطح المكتب)
  List<String> _tags = const [];
  late final TextEditingController _commentController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// النجوم المعروضة: التحويم يسبق الاختيار (نفس shown = hover || rating)
  int get _shown => _hover != 0 ? _hover : _rating;

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags = _tags.where((t) => t != tag).toList();
      } else {
        _tags = [..._tags, tag];
      }
    });
  }

  Future<void> _submit() async {
    // تحقق محلي مطابق للويب (رغم أن الزر معطّل قبل اختيار نجمة)
    if (_rating < 1) {
      showAppToast(context, 'اختر عدد النجوم أولًا', error: true);
      return;
    }
    if (_sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.store.submitFeedback(
        rating: _rating,
        tags: _tags,
        comment: _commentController.text,
      );
      if (!mounted) {
        return;
      }
      showAppToast(
        context,
        'شكرًا لك على تقييمك 💛\nرأيك يهمنا ويطوّر خدمتنا',
      );
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// نص إمكانية الوصول للنجمة (نفس aria-label في الويب)
  String _starLabel(int n) =>
      '$n ${n == 1 ? 'نجمة' : n == 2 ? 'نجمتان' : 'نجوم'}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SheetFrame(
      icon: Icons.star_rounded,
      title: 'قيّم إقامتك',
      description: 'رأيك يساعدنا على تحسين تجربة الضيافة',
      footer: _footer(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // النجوم (نجوم كاملة بالنقر كما في الويب)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final n in const [1, 2, 3, 4, 5])
                MouseRegion(
                  onEnter: (_) => setState(() => _hover = n),
                  onExit: (_) => setState(() => _hover = 0),
                  child: Tooltip(
                    message: _starLabel(n),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _rating = n),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.star_rounded,
                            size: 34,
                            color: n <= _shown
                                ? AppColors.gold
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                _ratingLabels[_rating],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const SheetLabel('وسوم سريعة'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _quickTags)
                _TagChip(
                  label: tag,
                  active: _tags.contains(tag),
                  onToggle: () => _toggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const SheetLabel('تعليقك (اختياري)'),
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 3,
            maxLength: 500,
            enabled: !_sending,
            decoration: const InputDecoration(
              hintText: 'شاركنا تجربتك بصفتك الخاصة...',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  /// صف الأزرار: إلغاء + إرسال التقييم (ذهبي كما في الويب)
  Widget _footer() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed:
                _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: FilledButton(
            onPressed: (_sending || _rating < 1) ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF2A2110),
              disabledBackgroundColor: AppColors.goldContainer,
              disabledForegroundColor: const Color(0xFF2A2110),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sending) ...[
                  sheetBusyIndicator,
                  const SizedBox(width: 8),
                ],
                const Text('إرسال التقييم'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// شريحة وسم سريع: ذهبية عند التفعيل (و«يحتاج تحسينًا» تحذيرية)
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.active,
    required this.onToggle,
  });

  final String label;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final negative = label == 'يحتاج تحسينًا';
    final (border, background, foreground) = switch ((active, negative)) {
      (true, true) => (
          AppColors.warning,
          AppColors.warningContainer,
          AppColors.warning,
        ),
      (true, false) => (
          AppColors.gold,
          AppColors.goldContainer,
          AppColors.goldDark,
        ),
      (false, _) => (
          scheme.outline,
          scheme.surface,
          scheme.onSurfaceVariant,
        ),
    };
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET FRAME — إطار موحد لصفائح أفعال الضيف السفلية
// (مقابل DialogContent في الويب): رأس بأيقونة ذهبية + عنوان + وصف،
// محتوى قابل للتمرير، وتذييل ثابت للأزرار
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../ui/theme.dart';

/// إطار صفيحة فعل: رأس + محتوى (تمرير داخلي) + تذييل أزرار مثبّت
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الرأس: أيقونة ذهبية + العنوان (نفس ترتيب الويب)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
        // الوصف (سطر أو سطران كما في الويب)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        const Divider(indent: 20, endIndent: 20, height: 20),
        // المحتوى: تمرير داخلي عند الطول الزائد (مثل max-h في الويب)
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: child,
          ),
        ),
        // التذييل الثابت: أزرار الإلغاء والإرسال
        if (footer != null)
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: footer,
          ),
      ],
    );
  }
}

/// تسمية حقل (مقابل Label في الويب)
class SheetLabel extends StatelessWidget {
  const SheetLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// مؤشر انشغال صغير لأزرار الحوارات (مقابل Loader2 في الويب)
const Widget sheetBusyIndicator = SizedBox(
  width: 18,
  height: 18,
  child: CircularProgressIndicator(strokeWidth: 2.2),
);

/// أيقونة الإرسال معكوسة أفقيًا كما في الويب (-scale-x-100 داخل RTL)
Widget mirroredSendIcon({double size = 18}) => Transform.flip(
      flipX: true,
      child: Icon(Icons.send_rounded, size: size),
    );

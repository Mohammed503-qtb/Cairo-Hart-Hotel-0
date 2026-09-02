// ─────────────────────────────────────────────────────────────
// TAB ROUTE — فتح شاشة تبويب كاملة عبر Navigator
// بديل تحويل setTab في الويب (الويب يبدّل التبويب داخل صفحة واحدة،
// وجذر التبويبات في Flutter يملكه GuestShell — فالتنقل عبر دفع شاشة)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

/// دفع شاشة تبويب بعنوان في AppBar (يستخدمها الرئيسية/الإقامة للانتقال)
Future<void> pushTabScreen(BuildContext context, String title, Widget child) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      ),
    ),
  );
}

/// نفس الدفع لكن باستبدال الشاشة الحالية (زر «تصفح الخدمات» من قائمة الطلبات)
Future<void> pushTabScreenReplacement(
  BuildContext context,
  String title,
  Widget child,
) {
  return Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      ),
    ),
  );
}

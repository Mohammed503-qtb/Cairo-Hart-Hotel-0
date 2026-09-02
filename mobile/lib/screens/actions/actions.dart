// ─────────────────────────────────────────────────────────────
// ACTIONS — نقاط دخول حوارات أفعال الضيف (نقل dialogات الويب)
//   showExtensionSheet  ← extension-dialog.tsx  (G-10)
//   showRoomChangeSheet ← room-change-dialog.tsx (G-11/12)
//   showCheckoutSheet   ← checkout-dialog.tsx    (G-13)
//   showFeedbackSheet   ← feedback-dialog.tsx    (G-16)
// التواقيع ثابتة (يستخدمها guest_shell وملكات الوكيل الآخر)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../state/guest_store.dart';
import 'checkout_sheet.dart';
import 'extension_sheet.dart';
import 'feedback_sheet.dart';
import 'room_change_sheet.dart';

/// فتح صفيحة سفلية موحدة: تمرير مضبوط + مساحة آمنة + لوحة مفاتيح
Future<void> _openSheet(BuildContext context, Widget sheet) async {
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
      child: sheet,
    ),
  );
}

/// طلب تمديد الإقامة (G-10) — نقل extension-dialog.tsx
Future<void> showExtensionSheet(BuildContext context, GuestStore store) async {
  await _openSheet(context, ExtensionSheet(store: store));
}

/// طلب تغيير الغرفة (G-11/12) — نقل room-change-dialog.tsx
Future<void> showRoomChangeSheet(
  BuildContext context,
  GuestStore store,
) async {
  await _openSheet(context, RoomChangeSheet(store: store));
}

/// طلب تسجيل الخروج (G-13) — نقل checkout-dialog.tsx
Future<void> showCheckoutSheet(BuildContext context, GuestStore store) async {
  await _openSheet(context, CheckoutSheet(store: store));
}

/// تقييم الإقامة (G-16) — نقل feedback-dialog.tsx
Future<void> showFeedbackSheet(BuildContext context, GuestStore store) async {
  await _openSheet(context, FeedbackSheet(store: store));
}

// ─────────────────────────────────────────────────────────────
// RECEPTION NOTIFICATIONS SCREEN — إشعارات الاستقبال (R-22/R-23)
// نقل notifications-sheet.tsx (ورقة جانبية في الويب) كشاشة كاملة:
// عند الفتح: جلب + تعليم المعروض غير المقروء تلقائيًا + زر تعليم الكل
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../models/reception.dart';
import '../../state/reception_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'reception_bits.dart';

class ReceptionNotificationsScreen extends StatefulWidget {
  const ReceptionNotificationsScreen({super.key, required this.store});

  final ReceptionStore store;

  @override
  State<ReceptionNotificationsScreen> createState() =>
      _ReceptionNotificationsScreenState();
}

class _ReceptionNotificationsScreenState
    extends State<ReceptionNotificationsScreen> {
  bool _firstLoad = true;

  ReceptionStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// الجلب + تعليم المعروض كمقروء (نفس سلوك الورقة عند الفتح)
  Future<void> _load() async {
    try {
      await store.refreshNotifications();
      await store.markVisibleNotificationsRead();
    } on ApiError {
      // الويب يسكت عند فشل الجلب ويضبط قائمة فارغة — نفس الصمت هنا
    }
    if (mounted) setState(() => _firstLoad = false);
  }

  /// «تحديد الكل كمقروء» — عبر تعليم كل المعروض غير المقروء
  /// (القائمة تجلب آخر 30 — نفس مجموعة العناصر التي تحدّثها الويب تفاؤليًا)
  Future<void> _markAllRead() async {
    try {
      await store.markVisibleNotificationsRead();
    } on ApiError catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder حول السكافولد كله: شارة غير المقروء في الشريط تتبع المخزن
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final unread = store.unreadCount;
        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              Icon(Icons.notifications_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 6),
              const Text('الإشعارات'),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unread جديد',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ]),
          ),
          body: Column(children: [
            // زر «تحديد الكل كمقروء» ثابت فوق القائمة (رأس الورقة في الويب)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: OutlinedButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('تحديد الكل كمقروء'),
              ),
            ),
            Expanded(child: _buildList()),
          ]),
        );
      },
    );
  }

  Widget _buildList() {
    final notifs = store.notifications;
    final showSkeleton =
        (_firstLoad || store.notificationsLoading) && notifs.isEmpty;
    if (showSkeleton) {
      return _scrollable(children: [loadingBlocks(4, height: 64)]);
    }
    if (notifs.isEmpty) {
      return _scrollable(children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Text(
              'لا إشعارات بعد 🔕',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: notifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _NotificationCard(n: notifs[i]),
      ),
    );
  }

  /// لف الحالات غير القابلة للتمرير بListView كي يعمل السحب للتحديث
  Widget _scrollable({required List<Widget> children}) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: children,
      ),
    );
  }
}

/// بطاقة إشعار واحدة (article في الويب): أيقونة النوع + العنوان + الجسم + الزمن
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n});

  final ReceptionNotification n;

  IconData get _typeIcon => switch (n.type) {
        'REQUEST' => Icons.room_service_rounded,
        'EXTENSION' => Icons.event_rounded,
        'CHAT' => Icons.chat_bubble_outline_rounded,
        'PAYMENT' => Icons.payments_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.read ? scheme.card : scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: n.read
              ? scheme.outlineVariant
              : scheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: n.read
                ? scheme.surfaceContainerHighest
                : scheme.primary.withValues(alpha: 0.10),
          ),
          child: Icon(
            _typeIcon,
            size: 16,
            color: n.read ? scheme.onSurfaceVariant : scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              n.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            if (n.body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                n.body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              fmt.timeAgoAr(n.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.70),
              ),
            ),
          ]),
        ),
        if (!n.read)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ]),
    );
  }
}

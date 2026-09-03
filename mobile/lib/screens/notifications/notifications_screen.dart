// ─────────────────────────────────────────────────────────────
// NOTIFICATIONS — شاشة الإشعارات (نقل notifications-sheet.tsx)
// قائمة إشعارات + تمييز غير المقروء + زر «تعليم الكل كمقروء»
// ملاحظة: الويب لا يعلم الكل تلقائيًا عند الفتح — فقط عبر الزر (مطابق)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// شاشة كاملة للإشعارات — نقطة الدخول الثابتة (يستخدمها GuestShell)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.store});

  final GuestStore store;

  @override
  Widget build(BuildContext context) {
    return _NotificationsView(store: store);
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView({required this.store});

  final GuestStore store;

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    // عند الفتح: تحديث القائمة (الويب يعتمد التحميل الأولي + Realtime)
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.store.refreshNotifications();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  /// G-15: تعليم كل الإشعارات كمقروءة (زر الويب نفسه)
  Future<void> _markAllRead() async {
    if (_marking) {
      return;
    }
    setState(() => _marking = true);
    try {
      await widget.store.markAllNotificationsRead();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, e.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final unread = store.unreadCount;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    size: 17,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'الإشعارات',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          // شارة غير المقروء (bg-destructive كما في الويب)
                          if (unread > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'تحديثات إقامتك وطلباتك لحظة بلحظة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: _buildBody(store),
          bottomNavigationBar: _buildBottomBar(scheme, unread),
        );
      },
    );
  }

  Widget _buildBody(GuestStore store) {
    if (store.notificationsLoading && store.notifications.isEmpty) {
      return const LoadingView();
    }
    if (store.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.info_outline,
        title: 'لا إشعارات بعد',
        subtitle: 'ستصلك هنا تحديثات الطلبات والرسائل وكل ما يخص إقامتك',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: store.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _NotificationCard(notification: store.notifications[index]),
    );
  }

  /// زر التذييل الثابت: تعليم الكل كمقروء (معطّل عند الصفر — نص الويب)
  Widget _buildBottomBar(ColorScheme scheme, int unread) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (unread == 0 || _marking) ? null : _markAllRead,
            icon: _marking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.done_all_rounded, size: 18),
            label: Text(unread == 0 ? 'كل الإشعارات مقروءة' : 'تعليم الكل كمقروء'),
          ),
        ),
      ),
    );
  }
}

/// بطاقة إشعار واحد: عنوان + نقطة ذهبية للغير مقروء + وقت نسبي
/// + نص + تاريخ كامل — نفس بنية الويب وألوانه
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !notification.read;
    return AppCard(
      padding: const EdgeInsets.all(14),
      // غير المقروء: خلفية ذهبية فاتحة + حدود ذهبية (كما في الويب)
      color: unread ? AppColors.goldContainer : null,
      border: unread ? const BorderSide(color: AppColors.gold) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (unread) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeAgoAr(notification.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (notification.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            formatDateTimeAr(notification.createdAt),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME — تبويب الرئيسية (نقل guest-home.tsx)
// بطاقة الترحيب + اللافتات + الإجراءات السريعة + ملخص الإقامة
// + آخر الإشعارات + بطاقة الطلبات النشطة
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../state/session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../actions/actions.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../requests/requests_screen.dart';
import '../services/services_screen.dart';
import '../shared/panels.dart';
import '../shared/tab_route.dart';
import '../stay/stay_screen.dart';

/// تبويب الرئيسية — نقطة الدخول الثابتة (يستخدمها GuestShell)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.session});

  final GuestStore store;
  final SessionController session;

  Future<void> _refreshDashboard(BuildContext context) async {
    try {
      await store.refreshDashboard();
    } on ApiError catch (e) {
      if (context.mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // اسم الضيف كما في الويب (guestName = session?.name ?? 'ضيف')
    final name = session.session?.name;
    final guestName = (name == null || name.isEmpty) ? 'ضيف' : name;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.bootstrapLoading && store.dashboard == null) {
          return const LoadingView();
        }
        final dash = store.dashboard;
        if (dash == null) {
          // EmptyState في الويب: العنوان + التلميح بنصيهما
          return ErrorRetryView(
            message: 'تعذر تحميل بيانات الإقامة\nحدث خطأ في الاتصال — أعد المحاولة',
            onRetry: () => store.bootstrap(),
          );
        }
        final stay = dash.stay;
        final requestedCheckout = stay.status == 'CHECKOUT_REQUESTED';

        return RefreshIndicator(
          onRefresh: () => _refreshDashboard(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _WelcomeCard(dash: dash, guestName: guestName),
              // ─── اللافتات (نفس شرطي الويب) ───
              if (requestedCheckout) ...[
                const SizedBox(height: 20),
                const GoldBanner(
                  title: 'تم إرسال طلب تسجيل الخروج',
                  body: 'الاستقبال سيجهّز مغادرتك ويتواصل معك قريبًا — يرجى تسوية الرصيد إن وُجد.',
                ),
              ],
              if (dash.balanceCents > 0) ...[
                const SizedBox(height: 20),
                const BalanceBanner(),
              ],
              const SizedBox(height: 20),
              _QuickActionsSection(
                store: store,
                requestedCheckout: requestedCheckout,
              ),
              const SizedBox(height: 20),
              _StaySummarySection(store: store, dash: dash),
              const SizedBox(height: 20),
              _NotificationsSection(store: store, dash: dash),
              if (dash.activeRequests > 0) ...[
                const SizedBox(height: 20),
                _ActiveRequestsCard(store: store, count: dash.activeRequests),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// بطاقة الترحيب الكحلية (نقل motion.section بزخارف الدوائر)
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.dash, required this.guestName});

  final GuestDashboard dash;
  final String guestName;

  @override
  Widget build(BuildContext context) {
    final stay = dash.stay;
    final remaining = stay.remainingNights ?? 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              // from-primary via-primary to-primary/85 نحو أسفل-يسار
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.navy,
                    AppColors.navy,
                    Color(0xD91A3C6E),
                  ],
                ),
              ),
            ),
          ),
          // زخارف دوائر شفافة (كما في الويب)
          Positioned(
            left: -40,
            top: -40,
            child: _decoCircle(160, const Color(0x1AFFFFFF)),
          ),
          Positioned(
            left: -16,
            top: 64,
            child: _decoCircle(96, const Color(0x33D4A843)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا $guestName 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'رقم غرفتك',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xBFFFFFFF),
                            ),
                          ),
                          // رقم لاتيني — LTR كما في الويب (dir="ltr")
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              stay.room.number,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stay.roomType.name} — الطابق ${stay.room.floor}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xE6FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.nightlight_round,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                remaining > 0
                                    ? '$remaining ${remaining == 1 ? 'ليلة متبقية' : 'ليالٍ متبقية'}'
                                    : 'آخر يوم اليوم',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stay.roomType.bedConfig,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xBFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: const Color(0x33FFFFFF)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إقامتك حتى',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                          Text(
                            formatDateWithDayAr(stay.expectedCheckOutAt),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // شارة الحالة الذهبية (bg-gold كما في الويب)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label(stayStatusLabels, stay.status),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A2110),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decoCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// إجراء سريع واحد (نقل QUICK_ACTIONS)
class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.store,
    required this.requestedCheckout,
  });

  final GuestStore store;
  final bool requestedCheckout;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      // طلب خدمة → تبويب الخدمات بالكتالوج (setTab+setServicesView في الويب)
      _QuickAction(
        icon: Icons.room_service_rounded,
        label: 'طلب خدمة',
        onTap: () =>
            pushTabScreen(context, 'الخدمات', ServicesScreen(store: store)),
      ),
      _QuickAction(
        icon: Icons.chat_bubble_outline,
        label: 'محادثة الاستقبال',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(store: store),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.update_rounded,
        label: 'تمديد الإقامة',
        onTap: () => showExtensionSheet(context, store),
      ),
      _QuickAction(
        icon: Icons.bed_rounded,
        label: 'تغيير الغرفة',
        onTap: () => showRoomChangeSheet(context, store),
      ),
      _QuickAction(
        icon: Icons.north_east_rounded,
        label: 'طلب الخروج',
        enabled: !requestedCheckout,
        onTap: () => showCheckoutSheet(context, store),
      ),
      _QuickAction(
        icon: Icons.star_rounded,
        label: 'ملاحظات',
        onTap: () => showFeedbackSheet(context, store),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('إجراءات سريعة'),
        LayoutBuilder(
          builder: (context, constraints) {
            // عمودان على الهاتف وثلاثة على الشاشات الأوسع (كالويب)
            final cols = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                for (final a in actions) _QuickActionTile(action: a),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// بلاطة إجراء سريع (أيقونة داخل دائرة + تسمية)
/// «طلب الخروج» معطلة بعد إرسال الطلب (disabled في الويب)
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: action.enabled ? 1 : 0.5,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: action.enabled ? action.onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 18, color: scheme.primary),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// خلية ملخص (نقل SummaryCell: تسمية بأيقونة + قيمة)
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StaySummarySection extends StatelessWidget {
  const _StaySummarySection({required this.store, required this.dash});

  final GuestStore store;
  final GuestDashboard dash;

  @override
  Widget build(BuildContext context) {
    final stay = dash.stay;
    final reservation = stay.reservation;
    final total = stay.totalNights ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'ملخص إقامتك',
          action: TextButton(
            // setTab('stay') في الويب → دفع شاشة الإقامة هنا
            onPressed: () =>
                pushTabScreen(context, 'إقامتي', StayScreen(store: store)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'عرض التفاصيل',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCell(
                      icon: Icons.group_rounded,
                      label: 'الضيوف',
                      child: Text(
                        '${reservation.adults} بالغ'
                        '${reservation.children > 0 ? ' + ${reservation.children} طفل' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCell(
                      icon: Icons.nightlight_round,
                      label: 'مدة الإقامة',
                      child: Text(
                        '$total ${total == 1 ? 'ليلة' : 'ليالٍ'}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCell(
                      icon: Icons.bed_rounded,
                      label: 'مرجع الحجز',
                      // المرجع لاتيني — LTR كما في الويب (dir="ltr")
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          reservation.bookingReference,
                          style: const TextStyle(
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCell(
                      icon: Icons.hotel_rounded,
                      label: 'الرصيد المستحق',
                      // أحمر عند وجود رصيد وأخضر عند التسوية (كما في الويب)
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          formatMoney(dash.balanceCents,
                              currency: dash.currency),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: dash.balanceCents > 0
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// قسم آخر الإشعارات (أول 3 إشعارات + زر كل الإشعارات)
class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({required this.store, required this.dash});

  final GuestStore store;
  final GuestDashboard dash;

  @override
  Widget build(BuildContext context) {
    final notifications = dash.notifications;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'آخر الإشعارات',
          action: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsScreen(store: store),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'كل الإشعارات',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (notifications.isEmpty)
          const DashedNote('لا إشعارات بعد — سنعلمك بكل جديد')
        else
          Column(
            children: [
              for (var i = 0; i < notifications.length && i < 3; i++) ...[
                _NotificationCard(
                  notification: notifications[i],
                  store: store,
                ),
                if (i < 2) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

/// بطاقة إشعار واحد (نقطة ذهبية/رمادية + عنوان + وقت + نص)
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.store});

  final NotificationItem notification;
  final GuestStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !notification.read;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // الضغط يفتح شاشة الإشعارات (مثل الويب تمامًا)
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(store: store),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: unread ? AppColors.gold : scheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الطلبات النشطة (تظهر فقط عند وجود طلبات نشطة — كما في الويب)
class _ActiveRequestsCard extends StatelessWidget {
  const _ActiveRequestsCard({required this.store, required this.count});

  final GuestStore store;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: scheme.surfaceContainerHighest,
      border: BorderSide(
        color: scheme.brightness == Brightness.light
            ? const Color(0x401A3C6E) // primary/25
            : const Color(0x40A8C2E8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.room_service_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'لديك $count ${count == 1 ? 'طلب نشط' : 'طلبات نشطة'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // goRequests في الويب → شاشة الطلبات هنا
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RequestsScreen(store: store),
                ),
              ),
              child: const Text('متابعة طلباتي'),
            ),
          ),
        ],
      ),
    );
  }
}

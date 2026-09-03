// ─────────────────────────────────────────────────────────────
// RECEPTION SHELL — هيكل وضع الاستقبال (نقل reception-app.tsx)
// هيدر (شعار + لوحة الاستقبال + اسم الموظف + جرس + خروج)
// + 6 تبويبات (لوحة/وصولون/مقيمون/طلبات/مغادرون/غرف — F4-b):
// شريط جانبي NavigationRail للعرض الواسع (لوحي — كالديسكتوب في الويب)
// وتنقل سفلي بـ 4 أساسية في الضيق (نفس سلوك الويب موبايل)
// + زر بحث عام (R-19) + Realtime
// (غرفة reception) بنفس معالجات الويب حرفيًا
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/socket_service.dart';
import '../../state/reception_store.dart';
import '../../state/session.dart';
import '../../ui/widgets.dart';
import 'arrivals_screen.dart';
import 'dashboard_screen.dart';
import 'departures_screen.dart';
import 'inhouse_screen.dart';
import 'reception_notifications_screen.dart';
import 'requests_screen.dart';
import 'rooms_screen.dart';
import 'search_screen.dart';

class ReceptionShell extends StatefulWidget {
  const ReceptionShell({
    super.key,
    required this.session,
    required this.store,
    required this.realtime,
  });

  final SessionController session;
  final ReceptionStore store;
  final RealtimeService realtime;

  @override
  State<ReceptionShell> createState() => _ReceptionShellState();
}

class _ReceptionShellState extends State<ReceptionShell> {
  int _tabIndex = 0;
  StreamSubscription<RealtimeEvent>? _rtSub;

  /// (أيقونة، تسمية، أساسي؟) — نفس NAV في reception-app.tsx:
  /// الأوائل الأربعة أساسية (تظهر في التنقل السفلي للضيق)
  static const _tabs = [
    (Icons.dashboard_rounded, 'لوحة التحكم', true),
    (Icons.flight_land_rounded, 'الوصولون', true),
    (Icons.groups_rounded, 'المقيمون', true),
    (Icons.room_service_rounded, 'الطلبات', true),
    (Icons.flight_takeoff_rounded, 'المغادرون', false),
    (Icons.grid_view_rounded, 'حالة الغرف', false),
  ];

  @override
  void initState() {
    super.initState();
    // F4: الانضمام لغرفة الاستقبال — كما في useSocket('reception') بالويب
    widget.realtime.joinReceptionRoom();
    _rtSub = widget.realtime.events.listen(_onRealtimeEvent);
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }

  /// توجيه أحداث Realtime (نفس معالجات الويب في reception-app.tsx)
  Future<void> _onRealtimeEvent(RealtimeEvent ev) async {
    if (!mounted) return;
    final staffName = widget.session.session?.name;
    switch (ev.name) {
      case 'request:new':
        final title = ev.textValue('title') ?? 'خدمة';
        final room = ev.textValue('roomNumber');
        showAppToast(
          context,
          room == null ? '🔔 طلب جديد: $title' : '🔔 طلب جديد: $title — غرفة $room',
        );
        await widget.store.onRealtimeBump();
        await widget.store.onRealtimeNotification();
      case 'reservation:new':
        final ref =
            ev.textValue('bookingReference') ?? ev.textValue('reference') ?? '';
        final guest = ev.textValue('guestName');
        showAppToast(
          context,
          '🆕 حجز جديد من الموقع${ref.isNotEmpty ? ' — $ref' : ''}'
          '${guest != null && guest.isNotEmpty ? ' — $guest' : ''}',
        );
        await widget.store.onRealtimeBump();
        await widget.store.onRealtimeNotification();
      case 'chat:message':
        final sender = ev.textValue('senderName');
        if (sender != null && sender.isNotEmpty && sender != staffName) {
          showAppToast(context, '💬 رسالة جديدة — $sender');
        }
        await widget.store.onRealtimeBump();
      case 'stay:updated':
      case 'room:status':
      case 'request:updated':
        await widget.store.onRealtimeBump();
      case 'notification:new':
        await widget.store.onRealtimeNotification();
    }
  }

  Future<void> _logout() async {
    await widget.session.logout();
  }

  /// بحث عام (R-19) — زر العدسة في الهيدر كما الويب
  Future<void> _openSearch() async {
    await showReceptionSearch(context, store: widget.store);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReceptionNotificationsScreen(store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = widget.store;
    final staffName = widget.session.session?.name ?? 'الاستقبال';
    final unread = store.unreadCount;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  semanticLabel: 'شعار فندق قلب القاهرة',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'لوحة الاستقبال',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        'فندق قلب القاهرة — عدن · $staffName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            actions: [
              IconButton(
                tooltip: 'بحث عام',
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: unread > 0
                    ? 'الإشعارات — $unread غير مقروء'
                    : 'الإشعارات',
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: _logout,
                icon: Icon(
                  Icons.logout_rounded,
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              final screens = [
                DashboardScreen(store: store, onGoTab: _goTab),
                ArrivalsScreen(store: store),
                InHouseScreen(store: store),
                RequestsScreen(store: store),
                DeparturesScreen(store: store),
                RoomsScreen(store: store),
              ];
              if (wide) {
                // شريط جانبي بكل التبويبات الستة (لوحي/ديسكتوب — كالويب lg)
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _tabIndex,
                      onDestinationSelected: _goTab,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final (icon, label, _) in _tabs)
                          NavigationRailDestination(
                            icon: Icon(icon),
                            selectedIcon: Icon(icon, size: 28),
                            label: Text(label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _tabIndex,
                        children: screens,
                      ),
                    ),
                  ],
                );
              }
              // الضيق: المكدس كاملًا — التنقل السفلي بالتبويبات الستة
              return IndexedStack(
                index: _tabIndex,
                children: screens,
              );
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 700) {
                return const SizedBox.shrink();
              }
              // الضيق: كل التبويبات الستة (ثابتة) — تبويب ثانوي نشط خارج
              // الأربعة الأساسية كان سيكسر حدود BottomNavigationBar، والطابق
              // الستة يضمن الوصول دائمًا (اللوحي يستخدم الشريط الجانبي أعلاه)
              return BottomNavigationBar(
                currentIndex: _tabIndex,
                onTap: _goTab,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                items: [
                  for (final (icon, label, _) in _tabs)
                    BottomNavigationBarItem(
                      icon: Icon(icon),
                      activeIcon: Icon(icon, size: 28),
                      label: label,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _goTab(int index) {
    setState(() => _tabIndex = index);
  }
}

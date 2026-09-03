// ─────────────────────────────────────────────────────────────
// RECEPTION SHELL — هيكل وضع الاستقبال (نقل reception-app.tsx)
// هيدر (شعار + لوحة الاستقبال + اسم الموظف + جرس + خروج)
// + تبويبات (لوحة/وصولون/مغادرون — تُوسَّع في F4-b) + Realtime
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
import 'reception_notifications_screen.dart';

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

  static const _tabs = [
    (Icons.dashboard_rounded, 'لوحة التحكم'),
    (Icons.flight_land_rounded, 'الوصولون'),
    (Icons.flight_takeoff_rounded, 'المغادرون'),
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
          body: IndexedStack(
            index: _tabIndex,
            children: [
              DashboardScreen(store: store, onGoTab: _goTab),
              ArrivalsScreen(store: store),
              DeparturesScreen(store: store),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: _goTab,
            items: [
              for (final (icon, label) in _tabs)
                BottomNavigationBarItem(
                  icon: Icon(icon),
                  activeIcon: Icon(icon, size: 28),
                  label: label,
                ),
            ],
          ),
        );
      },
    );
  }

  void _goTab(int index) {
    setState(() => _tabIndex = index);
  }
}

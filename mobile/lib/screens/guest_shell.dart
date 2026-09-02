// ─────────────────────────────────────────────────────────────
// GUEST SHELL — هيكل وضع الضيف (نقل guest-app.tsx)
// هيدر (شعار + اسم الفندق + اسم الضيف + جرس + خروج)
// 4 تبويبات + زر محادثة عائم + توصيل Realtime (F2)
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../state/guest_store.dart';
import '../state/session.dart';
import '../ui/widgets.dart';
import 'bill/bill_screen.dart';
import 'chat/chat_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'stay/stay_screen.dart';

class GuestShell extends StatefulWidget {
  const GuestShell({
    super.key,
    required this.session,
    required this.store,
    required this.realtime,
  });

  final SessionController session;
  final GuestStore store;
  final RealtimeService realtime;

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _tabIndex = 0;
  StreamSubscription<RealtimeEvent>? _rtSub;
  bool _roomJoined = false;

  static const _tabs = [
    (Icons.home_rounded, 'الرئيسية'),
    (Icons.bed_rounded, 'إقامتي'),
    (Icons.room_service_rounded, 'الخدمات'),
    (Icons.receipt_long_rounded, 'الفاتورة'),
  ];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _rtSub = widget.realtime.events.listen(_onRealtimeEvent);
    _maybeJoinRoom();
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => _maybeJoinRoom();

  /// الانضمام لغرفة الإقامة فور توفر stayId (F2)
  void _maybeJoinRoom() {
    if (_roomJoined) return;
    final sid = widget.store.stayId;
    if (sid != null && sid.isNotEmpty) {
      _roomJoined = true;
      widget.realtime.joinStayRoom(sid);
    }
  }

  /// توجيه أحداث Realtime (نفس معالجات الويب في guest-app.tsx)
  Future<void> _onRealtimeEvent(RealtimeEvent ev) async {
    if (!mounted) return;
    switch (ev.name) {
      case 'notification:new':
        showAppToast(context, ev.notificationTitle);
        await widget.store.onRealtimeNotification();
      case 'request:updated':
        await widget.store.onRealtimeRequestUpdated();
      case 'stay:updated':
        await widget.store.onRealtimeStayUpdated();
      case 'chat:message':
        await widget.store.onRealtimeChatMessage();
    }
  }

  Future<void> _logout() async {
    await widget.session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = widget.store;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hotelName = store.dashboard?.hotel.name ?? 'الفندق';
        final guestName = widget.session.session?.name ?? '';
        final unread = store.unreadCount;

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
                  semanticLabel: 'شعار $hotelName',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hotelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        '$guestName — تطبيق الضيف',
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
              // جرس الإشعارات (بadge غير المقروء)
              IconButton(
                tooltip: unread > 0 ? 'الإشعارات — $unread غير مقروء' : 'الإشعارات',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          NotificationsScreen(store: widget.store),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              // تسجيل الخروج
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(store: widget.store),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('المحادثة'),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
            items: [
              for (final (icon, label) in _tabs)
                BottomNavigationBarItem(
                  icon: Icon(icon),
                  activeIcon: Icon(icon, size: 28),
                  label: label,
                ),
            ],
          ),
          body: IndexedStack(
            index: _tabIndex,
            children: [
              HomeScreen(store: store, session: widget.session),
              StayScreen(store: store),
              ServicesScreen(store: store),
              BillScreen(store: store),
            ],
          ),
        );
      },
    );
  }
}

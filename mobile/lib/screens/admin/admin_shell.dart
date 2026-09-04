// ─────────────────────────────────────────────────────────────
// ADMIN SHELL — هيكل وضع الإدارة (نقل admin-app.tsx حرفيًا)
// هيدر (شعار + لوحة الإدارة + اسم الموظف + جرس + خروج)
// + 11 قسمًا: شريط جانبي قابل للطي للعرض الواسع (كالويب)
/// وتنقل سفلي بـ 4 أساسية + «المزيد» (نفس MOBILE_PRIMARY في الويب)
// + Realtime (غرفة admin) بنفس معالجات الويب
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/socket_service.dart';
import '../../state/admin_store.dart';
import '../../state/session.dart';
import '../../ui/widgets.dart';
import 'admin_bits.dart';
import 'audit_log_screen.dart';
import 'dashboard_screen.dart';
import 'guests_screen.dart';
import 'hotel_settings_screen.dart';
import 'rates_screen.dart';
import 'reports_screen.dart';
import 'reservations_screen.dart';
import 'room_types_screen.dart';
import 'rooms_screen.dart';
import 'services_screen.dart';
import 'staff_codes_screen.dart';

/// (المفتاح، التسمية، الأيقونة، أساسي؟) — نفس SECTIONS/MOBILE_PRIMARY
/// في admin-app.tsx: الأربعة الأولى أساسية (التنقل السفلي للضيق)
const List<(String, String, IconData, bool)> kAdminNav = [
  ('dashboard', 'لوحة التحكم', Icons.dashboard_rounded, true),
  ('hotel', 'إعدادات الفندق', Icons.settings_rounded, false),
  ('room-types', 'أنواع الغرف', Icons.bed_rounded, false),
  ('rooms', 'الغرف', Icons.door_front_door_rounded, true),
  ('rates', 'الأسعار', Icons.calendar_month_rounded, false),
  ('services', 'الخدمات', Icons.room_service_rounded, false),
  ('staff', 'الطاقم والأكواد', Icons.key_rounded, true),
  ('reservations', 'الحجوزات', Icons.content_paste_rounded, true),
  ('guests', 'الضيوف', Icons.people_rounded, false),
  ('reports', 'التقارير', Icons.bar_chart_rounded, false),
  ('audit', 'سجل التدقيق', Icons.receipt_long_rounded, false),
];

const List<String> kAdminPrimaryKeys = [
  'dashboard',
  'rooms',
  'reservations',
  'staff',
];

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.session,
    required this.store,
    required this.realtime,
  });

  final SessionController session;
  final AdminStore store;
  final RealtimeService realtime;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _section = 'dashboard';
  bool _collapsed = false;
  StreamSubscription<RealtimeEvent>? _rtSub;

  @override
  void initState() {
    super.initState();
    // F5: الانضمام لغرفة الإدارة — كما في useSocket('admin') بالويب
    widget.realtime.joinAdminRoom();
    _rtSub = widget.realtime.events.listen(_onRealtimeEvent);
    widget.store.bootstrap();
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }

  /// توجيه أحداث Realtime (نفس معالجات الويب في admin-app.tsx)
  Future<void> _onRealtimeEvent(RealtimeEvent ev) async {
    if (!mounted) return;
    switch (ev.name) {
      case 'notification:new':
        final title = ev.textValue('title') ?? 'إشعار جديد';
        final bodyText = ev.textValue('body') ?? '';
        showAppToast(
          context,
          bodyText.isEmpty ? '🔔 $title' : '🔔 $title — $bodyText',
        );
        await widget.store.onRealtimeNotification();
      case 'reservation:new':
        final ref =
            ev.textValue('bookingReference') ?? ev.textValue('reference') ?? '';
        final guest = ev.textValue('guestName');
        showAppToast(
          context,
          ref.isNotEmpty
              ? '🆕 حجز جديد — $ref${guest != null && guest.isNotEmpty ? ' · $guest' : ''}'
              : '🆕 وصل حجز جديد من الموقع',
        );
        await widget.store.onRealtimeBump();
      case 'room:status':
        await widget.store.onRealtimeBump();
      default:
        break;
    }
  }

  Future<void> _logout() async {
    await widget.session.logout();
  }

  void _navigate(String key) {
    setState(() => _section = key);
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final notifs = widget.store.notifications;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إشعارات التشغيل',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'آخر 30 إشعارًا تشغيليًا للإدارة والاستقبال',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: notifs.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد إشعارات حاليًا — ستصلك هنا تحديثات الحجوزات والطلبات فور حدوثها',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            )
                          : ListView.builder(
                              controller: controller,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: notifs.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child:
                                    AdminNotificationCard(item: notifs[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openMoreSections() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كل الأقسام',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      'تنقّل إلى أي قسم من أقسام لوحة الإدارة',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.2,
                  children: [
                    for (final (key, label, icon, _) in kAdminNav)
                      _moreTile(context, key, label, icon),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moreTile(BuildContext context, String key, String label,
      IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final active = _section == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          _navigate(key);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: active
                ? scheme.primary.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: active ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _screen(String key) {
    final store = widget.store;
    return switch (key) {
      'dashboard' => AdminDashboardScreen(
          store: store,
          onNavigate: _navigate,
        ),
      'hotel' => HotelSettingsScreen(store: store),
      'room-types' => RoomTypesScreen(store: store),
      'rooms' => AdminRoomsScreen(store: store),
      'rates' => RatesScreen(store: store),
      'services' => ServicesScreen(store: store),
      'staff' => StaffCodesScreen(store: store),
      'reservations' => AdminReservationsScreen(store: store),
      'guests' => GuestsScreen(store: store),
      'reports' => ReportsScreen(store: store),
      'audit' => AuditLogScreen(store: store),
      _ => AdminDashboardScreen(store: store, onNavigate: _navigate),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = widget.store;
    final staffName = widget.session.session?.name ?? 'المدير';
    final unread = store.unreadCount;
    final activeLabel = kAdminNav
        .firstWhere((n) => n.$1 == _section, orElse: () => kAdminNav.first)
        .$2;

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
                        'لوحة الإدارة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        'فندق قلب القاهرة — عدن · $staffName · $activeLabel',
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              final body = KeyedSubtree(
                key: ValueKey(_section),
                child: _screen(_section),
              );
              if (wide) {
                // شريط جانبي بكل الأقسام + قابل للطي (كالويب md+)
                return Row(
                  children: [
                    _rail(context),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                );
              }
              return body;
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 700) {
                return const SizedBox.shrink();
              }
              final moreActive = !kAdminPrimaryKeys.contains(_section);
              return BottomNavigationBar(
                currentIndex: moreActive
                    ? 4
                    : kAdminPrimaryKeys.indexOf(_section),
                onTap: (i) {
                  if (i == 4) {
                    _openMoreSections();
                    return;
                  }
                  _navigate(kAdminPrimaryKeys[i]);
                },
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    activeIcon: Icon(Icons.dashboard_rounded, size: 28),
                    label: 'لوحة',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.door_front_door_rounded),
                    activeIcon: Icon(Icons.door_front_door_rounded, size: 28),
                    label: 'الغرف',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.content_paste_rounded),
                    activeIcon: Icon(Icons.content_paste_rounded, size: 28),
                    label: 'الحجوزات',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.key_rounded),
                    activeIcon: Icon(Icons.key_rounded, size: 28),
                    label: 'الطاقم',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.menu_rounded),
                    activeIcon: const Icon(Icons.menu_rounded, size: 28),
                    label: 'المزيد',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// الشريط الجانبي القابل للطي — نفس aside في الويب (w-56/w-14)
  Widget _rail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = _collapsed ? 64.0 : 220.0;
    return Container(
      width: width,
      color: scheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: _collapsed ? 'فتح القائمة' : 'طي القائمة',
                onPressed: () => setState(() => _collapsed = !_collapsed),
                icon: Icon(
                  _collapsed
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final (key, label, icon, _) in kAdminNav)
                  _railItem(context, key, label, icon),
              ],
            ),
          ),
          if (!_collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  Icon(Icons.hotel_rounded,
                      size: 12, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'فندق قلب القاهرة — عدن',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _railItem(
      BuildContext context, String key, String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final active = _section == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _collapsed
                ? Icon(
                    icon,
                    size: 22,
                    color: active
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: active
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: active
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
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

// ─────────────────────────────────────────────────────────────
// APP ROOT — MaterialApp + RTL عربي + ثيم الفندق + دورة حياة الجلسة
// توجيه الجذور: booting → login → (ضيف: GuestShell | طاقم: RolePlaceholder)
// + renew عند العودة للمقدمة (سياسة §1.2.1) + إدارة Realtime/GuestStore
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/guest_shell.dart';
import 'screens/login_screen.dart';
import 'screens/role_placeholder.dart';
import 'screens/splash_gate.dart';
import 'services/socket_service.dart';
import 'state/guest_store.dart';
import 'state/session.dart';
import 'ui/theme.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.session});

  final SessionController session;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  late final SessionController _session;
  late final GuestStore _guestStore;
  late final RealtimeService _realtime;
  bool _guestBooted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.session;
    _guestStore = GuestStore(_session.api);
    _realtime = RealtimeService();
    _session.addListener(_onSessionChanged);
    _session.restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    _realtime.dispose();
    _guestStore.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (_session.status == AppStatus.authenticated && _session.isGuest) {
      if (!_guestBooted) {
        _guestBooted = true;
        _guestStore.bootstrap();
      }
    } else if (_session.status == AppStatus.loggedOut) {
      _guestBooted = false;
      _realtime.disconnect();
      _guestStore.reset();
    }
  }

  /// سياسة العميل المحمول §1.2.1: renew عند العودة للمقدمة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _session.renewOnForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        return MaterialApp(
          title: 'فندق قلب القاهرة',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _home(),
        );
      },
    );
  }

  Widget _home() {
    switch (_session.status) {
      case AppStatus.booting:
        return const SplashGate();
      case AppStatus.loggedOut:
      case AppStatus.loggingIn:
        return LoginScreen(session: _session);
      case AppStatus.authenticated:
        if (_session.isGuest) {
          return GuestShell(
            session: _session,
            store: _guestStore,
            realtime: _realtime,
          );
        }
        return RolePlaceholder(session: _session);
    }
  }
}

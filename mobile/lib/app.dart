// ─────────────────────────────────────────────────────────────
// APP ROOT — MaterialApp + RTL عربي + ثيم الفندق + دورة حياة الجلسة
// توجيه الجذور: booting → login → (ضيف: GuestShell | استقبال: ReceptionShell | إدارة: AdminShell)
// + renew عند العودة للمقدمة (سياسة §1.2.1) + إدارة Realtime/GuestStore/ReceptionStore/AdminStore
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/guest_shell.dart';
import 'screens/login_screen.dart';
import 'screens/reception/reception_shell.dart';
import 'screens/splash_gate.dart';
import 'screens/update_required_screen.dart';
import 'services/socket_service.dart';
import 'state/admin_store.dart';
import 'state/guest_store.dart';
import 'state/reception_store.dart';
import 'state/session.dart';
import 'ui/theme.dart';
import 'core/app_version.dart';
import 'config.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.session});

  final SessionController session;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  late final SessionController _session;
  late final GuestStore _guestStore;
  late final ReceptionStore _receptionStore;
  late final AdminStore _adminStore;
  late final RealtimeService _realtime;
  bool _guestBooted = false;
  bool _receptionBooted = false;
  bool _adminBooted = false;

  // F6 — حارس الحد الأدنى للإصدار (PUB-07 عند الإطلاق)
  bool _updateRequired = false;
  bool _updateRechecking = false;
  String _lastMinVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.session;
    _guestStore = GuestStore(_session.api);
    _receptionStore = ReceptionStore(_session.api);
    _adminStore = AdminStore(_session.api);
    _realtime = RealtimeService();
    _session.addListener(_onSessionChanged);
    _session.restore();
    _checkMinAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    _realtime.dispose();
    _guestStore.dispose();
    _receptionStore.dispose();
    _adminStore.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (_session.status == AppStatus.authenticated) {
      if (_session.isGuest && !_guestBooted) {
        _guestBooted = true;
        _guestStore.bootstrap();
      }
      if (_session.role == 'RECEPTION' && !_receptionBooted) {
        _receptionBooted = true;
        _receptionStore.bootstrap();
      }
      if (_session.role == 'ADMIN' && !_adminBooted) {
        _adminBooted = true;
        // الإقلاع الرسمي في AdminShell.initState (غرفة admin + bootstrap)
      }
    } else if (_session.status == AppStatus.loggedOut) {
      _guestBooted = false;
      _receptionBooted = false;
      _adminBooted = false;
      _realtime.disconnect();
      _guestStore.reset();
      _receptionStore.reset();
      _adminStore.reset();
    }
  }

  /// سياسة العميل المحمول §1.2.1: renew عند العودة للمقدمة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _session.renewOnForeground();
    }
  }

  /// F6: فحص PUB-07 عند الإطلاق — بلا خادم مضبوط نتجاوز (شاشة الدخول
  /// تطلب العنوان أولًا). فشل الفحص متسامح (fail-open) — الحجب فقط
  /// عندما يجيب الخادم صراحة بحد أعلى من إصدار هذا البناء.
  Future<void> _checkMinAppVersion() async {
    if (!AppConfig.hasBaseUrl) return;
    final min = await fetchMinAppVersion(AppConfig.baseUrl);
    if (!mounted) return;
    setState(() {
      _lastMinVersion = min ?? '';
      _updateRequired = min != null && needsUpdate(min);
      _updateRechecking = false;
    });
  }

  Future<void> _recheckMinAppVersion() async {
    setState(() => _updateRechecking = true);
    await _checkMinAppVersion();
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
    // F6: إعادة فحص جارية (بعد «إعادة المحاولة») → شاشة الانتظار
    if (_updateRechecking) return const SplashGate();
    // F6: حجب كامل عند إصدار أقل من حد الخادم
    if (_updateRequired) {
      return UpdateRequiredScreen(
        minVersion: _lastMinVersion,
        onRetry: _recheckMinAppVersion,
      );
    }
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
        if (_session.role == 'RECEPTION') {
          return ReceptionShell(
            session: _session,
            store: _receptionStore,
            realtime: _realtime,
          );
        }
        if (_session.role == 'ADMIN') {
          return AdminShell(
            session: _session,
            store: _adminStore,
            realtime: _realtime,
          );
        }
        return LoginScreen(session: _session);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN — نقطة الإطلاق: تهيئة الإعدادات ثم الجلسة ثم التطبيق
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import 'app.dart';
import 'config.dart';
import 'state/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  final session = SessionController();
  runApp(AppRoot(session: session));
}

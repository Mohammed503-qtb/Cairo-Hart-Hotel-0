// ─────────────────────────────────────────────────────────────
// SPLASH — شاشة الاسترجاع الأولي (أثناء restore + renew)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 112,
              height: 112,
              fit: BoxFit.contain,
              semanticLabel: 'شعار فندق قلب القاهرة',
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

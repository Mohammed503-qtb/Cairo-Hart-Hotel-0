// ─────────────────────────────────────────────────────────────
// THEME — هوية فندق قلب القاهرة: كحلي #1A3C6E + ذهبي #D4A843
// مطابقة للويب + Cairo + دعم ليلي/نهاري + RTL
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF1A3C6E);
  static const Color navyDark = Color(0xFF12294E);
  static const Color navyLight = Color(0xFF5B7DB1);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldDark = Color(0xFF8A6D1F);
  static const Color goldContainer = Color(0xFFF6EBCB);

  static const Color success = Color(0xFF1B8A5A);
  static const Color successContainer = Color(0xFFDCF2E7);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerContainer = Color(0xFFF9E0DD);
  static const Color warning = Color(0xFFB25E09);
  static const Color warningContainer = Color(0xFFFCEBD5);
  static const Color info = Color(0xFF1F6E8C);
  static const Color infoContainer = Color(0xFFDCF0F7);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.light(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD8E2F0),
    onPrimaryContainer: AppColors.navyDark,
    secondary: AppColors.gold,
    onSecondary: const Color(0xFF3A2E07),
    secondaryContainer: AppColors.goldContainer,
    onSecondaryContainer: const Color(0xFF4A3A0D),
    surface: Colors.white,
    onSurface: const Color(0xFF182334),
    surfaceContainerHighest: const Color(0xFFEDF1F7),
    onSurfaceVariant: const Color(0xFF5A6B82),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: AppColors.danger,
    outline: const Color(0xFFC9D3E0),
    outlineVariant: const Color(0xFFE2E8F0),
  );
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: const Color(0xFFF6F8FB),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.dark(
    primary: const Color(0xFFA8C2E8),
    onPrimary: AppColors.navyDark,
    primaryContainer: const Color(0xFF24406B),
    onPrimaryContainer: const Color(0xFFD8E2F0),
    secondary: AppColors.gold,
    onSecondary: const Color(0xFF3A2E07),
    secondaryContainer: const Color(0xFF4A3A0D),
    onSecondaryContainer: AppColors.goldContainer,
    surface: const Color(0xFF16233A),
    onSurface: const Color(0xFFE7EDF5),
    surfaceContainerHighest: const Color(0xFF1E2D47),
    onSurfaceVariant: const Color(0xFF9BAAC0),
    error: const Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    outline: const Color(0xFF3A4B66),
    outlineVariant: const Color(0xFF2A3A54),
  );
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: const Color(0xFF0E1726),
  );
}

ThemeData _base(ColorScheme scheme) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Cairo',
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: scheme.outline),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      selectedLabelStyle:
          const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: scheme.primary,
    ),
  );
}

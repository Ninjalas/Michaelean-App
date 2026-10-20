import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens for Michaelean (see docs/spec.md §2.1).
/// Screens should take colors, sizes and text styles from here,
/// never hardcode them.
class AppColors {
  static const navy = Color(0xFF242A5E); // primary actions, selected states
  static const red = Color(0xFFB3242E); // attention only (URGENT, alerts)
  static const white = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFFFFFF); // screen background: pure white, Luma-like
  static const ink = Color(0xFF16171D); // primary text
  static const muted = Color(0xFF6E7079); // secondary text (kept dark enough for AA)
  static const hairline = Color(0xFFECECEE); // dividers
  static const fill = Color(0xFFF3F3F4); // soft gray tiles, inputs, active nav pill

  // Status tints (spec §2.2): soft background + darker text, all WCAG AA.
  static const navyTint = Color(0xFFE6E8F3);
  static const greenTint = Color(0xFFE3F1E6);
  static const green = Color(0xFF256B36);
  static const amberTint = Color(0xFFF7EBD6);
  static const amber = Color(0xFF7A5210);
  static const redTint = Color(0xFFF6E1E2);

  /// Large, very soft shadow for floating pieces only (header pill, nav bar,
  /// back button, Up next card). Sheets get their depth from the dimmed page.
  static const floatShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, 8)),
  ];
}

/// 4-point spacing scale.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const screen = 20.0; // left/right screen margin
  static const section = 32.0; // gap between sections (spec: 24–32)
}

/// Motion (spec §2.5): 200–300 ms, ease-out.
class AppMotion {
  static const fast = Duration(milliseconds: 200); // small state changes
  static const normal = Duration(milliseconds: 250); // expand/collapse, sheets
  static const slow = Duration(milliseconds: 300); // page-level changes
  static const curve = Curves.easeOut;
}

class AppRadius {
  static const small = 12.0; // thumbnails, small elements
  static const large = 20.0; // cover images, sheets, modals
  static const pill = 999.0; // buttons, inputs, tags, nav bar
}

class AppTheme {
  /// Inter Display for large titles only (spec §2.3), with tight spacing.
  static const _display = TextStyle(fontFamily: 'InterDisplay', fontWeight: FontWeight.w600);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        error: AppColors.red,
        surface: AppColors.white,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      dividerColor: AppColors.hairline,
      // Smooth, never abrupt page changes (spec §2.5). iOS keeps its native
      // slide so the swipe-back gesture still works in the installed PWA.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            // Hero titles: profile name, School News headline
            displaySmall: _display.copyWith(fontSize: 34, height: 1.1, letterSpacing: -0.8),
            // Screen titles, e.g. "Student Life"
            headlineMedium: _display.copyWith(fontSize: 28, height: 1.15, letterSpacing: -0.6),
            // Detail-page titles, e.g. an event name; the Up next class
            headlineSmall: _display.copyWith(fontSize: 24, height: 1.2, letterSpacing: -0.5),
            // Section titles, e.g. "Pending Tasks"
            titleLarge: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
            // Row titles, e.g. an event name in a list
            titleMedium:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
            // Small muted labels, e.g. "LOCATION"
            labelMedium: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          )
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.hairline),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

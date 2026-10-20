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

  /// Large, very soft shadow for floating pieces only (header pill, nav bar).
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
  static const section = 36.0; // gap between sections
}

class AppRadius {
  static const small = 12.0; // thumbnails, small elements
  static const large = 20.0; // cover images, sheets, modals
  static const pill = 999.0; // buttons, inputs, tags, nav bar
}

class AppTheme {
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
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            // Screen titles, e.g. "Student Life"
            headlineMedium: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w500, letterSpacing: -0.4),
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

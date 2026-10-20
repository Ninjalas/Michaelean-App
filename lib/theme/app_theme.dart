import 'package:flutter/material.dart';

/// Design tokens for Michaelean (see docs/spec.md §2.1).
/// Screens should take colors, sizes and text styles from here,
/// never hardcode them.
class AppColors {
  static const navy = Color(0xFF242A5E); // primary actions, selected states
  static const red = Color(0xFFB3242E); // attention only (URGENT, alerts)
  static const white = Color(0xFFFFFFFF);
  static const paper = Color(0xFFF7F6F3); // screen background
  static const ink = Color(0xFF16171D); // primary text
  static const muted = Color(0xFF6E7079); // secondary text
  static const hairline = Color(0xFFE7E5E0); // dividers
  static const fill = Color(0xFFF1F0EC); // inputs, tonal buttons
}

/// 4-point spacing scale.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const screen = 20.0; // left/right screen margin
  static const section = 28.0; // gap between sections
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
                fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4),
            // Section titles, e.g. "Pending Tasks"
            titleLarge: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2),
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

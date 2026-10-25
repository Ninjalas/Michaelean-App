import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens for Michaelean (see docs/spec.md §2.1).
/// Screens should take colors, sizes and text styles from here,
/// never hardcode them.
class AppColors {
  static const navy = Color(0xFF242A5E); // primary actions, selected states
  static const red = Color(0xFFB3242E); // attention only (URGENT, alerts)
  static const white = Color(0xFFFFFFFF);
  static const page = Color(0xFFF4F5F9); // screen background: soft blue-grey, so white cards stand out
  static const ink = Color(0xFF16171D); // primary text
  static const muted = Color(0xFF6E7079); // secondary text (kept dark enough for AA)
  static const hairline = Color(0xFFECECEE); // dividers
  static const fill = Color(0xFFF3F3F4); // soft gray inside white: placeholders, neutral pills, nav pill
  static const track = Color(0xFFE9EBF1); // controls on the page: chips, day pills, switch track, skeletons
  static const trackText = Color(0xFF5A5C66); // secondary text on track (5.6:1; muted is only 4.1:1 there)

  static const onNavyMuted = Color(0xB8FFFFFF); // secondary text on navy (white at 72%)

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

  /// An even softer shadow under white cards on the page (spec §2.4); also
  /// keeps a white card visible on a white sheet.
  static const cardShadow = [
    BoxShadow(color: Color(0x0F1B2150), blurRadius: 18, offset: Offset(0, 4)),
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

  /// [d], or no animation when the phone's "reduce motion" setting is on
  /// (accessibility). Use it for every animation.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// The iOS-style page slide, used on every platform; pages just appear with
/// the phone's reduce-motion setting.
class SlidePageTransitions extends PageTransitionsBuilder {
  const SlidePageTransitions();

  static const _slide = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _slide.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
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
        // Bottom sheets, dialogs, and pickers: plain white, not navy-tinted.
        surfaceContainerLow: AppColors.white,
        surfaceContainerHigh: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.page,
      dividerColor: AppColors.hairline,
      // Pages slide in from the right on every phone, and back out on Back,
      // with the swipe-back gesture (spec §2.5, decided 2026-10-24).
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (final p in TargetPlatform.values) p: const SlidePageTransitions(),
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
          // Disabled is plain gray (spec §2.1 Forms).
          disabledBackgroundColor: AppColors.fill,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      // Luma-style inputs: borderless, light gray, rounded (spec §2.1 Forms).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // White with a hairline, so inputs read on the soft page and on white sheets.
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
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

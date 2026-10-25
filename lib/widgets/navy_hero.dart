import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The deep navy header at the top of the main tabs (spec §2.1, direction
/// B): solid navy from the very top of the screen (behind the status bar),
/// a faint emblem-red glow in one corner, rounded bottom corners. An
/// [overlap] card (e.g. Home's stats) can hang [overlapDepth] below its
/// bottom edge. Text inside should be white or [AppColors.onNavyMuted].
class NavyHero extends StatelessWidget {
  static const radius = 28.0; // bottom corners
  static const glowSize = 240.0;

  final Widget child;
  final Widget? overlap;
  final double overlapDepth;

  const NavyHero({super.key, required this.child, this.overlap, this.overlapDepth = 36});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top; // reach behind the status bar
    return Stack(
      children: [
        // The navy ends [overlapDepth] above the bottom, so the card hangs over.
        Positioned.fill(
          bottom: overlap == null ? 0 : overlapDepth,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(radius)),
            child: ColoredBox(
              color: AppColors.navy,
              child: Stack(
                children: [
                  // A faint red glow from the emblem's red, fading to nothing.
                  Positioned(
                    top: -glowSize / 3,
                    right: -glowSize / 3,
                    width: glowSize,
                    height: glowSize,
                    child: DecoratedBox(
                      key: const ValueKey('navy-hero-glow'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.red.withValues(alpha: 0.35),
                          AppColors.red.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, top + AppSpacing.md, AppSpacing.screen,
              overlap == null ? AppSpacing.lg + AppSpacing.sm : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconTheme.merge(
                data: const IconThemeData(color: AppColors.white),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: AppColors.white),
                  child: child,
                ),
              ),
              if (overlap != null) ...[
                const SizedBox(height: AppSpacing.lg),
                overlap!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

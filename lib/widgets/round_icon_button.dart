import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Floating white circle button with a soft shadow (back button, bell).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showDot; // small red dot, e.g. new notifications

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: AppColors.floatShadow,
      ),
      child: Stack(
        children: [
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: Icon(icon, color: AppColors.ink),
          ),
          if (showDot)
            Positioned(
              top: 11,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

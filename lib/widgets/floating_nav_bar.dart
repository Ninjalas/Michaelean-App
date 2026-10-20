import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavItem(this.label, this.icon, this.selectedIcon);
}

/// The floating, rounded bottom navigation bar (spec §2.1).
/// The selected tab sits in its own soft filled pill.
class FloatingNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        heightFactor: 1,
        child: Container(
          // Equal-width tabs, capped so the pill floats on wide screens and
          // still fits long labels ("Michaelean Life") on narrow phones.
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppColors.floatShadow,
          ),
          // Frosted glass: content scrolling underneath shows through, blurred.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                color: AppColors.white.withValues(alpha: 0.82),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected ? AppColors.fill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

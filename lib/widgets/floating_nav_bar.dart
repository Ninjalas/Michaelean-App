import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback? onLongPress; // e.g. the quick QR on the middle tab
  final String? longPressHint; // read by screen readers, e.g. "show your QR"

  const NavItem(this.label, this.icon, this.selectedIcon,
      {this.onLongPress, this.longPressHint});
}

/// The floating, rounded bottom navigation bar (spec §2.1).
/// The selected tab sits in a soft filled pill that slides to the tab you
/// tap, and its icon gives a tiny bounce (spec §2.5).
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
                child: Stack(
                  children: [
                    // One pill behind the tabs, gliding to the selected one.
                    Positioned.fill(
                      child: AnimatedAlign(
                        duration: AppMotion.of(context, AppMotion.normal),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(
                            items.length < 2 ? 0 : -1 + 2 * selectedIndex / (items.length - 1),
                            0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / items.length,
                          heightFactor: 1,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.fill,
                              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
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

class _NavButton extends StatefulWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  // 0 → 1 once per selection; at rest (1) the icon is its normal size.
  late final _bounce = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _bounce.duration = AppMotion.of(context, AppMotion.slow);
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;
    final onTap = widget.onTap;
    final color = selected ? AppColors.navy : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      onLongPress: item.onLongPress,
      onLongPressHint: item.longPressHint,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: item.onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Grows to 115% and settles back as the tab is selected.
              ScaleTransition(
                scale: _bounce.drive(const _Bounce()),
                child: Icon(selected ? item.selectedIcon : item.icon, color: color, size: 22),
              ),
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

/// 1 → 1.15 → 1: a quick rise, then an eased settle.
class _Bounce extends Animatable<double> {
  const _Bounce();

  @override
  double transform(double t) => 1 + 0.15 * math.sin(math.pi * Curves.easeOut.transform(t));
}

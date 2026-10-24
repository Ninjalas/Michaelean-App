import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A tappable card or row: the usual ripple, plus a slight shrink while it's
/// pressed, so it feels touchable (spec §2.5). It follows the ripple's own
/// pressed state, so starting to scroll doesn't shrink it, and a disabled one
/// (no [onTap]) doesn't react. No shrink with the phone's reduce-motion setting.
///
/// Cards with a fill pass [color] (and [shadow]) so the whole card shrinks.
class Pressable extends StatefulWidget {
  static const pressedScale = 0.97;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? shadow;
  final Widget child;

  const Pressable({
    super.key,
    required this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
    this.shadow,
    required this.child,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget card = InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      borderRadius: widget.borderRadius,
      onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
      child: widget.child,
    );
    if (widget.color != null) {
      card = Material(color: widget.color, borderRadius: widget.borderRadius, child: card);
    }
    if (widget.shadow != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(borderRadius: widget.borderRadius, boxShadow: widget.shadow),
        child: card,
      );
    }
    return AnimatedScale(
      scale: _pressed && !still ? Pressable.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: card,
    );
  }
}

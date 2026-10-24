import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tells each tab's first page when its tab was tapped again while it was
/// showing, so the page can glide back to the top. Provided by AppShell; one
/// notifier per tab (0 Home, 1 Student/Michaelean Life, 2 Profile).
class TabReselect extends InheritedWidget {
  final List<ChangeNotifier> taps;

  const TabReselect({super.key, required this.taps, required super.child});

  static TabReselect? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabReselect>();

  @override
  bool updateShouldNotify(TabReselect old) => taps != old.taps;
}

/// A tab notifier that can be "tapped".
class TabTap extends ChangeNotifier {
  void tap() => notifyListeners();
}

/// Glides [controller] back to the top. From far down it first jumps to one
/// screen from the top, so it never takes long. Instant with reduce motion.
Future<void> scrollToTop(BuildContext context, ScrollController controller) async {
  if (!controller.hasClients) return;
  final position = controller.position;
  final duration = AppMotion.of(context, AppMotion.slow);
  if (duration == Duration.zero) return controller.jumpTo(0);
  final screen = position.viewportDimension;
  if (position.pixels > screen * 1.5) controller.jumpTo(screen);
  await controller.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
}

/// Wraps a tab's first page: when [tab] is tapped again, [controller]
/// scrolls back to the top.
class ScrollToTopOnTabTap extends StatefulWidget {
  final int tab;
  final ScrollController controller;
  final Widget child;

  const ScrollToTopOnTabTap({
    super.key,
    required this.tab,
    required this.controller,
    required this.child,
  });

  @override
  State<ScrollToTopOnTabTap> createState() => _ScrollToTopOnTabTapState();
}

class _ScrollToTopOnTabTapState extends State<ScrollToTopOnTabTap> {
  ChangeNotifier? _taps;

  void _onTap() => scrollToTop(context, widget.controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final taps = TabReselect.maybeOf(context)?.taps[widget.tab];
    if (taps != _taps) {
      _taps?.removeListener(_onTap);
      _taps = taps?..addListener(_onTap);
    }
  }

  @override
  void dispose() {
    _taps?.removeListener(_onTap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

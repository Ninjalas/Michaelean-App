import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fades from a loading state to the loaded content (or an error message)
/// instead of swapping at once (spec §2.5). It fades only when [loaded]
/// changes; reloads that keep the content just update it in place. Instant
/// with the phone's reduce-motion setting.
class FadeSwitch extends StatelessWidget {
  final bool loaded;
  final Widget child;

  const FadeSwitch({super.key, required this.loaded, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.normal),
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      // Top-aligned, so content doesn't jump while the two overlap.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(loaded), child: child),
    );
  }
}

/// Crossfades a small control when its [state] changes, e.g. Connect →
/// Pending or Register → Registered (spec §2.5). The two overlap at the
/// size the parent gives, so a full-width button stays full width. Instant
/// with the phone's reduce-motion setting.
class StateFade extends StatelessWidget {
  final Object state;
  final Widget child;

  const StateFade({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }
}

/// A FutureBuilder builder whose result fades in once the data (or an
/// error) arrives.
AsyncWidgetBuilder<T> fadeOnLoad<T>(AsyncWidgetBuilder<T> builder) =>
    (context, snap) => FadeSwitch(
          loaded: snap.hasData || snap.hasError || snap.connectionState == ConnectionState.done,
          child: builder(context, snap),
        );

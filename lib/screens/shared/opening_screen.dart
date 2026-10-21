import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Opening intro, the first thing shown when the app opens (spec §1.1).
/// The SMCL emblem fades and scales in, then the name rises in. It ends on
/// its own (about 2.4 s, no Skip button), then goes to the sign-in preview.
///
/// Stands in for assets/videos/app_opening.mp4 until a real SMCL video exists.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> with SingleTickerProviderStateMixin {
  // Animation runs for the first ~60%; the rest is a short hold on the logo.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  bool _done = false;

  late final _emblemFade = _step(0, 0.3);
  late final _emblemScale = Tween(begin: 0.82, end: 1.0)
      .animate(CurvedAnimation(parent: _intro, curve: const Interval(0, 0.4, curve: Curves.easeOutCubic)));
  late final _titleIn = _step(0.25, 0.5);
  late final _subtitleIn = _step(0.35, 0.6);

  Animation<double> _step(double start, double end) =>
      CurvedAnimation(parent: _intro, curve: Interval(start, end, curve: AppMotion.curve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.isCompleted) return;
    // Reduced motion: show the finished logo, still hold briefly, no movement.
    if (MediaQuery.disableAnimationsOf(context)) _intro.value = 0.6;
    _intro.forward();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    context.go('/preview'); // replace, so Back doesn't return to the intro
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _emblemFade,
              child: ScaleTransition(
                scale: _emblemScale,
                // Same Hero tag as the sign-in screen: the emblem glides into place.
                child: Hero(
                  tag: 'smcl-emblem',
                  child: Image.asset('assets/images/SMCL_Emblem.png', height: 128,
                      semanticLabel: "Saint Michael's College of Laguna emblem"),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _riseIn(_titleIn, Text('Michaelean', style: text.displaySmall)),
            const SizedBox(height: AppSpacing.xs),
            _riseIn(
              _subtitleIn,
              Text("Saint Michael's College of Laguna",
                  style: text.bodyLarge?.copyWith(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }

  /// Fades in while sliding up a few pixels.
  Widget _riseIn(Animation<double> a, Widget child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
          child: child,
        ),
      );
}

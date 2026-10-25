import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Grey placeholder boxes shaped like the page that's loading, with a soft
/// light sweeping across them so it reads as "loading", not "stuck"
/// (spec §2.5). The boxes stay still with the phone's reduce-motion setting.
class LoadingBoxes extends StatefulWidget {
  final List<double> heights; // one box per height, top to bottom

  const LoadingBoxes({super.key, required this.heights});

  @override
  State<LoadingBoxes> createState() => _LoadingBoxesState();
}

class _LoadingBoxesState extends State<LoadingBoxes> with SingleTickerProviderStateMixin {
  static const sweep = Duration(milliseconds: 1200); // one pass of the light

  late final _shimmer = AnimationController(vsync: this, duration: sweep);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxes = Column(
      children: [
        for (final h in widget.heights)
          Container(
            height: h,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
          ),
      ],
    );
    if (!_shimmer.isAnimating) return boxes;
    final light = Color.lerp(AppColors.track, AppColors.white, 0.7)!;
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        // A band of light, from beyond the left edge to beyond the right.
        final x = -3 + 4 * _shimmer.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop, // only over the boxes themselves
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x, -0.3),
            end: Alignment(x + 2, 0.3),
            colors: [AppColors.track, light, AppColors.track],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
      child: boxes,
    );
  }
}

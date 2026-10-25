import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A white rounded card on the soft page, with a very soft shadow (spec
/// §2.1, direction B). A section's rows sit together in one card; with
/// [children], thin lines separate them, indented by [indent].
class SurfaceCard extends StatelessWidget {
  final Widget? child;
  final List<Widget>? children;
  final double indent; // where the lines between rows start (the text column)
  final EdgeInsetsGeometry padding;

  const SurfaceCard({
    super.key,
    this.child,
    this.children,
    this.indent = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  }) : assert((child == null) != (children == null), 'Give a child or children');

  @override
  Widget build(BuildContext context) {
    final rows = children;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency, // row ripples stay inside the rounded card
        borderRadius: BorderRadius.circular(AppRadius.large),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: rows == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) Divider(height: 1, indent: indent),
                      rows[i],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

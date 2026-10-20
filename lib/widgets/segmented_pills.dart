import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pill-shaped segmented control (spec §2.1): a soft gray track with a white
/// thumb that slides to the selected segment.
class SegmentedPills<T> extends StatelessWidget {
  final List<(T, String)> segments; // (value, label)
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedPills({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.$1 == selected);
    final n = segments.length;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppColors.floatShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (value, label) in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: value == selected,
                    child: InkWell(
                      onTap: () => onChanged(value),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: value == selected ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

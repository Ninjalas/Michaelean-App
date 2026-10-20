import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OverviewMetric {
  final String label;
  final String value;
  final double? progress; // 0–1 shows a thin bar; null shows none

  const OverviewMetric(this.label, this.value, {this.progress});
}

/// Expandable overview in the Home header: Attendance Overview for students,
/// Today's Overview for teachers (spec §6, §8). Collapsed: one summary line.
class ExpandableOverview extends StatefulWidget {
  final String title;
  final String summary;
  final List<OverviewMetric> metrics;
  final ValueChanged<String> onOpenMetric; // metric label → its detail page

  const ExpandableOverview({
    super.key,
    required this.title,
    required this.summary,
    required this.metrics,
    required this.onOpenMetric,
  });

  @override
  State<ExpandableOverview> createState() => _ExpandableOverviewState();
}

class _ExpandableOverviewState extends State<ExpandableOverview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                                style: text.labelMedium?.copyWith(color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(widget.summary, style: text.titleMedium),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              for (final m in widget.metrics) _metric(m),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
                child: Text('Sample data — not official records.',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(OverviewMetric m) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => widget.onOpenMetric(m.label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(m.label, style: text.bodyLarge)),
                Text(m.value, style: text.titleMedium),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
              ],
            ),
            if (m.progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: m.progress!.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: AppColors.fill,
                  color: AppColors.navy,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

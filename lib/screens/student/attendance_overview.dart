import 'package:flutter/material.dart';

import '../../models/feed.dart';
import '../../theme/app_theme.dart';

/// Expandable Attendance Overview in the Student Home header (spec §6).
/// Collapsed: one summary line. Expanded: four labeled metrics.
class AttendanceOverview extends StatefulWidget {
  final AttendanceSummary summary;
  final ValueChanged<String> onOpenMetric; // metric name → its detail page

  const AttendanceOverview({super.key, required this.summary, required this.onOpenMetric});

  @override
  State<AttendanceOverview> createState() => _AttendanceOverviewState();
}

class _AttendanceOverviewState extends State<AttendanceOverview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
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
                            Text('Attendance Overview',
                                style: text.labelMedium?.copyWith(color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              '${s.classPercent}% class · ${s.eventPercent}% events · '
                              '${s.requirementsCleared}/${s.requirementsTotal} cleared',
                              style: text.titleMedium,
                            ),
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
              _metric('Class Attendance', '${s.classPercent}%', s.classPercent / 100),
              _metric('Event Attendance', '${s.eventPercent}%', s.eventPercent / 100),
              _metric('Events Completed', '${s.eventsCompleted}', null),
              _metric(
                'Event Requirements',
                '${s.requirementsCleared}/${s.requirementsTotal} cleared',
                s.requirementsTotal == 0 ? 0 : s.requirementsCleared / s.requirementsTotal,
              ),
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

  Widget _metric(String label, String value, double? progress) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => widget.onOpenMetric(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: text.bodyLarge)),
                Text(value, style: text.titleMedium),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
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

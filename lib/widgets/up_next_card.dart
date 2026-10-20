import 'package:flutter/material.dart';

import '../models/feed.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

/// The solid navy "Up next" card with the next class (spec §6, §8): the one
/// navy hero on Home. Teachers allowed to take attendance also get a
/// Start attendance button. With no class ahead it shows a calm empty state.
class UpNextCard extends StatelessWidget {
  final ClassSession? session;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onStartAttendance; // null → no button

  const UpNextCard({
    super.key,
    required this.session,
    required this.now,
    this.onTap,
    this.onStartAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final c = session;
    if (c == null) return _empty(context);

    final text = Theme.of(context).textTheme;
    final inProgress = !c.start.isAfter(now);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppColors.floatShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('UP NEXT',
                        style: text.labelMedium
                            ?.copyWith(color: AppColors.onNavyMuted, letterSpacing: 1.2)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        inProgress ? 'Now' : formatDayLabel(c.start, now),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(c.subject, style: text.headlineSmall?.copyWith(color: AppColors.white)),
                const SizedBox(height: AppSpacing.md),
                _line(Icons.schedule_rounded, '${formatTime(c.start)} – ${formatTime(c.end)}'),
                _line(Icons.place_outlined, c.room),
                if (c.teacher != null)
                  _line(Icons.person_outline_rounded, c.teacher!)
                else
                  _line(Icons.groups_outlined, c.section),
                if (onStartAttendance != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onStartAttendance,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.navy,
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Start attendance'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.onNavyMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: AppColors.white)),
            ),
          ],
        ),
      );

  Widget _empty(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, color: AppColors.muted, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No upcoming classes', style: text.titleMedium),
                const SizedBox(height: 2),
                Text('Your schedule is clear for now.',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/campus.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

/// The status pill for a clearance requirement (spec §7.5), so students
/// and staff see the same words and colors.
StatusPill clearancePill(ClearanceStatus s) => switch (s) {
      ClearanceStatus.notStarted => const StatusPill('Not started'),
      ClearanceStatus.actionRequired => const StatusPill('Action required', tone: PillTone.amber),
      ClearanceStatus.inReview => const StatusPill('In review', tone: PillTone.navy),
      ClearanceStatus.needsCorrection => const StatusPill('Needs correction', tone: PillTone.red),
      ClearanceStatus.cleared => const StatusPill('Cleared', tone: PillTone.green),
      ClearanceStatus.onHold => const StatusPill('On hold', tone: PillTone.amber),
      ClearanceStatus.notApplicable => const StatusPill('Not applicable'),
    };

/// An icon for a clearance office, by name.
IconData officeIcon(String office) => switch (office) {
      'Library' => Icons.local_library_outlined,
      'Accounting' => Icons.payments_outlined,
      "Registrar's Office" => Icons.badge_outlined,
      'Office of Student Affairs' => Icons.groups_outlined,
      'Guidance Office' => Icons.support_agent_outlined,
      'Student Publication' => Icons.newspaper_outlined,
      _ => Icons.school_outlined, // departments
    };

/// Calm empty state outside a clearance period (spec §7.5).
class ClearanceUnavailable extends StatelessWidget {
  const ClearanceUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.muted, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clearance Unavailable', style: text.titleMedium),
                const SizedBox(height: 2),
                Text("There's no active clearance period right now.",
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

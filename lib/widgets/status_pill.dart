import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PillTone { neutral, navy, green, amber, red }

/// Small soft-tinted label, e.g. "Needs correction" or "URGENT" (spec §2.1).
class StatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;

  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.neutral => (AppColors.fill, AppColors.muted),
      PillTone.navy => (AppColors.navyTint, AppColors.navy),
      PillTone.green => (AppColors.greenTint, AppColors.green),
      PillTone.amber => (AppColors.amberTint, AppColors.amber),
      PillTone.red => (AppColors.redTint, AppColors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

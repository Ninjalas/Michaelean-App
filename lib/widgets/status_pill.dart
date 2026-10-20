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
      PillTone.navy => (const Color(0xFFE6E8F3), AppColors.navy),
      PillTone.green => (const Color(0xFFE3F1E6), const Color(0xFF256B36)),
      PillTone.amber => (const Color(0xFFF7EBD6), const Color(0xFF7A5210)),
      PillTone.red => (const Color(0xFFF6E1E2), AppColors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

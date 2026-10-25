import 'package:flutter/material.dart';

import '../models/campus.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';
import 'user_avatar.dart';

/// An organization in a list: logo, name, member count (spec §7.4).
class OrgRow extends StatelessWidget {
  static const textIndent = 48 + AppSpacing.md; // divider indent under the name

  final Organization org;
  final VoidCallback onTap;
  final Widget? pill; // e.g. "Member"

  const OrgRow({super.key, required this.org, required this.onTap, this.pill});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(name: org.name, imageAsset: org.logoAsset, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(org.name, style: text.titleMedium),
                  Text('${org.memberCount} members',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            // Capped and shrunk to fit, so with large text it never pushes past the edge.
            if (pill != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: FittedBox(fit: BoxFit.scaleDown, child: pill!),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

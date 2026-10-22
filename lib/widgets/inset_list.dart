import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded, soft-gray group of rows with white dividers (Luma's grouped
/// inset lists, spec §11). Used by Settings and its pages.
class InsetGroup extends StatelessWidget {
  final List<Widget> children;

  const InsetGroup(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(AppRadius.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1.5, thickness: 1.5, indent: 52, color: AppColors.white),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A tappable row: icon, label, optional subtitle, chevron.
class InsetRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? subtitle;

  const InsetRow(this.label, this.icon,
      {super.key, required this.onTap, this.color = AppColors.ink, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: text.bodyLarge?.copyWith(color: color)),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              if (color == AppColors.ink)
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A read-only row: icon, a small muted label, and its value below.
class InsetField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InsetField(this.label, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.muted, size: 22),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  Text(value, style: text.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Section title, e.g. "School News". Spacing above is part of the widget
/// so sections are evenly separated everywhere. With [onSeeAll], a
/// "See all ›" link sits on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader(this.title, {super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
    return Padding(
      padding: EdgeInsets.only(
          top: AppSpacing.section, bottom: onSeeAll == null ? AppSpacing.sm : 0),
      child: onSeeAll == null
          ? heading
          : Row(
              children: [
                Expanded(child: heading),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: Semantics(
                    label: 'See all $title',
                    excludeSemantics: true, // read "See all Events", not "See all ›"
                    child: const Text('See all ›'),
                  ),
                ),
              ],
            ),
    );
  }
}

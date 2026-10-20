import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Section title, e.g. "School News". Spacing above is part of the widget
/// so sections are evenly separated everywhere.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

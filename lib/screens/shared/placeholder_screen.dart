import 'package:flutter/material.dart';

import '../../services/session.dart';
import '../../theme/app_theme.dart';

/// Temporary tab content until the real screen is built in a later phase.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String comingIn;

  const PlaceholderScreen({super.key, required this.title, required this.comingIn});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = SessionScope.of(context);
    final user = session.user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.section, AppSpacing.screen, 120),
        children: [
          Text(title, style: text.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Coming in $comingIn',
              style: text.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.section),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          if (user != null)
            Text('Previewing as ${user.fullName} (mock ${user.role.name})',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: session.endPreview,
              child: const Text('Switch preview role'),
            ),
          ),
        ],
      ),
    );
  }
}

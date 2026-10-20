import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/round_icon_button.dart';

/// Stand-in page for links to features that aren't built yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 120),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: RoundIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Text(title, style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text("This part of the prototype hasn't been built yet. See the phase plan "
                'in README.md.',
                style: text.bodyLarge?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

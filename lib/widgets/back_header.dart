import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'round_icon_button.dart';

/// Top of a pushed page: floating round back button, title, optional action.
class BackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const BackHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.sm),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../theme/app_theme.dart';

/// Home's "+" button (a floating action button). Only shown to users with
/// the posting permission; see HomeScreen.
class CreatePostButton extends StatelessWidget {
  /// Distance from the screen's bottom edge, so the open menu can draw its
  /// "×" in exactly the same spot.
  final double bottom;

  const CreatePostButton({super.key, required this.bottom});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        heroTag: null,
        tooltip: 'Create post',
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        shape: const CircleBorder(),
        onPressed: () => context.push('/home/create', extra: bottom),
        child: const Icon(Icons.add_rounded, size: 28),
      );
}

/// The open "+" menu (a speed dial): the page dims, the "+" turns into an
/// "×", and the post types fan out above it. A router page, so the Back
/// gesture and a tap on the dimmed page both close it.
class CreateMenuPage extends Page<void> {
  final double bottom; // where the "+" button sits, from the screen's bottom edge

  const CreateMenuPage({super.key, required this.bottom});

  @override
  Route<void> createRoute(BuildContext context) => RawDialogRoute<void>(
        settings: this,
        barrierDismissible: true,
        barrierLabel: 'Close menu',
        barrierColor: const Color(0x66000000),
        transitionDuration: AppMotion.normal,
        transitionBuilder: (context, animation, secondary, child) => child,
        pageBuilder: (context, animation, secondary) =>
            _CreateMenu(animation: animation, bottom: bottom),
      );
}

class _CreateMenu extends StatelessWidget {
  final Animation<double> animation;
  final double bottom;

  const _CreateMenu({required this.animation, required this.bottom});

  static const _options = [
    ('Announcement', Icons.campaign_outlined, PostKind.announcement),
    ('School News', Icons.article_outlined, PostKind.schoolNews),
    ('Campus update', Icons.forum_outlined, PostKind.campusUpdate),
  ];

  void _choose(BuildContext context, PostKind kind) {
    final router = GoRouter.of(context);
    router.pop(); // close the menu first
    router.push('/home/compose/${kind.name}');
  }

  @override
  Widget build(BuildContext context) {
    final n = _options.length;
    return Stack(
      children: [
        Positioned(
          right: AppSpacing.screen,
          bottom: bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < n; i++)
                _staggered(
                  // The option nearest the button appears first.
                  Interval((n - 1 - i) * 0.15, 0.6 + (n - 1 - i) * 0.15, curve: AppMotion.curve),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _Option(
                      label: _options[i].$1,
                      icon: _options[i].$2,
                      onTap: () => _choose(context, _options[i].$3),
                    ),
                  ),
                ),
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Close menu',
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                shape: const CircleBorder(),
                onPressed: () => Navigator.of(context).pop(),
                // The "+" turns an eighth of a turn into an "×".
                child: RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.125)
                      .animate(CurvedAnimation(parent: animation, curve: AppMotion.curve)),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _staggered(Interval interval, Widget child) {
    final a = CurvedAnimation(parent: animation, curve: interval);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }
}

/// One menu choice: a white label pill and a small white icon circle.
class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Option({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            // Lines the icon circles up over the centre of the 56 px button.
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppColors.floatShadow,
                  ),
                  child: Text(label, style: text.titleSmall),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.floatShadow,
                  ),
                  child: Icon(icon, color: AppColors.navy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

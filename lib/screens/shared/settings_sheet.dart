import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/inset_list.dart';
import '../../widgets/segmented_pills.dart';

/// Settings pop-up content (spec §11), shared by both roles: grouped,
/// rounded inset lists in Luma's style. Each item opens its own page.
class SettingsSheet extends StatefulWidget {
  final UserService userService;

  const SettingsSheet({super.key, required this.userService});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _switching = false;

  void _open(String path) {
    final router = GoRouter.of(context);
    router.pop(); // close the pop-up first
    router.push(path);
  }

  /// Preview tool only: swaps the sample account. Not sign-in, not security.
  Future<void> _switchRole(UserRole role) async {
    final session = SessionScope.of(context);
    if (_switching || session.user?.role == role) return;
    setState(() => _switching = true);
    final user = await widget.userService.loadPreviewUser(role);
    if (!mounted) return;
    GoRouter.of(context).pop();
    session.startPreview(user);
  }

  void _logOut() {
    final session = SessionScope.of(context); // read before the sheet closes
    GoRouter.of(context).pop();
    session.endPreview(); // no real account in the prototype: ends the preview
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final role = SessionScope.of(context).user?.role ?? UserRole.student;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
      children: [
        InsetGroup([
          InsetRow('Personal Information', Icons.person_outline_rounded,
              onTap: () => _open('/profile/personal')),
          InsetRow('Account & Security', Icons.lock_outline_rounded,
              onTap: () => _open('/profile/security')),
          InsetRow('Notifications', Icons.notifications_none_rounded,
              onTap: () => _open('/profile/notifications')),
        ]),
        const SizedBox(height: AppSpacing.md),
        InsetGroup([
          InsetRow('Help & Support', Icons.help_outline_rounded,
              onTap: () => _open('/profile/help')),
          InsetRow('About Michaelean', Icons.info_outline_rounded,
              onTap: () => _open('/profile/about')),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text('Preview tools', style: text.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.sm),
        InsetGroup([
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview as', style: text.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedPills<UserRole>(
                  segments: const [(UserRole.student, 'Student'), (UserRole.teacher, 'Teacher')],
                  selected: role,
                  onChanged: _switchRole,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Switches the sample account for previewing. Not a sign-in and not '
                    'a security feature.',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        InsetGroup([
          InsetRow('Log Out', Icons.logout_rounded,
              color: AppColors.red,
              subtitle: 'Ends the preview and returns to sign-in',
              onTap: _logOut),
        ]),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/segmented_pills.dart';

/// Settings pop-up content (spec §11), shared by both roles: grouped,
/// rounded inset lists in Luma's style. Unbuilt items open placeholders.
class SettingsSheet extends StatefulWidget {
  final UserService userService;

  const SettingsSheet({super.key, required this.userService});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _switching = false;

  void _openSoon(String what) {
    final router = GoRouter.of(context);
    router.pop(); // close the pop-up first
    router.push(Uri(path: '/profile/soon', queryParameters: {'what': what}).toString());
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
        _Group([
          _Row('Personal Information', Icons.person_outline_rounded,
              onTap: () => _openSoon('Personal Information')),
          _Row('Account & Security', Icons.lock_outline_rounded,
              onTap: () => _openSoon('Account & Security')),
          _Row('Notifications', Icons.notifications_none_rounded,
              onTap: () => _openSoon('Notifications')),
        ]),
        const SizedBox(height: AppSpacing.md),
        _Group([
          _Row('Help & Support', Icons.help_outline_rounded,
              onTap: () => _openSoon('Help & Support')),
          _Row('About Michaelean', Icons.info_outline_rounded,
              onTap: () => _openSoon('About Michaelean')),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text('Preview tools', style: text.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.sm),
        _Group([
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
        _Group([
          _Row('Log Out', Icons.logout_rounded,
              color: AppColors.red,
              subtitle: 'Ends the preview and returns to sign-in',
              onTap: _logOut),
        ]),
      ],
    );
  }
}

/// A rounded, soft-gray group of rows with white dividers (iOS-style inset list).
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group(this.children);

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

class _Row extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? subtitle;

  const _Row(this.label, this.icon,
      {required this.onTap, this.color = AppColors.ink, this.subtitle});

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

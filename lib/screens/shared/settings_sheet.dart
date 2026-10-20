import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session.dart';
import '../../theme/app_theme.dart';

/// Settings pop-up content (spec §11), shared by both roles.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static const _items = [
    ('Personal Information', Icons.person_outline_rounded),
    ('Account & Security', Icons.lock_outline_rounded),
    ('Notifications', Icons.notifications_none_rounded),
    ('Help & Support', Icons.help_outline_rounded),
    ('About Michaelean', Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        for (final (label, icon) in _items)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            leading: Icon(icon, color: AppColors.ink),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            onTap: () {
              router.pop(); // close the pop-up first
              router.push(
                  Uri(path: '/profile/soon', queryParameters: {'what': label}).toString());
            },
          ),
        const Divider(height: AppSpacing.lg),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          leading: const Icon(Icons.logout_rounded, color: AppColors.red),
          title: const Text('Log Out', style: TextStyle(color: AppColors.red)),
          // No real account in the prototype: logging out ends the preview.
          subtitle: const Text('Ends the preview and returns to the role picker'),
          onTap: () {
            final session = SessionScope.of(context); // read before the sheet closes
            router.pop();
            session.endPreview();
          },
        ),
      ],
    );
  }
}

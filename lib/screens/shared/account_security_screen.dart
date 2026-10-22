import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// Account & Security (spec §11): an honest status page. Sign-in will be the
/// school's Microsoft 365 account (spec §4); in this prototype nothing is
/// connected, so there's nothing to change here yet.
class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Account & Security'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                children: [
                  Text('Sign-in', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  InsetGroup([
                    InsetField('Account', 'School Microsoft 365 account', Icons.account_circle_outlined),
                    const InsetField(
                        'Status', 'Not connected in this preview', Icons.link_off_rounded),
                    InsetField(
                      'This session',
                      'Preview as ${user.role == UserRole.student ? 'Student' : 'Teacher'} '
                          '· sample data',
                      Icons.visibility_outlined,
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Passwords and two-step verification will be managed by your Microsoft '
                    '365 account, not in Michaelean.',
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Your QR code', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  InsetGroup([
                    const InsetField('What it holds', 'A random sample code, never personal data',
                        Icons.qr_code_2_rounded),
                    InsetRow('Show my QR', Icons.qr_code_rounded, onTap: () => context.push('/qr')),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Showing your QR doesn't verify your identity, record attendance, or "
                    'clear anything by itself. Staff record those.',
                    style: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

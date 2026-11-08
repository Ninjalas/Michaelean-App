import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// Account & Security (spec §11): an honest status page. A test account
/// (docs/backend-plan.md) can change its password here; the sample preview
/// has nothing to change. Microsoft 365 sign-in (spec §4) comes later.
class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
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
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  120,
                ),
                children: [
                  Text('Sign-in', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  if (session.isSignedIn) ...[
                    InsetGroup([
                      InsetField('Account', user.email, Icons.account_circle_outlined),
                      const InsetField(
                        'Type',
                        'Test account · department trial',
                        Icons.science_outlined,
                      ),
                      InsetRow(
                        'Change password',
                        Icons.password_rounded,
                        onTap: () => context.push('/profile/security/password'),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This test account is separate from your Microsoft 365 account. '
                      'Changing this password doesn\'t change your Microsoft one.',
                      style: muted,
                    ),
                  ] else ...[
                    InsetGroup([
                      InsetField(
                        'Account',
                        'School Microsoft 365 account',
                        Icons.account_circle_outlined,
                      ),
                      const InsetField(
                        'Status',
                        'Not connected in this preview',
                        Icons.link_off_rounded,
                      ),
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
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text('Your QR code', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  InsetGroup([
                    const InsetField(
                      'What it holds',
                      'A random sample code, never personal data',
                      Icons.qr_code_2_rounded,
                    ),
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

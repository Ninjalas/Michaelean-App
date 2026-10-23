import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// Personal Information (spec §11): read-only. These come from school
/// records, and the app can't change them (spec §10). IDs stay masked.
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final isStudent = user.role == UserRole.student;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Personal Information'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                children: [
                  InsetGroup([
                    InsetField('Name', user.fullName, Icons.person_outline_rounded),
                    InsetField('Role', isStudent ? 'Student' : 'Teacher', Icons.badge_outlined),
                    InsetField(isStudent ? 'Program' : 'Faculty', user.designation,
                        Icons.school_outlined),
                    InsetField(isStudent ? 'Student ID' : 'Employee ID', user.maskedId,
                        Icons.tag_rounded),
                    InsetField('School email', user.email, Icons.mail_outline_rounded),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Official tags', style: text.labelMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.sm),
                  InsetGroup([
                    for (final t in user.tags) InsetField(_kind(t.kind), t.label, _icon(t.kind)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "These come from school records and can't be changed in the app. To "
                    "correct something, contact the Registrar's Office (see Help & Support).",
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Sample data for the prototype. The ID is masked on purpose.', style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _kind(TagKind k) => switch (k) {
        TagKind.institution => 'Institution',
        TagKind.school => 'School',
        TagKind.department => 'Department',
        TagKind.organization => 'Organization',
        TagKind.officer => 'Officer role',
        TagKind.role => 'Assigned role',
      };

  static IconData _icon(TagKind k) => switch (k) {
        TagKind.institution => Icons.account_balance_outlined,
        TagKind.school => Icons.school_outlined,
        TagKind.department => Icons.apartment_outlined,
        TagKind.organization => Icons.groups_outlined,
        TagKind.officer => Icons.workspace_premium_outlined,
        TagKind.role => Icons.verified_user_outlined,
      };
}

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/segmented_pills.dart';

/// Sign-in preview (spec §1.1, §4). Shows where Microsoft 365 sign-in will
/// go and lets you pick a mock student or teacher. It is not authentication.
class PreviewScreen extends StatefulWidget {
  final UserService userService;

  const PreviewScreen({super.key, required this.userService});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  UserRole _role = UserRole.student;
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final user = await widget.userService.loadPreviewUser(_role);
    if (!mounted) return;
    SessionScope.of(context).startPreview(user);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Hero(
                tag: 'smcl-emblem', // glides in from the opening intro
                child: Image.asset('assets/images/SMCL_Emblem.png', height: 128,
                    semanticLabel: "Saint Michael's College of Laguna emblem"),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Michaelean', textAlign: TextAlign.center, style: text.displaySmall),
              const SizedBox(height: AppSpacing.xs),
              Text("Saint Michael's College of Laguna",
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: AppColors.muted)),
              const Spacer(),
              Text('Preview as', style: text.labelMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.sm),
              SegmentedPills<UserRole>(
                segments: const [(UserRole.student, 'Student'), (UserRole.teacher, 'Teacher')],
                selected: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loading ? null : _signIn,
                child: const Text('Sign in with Microsoft (preview)'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Preview only. This does not sign you in, and it uses sample data, '
                  'not official school records.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

/// Development-only role picker. Stands in for Microsoft 365 sign-in
/// during the frontend phase. It is not authentication.
class PreviewScreen extends StatefulWidget {
  final UserService userService;

  const PreviewScreen({super.key, required this.userService});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _loading = false;

  Future<void> _preview(UserRole role) async {
    setState(() => _loading = true);
    final user = await widget.userService.loadPreviewUser(role);
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
            children: [
              const Spacer(),
              Image.asset('assets/images/SMCL_Emblem.png', height: 120,
                  semanticLabel: "Saint Michael's College of Laguna emblem"),
              const SizedBox(height: AppSpacing.lg),
              Text('Michaelean', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text("Saint Michael's College of Laguna",
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text('Development preview — not a sign-in. Uses mock data.',
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(color: AppColors.muted)),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : () => _preview(UserRole.student),
                  child: const Text('Preview as Student'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _preview(UserRole.teacher),
                  child: const Text('Preview as Teacher'),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
            ],
          ),
        ),
      ),
    );
  }
}

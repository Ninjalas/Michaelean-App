import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// About Michaelean (spec §11): what the app is, its prototype status, and
/// the open-source licenses it ships with.
class AboutScreen extends StatelessWidget {
  /// Keep in step with `version:` in pubspec.yaml.
  static const version = '0.1.0';

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('About Michaelean'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Image.asset('assets/images/SMCL_Emblem.png', height: 96,
                      semanticLabel: "Saint Michael's College of Laguna emblem"),
                  const SizedBox(height: AppSpacing.md),
                  Text('Michaelean', textAlign: TextAlign.center, style: text.headlineMedium),
                  Text("Saint Michael's College of Laguna",
                      textAlign: TextAlign.center, style: muted),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Version $version · Prototype', textAlign: TextAlign.center, style: muted),
                  const SizedBox(height: AppSpacing.section),
                  Text(
                    'Campus life in one app for students and teachers: schedules, '
                    'attendance, events, organizations, clearance, and notifications.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  InsetGroup([
                    const InsetField('Status', 'Frontend prototype', Icons.science_outlined),
                    const InsetField(
                        'Data', 'Sample data, not official school records', Icons.dataset_outlined),
                    const InsetField('Sign-in', 'Preview only; Microsoft 365 comes later',
                        Icons.login_rounded),
                    InsetRow(
                      'Open-source licenses',
                      Icons.description_outlined,
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Michaelean',
                        applicationVersion: '$version (prototype)',
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  Text('Built with Flutter. Fonts: Inter and Inter Display (SIL Open Font '
                      'License).', style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

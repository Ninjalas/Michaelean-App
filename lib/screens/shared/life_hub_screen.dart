import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_row.dart';
import '../../widgets/section_header.dart';

/// The feature hub tab: Student Life for students (spec §7), Michaelean Life
/// for teachers (spec §9). Feature screens themselves come in Phase 5.
class LifeHubScreen extends StatelessWidget {
  const LifeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final isStudent = user.role == UserRole.student;

    void open(String what) => context
        .push(Uri(path: '/life/soon', queryParameters: {'what': what}).toString());

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 120),
        children: [
          Text(isStudent ? 'Student Life' : 'Michaelean Life', style: text.headlineMedium),
          if (isStudent) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Your campus, beyond the classroom.',
                style: text.bodyLarge?.copyWith(color: AppColors.muted)),
            const SectionHeader('Explore'),
            _EventsCard(onTap: () => open('Events')),
            const SectionHeader('Your Student Life'),
            ..._rows([
              _Feature('Class', 'Schedule, attendance, and your QR', Icons.class_outlined),
              _Feature('Organizations', 'Your society and campus clubs', Icons.groups_outlined),
              _Feature('Clearance', 'Requirements and status', Icons.task_alt_outlined),
            ], open),
          ] else ...[
            const SectionHeader('Teaching & Campus'),
            ..._rows([
              _Feature('Class Management', 'Classes, attendance, and schedules',
                  Icons.class_outlined,
                  allowed: user.can(Permission.manageAssignedClasses),
                  deniedReason: 'No classes are assigned to you.'),
              _Feature('Events', 'Create and manage events', Icons.event_outlined,
                  allowed: user.can(Permission.manageEvents),
                  deniedReason: "You aren't an authorized event manager."),
              _Feature('Clearance', 'Verify student requirements', Icons.task_alt_outlined,
                  allowed: user.can(Permission.processClearance),
                  deniedReason: "You aren't assigned to a clearance area."),
            ], open),
          ],
        ],
      ),
    );
  }

  List<Widget> _rows(List<_Feature> features, void Function(String) open) => [
        for (var i = 0; i < features.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: ContentRow.textIndent),
          ContentRow(
            title: features[i].title,
            // Unauthorized features stay visible but disabled, with the reason.
            meta: features[i].allowed ? features[i].subtitle : features[i].deniedReason,
            metaIcon: features[i].allowed ? null : Icons.lock_outline_rounded,
            placeholderIcon: features[i].icon,
            onTap: features[i].allowed ? () => open(features[i].title) : null,
          ),
        ],
      ];
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool allowed;
  final String? deniedReason;

  const _Feature(this.title, this.subtitle, this.icon,
      {this.allowed = true, this.deniedReason});
}

/// The slightly more prominent Events entry in Student Life's Explore section.
class _EventsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EventsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Row(
            children: [
              const Icon(Icons.event_outlined, size: 32, color: AppColors.navy),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Events', style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text("See what's happening on campus",
                        style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

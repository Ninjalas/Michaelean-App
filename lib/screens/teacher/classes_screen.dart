import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';

/// The teacher's assigned classes (spec §9.1). Each opens its class page.
class ClassesScreen extends StatefulWidget {
  final CampusService campusService;

  const ClassesScreen({super.key, required this.campusService});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  Future<List<ClassInfo>>? _classes;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _classes = widget.campusService.loadAssignedClasses(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackHeader('Classes'),
            Expanded(
              child: !user.can(Permission.manageAssignedClasses)
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text('No classes are assigned to you.',
                          style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                    )
                  : FutureBuilder<List<ClassInfo>>(
                      future: _classes,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(child: Text("Couldn't load your classes."));
                        }
                        final classes = snap.data;
                        if (classes == null) return const LinearProgressIndicator();
                        if (classes.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.screen),
                            child: Text('No classes are assigned to you.',
                                style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen, 0, AppSpacing.screen, 120),
                          itemCount: classes.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = classes[i];
                            return ContentRow(
                              source: c.section,
                              title: c.subject,
                              meta: '${c.weekdays.map(weekdayShort).join(' · ')}, '
                                  '${formatMinutesRange(c.startMinute, c.endMinute)}',
                              metaIcon: Icons.schedule_rounded,
                              onTap: () => context.push('/life/classes/${c.id}'),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

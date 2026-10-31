import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/consultation.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/pressable.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/surface_card.dart';

/// Consultations (decided 2026-10-30): a teacher's own consultation forms,
/// or, for a student, the ones held with them (read-only). Newest first.
class ConsultationsScreen extends StatefulWidget {
  final CampusService campusService;

  const ConsultationsScreen({super.key, required this.campusService});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  Future<List<Consultation>>? _list;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload after a save (Session.refresh changes the key).
    final session = SessionScope.of(context);
    if (session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _list = widget.campusService.loadConsultations(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final isTeacher = user.role == UserRole.teacher;
    final mayHold = user.can(Permission.holdConsultations);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackHeader(
              'Consultations',
              trailing: mayHold
                  ? RoundIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'New consultation',
                      onPressed: () => context.push('/life/consultations/new'),
                    )
                  : null,
            ),
            Expanded(
              child: FutureBuilder<List<Consultation>>(
                future: _list,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text("Couldn't load consultations.", style: muted),
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      Text(
                        isTeacher
                            ? 'Only you and the student see a consultation. Sample records.'
                            : 'Consultations your teachers held with you. Only you and that '
                                'teacher see them. Sample records.',
                        style: text.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (list.isEmpty)
                        Text(
                            isTeacher
                                ? 'No consultations yet. Tap + to start one.'
                                : 'No consultations yet.',
                            style: muted)
                      else
                        SurfaceCard(children: [
                          for (final c in list) _row(c, isTeacher),
                        ]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Consultation c, bool isTeacher) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => context.push('/life/consultations/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isTeacher ? c.studentName : c.teacherName, style: text.titleMedium),
                  Text(c.rows.first.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${formatDate(c.heldAt)} · ${formatTime(c.heldAt)}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            if (!c.studentSigned) ...[
              const SizedBox(width: AppSpacing.sm),
              const StatusPill('Not signed', tone: PillTone.amber),
            ],
          ],
        ),
      ),
    );
  }
}

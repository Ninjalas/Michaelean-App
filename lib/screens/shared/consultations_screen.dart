import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/consultation.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/consultation_export_buttons.dart';
import '../../widgets/pressable.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/surface_card.dart';

/// Consultations (decided 2026-10-30): a teacher's own consultation forms,
/// or, for a student, the ones held with them (read-only). Newest first.
/// A teacher can Select signed ones and export them together, two per A4
/// page (decided 2026-10-31).
class ConsultationsScreen extends StatefulWidget {
  final CampusService campusService;

  const ConsultationsScreen({super.key, required this.campusService});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  Future<List<Consultation>>? _list;
  String? _loadedFor;
  Set<String>? _picked; // ids ticked in Select mode; null when not selecting

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
              trailing: !mayHold
                  ? null
                  : _picked != null
                      ? TextButton(
                          onPressed: () => setState(() => _picked = null),
                          child: const Text('Cancel'))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          TextButton(
                              onPressed: () => setState(() => _picked = {}),
                              child: const Text('Select')),
                          RoundIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'New consultation',
                            onPressed: () => context.push('/life/consultations/new'),
                          ),
                        ]),
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
                  final picked = _picked;
                  final chosen = [
                    if (picked != null)
                      for (final c in list)
                        if (picked.contains(c.id)) c,
                  ];
                  final pages = (chosen.length + 1) ~/ 2;
                  final listView = ListView(
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, picked == null ? 120 : AppSpacing.lg),
                    children: [
                      if (picked != null) ...[
                        Text(
                          'Tick signed consultations to export them, two forms per A4 page, '
                          'oldest first.',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
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
                  if (picked == null) return listView;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: listView),
                      Padding(
                        // Clear of the floating nav bar.
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              chosen.isEmpty
                                  ? 'None selected'
                                  : '${chosen.length} selected · $pages ${pages == 1 ? 'page' : 'pages'}',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ConsultationExportButtons(chosen.isEmpty ? null : chosen),
                          ],
                        ),
                      ),
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
    final picked = _picked;
    // Only signed ones can be exported, so only they can be ticked.
    void toggle() => setState(() => picked!.contains(c.id) ? picked.remove(c.id) : picked.add(c.id));
    return Pressable(
      onTap: picked == null
          ? () => context.push('/life/consultations/${c.id}')
          : c.studentSigned
              ? toggle
              : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            if (picked != null) ...[
              Checkbox(
                value: picked.contains(c.id),
                onChanged: c.studentSigned ? (_) => toggle() : null,
                semanticLabel: '${c.studentName}, ${formatDate(c.heldAt)}',
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
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

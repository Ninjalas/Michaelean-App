import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/consultation.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/consultation_export_buttons.dart';
import '../../widgets/post_image.dart';
import '../../widgets/surface_card.dart';

/// One consultation form (decided 2026-10-30), read-only. Its teacher can
/// edit it, have the student sign by showing their QR, and, once signed,
/// export it to PDF or Excel (on the top half of an A4 page); its student
/// only reads it.
class ConsultationDetailScreen extends StatefulWidget {
  final CampusService campusService;
  final String id;

  const ConsultationDetailScreen({super.key, required this.campusService, required this.id});

  @override
  State<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  Future<Consultation?>? _c;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _c = widget.campusService.loadConsultation(session.user!, widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Consultation?>(
          future: _c,
          builder: (context, snap) {
            final c = snap.data;
            final mine = c != null && c.teacherId == user.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Consultation'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError || c == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        snap.hasError
                            ? "Couldn't load this consultation."
                            : "This consultation isn't available.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                      children: [
                        SurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c.studentName} · ${c.studentSection}',
                                  style: text.titleMedium),
                              Text(c.studentMaskedId, style: muted),
                              const SizedBox(height: AppSpacing.sm),
                              Text('${formatDate(c.heldAt)} · ${formatTime(c.heldAt)}'),
                              Text('${c.department} · ${c.venue}'),
                              Text('With ${c.teacherName}', style: muted),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final (i, r) in c.rows.indexed) ...[
                          SurfaceCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reason ${c.rows.length > 1 ? i + 1 : ''}'.trim(),
                                    style: label),
                                Text(r.reason),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Intervention made', style: label),
                                Text(r.intervention.isEmpty ? '—' : r.intervention),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Text('Expected outcome', style: label),
                        const SizedBox(height: AppSpacing.xs),
                        Text(c.expectedOutcome.isEmpty ? '—' : c.expectedOutcome),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _signature('Student', c.studentName, c.studentSignature,
                                  c.studentSigned ? 'No e-signature on file' : 'Not yet signed'),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _signature('Instructor', c.teacherName, c.teacherSignature,
                                  'No e-signature on file'),
                            ),
                          ],
                        ),
                        if (c.editedAfterSigning) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text('Edited after the student signed.', style: muted),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text('Sample record in this preview, not an official school record.',
                            style: muted),
                      ],
                    ),
                  ),
                  if (mine)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!c.studentSigned) ...[
                            FilledButton.icon(
                              onPressed: () => context.push('/life/consultations/${c.id}/scan'),
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text('Scan QR to Sign'),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          OutlinedButton(
                            onPressed: () => context.push('/life/consultations/${c.id}/edit'),
                            child: const Text('Edit'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ConsultationExportButtons(c.studentSigned ? [c] : null),
                          if (!c.studentSigned) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text('The student signs first (Scan QR to Sign).',
                                textAlign: TextAlign.center, style: muted),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// A signature box: the uploaded picture above the signer's name.
  Widget _signature(String role, String name, String? photo, String missing) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$role signature', style: text.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 72,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.hairline),
          ),
          child: photo == null
              ? Text(missing,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.muted))
              : Semantics(
                  image: true,
                  label: "$name's e-signature",
                  child: PostImage(photo, fit: BoxFit.contain),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(name, style: text.bodyMedium),
      ],
    );
  }
}

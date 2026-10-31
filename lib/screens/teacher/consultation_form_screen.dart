import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/consultation.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/surface_card.dart';

/// Fill in or edit a consultation form (decided 2026-10-30): paired
/// reason/intervention rows (up to 5), then the expected outcome. A new form
/// is for [studentId]; [scanned] means the student showed their QR, so their
/// e-signature is added on save. With [id], edits that form (anytime).
class ConsultationFormScreen extends StatefulWidget {
  final CampusService campusService;
  final String? id;
  final String? studentId;
  final bool scanned;

  const ConsultationFormScreen({
    super.key,
    required this.campusService,
    this.id,
    this.studentId,
    this.scanned = false,
  });

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

/// One table row's two boxes.
typedef _Row = ({TextEditingController reason, TextEditingController intervention});

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  Future<bool>? _ready; // true → the form may be shown
  Consultation? _old;
  OrgMember? _student;
  final _rows = <_Row>[];
  final _outcome = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready ??= _load();
  }

  _Row _newRow([ConsultationRow? r]) => (
        reason: TextEditingController(text: r?.reason),
        intervention: TextEditingController(text: r?.intervention),
      );

  Future<bool> _load() async {
    final user = SessionScope.of(context).user!;
    final s = widget.campusService;
    if (widget.id != null) {
      _old = await s.loadConsultation(user, widget.id!);
      if (_old == null || _old!.teacherId != user.id) return false;
      _rows.addAll(_old!.rows.map(_newRow));
      _outcome.text = _old!.expectedOutcome;
      return true;
    }
    _student = (await s.findStudents(user, '')).where((m) => m.id == widget.studentId).firstOrNull;
    _rows.add(_newRow());
    return _student != null;
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.reason.dispose();
      r.intervention.dispose();
    }
    _outcome.dispose();
    super.dispose();
  }

  String? get _problem {
    final filled = _rows.where((r) => r.reason.text.trim().isNotEmpty);
    if (filled.isEmpty) return 'Add at least one reason.';
    if (_rows.any((r) => r.reason.text.trim().isEmpty && r.intervention.text.trim().isNotEmpty)) {
      return 'Every intervention needs its reason.';
    }
    return null;
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final Consultation saved;
    try {
      saved = await widget.campusService.saveConsultation(
        session.user!,
        id: _old?.id,
        studentId: _old?.studentId ?? _student!.id,
        rows: [for (final r in _rows) (reason: r.reason.text, intervention: r.intervention.text)],
        expectedOutcome: _outcome.text,
        scanned: widget.scanned,
      );
    } catch (e) {
      // Never claim success when the save failed.
      final reason = e is ArgumentError ? '${e.message}' : e is StateError ? e.message : null;
      if (mounted) setState(() => _error = 'Not saved. ${reason ?? "Couldn't reach the service."}');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    session.refresh();
    if (_old != null) {
      router.pop();
    } else {
      // Michaelean Life › Consultations › the new form, with the scanner gone.
      router.go('/life/consultations/${saved.id}');
    }
    messenger.showSnackBar(SnackBar(
      content: Text(_old != null
          ? 'Changes saved in this preview only.'
          : saved.studentSigned
              ? 'Saved and signed in this preview only.'
              : widget.scanned
                  ? 'Saved in this preview only. Not signed: ${saved.studentName} needs to add '
                      'an e-signature first.'
                  : 'Saved in this preview only. Not signed yet: the student shows their QR '
                      'to sign.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _ready,
          builder: (context, snap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(widget.id == null ? 'Consultation Form' : 'Edit Consultation'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError || snap.data != true)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        snap.hasError
                            ? "Couldn't load this form."
                            : widget.id == null
                                ? "This student isn't available."
                                : "You can't edit this consultation.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(child: _form()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: !_saving && _problem == null ? _save : null,
                      child: Text(_saving ? 'Saving…' : widget.id == null ? 'Save' : 'Save Changes'),
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

  Widget _form() {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    final old = _old;
    final name = old?.studentName ?? _student!.name;
    final section = old?.studentSection ?? _student!.section;
    final maskedId = old?.studentMaskedId ?? _student!.maskedId;
    final when = old?.heldAt ?? DateTime.now();
    final signedNote = old != null
        ? old.studentSigned
            ? 'Signed by the student. Changes now show "Edited after the student signed".'
            : 'Not signed yet: the student shows their QR on the saved form.'
        : widget.scanned
            ? "QR scanned: $name's e-signature is added when you save, if they have one on file."
            : 'Not signed yet: the student shows their QR on the saved form.';
    final problem = _problem;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name · $section', style: text.titleMedium),
              Text(maskedId, style: muted),
              const SizedBox(height: AppSpacing.sm),
              Text('${formatDate(when)} · ${formatTime(when)}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final (i, r) in _rows.indexed) ...[
          Row(
            children: [
              Expanded(child: Text('Reason ${i + 1}', style: label)),
              if (_rows.length > 1)
                IconButton(
                  tooltip: 'Remove reason ${i + 1}',
                  onPressed: () => setState(() {
                    final gone = _rows.removeAt(i);
                    gone.reason.dispose();
                    gone.intervention.dispose();
                  }),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
            ],
          ),
          TextField(
            controller: r.reason,
            onChanged: (_) => setState(() {}),
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Reason for consultation', counterText: ''),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: r.intervention,
            onChanged: (_) => setState(() {}),
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Intervention made', counterText: ''),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_rows.length < maxConsultationRows)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(_newRow())),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add reason (${_rows.length} of $maxConsultationRows)'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text('Expected outcome', style: label),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _outcome,
          minLines: 2,
          maxLines: 5,
          maxLength: 500,
          decoration:
              const InputDecoration(hintText: 'What should happen next?', counterText: ''),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Signatures', style: label),
        const SizedBox(height: AppSpacing.xs),
        Text(signedNote, style: muted),
        const SizedBox(height: AppSpacing.xs),
        Text(
            old != null
                ? 'Your signature from when this form was made stays on it.'
                : 'Your e-signature is added as the instructor and stays on this form.',
            style: muted),
        if (_error != null || problem != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error ?? problem!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

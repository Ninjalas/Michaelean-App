import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/clearance_widgets.dart';
import '../../widgets/user_avatar.dart';

/// One student at the clearance desk (spec §9.3): identification, this
/// office's requirements, and an explicit outcome with a reason. Saved in
/// this preview only; never an official record.
class ClearanceCaseScreen extends StatefulWidget {
  final CampusService campusService;
  final String studentId;

  const ClearanceCaseScreen({super.key, required this.campusService, required this.studentId});

  @override
  State<ClearanceCaseScreen> createState() => _ClearanceCaseScreenState();
}

class _ClearanceCaseScreenState extends State<ClearanceCaseScreen> {
  static const _outcomes = [
    (ClearanceStatus.cleared, 'Cleared'),
    (ClearanceStatus.needsCorrection, 'Needs Correction'),
    (ClearanceStatus.onHold, 'On Hold'),
  ];

  Future<ClearanceCase?>? _data;
  final _reason = TextEditingController();
  String? _itemId;
  ClearanceStatus? _outcome;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= widget.campusService
        .loadClearanceCase(SessionScope.of(context).user!, widget.studentId)
        .then((c) {
      // Start on the first requirement waiting for review.
      final first = c?.items.where((i) => i.status == ClearanceStatus.inReview).firstOrNull ??
          c?.items.firstOrNull;
      if (mounted && first != null) setState(() => _itemId = first.id);
      return c;
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Why the outcome can't be recorded yet, or null.
  String? get _problem {
    if (_itemId == null) return 'Pick a requirement.';
    if (_outcome == null) return 'Pick an outcome.';
    if (_outcome != ClearanceStatus.cleared && _reason.text.trim().isEmpty) {
      return 'Give a reason so the student knows what to fix.';
    }
    return null;
  }

  Future<void> _record(ClearanceCase c) async {
    final item = c.items.firstWhere((i) => i.id == _itemId);
    final label = _outcomes.firstWhere((o) => o.$1 == _outcome).$2;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record $label?'),
        content: Text('${item.title} for ${c.student.name}. This saves in this preview only. '
            "It isn't an official clearance record, and the student isn't notified."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Record')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.campusService.recordOutcome(
          session.user!, widget.studentId, item.id, _outcome!,
          reason: _reason.text);
    } catch (e) {
      // Never claim success when the save failed.
      final why = e is StateError ? e.message : e is ArgumentError ? '${e.message}' : null;
      if (mounted) setState(() => _error = 'Not recorded. ${why ?? "Couldn't reach the service."}');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh(); // after closing (see AttendanceReviewScreen._finalize)
    messenger.showSnackBar(const SnackBar(
      content: Text('Recorded in this preview only. Not an official clearance record.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ClearanceCase?>(
          future: _data,
          builder: (context, snap) {
            final c = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Verify Requirement'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("Couldn't load this student's clearance.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else if (c == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("You can't process this student's clearance.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(child: _form(c)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: _saving || _problem != null ? null : () => _record(c),
                      child: Text(_saving ? 'Recording…' : 'Record Outcome'),
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

  Widget _form(ClearanceCase c) {
    final text = Theme.of(context).textTheme;
    final s = c.student;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
      children: [
        Row(
          children: [
            UserAvatar(name: s.name, imageAsset: s.photoAsset, size: 56),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: text.titleLarge),
                  Text('${s.maskedId} · ${s.section}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
        _label('Requirement'),
        if (c.items.isEmpty)
          Text('This student has no requirements for your office.',
              style: text.bodyLarge?.copyWith(color: AppColors.muted)),
        RadioGroup<String>(
          groupValue: _itemId,
          onChanged: (id) => setState(() => _itemId = id),
          child: Column(
            children: [
              for (final i in c.items)
                RadioListTile<String>(
                  value: i.id,
                  contentPadding: EdgeInsets.zero,
                  title: Text(i.title),
                  subtitle: Align(alignment: Alignment.centerLeft, child: clearancePill(i.status)),
                ),
            ],
          ),
        ),
        _label('Outcome'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (value, label) in _outcomes)
              ChoiceChip(
                label: Text(label),
                selected: _outcome == value,
                showCheckmark: false,
                selectedColor: AppColors.navy,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _outcome == value ? AppColors.white : AppColors.ink,
                ),
                onSelected: (_) => setState(() => _outcome = value),
              ),
          ],
        ),
        _label(_outcome == ClearanceStatus.cleared ? 'Notes (optional)' : 'Reason'),
        TextField(
          controller: _reason,
          minLines: 2,
          maxLines: 5,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. Receipt photo is unreadable'),
        ),
        if (_error != null || (_outcome != null && _problem != null))
          Text(_error ?? _problem!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Check the records or documents before you record an outcome. A scan alone '
          'never clears a requirement.',
          style: text.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
      );
}

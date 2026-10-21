import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';

/// Change one session's time or room (spec §9.1). Mock assumption for open
/// decisions 1 and 3: assigned teachers may change a single session of their
/// own classes; recurring changes aren't offered. Saving changes this
/// preview only and notifies no one, and the confirmation says so.
class EditSessionScreen extends StatefulWidget {
  final CampusService campusService;
  final String sessionId;

  const EditSessionScreen({super.key, required this.campusService, required this.sessionId});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  Future<SessionAttendance?>? _load;
  final _room = TextEditingController();
  final _reason = TextEditingController();
  TimeOfDay? _start, _end;
  DateTime? _day;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= widget.campusService
        .loadSessionAttendance(SessionScope.of(context).user!, widget.sessionId)
        .then((a) {
      if (a != null && mounted) {
        final s = a.session;
        setState(() {
          _day = DateTime(s.start.year, s.start.month, s.start.day);
          _start = TimeOfDay.fromDateTime(s.start);
          _end = TimeOfDay.fromDateTime(s.end);
          _room.text = s.room;
        });
      }
      return a;
    });
  }

  @override
  void dispose() {
    _room.dispose();
    _reason.dispose();
    super.dispose();
  }

  DateTime _on(TimeOfDay t) => _day!.add(Duration(hours: t.hour, minutes: t.minute));

  /// The problem with the form, or null when it can be saved.
  String? get _invalid {
    if (_start == null || _end == null) return null;
    if (!_on(_end!).isAfter(_on(_start!))) return 'The class must end after it starts.';
    if (_room.text.trim().isEmpty) return 'Enter a room.';
    return null;
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
        context: context, initialTime: (isStart ? _start : _end) ?? TimeOfDay.now());
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.campusService.updateSession(
        session.user!,
        widget.sessionId,
        start: _on(_start!),
        end: _on(_end!),
        room: _room.text,
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      );
    } catch (_) {
      // Never claim success when the save failed.
      if (mounted) setState(() => _error = "Couldn't save the change. Nothing was changed.");
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh(); // after closing (see AttendanceReviewScreen._finalize)
    messenger.showSnackBar(const SnackBar(
      content: Text('Change saved in this preview only. Students were not notified.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<SessionAttendance?>(
          future: _load,
          builder: (context, snap) {
            final a = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Change Session'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (a == null || _day == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("You can't edit this class.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      children: [
                        Text(a.session.subject, style: text.titleMedium),
                        Text('This session only · ${weekdayName(_day!)}, ${formatDayMonth(_day!)}',
                            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(child: _timeField('Starts', _start!, () => _pick(true))),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _timeField('Ends', _end!, () => _pick(false))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Room', style: label),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(controller: _room, onChanged: (_) => setState(() {})),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Reason (optional)', style: label),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _reason,
                          maxLength: 120,
                          decoration: const InputDecoration(hintText: 'e.g. Room is under repair'),
                        ),
                        if (_invalid != null || _error != null)
                          Text(_error ?? _invalid!,
                              style: text.bodyMedium?.copyWith(color: AppColors.red)),
                        const SizedBox(height: AppSpacing.sm),
                        Text("Changing every week's session isn't available yet.",
                            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: _saving || _invalid != null ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save Changes'),
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

  Widget _timeField(String label, TimeOfDay t, VoidCallback onTap) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
              child: Row(
                children: [
                  Expanded(child: Text(formatTime(_on(t)), style: text.bodyLarge)),
                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

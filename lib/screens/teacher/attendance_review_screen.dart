import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/section_header.dart';
import '../../widgets/user_avatar.dart';

/// Roster review before finalizing (spec §9.1 steps 4–5). Unchecked students
/// become Absent. In this preview, finalizing isn't an official record, and
/// a failed save never shows success (spec §7.2).
class AttendanceReviewScreen extends StatefulWidget {
  final CampusService campusService;
  final String sessionId;
  final bool fromScanner; // close the scanner too after finalizing

  const AttendanceReviewScreen({
    super.key,
    required this.campusService,
    required this.sessionId,
    this.fromScanner = false,
  });

  @override
  State<AttendanceReviewScreen> createState() => _AttendanceReviewScreenState();
}

class _AttendanceReviewScreenState extends State<AttendanceReviewScreen> {
  Future<SessionAttendance?>? _att;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _att ??= widget.campusService
        .loadSessionAttendance(SessionScope.of(context).user!, widget.sessionId);
  }

  Future<void> _finalize() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.campusService.finalizeSession(session.user!, widget.sessionId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't finalize. Nothing was saved. Try again.";
        });
      }
      return;
    }
    router.pop(); // this review
    if (widget.fromScanner) router.pop(); // and the scanner under it
    // Refresh after closing: the router listens to the session too, and a
    // refresh before the pops would rebuild the screens being closed.
    session.refresh(); // Home's task and the class page update
    messenger.showSnackBar(const SnackBar(
      content: Text('Attendance finalized in this preview only. Not an official record.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<SessionAttendance?>(
          future: _att,
          builder: (context, snap) {
            final a = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Review Attendance'),
                if (snap.hasError)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.screen),
                    child: Text("Couldn't load this session."),
                  )
                else if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (a == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text("You can't review this class.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(child: _body(a)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Text(_error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        FilledButton(
                          onPressed: a.session.finalized || _saving ? null : _finalize,
                          child: Text(a.session.finalized
                              ? 'Already finalized'
                              : _saving
                                  ? 'Finalizing…'
                                  : 'Confirm finalization'),
                        ),
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

  Widget _body(SessionAttendance a) {
    final text = Theme.of(context).textTheme;
    final s = a.session;
    final unchecked = a.unchecked;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        Text(s.subject, style: text.titleMedium),
        Text('${s.section} · ${weekdayName(s.start)}, ${formatDayMonth(s.start)} · '
            '${formatTime(s.start)}',
            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.lg),
        Text.rich(TextSpan(style: text.bodyLarge, children: [
          TextSpan(
              text: '${a.presentCount} ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const TextSpan(text: 'present  ·  '),
          TextSpan(
              text: '${a.uncheckedCount} ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const TextSpan(text: 'unchecked'),
        ])),
        const SizedBox(height: AppSpacing.sm),
        Text('Unchecked students will be marked Absent when you finalize.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
        const SectionHeader('Unchecked'),
        if (unchecked.isEmpty)
          Text('Everyone was scanned.', style: text.bodyLarge?.copyWith(color: AppColors.muted))
        else
          for (var i = 0; i < unchecked.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 40 + AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  UserAvatar(
                      name: unchecked[i].name, imageAsset: unchecked[i].photoAsset, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(unchecked[i].name, style: text.bodyLarge)),
                  Text(unchecked[i].maskedId,
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

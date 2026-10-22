import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/user_avatar.dart';

/// Event check-in for its managers, like the class scanner (spec §9.1).
/// MOCK: no camera is used. Only registered students are marked; finalizing
/// adds an Attended record to each scanned student's Event History, in this
/// preview only. Nothing here verifies identity or saves an official record.
class EventCheckInScreen extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const EventCheckInScreen({super.key, required this.campusService, required this.eventId});

  @override
  State<EventCheckInScreen> createState() => _EventCheckInScreenState();
}

class _EventCheckInScreenState extends State<EventCheckInScreen> {
  EventCheckIn? _data;
  bool _loaded = false;
  bool _failed = false;
  bool _busy = false;
  bool _previewOpen = false; // preview tool: check in outside the event's hours
  ({ScanOutcome? outcome, RosterStudent? student, String? error})? _flash;
  Timer? _flashTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _reload();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    EventCheckIn? data;
    var failed = false;
    try {
      data = await widget.campusService
          .loadEventCheckIn(SessionScope.of(context).user!, widget.eventId);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _data = data;
      _failed = failed;
      _loaded = true;
    });
  }

  /// Check-in is open from 30 minutes before the start until the end, unless
  /// the preview tool opened it.
  bool get _open {
    final e = _data!.event;
    final now = DateTime.now();
    if (_data!.finalized) return false;
    return _previewOpen ||
        (!now.isBefore(e.start.subtract(const Duration(minutes: 30))) && now.isBefore(e.end));
  }

  Future<void> _scan(String token) async {
    setState(() => _busy = true);
    ({ScanOutcome? outcome, RosterStudent? student, String? error}) flash;
    try {
      final r = await widget.campusService.recordEventScan(
          SessionScope.of(context).user!, widget.eventId, token,
          ignoreClock: _previewOpen);
      flash = (outcome: r.outcome, student: r.student, error: null);
      await _reload();
    } catch (_) {
      flash = (outcome: null, student: null, error: 'Scan failed. Nothing was recorded.');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _flash = flash;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _finalize() async {
    final d = _data!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize attendance?'),
        content: Text('${d.present.length} of ${d.registrants.length} registered students were '
            "scanned. They get an Attended record. Students who weren't scanned get no "
            'record. This saves in this preview only.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalize')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      await widget.campusService.finalizeEventAttendance(session.user!, widget.eventId);
    } catch (_) {
      // Never claim success when it failed.
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't finalize. Nothing was recorded.")));
      return;
    }
    router.pop();
    session.refresh(); // after closing (see AttendanceReviewScreen._finalize)
    messenger.showSnackBar(const SnackBar(
      content: Text('Attendance finalized in this preview only. Not an official record.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator(color: AppColors.white))
            : LayoutBuilder(
                // Fills the screen when it fits; scrolls on short screens or large text.
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: _failed
                          ? _message("Couldn't load check-in. Go back and try again.")
                          : d == null
                              ? _message("You can't take attendance for this event.")
                              : _body(d),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _message(String s) => Column(
        children: [
          _top(null),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Text(s,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      );

  Widget _top(CampusEvent? e) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close check-in',
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: AppSpacing.md),
            if (e != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                    Text('${formatDayMonth(e.start)} · ${formatTime(e.start)} – ${formatTime(e.end)}',
                        style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 14)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _body(EventCheckIn d) {
    final e = d.event;
    final now = DateTime.now();
    return Column(
      children: [
        _top(e),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text('MOCK SCANNER · no camera is used',
              style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.onNavyMuted, width: 2),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: d.finalized
                            ? _note('Attendance for this event is finalized.')
                            : !_open
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _note(now.isBefore(e.start)
                                          ? 'Check-in opens 30 minutes before the event.'
                                          : 'This event has ended. Scans are rejected.'),
                                      const SizedBox(height: AppSpacing.md),
                                      TextButton(
                                        onPressed: () => setState(() => _previewOpen = true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppColors.white),
                                        child: const Text('Open anyway (preview tool)'),
                                      ),
                                    ],
                                  )
                                : d.registrants.isEmpty
                                    ? _note('No registered students to check in.')
                                    : _note("Point at a student's QR code"),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: _flash == null ? const SizedBox.shrink() : _flashCard(_flash!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    // The next registered student who hasn't been scanned.
                    onPressed: _busy || d.unchecked.isEmpty
                        ? null
                        : () => _scan(d.unchecked.first.qrToken),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.white, foregroundColor: AppColors.ink),
                    child: const Text('Simulate scan'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _scan('MOCK-UNKNOWN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.onNavyMuted,
                      side: const BorderSide(color: AppColors.onNavyMuted),
                    ),
                    child: const Text('Unknown code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          margin: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Present ${d.present.length} · Registered ${d.registrants.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: d.finalized || _busy ? null : _finalize,
                style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                child: const Text('Finalize'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _note(String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(s,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white, fontSize: 16)),
      );

  /// The brief result card shown after each scan.
  Widget _flashCard(({ScanOutcome? outcome, RosterStudent? student, String? error}) f) {
    final (String line, Color color) = switch (f.outcome) {
      ScanOutcome.present => ('Present', AppColors.green),
      ScanOutcome.duplicate => ('Already scanned. Counted once.', AppColors.amber),
      ScanOutcome.notEnrolled => ('Not registered for this event. Not marked.', AppColors.red),
      ScanOutcome.notOpenYet => ("Check-in isn't open yet. Not marked.", AppColors.amber),
      ScanOutcome.closed => ('Check-in is closed. Not marked.', AppColors.amber),
      null => (f.error ?? '', AppColors.red),
    };
    return Container(
      key: ValueKey(f),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (f.student != null) ...[
            UserAvatar(name: f.student!.name, imageAsset: f.student!.photoAsset, size: 88),
            const SizedBox(height: AppSpacing.md),
            Text(f.student!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(line,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

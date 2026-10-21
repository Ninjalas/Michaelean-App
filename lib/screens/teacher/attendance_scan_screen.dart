import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/user_avatar.dart';

/// The attendance scanner (spec §9.1), reached only through Start attendance.
/// MOCK: no camera is used. "Simulate scan" buttons stand in for scanning a
/// student's QR, and the attendance rules (spec §7.2) decide each result.
/// Nothing here verifies identity or saves an official record.
class AttendanceScanScreen extends StatefulWidget {
  final CampusService campusService;
  final String sessionId;

  const AttendanceScanScreen({super.key, required this.campusService, required this.sessionId});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  SessionAttendance? _att;
  bool _loaded = false;
  bool _busy = false;
  bool _previewOpen = false; // preview tool: scan outside class hours
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
    final a = await widget.campusService
        .loadSessionAttendance(SessionScope.of(context).user!, widget.sessionId);
    if (!mounted) return;
    setState(() {
      _att = a;
      _loaded = true;
    });
  }

  bool get _open {
    final s = _att!.session;
    final now = DateTime.now();
    if (s.finalized) return false;
    return _previewOpen || (!now.isBefore(s.start) && now.isBefore(s.end));
  }

  Future<void> _scan(String token) async {
    setState(() => _busy = true);
    ({ScanOutcome? outcome, RosterStudent? student, String? error}) flash;
    try {
      final r = await widget.campusService.recordScan(
          SessionScope.of(context).user!, widget.sessionId, token,
          ignoreClock: _previewOpen);
      flash = (outcome: r.outcome, student: r.student, error: null);
      await _reload();
    } catch (_) {
      flash = (outcome: null, student: null, error: 'Scan failed. Nothing was recorded.');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _showFlash(flash);
  }

  /// Shows a result briefly, then the "camera" is ready again (spec §9.1).
  void _showFlash(({ScanOutcome? outcome, RosterStudent? student, String? error}) flash) {
    setState(() => _flash = flash);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  void _scanNext() {
    final next = _att!.unchecked.firstOrNull;
    if (next == null) {
      _showFlash((outcome: null, student: null, error: 'Everyone is checked in.'));
      return;
    }
    _scan(next.qrToken);
  }

  @override
  Widget build(BuildContext context) {
    final a = _att;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator(color: AppColors.white))
            : a == null
                ? _message("You can't take attendance for this class.")
                : _scanner(a),
      ),
    );
  }

  Widget _message(String s) => Column(
        children: [
          _top(null),
          Expanded(
            child: Center(
              child: Text(s, style: const TextStyle(color: AppColors.white, fontSize: 16)),
            ),
          ),
        ],
      );

  Widget _top(SessionAttendance? a) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close scanner',
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: AppSpacing.md),
            if (a != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.session.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(
                        '${a.session.section} · ${formatTime(a.session.start)} – '
                        '${formatTime(a.session.end)}',
                        style: const TextStyle(color: AppColors.onNavyMuted, fontSize: 14)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _scanner(SessionAttendance a) {
    final s = a.session;
    final now = DateTime.now();
    return Column(
      children: [
        _top(a),
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
              padding: const EdgeInsets.all(AppSpacing.screen * 2),
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
                        child: s.finalized
                            ? _note('Attendance for this session is finalized.')
                            : !_open
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _note(now.isBefore(s.start)
                                          ? 'Attendance opens at ${formatTime(s.start)}'
                                              '${_sameDay(s.start, now) ? '' : ' on ${weekdayName(s.start)}'}.'
                                          : 'This session has ended. Scans are rejected.'),
                                      const SizedBox(height: AppSpacing.md),
                                      TextButton(
                                        onPressed: () => setState(() => _previewOpen = true),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.white),
                                        child: const Text('Open anyway (preview tool)'),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.onNavyMuted),
                                      SizedBox(height: AppSpacing.sm),
                                      Text("Point at a student's QR code",
                                          style: TextStyle(color: AppColors.onNavyMuted)),
                                    ],
                                  ),
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
                    onPressed: _busy ? null : _scanNext,
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
                      // Readable on the dark scanner even while a scan is running.
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
        // Live counter + Finish (spec §9.1).
        Container(
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Present ${a.presentCount} · Unchecked ${a.uncheckedCount}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: s.finalized
                    ? null
                    : () => context.push('/attendance/${s.id}/review?from=scanner'),
                style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _note(String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(s, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white, fontSize: 16)),
      );

  /// The brief result card shown after each scan.
  Widget _flashCard(({ScanOutcome? outcome, RosterStudent? student, String? error}) f) {
    final (String line, Color color) = switch (f.outcome) {
      ScanOutcome.present => ('Present', AppColors.green),
      ScanOutcome.duplicate => ('Already scanned. Counted once.', AppColors.amber),
      ScanOutcome.notEnrolled => ('Not on this class roster. Not marked.', AppColors.red),
      ScanOutcome.notOpenYet => ("Session hasn't started. Not marked.", AppColors.amber),
      ScanOutcome.closed => ('Session closed. Not marked.', AppColors.amber),
      null => (f.error ?? '', AppColors.red),
    };
    return Container(
      key: ValueKey(f),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

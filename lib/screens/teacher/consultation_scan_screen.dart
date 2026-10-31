import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/consultation.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/user_avatar.dart';

/// The student shows their QR for a consultation (decided 2026-10-30): to
/// start a new form, or, with [signId], to sign a saved one. A new form can
/// also start from a name search, unsigned until the student scans. A
/// teacher without an e-signature is asked to add one first (2026-10-31).
/// MOCK: no camera; "sample QR" buttons stand in for scanning, and nothing
/// here verifies who the student is.
class ConsultationScanScreen extends StatefulWidget {
  final CampusService campusService;
  final String? signId;

  const ConsultationScanScreen({super.key, required this.campusService, this.signId});

  @override
  State<ConsultationScanScreen> createState() => _ConsultationScanScreenState();
}

class _ConsultationScanScreenState extends State<ConsultationScanScreen> {
  Future<(List<OrgMember>, Consultation?, String?)>? _data;
  String _query = '';
  bool _searching = false;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  Future<(List<OrgMember>, Consultation?, String?)> _load() {
    final user = SessionScope.of(context).user!;
    return (
      widget.campusService.findStudents(user, ''),
      widget.signId == null
          ? Future<Consultation?>.value()
          : widget.campusService.loadConsultation(user, widget.signId!),
      widget.campusService.loadSignature(user),
    ).wait;
  }

  Future<void> _addSignature() async {
    await context.push('/life/consultations/signature');
    if (!mounted) return;
    final reload = _load(); // it may be there now
    setState(() {
      _data = reload;
    });
  }

  void _start(OrgMember m, {required bool scanned}) => context.pushReplacement(Uri(
        path: '/life/consultations/new/form',
        queryParameters: {'student': m.id, if (scanned) 'scanned': '1'},
      ).toString());

  Future<void> _sign(Consultation c, OrgMember scanned) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final session = SessionScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signed =
          await widget.campusService.signConsultation(session.user!, c.id, scanned.id);
      router.pop();
      session.refresh();
      messenger.showSnackBar(SnackBar(
        content: Text(signed.studentSignature != null
            ? "Signed with ${c.studentName}'s e-signature, in this preview only."
            : "Signed, but ${c.studentName} has no e-signature on file yet."),
      ));
    } on StateError catch (e) {
      if (mounted) setState(() => _error = 'Not signed. ${e.message}');
    } catch (_) {
      if (mounted) setState(() => _error = "Not signed. Couldn't reach the service.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(List<OrgMember>, Consultation?, String?)>(
          future: _data,
          builder: (context, snap) {
            final students = snap.data?.$1 ?? const <OrgMember>[];
            final signing = snap.data?.$2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(widget.signId == null ? 'New Consultation' : 'Scan to Sign'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError || (widget.signId != null && signing == null))
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        snap.hasError
                            ? "Couldn't load students."
                            : "This consultation isn't available.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else if (widget.signId == null && snap.data!.$3 == null)
                  _gate()
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                      children: _searching
                          ? _search(students)
                          : _scanner(students, signing, muted),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// No e-signature yet: every consultation needs the teacher's.
  Widget _gate() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.draw_outlined, size: 48, color: AppColors.navy),
          const SizedBox(height: AppSpacing.md),
          Text('Add your e-signature before starting a consultation.',
              textAlign: TextAlign.center, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('It goes on every consultation form you make.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: _addSignature, child: const Text('Add e-signature')),
        ],
      ),
    );
  }

  List<Widget> _scanner(List<OrgMember> students, Consultation? signing, TextStyle? muted) {
    final text = Theme.of(context).textTheme;
    // A few sample QR codes to "scan": for signing, the right student and
    // someone else; otherwise Nicolas and a few classmates.
    final samples = signing != null
        ? [
            ...students.where((m) => m.id == signing.studentId),
            ...students.where((m) => m.id != signing.studentId).take(1),
          ]
        : [
            ...students.where((m) => m.id == 'mock-student-1'),
            ...students.where((m) => m.id != 'mock-student-1').take(3),
          ];
    return [
      Text(
          signing != null
              ? '${signing.studentName} shows their QR to sign. Their saved e-signature '
                  'is added to the form.'
              : 'The student shows their QR. Their saved e-signature is added to the form.',
          style: muted),
      const SizedBox(height: AppSpacing.md),
      AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: const Center(
            child: Icon(Icons.qr_code_scanner_rounded, size: 72, color: AppColors.white),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
          'Mock scanner: no camera in this preview. Tap a sample QR below. A scan '
          "doesn't verify who the student is.",
          style: muted),
      const SizedBox(height: AppSpacing.md),
      Text('Sample QR codes', style: text.labelMedium?.copyWith(color: AppColors.muted)),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final m in samples)
            ActionChip(
              avatar: const Icon(Icons.qr_code_rounded, size: 18),
              label: Text("${m.name}'s QR"),
              onPressed: _busy
                  ? null
                  : () => signing != null ? _sign(signing, m) : _start(m, scanned: true),
            ),
        ],
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(_error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
      ],
      if (signing == null) ...[
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => setState(() => _searching = true),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Find the student by name instead'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text("The form stays unsigned until the student shows their QR.", style: muted),
      ],
    ];
  }

  List<Widget> _search(List<OrgMember> students) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final q = _query.trim().toLowerCase();
    final list = [for (final m in students) if (m.name.toLowerCase().contains(q)) m];
    return [
      TextField(
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(
          hintText: 'Search students by name',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text('Sample students from the class lists.', style: muted),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text('No students match "$_query".', style: muted),
        ),
      for (final m in list)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: UserAvatar(name: m.name, imageAsset: m.photoAsset, size: 40),
          title: Text(m.name),
          subtitle: Text('${m.section} · ${m.maskedId}'),
          onTap: () => _start(m, scanned: false),
        ),
    ];
  }
}

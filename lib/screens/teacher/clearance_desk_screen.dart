import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/clearance_widgets.dart';
import '../../widgets/section_header.dart';
import '../../widgets/user_avatar.dart';

/// Clearance verification for authorized staff (spec §9.3): the assigned
/// office, pending requirements, and Scan Student QR. Scanning only finds
/// the student; the outcome is recorded explicitly on the next page.
class ClearanceDeskScreen extends StatefulWidget {
  final CampusService campusService;

  const ClearanceDeskScreen({super.key, required this.campusService});

  @override
  State<ClearanceDeskScreen> createState() => _ClearanceDeskScreenState();
}

class _ClearanceDeskScreenState extends State<ClearanceDeskScreen> {
  Future<ClearanceDesk?>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadClearanceDesk(session.user!);
    }
  }

  /// The mock scanner: no camera. "Simulate scan" reads the next pending
  /// student's mock code; "Unknown code" reads one that matches nobody.
  Future<void> _scan(ClearanceDesk desk) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = SessionScope.of(context).user!;
    final token = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheet) {
        final text = Theme.of(sheet).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MOCK SCANNER · no camera is used',
                    style: text.labelMedium?.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.sm),
                Text('Scan Student QR', style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('Scanning only finds the student. It never clears anything.',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: desk.pending.isEmpty
                      ? null
                      : () => Navigator.pop(sheet, desk.pending.first.student.qrToken),
                  child: const Text('Simulate scan'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
                  onPressed: () => Navigator.pop(sheet, 'MOCK-UNKNOWN'),
                  child: const Text('Unknown code'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (token == null) return;
    final String? studentId;
    try {
      studentId = await widget.campusService.findStudentByQr(user, token);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't check this code.")));
      return;
    }
    if (studentId == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No student matches this code. Nothing was recorded.')));
      return;
    }
    router.push('/life/verify/$studentId');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ClearanceDesk?>(
          future: _data,
          builder: (context, snap) {
            final desk = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Clearance Verification'),
                Expanded(
                  child: snap.hasError
                      ? const Center(child: Text("Couldn't load clearance verification."))
                      : snap.connectionState != ConnectionState.done && !snap.hasData
                          ? const Align(
                              alignment: Alignment.topCenter, child: LinearProgressIndicator())
                          : desk == null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  child: Text(
                                      "Clearance processing isn't available to you. You may "
                                      'not be assigned to a clearance area, or there is no '
                                      'active period.',
                                      style: muted),
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.screen),
                                      decoration: BoxDecoration(
                                        color: AppColors.fill,
                                        borderRadius: BorderRadius.circular(AppRadius.large),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(desk.office, style: text.titleLarge),
                                          Text(
                                              '${desk.periodName} · '
                                              '${desk.pending.length} pending',
                                              style: text.bodyMedium
                                                  ?.copyWith(color: AppColors.muted)),
                                          const SizedBox(height: AppSpacing.lg),
                                          FilledButton.icon(
                                            onPressed: () => _scan(desk),
                                            icon: const Icon(Icons.qr_code_scanner_rounded),
                                            label: const Text('Scan Student QR'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SectionHeader('Pending'),
                                    if (desk.pending.isEmpty)
                                      Text('Nothing is waiting for review.', style: muted),
                                    for (var i = 0; i < desk.pending.length; i++) ...[
                                      if (i > 0)
                                        const Divider(height: 1, indent: 48 + AppSpacing.md),
                                      _caseRow(desk.pending[i]),
                                    ],
                                  ],
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _caseRow(ClearanceCase c) {
    final text = Theme.of(context).textTheme;
    final waiting = c.items.where((i) => i.status == ClearanceStatus.inReview).toList();
    return InkWell(
      onTap: () => context.push('/life/verify/${c.student.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(name: c.student.name, imageAsset: c.student.photoAsset, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.student.name, style: text.titleMedium),
                  Text('${c.student.maskedId} · ${c.student.section}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(waiting.map((i) => i.title).join(' · '),
                      style: text.bodyMedium),
                ],
              ),
            ),
            clearancePill(ClearanceStatus.inReview),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

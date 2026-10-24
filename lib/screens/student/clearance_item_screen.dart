import 'package:flutter/material.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/clearance_widgets.dart';
import '../../widgets/fade_switch.dart';

/// One clearance requirement (spec §7.5): what to do, the reason if it was
/// returned, and a way to resubmit. Submitting only sends it for review;
/// staff record the outcome.
class ClearanceItemScreen extends StatefulWidget {
  final CampusService campusService;
  final String itemId;

  const ClearanceItemScreen({super.key, required this.campusService, required this.itemId});

  @override
  State<ClearanceItemScreen> createState() => _ClearanceItemScreenState();
}

class _ClearanceItemScreenState extends State<ClearanceItemScreen> {
  Future<ClearanceView>? _data;
  String? _loadedFor;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadClearanceView(session.user!);
    }
  }

  Future<void> _submit() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.campusService.markSubmitted(session.user!, widget.itemId);
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not submitted. ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Not submitted. Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh();
    messenger.showSnackBar(const SnackBar(
      content: Text('Marked as submitted in this preview only. Nothing was uploaded, and '
          "it isn't cleared until the office reviews it."),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ClearanceView>(
          future: _data,
          builder: (context, snap) {
            final item =
                snap.data?.active?.items.where((i) => i.id == widget.itemId).firstOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(item?.office ?? 'Requirement'),
                Expanded(
                  child: FadeSwitch(
                    loaded: snap.hasData || snap.hasError || snap.connectionState == ConnectionState.done,
                    child: snap.hasError
                        ? const Center(child: Text("Couldn't load this requirement."))
                        : snap.connectionState != ConnectionState.done && !snap.hasData
                            ? const Align(
                                alignment: Alignment.topCenter, child: LinearProgressIndicator())
                            : item == null
                                ? Padding(
                                    padding: const EdgeInsets.all(AppSpacing.screen),
                                    child: Text(
                                        "This requirement isn't available. There may be no "
                                        'active clearance period.',
                                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                  )
                                : _content(item),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(ClearanceItem item) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    final canSubmit = const {
      ClearanceStatus.notStarted,
      ClearanceStatus.actionRequired,
      ClearanceStatus.needsCorrection,
    }.contains(item.status);
    final statusNote = switch (item.status) {
      ClearanceStatus.inReview => 'The office is reviewing it. Nothing to do for now.',
      ClearanceStatus.cleared => 'This requirement is cleared.',
      ClearanceStatus.notApplicable => "This requirement doesn't apply to you.",
      ClearanceStatus.onHold => 'The office put this on hold. Contact them about it.',
      _ => null,
    };
    final returned = item.reason != null &&
        (item.status == ClearanceStatus.needsCorrection || item.status == ClearanceStatus.onHold);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
              child: Icon(officeIcon(item.office), color: AppColors.ink, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(item.title, style: text.headlineSmall)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Align(alignment: Alignment.centerLeft, child: clearancePill(item.status)),
        if (returned) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: item.status == ClearanceStatus.onHold ? AppColors.amberTint : AppColors.redTint,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status == ClearanceStatus.onHold
                      ? 'Put on hold by ${item.office}'
                      : 'Returned by ${item.office}',
                  style: text.labelMedium?.copyWith(
                      color: item.status == ClearanceStatus.onHold
                          ? AppColors.amber
                          : AppColors.red),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(item.reason!, style: text.bodyLarge),
              ],
            ),
          ),
        ],
        _label('What to do'),
        Text(item.instructions, style: text.bodyLarge),
        if (item.evidenceRequired) ...[
          _label('Evidence'),
          Text(
            'A photo or document is required. Uploading isn\'t available in this preview; '
            'bring it to the office.',
            style: text.bodyLarge,
          ),
        ],
        if (statusNote != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(statusNote, style: muted),
        ],
        if (canSubmit) ...[
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy
                ? 'Sending…'
                : item.status == ClearanceStatus.needsCorrection
                    ? 'Resubmit for Review'
                    : 'I\'ve Done This'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Submitting or showing your QR never clears a requirement by itself. '
          'The office records the outcome.',
          style: text.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
      );
}

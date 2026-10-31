import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../utils/tab_path.dart';
import '../../widgets/back_header.dart';
import '../../widgets/clearance_widgets.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/surface_card.dart';

/// The student's clearance (spec §7.5): during a period, the progress and
/// one row per requirement; outside one, a calm Clearance Unavailable
/// state. Past clearances stay visible either way.
class ClearanceScreen extends StatefulWidget {
  final CampusService campusService;

  const ClearanceScreen({super.key, required this.campusService});

  @override
  State<ClearanceScreen> createState() => _ClearanceScreenState();
}

class _ClearanceScreenState extends State<ClearanceScreen> {
  Future<ClearanceView>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadClearanceView(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Clearance'),
            Expanded(
              child: FutureBuilder<ClearanceView>(
                future: _data,
                builder: fadeOnLoad((context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Couldn't load your clearance."),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: () => setState(() {
                                _data = widget.campusService
                                    .loadClearanceView(SessionScope.of(context).user!);
                              }),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final v = snap.data;
                  if (v == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      if (v.active == null)
                        const ClearanceUnavailable()
                      else
                        ..._active(v.active!),
                      const SectionHeader('Past Clearances'),
                      if (v.past.isEmpty) _muted('No past clearances.'),
                      if (v.past.isNotEmpty)
                        SurfaceCard(children: [
                          for (var i = 0; i < v.past.length; i++)
                            _pastRow(v.past[i]),
                        ]),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _active(ClearancePeriod p) {
    final text = Theme.of(context).textTheme;
    final total = p.applicable.length;
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.screen),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: text.titleLarge),
            Text('Due ${weekdayName(p.deadline)}, ${formatDayMonth(p.deadline)}',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.lg),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '${p.cleared}',
                    style: text.displaySmall?.copyWith(color: AppColors.navy)),
                TextSpan(
                    text: ' / $total cleared',
                    style: text.titleMedium?.copyWith(color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : p.cleared / total,
                minHeight: 10,
                backgroundColor: AppColors.track, // the empty part shows on the white card
                color: AppColors.navy,
                semanticsLabel: '${p.cleared} of $total cleared',
              ),
            ),
          ],
        ),
      ),
      const SectionHeader('Requirements'),
      if (p.items.isNotEmpty)
        SurfaceCard(indent: 44 + AppSpacing.md, children: [
          for (var i = 0; i < p.items.length; i++)
            _itemRow(p.items[i]),
        ]),
      const SizedBox(height: AppSpacing.md),
      _muted("Not applicable requirements don't count toward your total."),
    ];
  }

  Widget _itemRow(ClearanceItem item) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => context.push(inTab(context, '/life/clearance/${item.id}')),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
              child: Icon(officeIcon(item.office), color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.office, style: text.titleMedium),
                  Text(item.title, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.xs),
                  clearancePill(item.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _pastRow(PastClearance c) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: text.titleMedium),
                Text('Completed ${formatDate(c.completedOn)}',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          const StatusPill('Cleared', tone: PillTone.green),
        ],
      ),
    );
  }

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted));
}

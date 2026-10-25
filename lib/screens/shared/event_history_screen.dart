import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_record.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../utils/tab_path.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/surface_card.dart';

/// The student's recorded events, opened from Home's attendance stats so
/// Back returns to Home (decided 2026-10-24). Profile shows the same list.
class EventHistoryScreen extends StatefulWidget {
  final CampusService campusService;

  const EventHistoryScreen({super.key, required this.campusService});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  Future<List<EventRecord>>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadEventHistory(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Event History'),
            Expanded(
              child: FutureBuilder<List<EventRecord>>(
                future: _data,
                builder: fadeOnLoad((context, snap) {
                  if (snap.hasError) {
                    return const Center(child: Text("Couldn't load your event history."));
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, 0, AppSpacing.screen, 120),
                    children: [
                      Text('Events with an attendance record. Registering alone isn’t listed.',
                          style: muted),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Text('No recorded events yet.', style: muted),
                        ),
                      if (list.isNotEmpty)
                        SurfaceCard(indent: ContentRow.textIndent, children: [
                          for (var i = 0; i < list.length; i++)
                            eventRecordRow(context, list[i]),
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
}

/// One recorded event; it opens in the current tab.
Widget eventRecordRow(BuildContext context, EventRecord e) => ContentRow(
      title: e.eventName,
      meta: '${formatDate(e.date)} · ${e.role.label}',
      metaIcon: Icons.calendar_today_outlined,
      imageAsset: e.imageAsset,
      placeholderIcon: Icons.event_outlined,
      pill: StatusPill(e.status.label, tone: PillTone.green),
      onTap: () => context.push(inTab(context, '/life/events/${e.eventId}')),
    );

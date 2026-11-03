import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/status_pill.dart';

class AllEventsScreen extends StatefulWidget {
  final CampusService campusService;

  const AllEventsScreen({super.key, required this.campusService});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  Future<List<CampusEvent>>? _events;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    final user = session.user;
    if (user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _events = _load(user);
    }
  }

  Future<List<CampusEvent>> _load(UserProfile user) =>
      user.role == UserRole.student
      ? widget.campusService.loadUpcomingEvents(user)
      : widget.campusService.loadManagedEvents(user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<CampusEvent>>(
          future: _events,
          builder: (context, snapshot) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: BackHeader('Events')),
                if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Couldn't load events."),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: () {
                                final user = SessionScope.of(context).user;
                                if (user != null) {
                                  setState(() => _events = _load(user));
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (snapshot.data == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.data!.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No events available right now.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final event = snapshot.data![index];
                        final now = DateTime.now();
                        return Column(
                          children: [
                            ContentRow(
                              source: event.host,
                              sourceImage: event.hostLogo,
                              title: event.title,
                              meta:
                                  '${formatDayLabel(event.start, now)} · ${formatTime(event.start)} · ${event.venue}',
                              metaIcon: Icons.schedule_rounded,
                              imageAsset: event.coverAsset,
                              placeholderIcon: Icons.event_outlined,
                              pill: event.status == EventStatus.draft
                                  ? const StatusPill('Draft')
                                  : null,
                              onSourceTap: event.hostProfileId == null
                                  ? null
                                  : () => context.push(
                                      '/life/community/${event.hostProfileId}',
                                    ),
                              onTap: () => context.push(
                                '/life/event-details',
                                extra: event,
                              ),
                            ),
                            if (index < snapshot.data!.length - 1)
                              const Divider(
                                height: 1,
                                indent: ContentRow.textIndent,
                              ),
                          ],
                        );
                      }, childCount: snapshot.data!.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

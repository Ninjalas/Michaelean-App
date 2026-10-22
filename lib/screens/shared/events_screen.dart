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
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/segmented_pills.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/two_tone_date.dart';

/// Events (spec §7.3, §9.2). Students: Discover | My events. Teachers who
/// may manage events: Upcoming | Past | Drafts, with + to create one.
class EventsScreen extends StatefulWidget {
  final CampusService campusService;

  const EventsScreen({super.key, required this.campusService});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

enum _View { discover, mine, upcoming, past, drafts }

enum _Filter { all, school, department, orgs }

class _EventsScreenState extends State<EventsScreen> {
  _View? _view; // set on first build from the role
  _Filter _filter = _Filter.all;
  Future<List<EventDetail>>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    final user = session.user;
    if (user != null && session.dataKey != _loadedFor) {
      if (_loadedFor?.split('#').first != user.id) {
        _view = user.role == UserRole.student ? _View.discover : _View.upcoming;
      }
      _loadedFor = session.dataKey;
      _data = _load(user);
    }
  }

  Future<List<EventDetail>> _load(UserProfile user) => widget.campusService.loadEvents(
      user,
      switch (_view!) {
        _View.discover => EventList.discover,
        _View.mine => EventList.mine,
        _ => EventList.managed,
      });

  void _show(_View view) {
    final user = SessionScope.of(context).user!;
    final needsReload = user.role == UserRole.student;
    setState(() {
      _view = view;
      if (needsReload) _data = _load(user); // teachers' tabs share one list
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink();
    final isStudent = user.role == UserRole.student;
    final mayManage = user.can(Permission.manageEvents);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackHeader(
              isStudent ? 'Events' : 'Events You Manage',
              trailing: !isStudent && mayManage
                  ? RoundIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Create event',
                      onPressed: () => context.push('/life/events/new'),
                    )
                  : null,
            ),
            if (!isStudent && !mayManage)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: _muted("You aren't an authorized event manager."),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                child: SegmentedPills<_View>(
                  segments: isStudent
                      ? const [(_View.discover, 'Discover'), (_View.mine, 'My events')]
                      : const [
                          (_View.upcoming, 'Upcoming'),
                          (_View.past, 'Past'),
                          (_View.drafts, 'Drafts'),
                        ],
                  selected: _view!,
                  onChanged: _show,
                ),
              ),
              Expanded(
                child: FutureBuilder<List<EventDetail>>(
                  future: _data,
                  builder: (context, snap) {
                    if (snap.hasError) return _error(user);
                    if (snap.connectionState != ConnectionState.done) {
                      return const Align(
                          alignment: Alignment.topCenter, child: LinearProgressIndicator());
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                      children: _content(user, snap.data!),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _content(UserProfile user, List<EventDetail> all) {
    final now = DateTime.now();
    bool ended(EventDetail d) => !d.event.end.isAfter(now);
    bool isDraft(EventDetail d) => d.event.status == EventStatus.draft;
    switch (_view!) {
      case _View.discover:
        final shown = all.where((d) => _filter == _Filter.all || _kind(user, d.event) == _filter);
        return [
          _filters(),
          ..._grouped(shown.toList(), empty: 'No events match this filter.'),
        ];
      case _View.mine:
        final upcoming = all.where((d) => !ended(d)).toList();
        final past = all.where(ended).toList();
        return [
          ..._grouped(upcoming, empty: "You haven't registered for any upcoming events."),
          if (past.isNotEmpty) ...[
            const SectionHeader('Past'),
            ..._grouped(past),
          ],
          const SizedBox(height: AppSpacing.lg),
          _muted('Registering isn\'t attendance. Your recorded events are on your Profile.'),
        ];
      case _View.upcoming:
        return _grouped(all.where((d) => !isDraft(d) && !ended(d)).toList(),
            empty: 'No upcoming events. Create one with +.');
      case _View.past:
        return _grouped(all.where((d) => !isDraft(d) && ended(d)).toList(),
            empty: 'No past events.');
      case _View.drafts:
        return _grouped(all.where(isDraft).toList(), empty: 'No drafts.');
    }
  }

  /// Which Discover filter an event falls under. Each event has one
  /// audience, so it appears once under All.
  _Filter _kind(UserProfile user, CampusEvent e) {
    if (e.audience == null) return _Filter.school;
    final tag = user.tags.where((t) => t.label == e.audience).firstOrNull;
    return tag?.kind == TagKind.organization ? _Filter.orgs : _Filter.department;
  }

  Widget _filters() {
    const labels = {
      _Filter.all: 'All',
      _Filter.school: 'School-wide',
      _Filter.department: 'Department',
      _Filter.orgs: 'My Orgs',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          for (final f in _Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Semantics(
                button: true,
                selected: f == _filter,
                child: Material(
                  color: f == _filter ? AppColors.navy : AppColors.fill,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      alignment: Alignment.center,
                      child: Text(
                        labels[f]!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: f == _filter ? AppColors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Rows under two-tone date headers (spec §2.1).
  List<Widget> _grouped(List<EventDetail> events, {String? empty}) {
    if (events.isEmpty) {
      return [
        if (empty != null)
          Padding(padding: const EdgeInsets.only(top: AppSpacing.section), child: _muted(empty)),
      ];
    }
    final out = <Widget>[];
    DateTime? day;
    for (final d in events) {
      final s = d.event.start;
      final thisDay = DateTime(s.year, s.month, s.day);
      if (thisDay != day) {
        day = thisDay;
        out.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg + AppSpacing.sm),
          child: TwoToneDate(s, style: Theme.of(context).textTheme.titleMedium),
        ));
      } else {
        out.add(const Divider(height: 1, indent: ContentRow.textIndent));
      }
      out.add(_row(d));
    }
    return out;
  }

  Widget _row(EventDetail d) {
    final e = d.event;
    final when = '${formatTime(e.start)} · ${d.canManage ? '${d.going} going' : e.venue}';
    return ContentRow(
      source: e.host,
      sourceImage: e.hostLogo,
      title: e.title,
      meta: when,
      metaIcon: Icons.schedule_rounded,
      imageAsset: e.coverAsset,
      placeholderIcon: Icons.event_outlined,
      pill: eventPill(d, DateTime.now()),
      onTap: () => context.push('/life/events/${e.id}'),
    );
  }

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  Widget _error(UserProfile user) => Padding(
        padding: const EdgeInsets.all(AppSpacing.section),
        child: Column(
          children: [
            const Text("Couldn't load events."),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => setState(() => _data = _load(user)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

/// The status pill on an event row: the user's registration first, then
/// why registration is closed. Registration is never shown as attendance.
StatusPill? eventPill(EventDetail d, DateTime now) {
  final e = d.event;
  if (e.status == EventStatus.cancelled) return const StatusPill('Cancelled', tone: PillTone.red);
  if (e.status == EventStatus.draft) return const StatusPill('Draft');
  if (d.record != null) return StatusPill(d.record!.status.label, tone: PillTone.green);
  if (d.registered) {
    if (!e.end.isAfter(now)) return const StatusPill('Registered');
    return d.invited
        ? const StatusPill('Invited', tone: PillTone.navy)
        : const StatusPill('Going', tone: PillTone.green);
  }
  if (d.canManage || !e.start.isAfter(now)) return null;
  if (e.capacity != null && d.going >= e.capacity!) return const StatusPill('Full');
  if (e.deadline != null && !e.deadline!.isAfter(now)) return const StatusPill('Closed');
  return null;
}

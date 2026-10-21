import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// The feature hub tab, for browsing: Student Life for students (spec §7),
/// Michaelean Life for teachers (spec §9). Each feature shows a live preview
/// of its content with "See all ›". Home covers today and alerts.
class LifeHubScreen extends StatefulWidget {
  final CampusService campusService;

  const LifeHubScreen({super.key, required this.campusService});

  @override
  State<LifeHubScreen> createState() => _LifeHubScreenState();
}

class _HubData {
  final List<ClassSession> classes;
  final List<CampusEvent> events; // students: upcoming; teachers: ones they manage
  final List<Organization> organizations;
  final ClearanceSummary? clearance;
  final ClearanceOffice? office;

  const _HubData({
    required this.classes,
    required this.events,
    this.organizations = const [],
    this.clearance,
    this.office,
  });
}

class _LifeHubScreenState extends State<LifeHubScreen> {
  Future<_HubData>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = SessionScope.of(context).user;
    if (user != null) _data ??= _load(user);
  }

  Future<_HubData> _load(UserProfile user) async {
    final s = widget.campusService;
    if (user.role == UserRole.student) {
      final (classes, events, orgs, clearance) = await (
        s.loadClasses(user),
        s.loadUpcomingEvents(user),
        s.loadMyOrganizations(user),
        s.loadClearance(user),
      ).wait;
      return _HubData(
          classes: classes, events: events, organizations: orgs, clearance: clearance);
    }
    final (classes, events, office) = await (
      s.loadClasses(user),
      s.loadManagedEvents(user),
      s.loadClearanceOffice(user),
    ).wait;
    return _HubData(classes: classes, events: events, office: office);
  }

  void _open(String what) =>
      context.push(Uri(path: '/life/soon', queryParameters: {'what': what}).toString());

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final isStudent = user.role == UserRole.student;

    return SafeArea(
      bottom: false,
      child: FutureBuilder<_HubData>(
        future: _data,
        builder: (context, snap) {
          final data = snap.data;
          return ListView(
            // No side padding here: the events strip runs edge to edge.
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 120),
            children: [
              _pad(Text(isStudent ? 'Student Life' : 'Michaelean Life',
                  style: text.headlineMedium)),
              const SizedBox(height: AppSpacing.xs),
              _pad(Text(
                isStudent ? 'Your campus, beyond the classroom.' : 'Teaching & Campus',
                style: text.bodyLarge?.copyWith(color: AppColors.muted),
              )),
              if (snap.hasError)
                _pad(_error())
              else if (data == null)
                _pad(_loading())
              else if (isStudent)
                ..._student(data)
              else
                ..._teacher(user, data),
            ],
          );
        },
      ),
    );
  }

  // ---------- Student Life ----------

  List<Widget> _student(_HubData d) {
    final now = DateTime.now();
    return [
      _pad(SectionHeader('Class', onSeeAll: () => _open('Class'))),
      ..._studentClasses(d.classes, now),

      _pad(SectionHeader('Events', onSeeAll: () => _open('Events'))),
      if (d.events.isEmpty)
        _pad(_muted('No upcoming events for you right now.'))
      else
        SizedBox(
          // 4:3 cover on a 240-wide card, plus room for the text below it,
          // which grows with the phone's text-size setting.
          height: _EventCard.width * 3 / 4 +
              MediaQuery.textScalerOf(context).scale(_EventCard.textBlock),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: d.events.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) =>
                _EventCard(event: d.events[i], now: now, onTap: () => _open(d.events[i].title)),
          ),
        ),

      _pad(SectionHeader('Organizations', onSeeAll: () => _open('Organizations'))),
      if (d.organizations.isEmpty)
        _pad(_muted("You haven't joined any organizations yet."))
      else
        ..._divided([
          for (final o in d.organizations) _OrgRow(org: o, onTap: () => _open(o.name)),
        ], indent: 48 + AppSpacing.md),

      _pad(SectionHeader('Clearance', onSeeAll: () => _open('Clearance'))),
      _pad(d.clearance == null
          ? const _ClearanceUnavailable()
          : _ClearanceProgress(summary: d.clearance!, onTap: () => _open('Clearance'))),
    ];
  }

  List<Widget> _studentClasses(List<ClassSession> classes, DateTime now) {
    final today = classes.where((c) => _sameDay(c.start, now)).toList();
    final next = nextClass(classes, now);
    if (today.isEmpty) {
      return [
        _pad(_muted(next == null
            ? 'No classes scheduled.'
            : 'No classes today. Next: ${next.subject}, '
                '${formatDayLabel(next.start, now)} at ${formatTime(next.start)}.')),
      ];
    }
    return _divided([
      for (final c in today)
        ContentRow(
          source: '${formatTime(c.start)} – ${formatTime(c.end)}',
          title: c.subject,
          meta: [c.room, if (c.teacher != null) c.teacher!].join(' · '),
          metaIcon: Icons.place_outlined,
          pill: _timePill(c, now, isNext: c.id == next?.id),
          onTap: () => _open(c.subject),
        ),
    ]);
  }

  StatusPill? _timePill(ClassSession c, DateTime now, {required bool isNext}) {
    if (!c.end.isAfter(now)) return const StatusPill('Ended');
    if (!c.start.isAfter(now)) return const StatusPill('Now', tone: PillTone.green);
    if (isNext) return const StatusPill('Next', tone: PillTone.navy);
    return null;
  }

  // ---------- Michaelean Life ----------

  List<Widget> _teacher(UserProfile user, _HubData d) {
    final now = DateTime.now();
    final today = d.classes.where((c) => _sameDay(c.start, now)).toList();
    return [
      // Permissions, not the Teacher label, decide what's usable (spec §12).
      if (!user.can(Permission.manageAssignedClasses))
        ..._denied('Classes', 'No classes are assigned to you.')
      else ...[
        _pad(SectionHeader('Classes', onSeeAll: () => _open('Classes'))),
        if (today.isEmpty)
          _pad(_muted('No classes today.'))
        else
          ..._divided([
            for (final c in today)
              _TeacherClassRow(
                session: c,
                now: now,
                onTap: () => _open(c.subject),
                onStartAttendance: () => _open('Start attendance'),
              ),
          ]),
      ],

      if (!user.can(Permission.manageEvents))
        ..._denied('Events You Manage', "You aren't an authorized event manager.")
      else ...[
        _pad(SectionHeader('Events You Manage', onSeeAll: () => _open('Events you manage'))),
        if (d.events.isEmpty)
          _pad(_muted('No events to manage yet.'))
        else
          ..._divided(indent: ContentRow.textIndent, [
            for (final e in d.events)
              ContentRow(
                source: e.host,
                sourceImage: e.hostLogo,
                title: e.title,
                meta: '${formatDayLabel(e.start, now)} · ${formatTime(e.start)} · ${e.venue}',
                metaIcon: Icons.schedule_rounded,
                imageAsset: e.coverAsset,
                placeholderIcon: Icons.event_outlined,
                pill: e.status == EventStatus.draft ? const StatusPill('Draft') : null,
                onTap: () => _open(e.title),
              ),
          ]),
      ],

      if (!user.can(Permission.processClearance))
        ..._denied('Clearance', "You aren't assigned to a clearance area.")
      else ...[
        _pad(SectionHeader('Clearance', onSeeAll: () => _open('Clearance verification'))),
        _pad(d.office == null
            ? const _ClearanceUnavailable()
            : _OfficeTile(office: d.office!, onTap: () => _open('Clearance verification'))),
      ],
    ];
  }

  /// A feature the user can't use: visible, but with no link and a reason.
  List<Widget> _denied(String title, String reason) => [
        _pad(SectionHeader(title)),
        _pad(Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _muted(reason)),
          ],
        )),
      ];

  // ---------- Shared bits ----------

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: child,
      );

  Widget _muted(String s) => Text(s,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted));

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) _pad(Divider(height: 1, indent: indent)),
          _pad(rows[i]),
        ],
      ];

  Widget _loading() => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.section),
        child: Column(
          children: [
            for (final h in [120.0, 240.0, 120.0])
              Container(
                height: h,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
              ),
          ],
        ),
      );

  Widget _error() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Column(
          children: [
            const Text("Couldn't load this page."),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => setState(() => _data = _load(SessionScope.of(context).user!)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A card in the horizontal events strip: cover photo, date, title, venue.
class _EventCard extends StatelessWidget {
  static const width = 240.0;
  static const textBlock = 104.0; // date + two-line title + venue, at normal text size

  final CampusEvent event;
  final DateTime now;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: event.coverAsset != null
                    ? Image.asset(event.coverAsset!, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: AppColors.fill,
                        child: Icon(Icons.event_outlined, size: 40, color: AppColors.muted),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text('${formatDayLabel(event.start, now)} · ${formatTime(event.start)}',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 2),
            // Flexible: if space runs short, the title drops to one line
            // instead of overflowing the strip.
            Flexible(
              child: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: text.titleMedium),
            ),
            const SizedBox(height: 2),
            Text(event.venue, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _OrgRow extends StatelessWidget {
  final Organization org;
  final VoidCallback onTap;

  const _OrgRow({required this.org, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(name: org.name, imageAsset: org.logoAsset, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(org.name, style: text.titleMedium),
                  Text('${org.memberCount} members',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// A teacher's class today. Start attendance only while the class hasn't
/// ended: scans after a session closes are rejected (spec §7.2).
class _TeacherClassRow extends StatelessWidget {
  final ClassSession session;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onStartAttendance;

  const _TeacherClassRow({
    required this.session,
    required this.now,
    required this.onTap,
    required this.onStartAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = session;
    final ended = !c.end.isAfter(now);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${formatTime(c.start)} – ${formatTime(c.end)}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(c.subject, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text('${c.section} · ${c.room}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (!ended)
              FilledButton(
                onPressed: onStartAttendance,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyTint,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('Start attendance'),
              )
            else if (c.awaitingFinalization)
              const StatusPill('To finalize', tone: PillTone.amber)
            else
              const StatusPill('Ended'),
          ],
        ),
      ),
    );
  }
}

class _ClearanceProgress extends StatelessWidget {
  final ClearanceSummary summary;
  final VoidCallback onTap;

  const _ClearanceProgress({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = summary;
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(s.periodName, style: text.titleMedium)),
                  Text('${s.cleared}/${s.total}',
                      style: text.headlineSmall?.copyWith(fontSize: 22, color: AppColors.navy)),
                ],
              ),
              Text('Due ${formatDayMonth(s.deadline)}',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: s.total == 0 ? 0 : s.cleared / s.total,
                  minHeight: 6,
                  backgroundColor: AppColors.white,
                  color: AppColors.navy,
                  semanticsLabel: '${s.cleared} of ${s.total} cleared',
                ),
              ),
              if (s.needsCorrection > 0) ...[
                const SizedBox(height: AppSpacing.md),
                StatusPill('${s.needsCorrection} needs correction', tone: PillTone.red),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeTile extends StatelessWidget {
  final ClearanceOffice office;
  final VoidCallback onTap;

  const _OfficeTile({required this.office, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Row(
            children: [
              Expanded(child: Text(office.name, style: text.titleMedium)),
              Text('${office.pendingCount} pending',
                  style: text.titleMedium?.copyWith(color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calm empty state outside a clearance period (spec §7.5).
class _ClearanceUnavailable extends StatelessWidget {
  const _ClearanceUnavailable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.muted, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clearance Unavailable', style: text.titleMedium),
                const SizedBox(height: 2),
                Text("There's no active clearance period right now.",
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

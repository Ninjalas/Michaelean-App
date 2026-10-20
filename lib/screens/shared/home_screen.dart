import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';
import '../../widgets/expandable_overview.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// Home for both roles (spec §6 Student Home, §8 Teacher Home). The layout
/// is shared; the feed decides which role-specific sections appear.
class HomeScreen extends StatefulWidget {
  final HomeService homeService;

  const HomeScreen({super.key, required this.homeService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  Future<HomeFeed>? _feed;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.offset > 56; // the big greeting has scrolled away
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feed ??= _load();
  }

  Future<HomeFeed> _load() =>
      widget.homeService.loadHome(SessionScope.of(context).user!);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openSoon(String what) =>
      context.push(Uri(path: '/home/soon', queryParameters: {'what': what}).toString());

  void _openPost(Post p) => context.push('/home/post/${p.id}');

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    // Preview just ended; the router is about to leave this screen.
    if (user == null) return const SizedBox.shrink();
    return FutureBuilder<HomeFeed>(
      future: _feed,
      builder: (context, snap) {
        final feed = snap.data;
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            _header(user, feed),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, 0, AppSpacing.screen, 120), // room for nav bar
              sliver: SliverList.list(children: [
                _greeting(user),
                if (snap.hasError)
                  _error()
                else if (feed == null)
                  _loading()
                else if (feed.isEmpty)
                  _empty()
                else
                  ..._content(feed),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _header(UserProfile user, HomeFeed? feed) {
    final text = Theme.of(context).textTheme;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: AppSpacing.screen,
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: _collapsed
          ? const Border(bottom: BorderSide(color: AppColors.hairline))
          : null,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _collapsed
            ? Row(
                key: const ValueKey('compact'),
                children: [
                  UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 34),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text('${greetingFor(DateTime.now())}, ${user.firstName}',
                        overflow: TextOverflow.ellipsis, style: text.titleMedium),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('brand'),
                children: [
                  Image.asset('assets/images/SMCL_Emblem.png', height: 34,
                      semanticLabel: "Saint Michael's College of Laguna emblem"),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Michaelean',
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.screen),
          child: RoundIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            showDot: (feed?.notifications.isNotEmpty) ?? false,
            onPressed: () => context.push('/home/notifications'),
          ),
        ),
      ],
    );
  }

  Widget _greeting(UserProfile user) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${greetingFor(now)}, ${user.firstName}', style: text.headlineMedium),
          const SizedBox(height: 2),
          Text(formatLongDate(now), style: text.bodyLarge?.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }

  List<Widget> _content(HomeFeed feed) {
    final now = DateTime.now();
    final a = feed.attendance;
    final t = feed.today;
    return [
      if (a != null)
        ExpandableOverview(
          title: 'Attendance Overview',
          summary: '${a.classPercent}% class · ${a.eventPercent}% events · '
              '${a.requirementsCleared}/${a.requirementsTotal} cleared',
          onOpenMetric: _openSoon,
          metrics: [
            OverviewMetric('Class Attendance', '${a.classPercent}%',
                progress: a.classPercent / 100),
            OverviewMetric('Event Attendance', '${a.eventPercent}%',
                progress: a.eventPercent / 100),
            OverviewMetric('Events Completed', '${a.eventsCompleted}'),
            OverviewMetric(
              'Event Requirements',
              '${a.requirementsCleared}/${a.requirementsTotal} cleared',
              progress: a.requirementsTotal == 0
                  ? 0
                  : a.requirementsCleared / a.requirementsTotal,
            ),
          ],
        ),

      if (t != null) ...[
        ExpandableOverview(
          title: "Today's Overview",
          summary: '${t.classesToday} classes · ${t.sessionsToFinalize} to finalize · '
              '${t.upcomingEvents} events',
          onOpenMetric: _openSoon,
          metrics: [
            OverviewMetric('Classes Today', '${t.classesToday}'),
            OverviewMetric('Attendance to Finalize', '${t.sessionsToFinalize}'),
            OverviewMetric('Upcoming Events', '${t.upcomingEvents}'),
          ],
        ),
        const SectionHeader('Next Class'),
        _nextClass(feed.nextClass, now),
      ],

      if (feed.tasks.isNotEmpty) ...[
        const SectionHeader('Pending Tasks'),
        ..._divided([
          for (final t in feed.tasks)
            ContentRow(
              title: t.title,
              meta: t.detail,
              pill: _taskPill(t.status),
              onTap: () => _openSoon(t.title),
            ),
        ]),
      ],

      if (feed.changes.isNotEmpty) ...[
        const SectionHeader('Schedule & Room Changes'),
        ..._divided([
          for (final p in feed.changes)
            ContentRow(
              source: p.source,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.announcements.isNotEmpty) ...[
        const SectionHeader('Announcements'),
        ..._divided([
          for (final p in feed.announcements)
            ContentRow(
              source: p.source,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.featuredNews != null) ...[
        const SectionHeader('School News'),
        _featured(feed.featuredNews!, now),
        ..._divided([
          for (final p in feed.moreNews)
            ContentRow(
              source: p.source,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              imageAsset: p.imageAsset,
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.forYou.isNotEmpty) ...[
        const SectionHeader('For You'),
        ..._divided([
          for (final p in feed.forYou)
            ContentRow(
              source: p.source,
              sourceImage: p.sourceImage,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              imageAsset: p.imageAsset,
              pill: p.urgent ? const StatusPill('URGENT', tone: PillTone.red) : null,
              onTap: () => _openPost(p),
            ),
        ]),
      ],
    ];
  }

  Widget _featured(Post p, DateTime now) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _openPost(p),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(p.imageAsset!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text('${p.source} · ${formatTimeAgo(p.publishedAt, now)}',
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.xs),
            Text(p.title, style: text.titleLarge),
          ],
        ),
      ),
    );
  }

  Widget _nextClass(ClassSession? c, DateTime now) {
    final text = Theme.of(context).textTheme;
    if (c == null) {
      return Text('No upcoming classes scheduled.',
          style: text.bodyLarge?.copyWith(color: AppColors.muted));
    }
    final day = c.start.isAfter(now) ? formatDayLabel(c.start, now) : 'Now';
    return InkWell(
      onTap: () => _openSoon(c.subject),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(day, tone: day == 'Now' ? PillTone.green : PillTone.navy),
            const SizedBox(height: AppSpacing.sm),
            Text(c.subject, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('${c.section} · ${formatTime(c.start)} – ${formatTime(c.end)}',
                style: text.bodyLarge),
            Text(c.room, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  StatusPill _taskPill(TaskStatus s) => switch (s) {
        TaskStatus.needsCorrection => const StatusPill('Needs correction', tone: PillTone.red),
        TaskStatus.actionRequired => const StatusPill('Action required', tone: PillTone.navy),
        TaskStatus.inReview => const StatusPill('In review', tone: PillTone.amber),
      };

  List<Widget> _divided(List<Widget> rows) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          rows[i],
        ],
      ];

  Widget _loading() => Column(
        children: [
          for (final h in [64.0, 120.0, 220.0])
            Container(
              height: h,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
            ),
        ],
      );

  Widget _error() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Column(
          children: [
            const Text("Couldn't load your feed."),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => setState(() => _feed = _load()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section * 2),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text('Nothing new yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Announcements and news for you will appear here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stats_row.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/two_tone_date.dart';
import '../../widgets/up_next_card.dart';
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
                  ..._content(user, feed),
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
      // Solid white, no border (Luma-like). A blurred header painted the feed
      // over itself on Flutter web, so blur is kept to the floating nav bar.
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: _collapsed
            ? Row(
                key: const ValueKey('compact'),
                children: [
                  UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 38),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${greetingFor(DateTime.now())}, ${user.firstName}',
                            overflow: TextOverflow.ellipsis, style: text.titleMedium),
                        TwoToneDate(DateTime.now(), style: text.bodyMedium),
                      ],
                    ),
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
          TwoToneDate(now, style: text.bodyLarge),
        ],
      ),
    );
  }

  List<Widget> _content(UserProfile user, HomeFeed feed) {
    final now = DateTime.now();
    final a = feed.attendance;
    final t = feed.today;
    final isTeacher = user.role == UserRole.teacher;
    return [
      if (a != null)
        StatsRow(items: [
          StatItem('${a.classPercent}%', 'Class attendance',
              onTap: () => _openSoon('Class attendance')),
          StatItem('${a.eventPercent}%', 'Event attendance',
              onTap: () => _openSoon('Event attendance')),
          // Event history lives on Profile.
          StatItem('${a.eventsCompleted}', 'Events completed', onTap: () => context.go('/profile')),
          StatItem('${a.requirementsCleared}/${a.requirementsTotal}', 'Cleared',
              onTap: () => _openSoon('Clearance')),
        ]),
      if (t != null)
        StatsRow(items: [
          StatItem('${t.classesToday}', 'Classes today', onTap: () => _openSoon('Classes')),
          StatItem('${t.sessionsToFinalize}', 'To finalize',
              onTap: () => _openSoon('Attendance to finalize')),
          StatItem('${t.upcomingEvents}', 'Upcoming events',
              onTap: () => _openSoon('Upcoming events')),
        ]),
      const SizedBox(height: AppSpacing.lg),
      UpNextCard(
        session: feed.nextClass,
        now: now,
        onTap: feed.nextClass == null ? null : () => _openSoon(feed.nextClass!.subject),
        // Permission, not the Teacher label, decides who sees this (spec §12).
        onStartAttendance: isTeacher &&
                feed.nextClass != null &&
                user.can(Permission.manageAssignedClasses)
            ? () => _openSoon('Start attendance')
            : null,
      ),

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

      if (isTeacher) ...[
        const SectionHeader("Today's Classes"),
        if (feed.todayClasses.isEmpty)
          Text('No classes today.', style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.muted))
        else
          ..._divided([
            for (final c in feed.todayClasses)
              ContentRow(
                source: c.section,
                title: c.subject,
                meta: '${formatTime(c.start)} – ${formatTime(c.end)} · ${c.room}',
                metaIcon: Icons.schedule_rounded,
                pill: _classPill(c, now),
                onTap: () => _openSoon(c.subject),
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
              metaIcon: Icons.schedule_rounded,
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
              metaIcon: Icons.schedule_rounded,
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.featuredNews != null) ...[
        const SectionHeader('School News'),
        _featured(feed.featuredNews!, now),
        ..._divided(indent: ContentRow.textIndent, [
          for (final p in feed.moreNews)
            ContentRow(
              source: p.source,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              metaIcon: Icons.schedule_rounded,
              imageAsset: p.imageAsset,
              placeholderIcon: Icons.article_outlined,
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.campusFeed.isNotEmpty) ...[
        const SectionHeader('Campus Feed'),
        ..._divided(indent: ContentRow.textIndent, [
          for (final p in feed.campusFeed)
            ContentRow(
              source: p.source,
              sourceImage: p.sourceImage,
              title: p.title,
              meta: formatTimeAgo(p.publishedAt, now),
              metaIcon: Icons.schedule_rounded,
              imageAsset: p.imageAsset,
              placeholderIcon: Icons.campaign_outlined,
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
            Text(p.title, style: text.headlineSmall),
          ],
        ),
      ),
    );
  }

  /// Only states a teacher can act on or that are plain facts of the clock.
  StatusPill? _classPill(ClassSession c, DateTime now) {
    if (c.awaitingFinalization) return const StatusPill('To finalize', tone: PillTone.amber);
    if (!c.start.isAfter(now) && c.end.isAfter(now)) {
      return const StatusPill('Now', tone: PillTone.green);
    }
    if (!c.end.isAfter(now)) return const StatusPill('Ended');
    return null;
  }

  StatusPill _taskPill(TaskStatus s) => switch (s) {
        TaskStatus.needsCorrection => const StatusPill('Needs correction', tone: PillTone.red),
        TaskStatus.actionRequired => const StatusPill('Action required', tone: PillTone.navy),
        TaskStatus.inReview => const StatusPill('In review', tone: PillTone.amber),
      };

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
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

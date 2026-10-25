import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../utils/tab_path.dart';
import '../../widgets/content_row.dart';
import '../teacher/create_menu.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/loading_boxes.dart';
import '../../widgets/navy_hero.dart';
import '../../widgets/pressable.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stats_row.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/tab_reselect.dart';
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
  int _unread = 0; // unread notifications the bell shows
  String? _loadedFor; // Session.dataKey the feed belongs to
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.offset > 110; // the hero's greeting has scrolled away
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the previewed account changes (role switch in Settings);
    // the tab stays alive, so it would otherwise keep the old user's feed.
    final user = SessionScope.of(context).user;
    if (user != null && SessionScope.of(context).dataKey != _loadedFor) {
      _loadedFor = SessionScope.of(context).dataKey;
      _feed = _load();
      _loadUnread();
    }
  }

  Future<void> _loadUnread() async {
    try {
      final n = await widget.homeService.countUnread(SessionScope.of(context).user!);
      if (mounted) setState(() => _unread = n);
    } catch (_) {
      // No dot rather than a wrong one; the pop-up shows the load error.
    }
  }

  Future<void> _openNotifications() async {
    await context.push('/home/notifications');
    if (mounted) _loadUnread(); // some were read
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
    // Permission, not the Teacher label, decides who may post (spec §12).
    final canPost = user.can(Permission.postToCampusFeed);
    // With extendBody, the bottom padding includes the floating nav bar.
    final fabBottom = MediaQuery.paddingOf(context).bottom + AppSpacing.md;
    final feedView = FutureBuilder<HomeFeed>(
      future: _feed,
      builder: (context, snap) {
        final feed = snap.data;
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _hero(user, feed, failed: snap.hasError)),
            SliverPadding(
              // Room for the nav bar (and the + button above it).
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, canPost ? 192 : 120),
              sliver: SliverList.list(children: [
                // The placeholders fade into the feed (spec §2.5).
                FadeSwitch(
                  loaded: feed != null || snap.hasError,
                  child: snap.hasError
                      ? _error()
                      : feed == null
                          ? _loading()
                          : feed.isEmpty
                              ? _empty()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: _content(user, feed),
                                ),
                ),
              ]),
            ),
          ],
        );
      },
    );
    // Tapping Home again glides back to the top. Once the greeting has
    // scrolled away, a compact navy bar stays pinned at the top.
    final scrollable = ScrollToTopOnTabTap(
      tab: 0,
      controller: _scroll,
      child: Stack(
        children: [
          feedView,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              child: _collapsed ? _compactBar(user) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
    if (!canPost) return scrollable;
    return Stack(
      children: [
        scrollable,
        Positioned(
          right: AppSpacing.screen,
          bottom: fabBottom,
          child: CreatePostButton(bottom: fabBottom),
        ),
      ],
    );
  }

  /// The navy hero (spec §2.1, direction B): emblem, wordmark and bell, the
  /// greeting and date, and the stats card hanging over its bottom edge.
  Widget _hero(UserProfile user, HomeFeed? feed, {required bool failed}) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final stats = feed == null ? null : _stats(feed);
    return NavyHero(
      overlap: failed || (feed != null && stats == null)
          ? null
          // A plain white card holds the place until the numbers arrive.
          : FadeSwitch(
              loaded: feed != null,
              child: stats ??
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      boxShadow: AppColors.cardShadow,
                    ),
                  ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/SMCL_Emblem.png', height: 34,
                  semanticLabel: "Saint Michael's College of Laguna emblem"),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Michaelean',
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.white)),
              ),
              _bell(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('${greetingFor(now)}, ${user.firstName}',
              style: text.headlineMedium?.copyWith(color: AppColors.white)),
          const SizedBox(height: 2),
          TwoToneDate(now,
              style: text.bodyLarge?.copyWith(color: AppColors.white),
              suffixColor: AppColors.onNavyMuted),
        ],
      ),
    );
  }

  /// Students: attendance and clearance; teachers: today at a glance.
  Widget? _stats(HomeFeed feed) {
    final a = feed.attendance;
    final t = feed.today;
    if (a != null) {
      return StatsRow(items: [
        StatItem('${a.classPercent}%', 'Class attendance',
            onTap: () => context.push('/home/class')),
        StatItem('${a.eventPercent}%', 'Event attendance',
            onTap: () => context.push('/home/history')),
        StatItem('${a.eventsCompleted}', 'Events completed',
            onTap: () => context.push('/home/history')),
        StatItem('${a.requirementsCleared}/${a.requirementsTotal}', 'Cleared',
            onTap: () => context.push('/home/clearance')),
      ]);
    }
    if (t != null) {
      return StatsRow(items: [
        StatItem('${t.classesToday}', 'Classes today',
            onTap: () => context.push('/home/classes')),
        StatItem('${t.sessionsToFinalize}', 'To finalize',
            onTap: () => context.push('/home/classes')),
        StatItem('${t.upcomingEvents}', 'Upcoming events',
            onTap: () => context.push('/home/events')),
      ]);
    }
    return null;
  }

  Widget _bell() => RoundIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: _unread == 0 ? 'Notifications' : 'Notifications, $_unread unread',
        showDot: _unread > 0,
        onPressed: _openNotifications,
      );

  /// Pinned at the top once the hero's greeting has scrolled away: navy,
  /// with the avatar, greeting, date and the bell.
  Widget _compactBar(UserProfile user) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    return Material(
      key: const ValueKey('compact-bar'),
      color: AppColors.navy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.screen,
            MediaQuery.paddingOf(context).top + AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
        child: Row(
          children: [
            UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 38),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${greetingFor(now)}, ${user.firstName}',
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: AppColors.white)),
                  TwoToneDate(now,
                      style: text.bodyMedium?.copyWith(color: AppColors.white),
                      suffixColor: AppColors.onNavyMuted),
                ],
              ),
            ),
            _bell(),
          ],
        ),
      ),
    );
  }

  /// A navy tile icon for a pending task, from where it leads.
  static IconData _taskIcon(String? route) => switch (route) {
        final r? when r.contains('clearance') => Icons.fact_check_outlined,
        final r? when r.contains('events') => Icons.event_outlined,
        final r? when r.startsWith('/attendance') => Icons.qr_code_scanner_rounded,
        final r? when r.contains('classes') => Icons.class_outlined,
        _ => Icons.assignment_outlined,
      };

  List<Widget> _content(UserProfile user, HomeFeed feed) {
    final now = DateTime.now();
    final isTeacher = user.role == UserRole.teacher;
    return [
      UpNextCard(
        session: feed.nextClass,
        now: now,
        onTap: feed.nextClass == null
            ? null
            : () => context.push(isTeacher
                ? '/home/classes/${feed.nextClass!.classId}'
                : '/home/class'),
        // Permission, not the Teacher label, decides who sees this (spec §12).
        onStartAttendance: isTeacher &&
                feed.nextClass != null &&
                user.can(Permission.manageAssignedClasses)
            ? () => context.push('/attendance/${feed.nextClass!.id}')
            : null,
      ),

      if (feed.tasks.isNotEmpty) ...[
        const SectionHeader('Pending Tasks'),
        ..._divided(indent: ContentRow.iconIndent, [
          for (final t in feed.tasks)
            ContentRow(
              title: t.title,
              icon: _taskIcon(t.route),
              meta: t.detail,
              pill: _taskPill(t.status),
              onTap: () => t.route != null ? context.push(inTab(context, t.route!)) : _openSoon(t.title),
            ),
        ]),
      ],

      if (isTeacher) ...[
        const SectionHeader("Today's Classes"),
        if (feed.todayClasses.isEmpty)
          Text('No classes today.', style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.muted))
        else
          ..._divided(indent: ContentRow.iconIndent, [
            for (final c in feed.todayClasses)
              ContentRow(
                source: c.section,
                title: c.subject,
                icon: Icons.class_outlined,
                meta: '${formatTime(c.start)} – ${formatTime(c.end)} · ${c.room}',
                metaIcon: Icons.schedule_rounded,
                pill: _classPill(c, now),
                onTap: () => context.push('/home/classes/${c.classId}'),
              ),
          ]),
      ],

      if (feed.changes.isNotEmpty) ...[
        const SectionHeader('Schedule & Room Changes'),
        ..._divided(indent: ContentRow.iconIndent, [
          for (final p in feed.changes)
            ContentRow(
              source: p.source,
              title: p.title,
              icon: Icons.edit_calendar_outlined,
              meta: formatTimeAgo(p.publishedAt, now),
              metaIcon: Icons.schedule_rounded,
              onTap: () => _openPost(p),
            ),
        ]),
      ],

      if (feed.announcements.isNotEmpty) ...[
        const SectionHeader('Announcements'),
        ..._divided(indent: ContentRow.iconIndent, [
          for (final p in feed.announcements)
            ContentRow(
              source: p.source,
              title: p.title,
              icon: Icons.campaign_outlined,
              meta: formatTimeAgo(p.publishedAt, now),
              metaIcon: Icons.schedule_rounded,
              pill: p.urgent ? const StatusPill('URGENT', tone: PillTone.red) : null,
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
    return Pressable(
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
    if (c.finalized) return const StatusPill('Finalized', tone: PillTone.green);
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

  /// A section's rows together in one white card (spec §2.1).
  List<Widget> _divided(List<Widget> rows, {double indent = 0}) =>
      rows.isEmpty ? const [] : [SurfaceCard(indent: indent, children: rows)];

  // Shaped like Up Next and the first section (the stats wait in the hero).
  Widget _loading() => const LoadingBoxes(heights: [120, 220]);

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

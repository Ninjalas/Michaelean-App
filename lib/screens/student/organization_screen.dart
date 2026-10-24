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
import '../../utils/tab_path.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/person_row.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';
import '../shared/events_screen.dart' show eventPill;

/// One organization (spec §7.4): cover, logo, name, tags, and membership,
/// then tabs About, Schedule, Events, News, Officers. Events open the shared
/// event page, and Back returns here. News includes posts its adviser made
/// in this preview; the adviser also gets a Manage club button.
class OrganizationScreen extends StatefulWidget {
  final CampusService campusService;
  final HomeService homeService;
  final String orgId;

  const OrganizationScreen({
    super.key,
    required this.campusService,
    required this.homeService,
    required this.orgId,
  });

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  static const _tabs = ['About', 'Schedule', 'Events', 'News', 'Officers'];

  Future<OrganizationPage?>? _data;
  Future<List<Post>>? _clubPosts; // made by its adviser in this preview
  String? _loadedFor;
  int _tab = 0;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadOrganization(session.user!, widget.orgId);
      _clubPosts = widget.homeService.loadClubPosts(session.user!, widget.orgId)
        // Shown in the News tab; until it's opened, a failure must not go uncaught.
        ..ignore();
    }
  }

  Future<void> _requestToJoin() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.campusService.requestToJoin(session.user!, widget.orgId);
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not sent. ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Not sent. Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh();
    messenger.showSnackBar(const SnackBar(
      content: Text("Request saved in this preview only. You're not a member until "
          'the club accepts it.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<OrganizationPage?>(
          future: _data,
          builder: (context, snap) {
            final page = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(page?.org.name ?? 'Organization'),
                Expanded(
                  child: FadeSwitch(
                    loaded: snap.hasData || snap.hasError || snap.connectionState == ConnectionState.done,
                    child: snap.hasError
                        ? const Center(child: Text("Couldn't load this organization."))
                        : snap.connectionState != ConnectionState.done && !snap.hasData
                            ? const Align(
                                alignment: Alignment.topCenter, child: LinearProgressIndicator())
                            : page == null
                                ? Padding(
                                    padding: const EdgeInsets.all(AppSpacing.screen),
                                    child: Text("This organization isn't available to you.",
                                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                  )
                                : _content(page),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(OrganizationPage p) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final o = p.org;
    final user = SessionScope.of(context).user!;
    const logo = 72.0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        // Cover with the logo overlapping its bottom edge.
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: AspectRatio(
                aspectRatio: 2,
                child: o.coverAsset != null
                    ? Image.asset(o.coverAsset!, fit: BoxFit.cover)
                    : const ColoredBox(color: AppColors.navyTint),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              bottom: -logo / 2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: UserAvatar(name: o.name, imageAsset: o.logoAsset, size: logo),
              ),
            ),
          ],
        ),
        const SizedBox(height: logo / 2 + AppSpacing.md),
        Text(o.name, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text('${o.memberCount} members', style: muted),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusPill(o.kind == OrgKind.society ? 'Departmental society' : 'School-wide club',
                tone: PillTone.navy),
            if (o.department != null) StatusPill(o.department!),
            if (p.isMember) const StatusPill('Member', tone: PillTone.green),
          ],
        ),
        if (!p.isMember && user.role == UserRole.student) ...[
          const SizedBox(height: AppSpacing.lg),
          if (p.requested) ...[
            const OutlinedButton(onPressed: null, child: Text('Request saved')),
            const SizedBox(height: AppSpacing.sm),
            Text("You're not a member until the club's adviser accepts your request.",
                style: muted),
          ] else
            FilledButton(
              onPressed: _busy ? null : _requestToJoin,
              child: Text(_busy ? 'Sending…' : 'Request to Join'),
            ),
        ],
        if (p.advises) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.push('/life/clubs/${o.id}'),
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Manage club'),
          ),
        ],
        if (!p.isMember && p.membersOnlyHidden > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Some events and posts are for members only.', style: muted),
        ],
        const SizedBox(height: AppSpacing.lg),
        DefaultTabController(
          length: _tabs.length + (p.members != null ? 1 : 0),
          initialIndex: _tab,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.only(right: AppSpacing.lg),
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.muted,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            indicatorColor: AppColors.navy,
            dividerColor: AppColors.hairline,
            onTap: (i) => setState(() => _tab = i),
            tabs: [
              for (final t in _tabs) Tab(text: t),
              if (p.members != null) Tab(text: 'Members (${p.members!.length})'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...switch (_tab) {
          0 => _about(p),
          1 => _schedule(o),
          2 => _events(p),
          3 => _news(p),
          4 => _officers(o),
          _ => _membersTab(p),
        },
      ],
    );
  }

  Widget _empty(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Text(s,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
      );

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
          rows[i],
        ],
      ];

  List<Widget> _about(OrganizationPage p) {
    final text = Theme.of(context).textTheme;
    return [
      const SizedBox(height: AppSpacing.sm),
      Text(p.org.about.isEmpty ? 'No description yet.' : p.org.about, style: text.bodyLarge),
    ];
  }

  List<Widget> _schedule(Organization o) {
    if (o.meetings.isEmpty) return [_empty('No regular meetings listed.')];
    return _divided([
      for (final m in o.meetings)
        ContentRow(
          title: m.title,
          source: m.when,
          meta: m.place,
          metaIcon: Icons.place_outlined,
        ),
    ]);
  }

  List<Widget> _events(OrganizationPage p) {
    if (p.events.isEmpty) return [_empty('No upcoming events you can join.')];
    final now = DateTime.now();
    return _divided(indent: ContentRow.textIndent, [
      for (final d in p.events)
        ContentRow(
          source: '${formatDayLabel(d.event.start, now)} · ${formatTime(d.event.start)}',
          title: d.event.title,
          meta: d.event.venue,
          metaIcon: Icons.place_outlined,
          imageAsset: d.event.coverAsset,
          placeholderIcon: Icons.event_outlined,
          pill: eventPill(d, now),
          onTap: () => context.push(inTab(context, '/life/events/${d.event.id}')),
        ),
    ]);
  }

  List<Widget> _news(OrganizationPage p) {
    return [
      FutureBuilder<List<Post>>(
        future: _clubPosts,
        builder: (context, snap) {
          if (snap.hasError) return _empty("Couldn't load this club's posts.");
          final news = [...?snap.data, ...p.news]
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          if (news.isEmpty) return _empty('No posts yet.');
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: _newsRows(p, news));
        },
      ),
    ];
  }

  List<Widget> _newsRows(OrganizationPage p, List<Post> news) {
    final now = DateTime.now();
    return _divided([
      for (final post in news)
        ContentRow(
          source: formatTimeAgo(post.publishedAt, now),
          title: post.title,
          meta: post.body,
          imageAsset: post.imageAsset,
          pill: post.urgent ? const StatusPill('URGENT', tone: PillTone.red) : null,
          onTap: () => context.push(inTab(context, '/life/organizations/${p.org.id}/post/${post.id}')),
        ),
    ]);
  }

  /// Everyone in the club (spec §7.4); tapping one opens their profile.
  List<Widget> _membersTab(OrganizationPage p) {
    final members = p.members ?? const [];
    if (members.isEmpty) return [_empty('No members listed.')];
    return _divided(indent: PersonRow.textIndent, [
      for (final m in members)
        PersonRow(
          person: m,
          onTap: () => context.push(inTab(context, '/life/people/${m.id}')),
          trailing: connectAction(context, widget.campusService, m),
        ),
    ]);
  }

  List<Widget> _officers(Organization o) {
    if (o.officers.isEmpty) return [_empty('No officers listed.')];
    final text = Theme.of(context).textTheme;
    return _divided(indent: 48 + AppSpacing.md, [
      for (final f in o.officers)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              UserAvatar(name: f.name, imageAsset: f.photoAsset, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: text.titleMedium),
                    Text(f.position, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}

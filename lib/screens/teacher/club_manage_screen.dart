import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../models/feed.dart';
import '../../services/campus_service.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/user_avatar.dart';

/// Manage club (decided 2026-10-23): the page a club's adviser uses to run
/// it. Tabs: Members (add, remove, officer positions, copy the list),
/// Requests (accept or decline), Posts, Events, and Info. Everything changes
/// this preview only; students see notices only in this preview's bell.
class ClubManageScreen extends StatefulWidget {
  final CampusService campusService;
  final HomeService homeService;
  final String orgId;

  const ClubManageScreen({
    super.key,
    required this.campusService,
    required this.homeService,
    required this.orgId,
  });

  @override
  State<ClubManageScreen> createState() => _ClubManageScreenState();
}

class _ClubManageScreenState extends State<ClubManageScreen> {
  Future<(ClubAdmin?, List<Post>)>? _data;
  String? _loadedFor; // Session.dataKey the data belongs to
  int _tab = 0;
  bool _busy = false;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = (
        widget.campusService.loadClubAdmin(session.user!, widget.orgId),
        widget.homeService.loadClubPosts(session.user!, widget.orgId),
      ).wait;
    }
  }

  /// Runs an adviser action, then reloads and says honestly what happened.
  Future<void> _act(Future<void> Function() action, String done) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not saved. ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Not saved. Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    session.refresh();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  /// Asks for an optional reason; null when cancelled.
  Future<String?> _confirmWithReason({
    required String title,
    required String message,
    required String action,
  }) {
    var reason = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.md),
            TextField(
              onChanged: (v) => reason = v,
              maxLength: 200,
              decoration: const InputDecoration(hintText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, reason),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  static const _notice = "in this preview only. They see a notice in this preview's bell.";

  Future<void> _remove(OrgMember m) async {
    final reason = await _confirmWithReason(
      title: 'Remove ${m.name}?',
      message: 'They will no longer be a member or see members-only posts and events.',
      action: 'Remove',
    );
    if (reason == null || !mounted) return;
    final user = SessionScope.of(context).user!;
    await _act(
      () => widget.campusService.removeMember(user, widget.orgId, m.id, reason: reason),
      'Removed $_notice',
    );
  }

  Future<void> _answer(OrgMember m, {required bool accept}) async {
    String? reason;
    if (!accept) {
      reason = await _confirmWithReason(
        title: "Decline ${m.name}'s request?",
        message: 'They can ask again later.',
        action: 'Decline',
      );
      if (reason == null || !mounted) return;
    }
    final user = SessionScope.of(context).user!;
    await _act(
      () => widget.campusService
          .answerJoinRequest(user, widget.orgId, m.id, accept: accept, reason: reason),
      '${accept ? 'Accepted' : 'Declined'} $_notice',
    );
  }

  Future<void> _setPosition(OrgMember m) async {
    // '' means "no position"; null means the dialog was closed.
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Position for ${m.name}'),
        children: [
          for (final p in officerPositions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, p),
              child: Text(p,
                  style: p == m.position ? const TextStyle(fontWeight: FontWeight.w600) : null),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('No position (member)'),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final user = SessionScope.of(context).user!;
    await _act(
      () => widget.campusService
          .setOfficerPosition(user, widget.orgId, m.id, picked.isEmpty ? null : picked),
      'Position saved in this preview only.',
    );
  }

  Future<void> _copyList(ClubAdmin a) async {
    final messenger = ScaffoldMessenger.of(context);
    final lines = [
      '${a.org.name} members (${a.members.length}) · sample data, IDs masked',
      for (final m in a.members)
        [m.name, m.position ?? 'Member', m.section, m.maskedId].join(' · '),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    messenger.showSnackBar(const SnackBar(content: Text('Member list copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<(ClubAdmin?, List<Post>)>(
          future: _data,
          builder: (context, snap) {
            final admin = snap.data?.$1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(admin?.org.name ?? 'Manage club'),
                Expanded(
                  child: snap.hasError
                      ? const Center(child: Text("Couldn't load this club."))
                      : !snap.hasData
                          ? const Align(
                              alignment: Alignment.topCenter, child: LinearProgressIndicator())
                          : admin == null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.screen),
                                  child: Text("You aren't an adviser of this club.",
                                      style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                                )
                              : _content(admin, snap.data!.$2),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(ClubAdmin a, List<Post> posts) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final tabs = ['Members', 'Requests (${a.requests.length})', 'Posts', 'Events', 'Info'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
      children: [
        Row(
          children: [
            UserAvatar(name: a.org.name, imageAsset: a.org.logoAsset, size: 56),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a.org.memberCount} members', style: text.titleMedium),
                  Text("You're its adviser", style: muted),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/life/organizations/${a.org.id}'),
              child: const Text('Club page'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Changes stay in this preview. Students see notices only in this preview.',
            style: muted),
        const SizedBox(height: AppSpacing.md),
        DefaultTabController(
          length: tabs.length,
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
            tabs: [for (final t in tabs) Tab(text: t)],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...switch (_tab) {
          0 => _members(a),
          1 => _requests(a),
          2 => _posts(a, posts),
          3 => _events(a),
          _ => _info(a),
        },
      ],
    );
  }

  Widget _empty(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
      );

  List<Widget> _divided(List<Widget> rows, {double indent = 0}) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
          rows[i],
        ],
      ];

  /// Avatar, name, and "section · masked ID", with something on the right.
  /// Tapping opens the student's full profile (spec §10.1).
  Widget _person(OrgMember m, Widget trailing) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/life/people/${m.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(name: m.name, imageAsset: m.photoAsset, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: text.titleMedium),
                  Text('${m.section} · ${m.maskedId}',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  if (m.position != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    StatusPill(m.position!, tone: PillTone.navy),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  List<Widget> _members(ClubAdmin a) {
    final q = _search.trim().toLowerCase();
    final shown = a.members.where((m) => m.name.toLowerCase().contains(q)).toList();
    return [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push('/life/clubs/${a.org.id}/add'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add member'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: a.members.isEmpty ? null : () => _copyList(a),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy list'),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(
          hintText: 'Search members',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      if (a.members.isEmpty)
        _empty('No members yet.')
      else if (shown.isEmpty)
        _empty('No members match "$_search".')
      else
        ..._divided(indent: 44 + AppSpacing.md, [
          for (final m in shown)
            _person(
              m,
              PopupMenuButton<String>(
                tooltip: 'Options for ${m.name}',
                enabled: !_busy,
                onSelected: (v) => v == 'position' ? _setPosition(m) : _remove(m),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'position', child: Text('Set position')),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from club', style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            ),
        ]),
    ];
  }

  List<Widget> _requests(ClubAdmin a) {
    if (a.requests.isEmpty) return [_empty('No one is waiting to join.')];
    return [
      Text('Oldest first. Accepting makes them a member right away.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
      ..._divided(indent: 44 + AppSpacing.md, [
        for (final m in a.requests)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _person(m, const SizedBox.shrink()),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _answer(m, accept: false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _answer(m, accept: true),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
      ]),
    ];
  }

  List<Widget> _posts(ClubAdmin a, List<Post> posts) {
    final now = DateTime.now();
    return [
      FilledButton.icon(
        onPressed: () => context.push('/life/clubs/${a.org.id}/post'),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New club post'),
      ),
      if (posts.isEmpty)
        _empty('No posts from this preview yet.')
      else
        ..._divided([
          for (final p in posts)
            ContentRow(
              source: '${formatTimeAgo(p.publishedAt, now)} · ${p.sentTo ?? ''}',
              title: p.title,
              meta: p.body,
              pill: p.urgent ? const StatusPill('URGENT', tone: PillTone.red) : null,
              onTap: () => context.push('/life/organizations/${a.org.id}/post/${p.id}'),
            ),
        ]),
    ];
  }

  List<Widget> _events(ClubAdmin a) {
    final now = DateTime.now();
    return [
      FilledButton.icon(
        onPressed: () => context.push('/life/clubs/${a.org.id}/event'),
        icon: const Icon(Icons.event_outlined),
        label: const Text('New club event'),
      ),
      if (a.events.isEmpty)
        _empty('No club events yet.')
      else
        ..._divided(indent: ContentRow.textIndent, [
          for (final e in a.events)
            ContentRow(
              source: '${formatDayLabel(e.start, now)} · ${formatTime(e.start)}',
              title: e.title,
              meta: e.venue,
              metaIcon: Icons.place_outlined,
              imageAsset: e.coverAsset,
              placeholderIcon: Icons.event_outlined,
              pill: switch (e.status) {
                EventStatus.draft => const StatusPill('Draft'),
                EventStatus.cancelled => const StatusPill('Cancelled', tone: PillTone.red),
                _ => null,
              },
              onTap: () => context.push('/life/events/${e.id}'),
            ),
        ]),
    ];
  }

  List<Widget> _info(ClubAdmin a) {
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    return [
      OutlinedButton.icon(
        onPressed: () => context.push('/life/clubs/${a.org.id}/info'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit info'),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('About', style: label),
      const SizedBox(height: AppSpacing.xs),
      Text(a.org.about.isEmpty ? 'No description yet.' : a.org.about, style: text.bodyLarge),
      const SizedBox(height: AppSpacing.lg),
      Text('Meetings', style: label),
      if (a.org.meetings.isEmpty)
        _empty('No regular meetings listed.')
      else
        ..._divided([
          for (final m in a.org.meetings)
            ContentRow(
              title: m.title,
              source: m.when,
              meta: m.place.isEmpty ? null : m.place,
              metaIcon: Icons.place_outlined,
            ),
        ]),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/attendance.dart';
import '../../models/campus.dart';
import '../../models/feed.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/content_row.dart';
import '../../widgets/photo_source.dart';
import '../../widgets/post_image.dart';
import '../../widgets/status_pill.dart';

/// Write or edit a post from Home's "+" menu: an announcement, School News,
/// or a campus update. A live preview shows the row as it will appear on
/// Home. With [orgId], it's a club post by the club's adviser, for its
/// members or everyone. School News, campus updates, and club posts can have
/// up to 4 photos, uploaded from the device (kept in memory only). Posts are
/// kept in this preview only. Only urgent announcements and club posts
/// notify, and only in this preview's bell; the confirmation says so.
class PostFormScreen extends StatefulWidget {
  final HomeService homeService;
  final CampusService campusService;
  final PostKind? kind; // a new post of this kind…
  final String? orgId; // …or a new post for this club…
  final String? postId; // …or edit this post

  const PostFormScreen({
    super.key,
    required this.homeService,
    required this.campusService,
    this.kind,
    this.orgId,
    this.postId,
  });

  /// The kinds a teacher can post, with their form titles.
  static const kinds = {
    PostKind.announcement: 'Announcement',
    PostKind.schoolNews: 'School News',
    PostKind.campusUpdate: 'Campus Update',
  };

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

/// Who a post goes to: a key for the dropdown, words for people, and how
/// the service filters it (a tag label or a class).
typedef _Audience = ({String key, String label, String? tag, String? classId});

class _PostFormScreenState extends State<PostFormScreen> {
  Future<bool>? _ready; // true → the form may be shown
  final _title = TextEditingController();
  final _body = TextEditingController();
  late PostKind? _kind = widget.orgId != null ? PostKind.organizationNews : widget.kind;
  Organization? _club; // set for a club post
  List<_Audience> _audiences = const [];
  String _to = 'all';
  bool _urgent = false;
  List<String> _photos = []; // the first is the cover
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.postId == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready ??= _load(SessionScope.of(context).user!);
  }

  Future<bool> _load(UserProfile user) async {
    final post = _isNew ? null : await widget.homeService.findPost(widget.postId!);
    final clubId = widget.orgId ?? post?.orgId;
    if (clubId != null) {
      // A club post: only its adviser, to its members or to everyone.
      _club = (await widget.campusService.loadAdvisedClubs(user, power: ClubPower.posts))
          .where((c) => c.org.id == clubId)
          .firstOrNull
          ?.org;
      if (_club == null) return false;
      _audiences = [
        (key: 'tag:${_club!.name}', label: 'Members of ${_club!.name}', tag: _club!.name,
            classId: null),
        (key: 'all', label: 'Everyone at SMCL', tag: null, classId: null),
      ];
      _to = _audiences.first.key;
    } else {
      final classes = await widget.campusService.loadAssignedClasses(user);
      _audiences = [
        (key: 'all', label: 'Everyone at SMCL', tag: null, classId: null),
        for (final t in user.tags.where((t) => t.kind == TagKind.department))
          (key: 'tag:${t.label}', label: t.label, tag: t.label, classId: null),
        for (final ClassInfo c in classes)
          (key: 'class:${c.id}', label: '${c.subject} · ${c.section}', tag: null, classId: c.id),
      ];
    }
    if (post != null) {
      if (post.authorId != user.id) return false;
      _kind = post.kind;
      _title.text = post.title;
      _body.text = post.body;
      _urgent = post.urgent;
      _photos = [...post.images];
      _to = post.classId != null
          ? 'class:${post.classId}'
          : post.audience != null
              ? 'tag:${post.audience}'
              : 'all';
      // A class or department the teacher no longer has: keep it as it was.
      if (!_audiences.any((a) => a.key == _to)) {
        _audiences = [
          ..._audiences,
          (key: _to, label: post.sentTo ?? _to, tag: post.audience, classId: post.classId),
        ];
      }
    }
    if (!_isNew && post == null) return false;
    return _club != null ||
        (user.can(Permission.postToCampusFeed) && PostFormScreen.kinds.containsKey(_kind));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// School News always goes to everyone.
  _Audience get _audience => _kind == PostKind.schoolNews
      ? _audiences.first
      : _audiences.firstWhere((a) => a.key == _to, orElse: () => _audiences.first);

  /// Announcements and club posts can be urgent; urgent ones notify.
  bool get _canBeUrgent => _kind == PostKind.announcement || _club != null;

  bool get _notifies => _canBeUrgent && _urgent;

  /// Announcements stay text only (decided 2026-10-31).
  bool get _canHavePhotos =>
      _kind == PostKind.schoolNews || _kind == PostKind.campusUpdate || _club != null;

  List<String> get _postPhotos => _canHavePhotos ? _photos : const [];

  Future<void> _addPhotos() async {
    try {
      final added = await pickPhotos(context, limit: maxPostPhotos - _photos.length);
      if (mounted) setState(() => _photos = [..._photos, ...added]);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't add the photo. Try another one.");
    }
  }

  String? get _problem {
    if (_title.text.trim().isEmpty) return 'Add a title.';
    if (_body.text.trim().isEmpty) return 'Add a message.';
    return null;
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final to = _audience;
    final notifies = _notifies;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.homeService.savePost(
        session.user!,
        postId: widget.postId,
        orgId: _club?.id,
        kind: _kind!,
        title: _title.text,
        body: _body.text,
        audience: to.tag,
        classId: to.classId,
        sentTo: to.label,
        urgent: _notifies,
        images: _postPhotos,
      );
    } catch (e) {
      // Never claim success when the save failed.
      final reason = e is ArgumentError ? '${e.message}' : e is StateError ? e.message : null;
      if (mounted) setState(() => _error = 'Not saved. ${reason ?? "Couldn't reach the service."}');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh(); // after closing, so Home and the post page reload
    messenger.showSnackBar(SnackBar(
      content: Text(switch ((_isNew, notifies)) {
        (true, true) => 'Posted in this preview only. Its audience gets a notification in '
            'this preview; nothing is really sent.',
        (true, false) => 'Posted in this preview only. Not sent to anyone.',
        (false, true) => 'Changes saved in this preview only. Its notification was updated.',
        (false, false) => 'Changes saved in this preview only. Nobody was notified.',
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = !_isNew
        ? 'Edit Post'
        : widget.orgId != null
            ? 'New Club Post'
            : 'New ${PostFormScreen.kinds[_kind] ?? 'Post'}';
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _ready,
          builder: (context, snap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackHeader(title),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError || snap.data != true)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                      snap.hasError
                          ? "Couldn't load this form."
                          : _isNew
                              ? "You don't have permission to post."
                              : "You can't edit this post.",
                      style: text.bodyLarge?.copyWith(color: AppColors.muted),
                    ),
                  )
                else ...[
                  Expanded(child: _form()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: !_saving && _problem == null ? _save : null,
                      child: Text(_saving ? 'Saving…' : _isNew ? 'Post' : 'Save Changes'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form() {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final problem = _problem;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
      children: [
        TextField(
          controller: _title,
          onChanged: (_) => setState(() {}),
          style: text.titleLarge,
          maxLength: 120,
          decoration: InputDecoration(
              hintText: _kind == PostKind.schoolNews ? 'Headline' : 'Title', counterText: ''),
        ),
        _label('Message'),
        TextField(
          controller: _body,
          onChanged: (_) => setState(() {}),
          minLines: 4,
          maxLines: 10,
          maxLength: 1000,
          decoration: InputDecoration(
              hintText: _kind == PostKind.schoolNews
                  ? 'Tell the story'
                  : 'What should people know?'),
        ),
        _label('Who sees it'),
        if (_kind == PostKind.schoolNews)
          Text('School News goes to everyone at SMCL.', style: text.bodyLarge)
        else
          DropdownButtonFormField<String>(
            initialValue: _audience.key,
            isExpanded: true, // long class and department names shorten instead of overflowing
            items: [
              for (final a in _audiences)
                DropdownMenuItem(
                  value: a.key,
                  child: Text(a.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (k) => setState(() => _to = k ?? 'all'),
          ),
        if (_canBeUrgent) ...[
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as urgent'),
            subtitle: const Text('Shown first, with an URGENT label. Notifies who can see it.'),
            value: _urgent,
            onChanged: (v) => setState(() => _urgent = v),
          ),
        ],
        if (_canHavePhotos) ...[
          _label('Photos · ${_photos.length} of $maxPostPhotos'),
          _photoStrip(),
          const SizedBox(height: AppSpacing.xs),
          Text(
              _photos.length > 1
                  ? 'Hold a photo and drag it to change the order. The first is the cover. '
                      'Kept in this preview only, never uploaded anywhere.'
                  : 'Kept in this preview only, never uploaded anywhere.',
              style: muted),
        ],
        _label('Preview'),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _preview(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
            _notifies
                ? 'Kept in this preview only. Who can see it gets an urgent notification in '
                    'this preview; nothing is really sent.'
                : 'Posts are kept in this preview only. Nobody is notified.',
            style: muted),
        if (_error != null || problem != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error ?? problem!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// The row as Home will show it.
  Widget _preview() {
    final user = SessionScope.of(context).user!;
    final title = _title.text.trim();
    return ContentRow(
      source: _club?.name ?? user.fullName,
      sourceImage: _club != null
          ? _club!.logoAsset
          : _kind == PostKind.campusUpdate
              ? user.photoAsset
              : null,
      title: title.isEmpty ? 'Your title appears here' : title,
      meta: 'Just now · ${_audience.label}',
      metaIcon: Icons.schedule_rounded,
      imageAsset: _postPhotos.firstOrNull,
      placeholderIcon: switch (_kind) {
        PostKind.schoolNews => Icons.article_outlined,
        PostKind.campusUpdate || PostKind.organizationNews => Icons.campaign_outlined,
        _ => null,
      },
      pill: _notifies
          ? const StatusPill('URGENT', tone: PillTone.red)
          : null,
    );
  }

  /// Thumbnails to remove or reorder, then an Add button while there's room.
  Widget _photoStrip() {
    const size = 88.0;
    final radius = BorderRadius.circular(AppRadius.small);
    return SizedBox(
      height: size,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        onReorderItem: (from, to) => setState(() => _photos.insert(to, _photos.removeAt(from))),
        footer: _photos.length < maxPostPhotos
            ? Semantics(
                button: true,
                label: 'Add photos',
                child: InkWell(
                  onTap: _addPhotos,
                  borderRadius: radius,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: AppColors.track, borderRadius: radius),
                    child: const ExcludeSemantics(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.trackText),
                          SizedBox(height: AppSpacing.xs),
                          Text('Add', style: TextStyle(color: AppColors.trackText)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        children: [
          for (var i = 0; i < _photos.length; i++)
            Padding(
              key: ValueKey(_photos[i]),
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Stack(
                children: [
                  ReorderableDelayedDragStartListener(
                    index: i,
                    child: Semantics(
                      image: true,
                      label: i == 0 ? 'Photo 1, the cover' : 'Photo ${i + 1}',
                      child: ClipRRect(
                        borderRadius: radius,
                        child: PostImage(_photos[i], width: size, height: size, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      tooltip: 'Remove photo ${i + 1}',
                      onPressed: () => setState(() => _photos.removeAt(i)),
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/photo_carousel.dart';
import '../../widgets/rich_caption.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/user_avatar.dart';

/// Detail page for an announcement, news item, or organization post. The
/// author of a post made in this preview can edit or delete it.
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final HomeService homeService;

  const PostDetailScreen({super.key, required this.postId, required this.homeService});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Future<Post?>? _post;
  String? _loadedFor; // Session.dataKey the post belongs to
  bool _deleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload after an edit (the form refreshes the session).
    final key = SessionScope.of(context).dataKey;
    if (key != _loadedFor) {
      _loadedFor = key;
      _post = widget.homeService.findPost(widget.postId);
    }
  }

  Future<void> _delete(Post p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('It will be removed from Home for everyone in this preview.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _deleting = true);
    try {
      await widget.homeService.deletePost(session.user!, p.id);
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't delete this post.")));
      return;
    }
    router.pop();
    session.refresh();
    messenger.showSnackBar(const SnackBar(content: Text('Post deleted from this preview.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final me = SessionScope.of(context).user;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Post?>(
          future: _post,
          builder: (context, snap) {
            final p = snap.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 120),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (snap.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snap.hasError)
                  Text("Couldn't load this post.", style: text.titleMedium)
                else if (p == null)
                  Text("This post isn't available.", style: text.titleMedium)
                else ...[
                  if (p.images.isNotEmpty) ...[
                    PhotoCarousel(p.images),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Row(
                    children: [
                      UserAvatar(name: p.source, imageAsset: p.sourceImage, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${p.source} · ${formatTimeAgo(p.publishedAt, DateTime.now())}'
                          '${p.edited ? ' · Edited' : ''}',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(p.title, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  RichCaption(p.body, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.section),
                  if (p.authorId != null) ...[
                    if (p.sentTo != null)
                      Text('Posted to: ${p.sentTo}',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                    Text(
                        p.kind == PostKind.announcement && p.urgent
                            ? 'Posted in this preview only. Its audience got an urgent '
                                'notification in this preview.'
                            : 'Posted in this preview only. Nobody was notified.',
                        style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  ] else
                    Text('Sample post for the prototype — not an official announcement.',
                        style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  if (me != null && p.authorId == me.id) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _deleting
                                ? null
                                // Edit lives under whichever page opened the post.
                                : () => context.push(
                                    '${GoRouterState.of(context).uri.path}/edit'),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _deleting ? null : () => _delete(p),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(_deleting ? 'Deleting…' : 'Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

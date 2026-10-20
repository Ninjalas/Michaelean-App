import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../services/home_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/user_avatar.dart';

/// Detail page for an announcement, news item, or organization post.
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final HomeService homeService;

  const PostDetailScreen({super.key, required this.postId, required this.homeService});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final Future<Post?> _post = widget.homeService.findPost(widget.postId);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                else if (p == null)
                  Text("This post isn't available.", style: text.titleMedium)
                else ...[
                  if (p.imageAsset != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      child: Image.asset(p.imageAsset!, width: double.infinity),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Row(
                    children: [
                      UserAvatar(name: p.source, imageAsset: p.sourceImage, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${p.source} · ${formatTimeAgo(p.publishedAt, DateTime.now())}',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(p.title, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text(p.body, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.section),
                  Text('Sample post for the prototype — not an official announcement.',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

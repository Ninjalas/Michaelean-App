import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';

/// Recent notifications, shown inside the shared pop-up and grouped into
/// Today / Earlier (spec §6). Opening one only navigates; it changes no record.
class NotificationsSheet extends StatefulWidget {
  final HomeService homeService;

  const NotificationsSheet({super.key, required this.homeService});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  Future<List<AppNotification>>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= widget.homeService.loadNotifications(SessionScope.of(context).user!);
  }

  void _open(AppNotification n) {
    final router = GoRouter.of(context);
    router.pop(); // close the pop-up first
    router.push(n.postId != null
        ? '/home/post/${n.postId}'
        : Uri(path: '/home/soon', queryParameters: {'what': n.title}).toString());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: (context, snap) {
        final now = DateTime.now(); // read after loading, so "1h ago" isn't "59m ago"
        final items = snap.data;
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Text("Couldn't load notifications."),
          );
        }
        if (items == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.section),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Text('No notifications yet.'),
          );
        }
        bool isToday(DateTime t) =>
            t.year == now.year && t.month == now.month && t.day == now.day;
        final today = items.where((n) => isToday(n.time)).toList();
        final earlier = items.where((n) => !isToday(n.time)).toList();
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          children: [
            if (today.isNotEmpty) ..._group('Today', today, now),
            if (earlier.isNotEmpty) ..._group('Earlier', earlier, now),
          ],
        );
      },
    );
  }

  List<Widget> _group(String label, List<AppNotification> items, DateTime now) {
    final text = Theme.of(context).textTheme;
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Semantics(
          header: true,
          child: Text(label, style: text.labelMedium?.copyWith(color: AppColors.muted)),
        ),
      ),
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 52),
        _row(items[i], now),
      ],
    ];
  }

  Widget _row(AppNotification n, DateTime now) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _open(n),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
              child: Icon(_icon(n.kind), size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatTimeAgo(n.time, now),
                style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  static IconData _icon(NotificationKind k) => switch (k) {
        NotificationKind.announcement => Icons.campaign_outlined,
        NotificationKind.organization => Icons.groups_outlined,
        NotificationKind.schedule => Icons.event_note_outlined,
        NotificationKind.clearance => Icons.fact_check_outlined,
        NotificationKind.attendance => Icons.how_to_reg_outlined,
        NotificationKind.news => Icons.article_outlined,
      };
}

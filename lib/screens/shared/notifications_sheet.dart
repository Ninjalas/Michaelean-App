import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed.dart';
import '../../services/home_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/content_row.dart';

/// Recent notifications, shown inside the shared pop-up (spec §6).
/// Opening one only navigates; it changes no record.
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
    final now = DateTime.now();
    return FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: (context, snap) {
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
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => ContentRow(
            title: items[i].title,
            meta: formatTimeAgo(items[i].time, now),
            onTap: () => _open(items[i]),
          ),
        );
      },
    );
  }
}

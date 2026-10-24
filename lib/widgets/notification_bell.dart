import 'package:flutter/material.dart';
import '../services/notification_inbox.dart';
import '../screens/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: NotificationInbox.instance,
      builder: (context, _) {
        final count = NotificationInbox.instance.unreadCount;
        return IconButton(
            tooltip:
                count > 0 ? '$count unread notifications' : 'Notifications',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            icon: Badge(
                isLabelVisible: count > 0,
                label: Text(count > 99 ? '99+' : '$count'),
                child: const Icon(Icons.notifications_none_rounded)));
      });
}

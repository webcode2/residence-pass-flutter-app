import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';

class GuardNotificationBell extends StatelessWidget {
  const GuardNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = NotificationInbox.instance;
    return ListenableBuilder(
      listenable: inbox,
      builder: (context, _) {
        final count = inbox.unreadCount;
        return IconButton(
          tooltip: count == 0 ? 'Notifications' : '$count unread notifications',
          icon: Badge.count(
            count: count,
            isLabelVisible: count > 0,
            maxCount: 99,
            child: const Icon(Icons.notifications_none_rounded),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const _GuardInboxRoute()),
          ),
        );
      },
    );
  }
}

class _GuardInboxRoute extends StatefulWidget {
  const _GuardInboxRoute();

  @override
  State<_GuardInboxRoute> createState() => _GuardInboxRouteState();
}

class _GuardInboxRouteState extends State<_GuardInboxRoute> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // The shared screen refreshes synchronously on mount. Let the covered
    // guard app bars detach their inbox listeners before mounting that screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? const NotificationsScreen() : const Scaffold();
}

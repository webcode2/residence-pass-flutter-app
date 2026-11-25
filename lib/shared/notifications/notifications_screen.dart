import 'package:flutter/material.dart';
import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/ui/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final inbox = NotificationInbox.instance;
  @override
  void initState() {
    super.initState();
    inbox.refresh();
  }

  Future<void> read(String? id) async {
    try {
      await inbox.markRead(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not mark notifications as read. Please retry.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: inbox,
      builder: (context, _) => Scaffold(
            appBar: AppBar(
                title: Text(inbox.unreadCount > 0
                    ? 'Notifications (${inbox.unreadCount})'
                    : 'Notifications'),
                actions: [
                  if (inbox.unreadCount > 0)
                    TextButton(
                        onPressed: () => read(null),
                        child: const Text('Mark all read'))
                ]),
            body: RefreshIndicator(
                onRefresh: inbox.refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: TokenTheme.pageSidePadding, vertical: 12),
                    children: [
                      if (inbox.loading && inbox.items.isEmpty)
                        const Center(child: CircularProgressIndicator()),
                      if (inbox.error != null)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(inbox.error!,
                                style: const TextStyle(color: Colors.red))),
                      if (!inbox.loading &&
                          inbox.items.isEmpty &&
                          inbox.error == null)
                        const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No notifications yet.',
                                textAlign: TextAlign.center)),
                      for (final item in inbox.items)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          leading: Icon(
                              item['is_read'] == true
                                  ? Icons.notifications_none
                                  : Icons.notifications_active_outlined,
                              color: item['is_read'] == true
                                  ? null
                                  : TokenTheme.primaryMint),
                          title: Text(item['title'] as String,
                              style: TextStyle(
                                  fontWeight: item['is_read'] == true
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(
                              '${item['body']}\n${DateTime.tryParse(item['created_at'] as String)?.toLocal().toString().split('.').first ?? ''}'),
                          isThreeLine: true,
                          onTap: () async {
                            await read(item['id'] as String);
                            if (!context.mounted) return;
                            final data =
                                Map<String, dynamic>.from(item['data'] as Map);
                            if (data['type'] == 'chat_message' ||
                                data['type'] == 'sos_missed') {
                              Navigator.pop(context);
                              FCMService.instance
                                  .handleChatMessage(data, opened: true);
                            }
                          },
                        ),
                      if (inbox.hasMore)
                        TextButton(
                            onPressed: inbox.loading ? null : inbox.loadMore,
                            child: Text(inbox.loading
                                ? 'Loading…'
                                : 'Load older notifications')),
                    ])),
          ));
}

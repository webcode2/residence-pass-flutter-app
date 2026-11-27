import 'package:flutter/material.dart';
import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/ui/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.announcementId});
  final String? announcementId;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final inbox = NotificationInbox.instance;
  Map<String, dynamic>? _opened;
  String? _announcementError;

  String? category(Map<String, dynamic> item) {
    final data = item['data'] as Map?;
    if (data?['type'] != 'announcement') return null;
    const labels = {
      'alert': 'Alert',
      'maintenance': 'Maintenance',
      'security': 'Security',
    };
    return labels[data?['category']] ?? 'Announcement';
  }

  Future<void> _loadAnnouncement() async {
    final id = widget.announcementId;
    if (id == null) return;
    try {
      final item = await inbox.getAnnouncement(id);
      if (!mounted) return;
      setState(() {
        _opened = item;
        _announcementError = null;
      });
      await read(item['id'] as String);
      await inbox.refresh();
    } catch (_) {
      if (mounted) {
        setState(
            () => _announcementError = 'Unable to open this announcement.');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    inbox.refresh();
    _loadAnnouncement();
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
                      if (_opened != null)
                        Card(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2B2B2B)
                              : const Color(0xFFE7E7E7),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category(_opened!) ?? 'Announcement'),
                                const SizedBox(height: 8),
                                Text(_opened!['title'] as String,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text(_opened!['body'] as String),
                              ],
                            ),
                          ),
                        ),
                      if (_announcementError != null)
                        ListTile(
                          title: Text(_announcementError!),
                          trailing: TextButton(
                            onPressed: _loadAnnouncement,
                            child: const Text('Retry'),
                          ),
                        ),
                      if (widget.announcementId != null &&
                          _opened == null &&
                          _announcementError == null)
                        const LinearProgressIndicator(),
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
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? TokenTheme.darkAccent
                                      : TokenTheme.primaryMint),
                          title: Text(item['title'] as String,
                              style: TextStyle(
                                  fontWeight: item['is_read'] == true
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(
                              '${category(item) == null ? '' : '${category(item)}\n'}${item['body']}\n${DateTime.tryParse(item['created_at'] as String)?.toLocal().toString().split('.').first ?? ''}'),
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

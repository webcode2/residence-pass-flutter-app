import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/notifications/notifications_screen.dart';
import 'package:estate/shared/ui/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Notification bell labels unread count and hides zero',
      (tester) async {
    final inbox = NotificationInbox.instance;
    inbox.unreadCount = 7;
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationBell())));
    expect(find.text('7'), findsOneWidget);
    expect(find.byTooltip('7 unread notifications'), findsOneWidget);
    inbox.unreadCount = 123;
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: NotificationBell(key: ValueKey('updated')))));
    expect(find.text('99+'), findsOneWidget);
    expect(find.byTooltip('123 unread notifications'), findsOneWidget);
    inbox.clear();
    await tester.pump();
    expect(find.text('99+'), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('Announcement categories appear in the notification inbox',
      (tester) async {
    final inbox = NotificationInbox.instance;
    addTearDown(inbox.clear);
    inbox.items = [
      for (final category in ['alert', 'maintenance', 'security'])
        {
          'title': 'Estate update',
          'body': 'Please read this notice.',
          'data': {'type': 'announcement', 'category': category},
          'created_at': '2026-11-26T10:00:00Z',
          'is_read': false,
        }
    ];
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    for (final label in ['Alert', 'Maintenance', 'Security']) {
      expect(find.textContaining('$label\nPlease read this notice.'),
          findsOneWidget);
    }
  });

  test('Only tapping an announcement queues its deep link', () {
    final fcm = FCMService.instance;
    addTearDown(() => fcm.pendingAnnouncement.value = null);
    final announcement = <String, dynamic>{
      'type': 'announcement',
      'announcement_id': 'test-announcement',
      'app_id': 'test-estate',
    };
    fcm.handleChatMessage(announcement);
    expect(fcm.pendingAnnouncement.value, isNull);
    fcm.handleChatMessage(announcement, opened: true);
    expect(fcm.pendingAnnouncement.value, announcement);
  });
}

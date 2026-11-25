import 'package:estate/shared/notifications/notification_inbox.dart';
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
}

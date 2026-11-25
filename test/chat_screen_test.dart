import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatService extends ChatService {
  int reads = 0;
  bool failSend = false;
  @override
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    if (body != null) {
      if (failSend) throw Exception('Unable to send');
      return {};
    }
    reads++;
    if (path.startsWith('threads/')) {
      return {
        'id': 'thread-1',
        'status': 'open',
        'messages': <dynamic>[],
        'gate_site_name': 'Main gate',
        'has_active_emergency': false
      };
    }
    return <dynamic>[];
  }
}

void main() {
  testWidgets('chat refreshes for matching FCM events without polling',
      (tester) async {
    final api = FakeChatService();
    await tester.pumpWidget(
        MaterialApp(home: ChatScreen(threadId: 'thread-1', service: api)));
    await tester.pumpAndSettle();
    expect(api.reads, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(api.reads, 1);
    FCMService.instance
        .handleChatMessage({'type': 'chat_message', 'thread_id': 'other'});
    await tester.pumpAndSettle();
    expect(api.reads, 1);
    FCMService.instance
        .handleChatMessage({'type': 'chat_message', 'thread_id': 'thread-1'});
    await tester.pumpAndSettle();
    expect(api.reads, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed sends preserve draft and expose retryable error',
      (tester) async {
    final api = FakeChatService()..failSend = true;
    await tester.pumpWidget(
        MaterialApp(home: ChatScreen(threadId: 'thread-1', service: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Please open the gate');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Please open the gate'), findsOneWidget);
    expect(find.text('Unable to send'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guards cannot initiate conversations', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ChatScreen(isGuard: true, service: FakeChatService())));
    await tester.pumpAndSettle();
    expect(find.text('New chat'), findsNothing);
    expect(find.text('No conversations yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

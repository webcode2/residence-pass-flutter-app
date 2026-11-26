import 'package:estate/gate/screens/gate_chat_thread_screen.dart';
import 'package:estate/gate/ui/whatsapp_chat_tile.dart';
import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/ui/theme.dart';
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

class GuardChatFixture extends ChatService {
  final writes = <String, Map<String, dynamic>>{};
  bool resolved = false;

  @override
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    if (body != null) {
      writes[path] = body;
      if (path.endsWith('/resolve')) resolved = true;
      return {};
    }
    if (path.startsWith('threads?')) {
      return [
        {
          'id': 'thread-1',
          'resident_name': 'Tomi Adeyemi',
          'status': resolved ? 'resolved' : 'open',
          'last_message_text': 'Thank you. I’ll meet the courier at the gate.',
          'guard_unread_count': 2,
        },
        {
          'id': 'thread-2',
          'resident_name': 'Amara Nwosu',
          'status': 'open',
          'last_message_text': 'Please send an officer to the courtyard.',
          'has_active_emergency': true,
          'guard_unread_count': 1,
        },
        {
          'id': 'thread-3',
          'resident_name': 'Daniel Bello',
          'status': 'closed',
          'last_message_text': 'The guest has left the estate.',
        },
      ];
    }
    if (path == 'threads/thread-1') {
      return {
        'id': 'thread-1',
        'status': resolved ? 'resolved' : 'open',
        'resident_name': 'Tomi Adeyemi',
        'messages': [
          {
            'sender_id': 'resident-1',
            'sender_name': 'Tomi Adeyemi',
            'message': 'A courier is arriving with a delivery for my unit.',
            'created_at': '2026-11-25T10:12:00',
          },
          {
            'sender_id': 'fixture-guard',
            'sender_name': 'Ada Okafor',
            'officer_post': 'Main gate',
            'message': 'Package at security desk',
            'status_tag': 'DELIVERY',
            'created_at': '2026-11-25T10:14:00',
            'is_read': true,
          },
          {
            'sender_id': 'resident-1',
            'sender_name': 'Tomi Adeyemi',
            'message': 'Thank you. I’ll meet the courier at the gate.',
            'created_at': '2026-11-25T10:16:00',
          },
        ],
      };
    }
    throw StateError('Unexpected fixture request: $path');
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
        home: GateChatThreadScreen(isGuard: true, service: FakeChatService())));
    await tester.pumpAndSettle();
    expect(find.text('New chat'), findsNothing);
    expect(find.text('No conversations yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guard inbox opens a shared thread with guard actions',
      (tester) async {
    final api = GuardChatFixture();
    addTearDown(() => ChatService.guardUnread.value = 0);
    await tester.pumpWidget(
        MaterialApp(home: GateChatThreadScreen(isGuard: true, service: api)));
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.text('New chat'), findsNothing);
    expect(ChatService.guardUnread.value, 3);

    await tester.tap(find.text('Tomi Adeyemi'));
    await tester.pumpAndSettle();
    expect(
        find.text('A courier is arriving with a delivery for my unit.',
            findRichText: true),
        findsOneWidget);
    expect(
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        TokenTheme.lightBg);
    expect(find.byTooltip('Send as emergency'), findsNothing);
    await tester.tap(find.text('CLEARED'));
    await tester.pumpAndSettle();
    expect(api.writes['threads/thread-1/messages'], {
      'message': 'Visitor cleared through gate',
      'status_tag': 'CLEARED',
    });
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();
    expect(api.writes['threads/thread-1/resolve'], isEmpty);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guard inbox search and unread tab filter the list', (tester) async {
    final api = GuardChatFixture();
    addTearDown(() => ChatService.guardUnread.value = 0);
    await tester.pumpWidget(
        MaterialApp(home: GateChatThreadScreen(isGuard: true, service: api)));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsAppChatTile), findsNWidgets(3));
    final inboxPadding =
        tester.widget<ListView>(find.byType(ListView)).padding as EdgeInsets;
    expect(
      inboxPadding.top,
      12,
      reason: 'the first row must sit below the app bar and tabs',
    );

    await tester.enterText(find.byType(TextField), 'Amara');
    await tester.pumpAndSettle();
    expect(find.byType(WhatsAppChatTile), findsOneWidget);
    expect(find.text('Tomi Adeyemi'), findsNothing);
    expect(find.text('Amara Nwosu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsAppChatTile), findsNWidgets(2));
    expect(find.text('Daniel Bello'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}

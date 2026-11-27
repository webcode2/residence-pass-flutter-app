import 'dart:async';

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
  Map<String, dynamic>? createdThread;
  @override
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    if (body != null) {
      if (failSend) throw Exception('Unable to send');
      if (path == 'threads') {
        createdThread = body;
        return {'id': 'thread-1'};
      }
      return {};
    }
    reads++;
    if (path == 'gates') {
      return [
        {'id': 'north', 'name': 'North gate'}
      ];
    }
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

class DelayedChatService extends FakeChatService {
  final pending = <Completer<Map<String, dynamic>>>[];
  final submitted = <Map<String, dynamic>>[];

  @override
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) {
    if (body == null || !path.endsWith('/messages')) {
      return super.request(path, body: body);
    }
    final response = Completer<Map<String, dynamic>>();
    pending.add(response);
    submitted.add(body);
    return response.future;
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
  testWidgets('Resident starts a chat from the gatehouse bottom sheet',
      (tester) async {
    final api = FakeChatService();
    await tester.pumpWidget(MaterialApp(home: ChatScreen(service: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Primary gate')),
        findsOneWidget);
    final start = find.widgetWithText(FilledButton, 'Start chat');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        'Please meet me at the gate.');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('North gate').last);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(api.createdThread, {
      'initial_message': 'Please meet me at the gate.',
      'is_emergency': false,
      'gate_site_id': 'north',
    });
  });

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

  testWidgets('failed sends stay in chat with tappable error details',
      (tester) async {
    final api = FakeChatService()..failSend = true;
    await tester.pumpWidget(
        MaterialApp(home: ChatScreen(threadId: 'thread-1', service: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Please open the gate');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Please open the gate'), findsOneWidget);
    final status = find.ancestor(
      of: find.textContaining('Send failed'),
      matching: find.byType(TextButton),
    );
    expect(status, findsOneWidget);
    await tester.tap(status);
    await tester.pumpAndSettle();
    expect(find.text('Unable to send'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('composer stays available while earlier messages are sending',
      (tester) async {
    final api = DelayedChatService();
    await tester.pumpWidget(
        MaterialApp(home: ChatScreen(threadId: 'thread-1', service: api)));
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    final send = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Send message');

    await tester.enterText(field, 'First message');
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('First message'), findsOneWidget);
    expect(find.textContaining('Sending'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(tester.widget<IconButton>(send).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.enterText(field, 'Next message');
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(api.pending, hasLength(2));

    api.pending[0].complete({'id': 'first'});
    await tester.pumpAndSettle();
    expect(find.textContaining('Sent'), findsOneWidget);
    expect(find.textContaining('Sending'), findsOneWidget);
    api.pending[1].complete({'id': 'second'});
    await tester.pumpAndSettle();
    expect(find.textContaining('Sent'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('emergency icon in the composer toggles without sending',
      (tester) async {
    final api = DelayedChatService();
    await tester.pumpWidget(
        MaterialApp(home: ChatScreen(threadId: 'thread-1', service: api)));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, 'Please send a guard');
    expect(tester.widget<TextField>(field).decoration!.suffixIcon,
        isA<IconButton>());
    await tester.tap(find.byTooltip('Turn on emergency mode'));
    await tester.pumpAndSettle();
    expect(api.submitted, isEmpty);
    expect(find.text('Emergency message'), findsOneWidget);

    await tester.tap(find.byTooltip('Turn off emergency mode'));
    await tester.pumpAndSettle();
    expect(api.submitted, isEmpty);
    await tester.tap(find.byTooltip('Turn on emergency mode'));
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(api.submitted.single, {
      'message': 'Please send a guard',
      'status_tag': 'EMERGENCY',
    });
    expect(find.byTooltip('Turn on emergency mode'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    api.pending.single.complete({'id': 'emergency'});
    await tester.pumpAndSettle();
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
    expect(tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
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

  testWidgets('guard inbox search and unread tab filter the list',
      (tester) async {
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

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byTooltip('Search chats'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
    await tester.enterText(find.byType(TextField), 'Amara');
    await tester.pumpAndSettle();
    expect(find.byType(WhatsAppChatTile), findsOneWidget);
    expect(find.text('Tomi Adeyemi'), findsNothing);
    expect(find.text('Amara Nwosu'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(WhatsAppChatTile), findsNWidgets(3));
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsAppChatTile), findsNWidgets(2));
    expect(find.text('Daniel Bello'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}

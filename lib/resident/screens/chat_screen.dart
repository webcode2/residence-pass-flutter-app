import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen(
      {super.key, this.isGuard = false, this.threadId, this.service});

  final bool isGuard;
  final String? threadId;
  final ChatService? service;

  @override
  Widget build(BuildContext context) => SharedChatScreen(
        isGuard: isGuard,
        inboxTitle: isGuard ? 'Resident chat' : 'Gatehouse chat',
        participantField: isGuard ? 'resident_name' : 'gate_site_name',
        participantFallback: isGuard ? 'Resident' : 'Gatehouse',
        threadId: threadId,
        service: service,
        buildThread: (id, api) =>
            ChatScreen(isGuard: isGuard, threadId: id, service: api),
      );
}

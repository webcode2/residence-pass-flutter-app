import 'package:estate/gate/screens/gate_chat_list_screen.dart';
import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';

class GateChatThreadScreen extends StatelessWidget {
  const GateChatThreadScreen(
      {super.key, this.isGuard = false, this.threadId, this.service});

  final bool isGuard;
  final String? threadId;
  final ChatService? service;

  @override
  Widget build(BuildContext context) {
    if (threadId == null && isGuard) {
      return GateChatListScreen(service: service);
    }
    final palette = GatePalette.of(context);
    final theme = Theme.of(context);
    // Keep the conversation neutral and aligned with the app's warm greys;
    // only the chat list uses the WhatsApp colour language.
    final conversationBg = palette.dark ? TokenTheme.darkBg : TokenTheme.lightBg;
    final incomingBubble =
        palette.dark ? TokenTheme.darkCard : const Color(0xFFF0F1EF);
    final outgoingBubble =
        palette.dark ? TokenTheme.darkTint(0.18) : const Color(0xFFE7E9E6);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: palette.accent,
          primaryContainer: outgoingBubble,
          surfaceContainerHighest: incomingBubble,
        ),
      ),
      child: SharedChatScreen(
        isGuard: isGuard,
        inboxTitle: isGuard ? 'Resident chat' : 'Gatehouse chat',
        participantField: isGuard ? 'resident_name' : 'gate_site_name',
        participantFallback: isGuard ? 'Resident' : 'Gatehouse',
        threadId: threadId,
        service: service,
        backgroundColor: conversationBg,
        buildHeader: (context, title, actions) =>
            gateHeader(context, title, actions: actions),
        buildEmptyInbox: (_) => const GateEmptyState(
            Icons.chat_bubble_outline, 'No conversations yet.'),
        buildInboxTile: _buildInboxTile,
        buildThread: (id, api) =>
            GateChatThreadScreen(isGuard: isGuard, threadId: id, service: api),
      ),
    );
  }

  Widget _buildInboxTile(
      BuildContext context, ChatInboxEntry entry, VoidCallback onTap) {
    final palette = GatePalette.of(context);
    final emergency = entry.emergency;
    final unread = entry.unread;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: emergency ? palette.danger : palette.line)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: onTap,
          leading: GateIcon(
              emergency ? Icons.emergency_outlined : Icons.chat_bubble_outline,
              emergency ? palette.danger : palette.accent),
          title: Text(entry.name,
              style: TextStyle(
                  color: palette.ink,
                  fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.preview.isNotEmpty)
                Text(entry.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                GateStatus(entry.status,
                    entry.status == 'Open' ? palette.accent : palette.muted),
                if (emergency) GateStatus('Emergency', palette.danger),
              ]),
            ],
          ),
          trailing: unread > 0
              ? Semantics(
                  label: '$unread unread messages',
                  child: ExcludeSemantics(
                      child: Badge.count(
                          count: unread,
                          backgroundColor: palette.action,
                          textColor: Colors.white)))
              : Icon(Icons.chevron_right, color: palette.muted),
        ),
      ),
    );
  }
}

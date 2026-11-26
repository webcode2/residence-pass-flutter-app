// Resident copy of the gate chat look (copied, not shared, so gate redesigns never change residents).
import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/resident/ui/whatsapp_chat_tile.dart';
import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:flutter/material.dart';

/// Resident inbox with the WhatsApp chat-list presentation.
///
/// Data loading, refresh, unread counts and navigation stay in
/// [SharedChatScreen]; only the header, search/filter controls and rows are
/// gate-specific.
class ResidentChatListScreen extends StatefulWidget {
  const ResidentChatListScreen({super.key, this.service});

  final ChatService? service;

  @override
  State<ResidentChatListScreen> createState() => _ResidentChatListScreenState();
}

class _ResidentChatListScreenState extends State<ResidentChatListScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _unreadOnly = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _unreadOnly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = WhatsAppPalette(dark);

    return AnimatedBuilder(
      animation: Listenable.merge([_search, _unreadOnly]),
      builder: (context, _) {
        return SharedChatScreen(
          isGuard: false,
          inboxTitle: 'Chats',
          participantField: 'gate_site_name',
          participantFallback: 'Resident',
          service: widget.service,
          backgroundColor: palette.canvas,
          inboxPadding: const EdgeInsets.only(top: 12, bottom: 8),
          inboxFilter: (entry) {
            final query = _search.text.trim().toLowerCase();
            final matches = query.isEmpty ||
                entry.name.toLowerCase().contains(query) ||
                entry.preview.toLowerCase().contains(query) ||
                (entry.unitAddress ?? '').toLowerCase().contains(query);
            return matches && (!_unreadOnly.value || entry.unread > 0);
          },
          buildHeader: (context, title, actions) => AppBar(
            backgroundColor: palette.header,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            titleSpacing: 4,
            leading: Scaffold.maybeOf(context)?.hasDrawer == true
                ? IconButton(
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  )
                : null,
            title: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Search chats',
                icon: const Icon(Icons.search_rounded),
                onPressed: () =>
                    FocusScope.of(context).requestFocus(_searchFocus),
              ),
              PopupMenuButton<int>(
                tooltip: 'More chat options',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (_) {
                  for (final action in actions) {
                    if (action is IconButton) action.onPressed?.call();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<int>(value: 0, child: Text('Refresh chat')),
                ],
              ),
            ],
          ),
          buildInboxHeader: (_) => _searchAndTabs(palette),
          buildInboxTile: (context, entry, onTap) => WhatsAppChatTile(
            entry: entry,
            onTap: onTap,
            dark: dark,
          ),
          buildEmptyInbox: (_) => SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 56, color: palette.textSecondary.withAlpha(90)),
                  const SizedBox(height: 12),
                  Text('No conversations yet.',
                      style: TextStyle(color: palette.textSecondary)),
                ],
              ),
            ),
          ),
          buildThread: (id, api) => ChatScreen(
            isGuard: false,
            threadId: id,
            service: api,
          ),
        );
      },
    );
  }

  Widget _searchAndTabs(WhatsAppPalette palette) {
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.header),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            TextField(
              controller: _search,
              focusNode: _searchFocus,
              style: TextStyle(color: palette.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search chats',
                hintStyle: TextStyle(color: Colors.white.withAlpha(180)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white70, size: 22),
                filled: true,
                fillColor: palette.searchFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InboxTab(
                    label: 'All',
                    selected: !_unreadOnly.value,
                    palette: palette,
                    onTap: () => _unreadOnly.value = false,
                  ),
                ),
                Expanded(
                  child: _InboxTab(
                    label: 'Unread',
                    selected: _unreadOnly.value,
                    palette: palette,
                    onTap: () => _unreadOnly.value = true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final WhatsAppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
}

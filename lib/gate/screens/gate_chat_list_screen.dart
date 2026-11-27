import 'package:estate/gate/screens/gate_chat_thread_screen.dart';
import 'package:estate/gate/ui/whatsapp_chat_tile.dart';
import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:flutter/material.dart';

/// Guard inbox with the WhatsApp chat-list presentation.
///
/// Data loading, refresh, unread counts and navigation stay in
/// [SharedChatScreen]; only the header, search/filter controls and rows are
/// gate-specific.
class GateChatListScreen extends StatefulWidget {
  const GateChatListScreen({super.key, this.service});

  final ChatService? service;

  @override
  State<GateChatListScreen> createState() => _GateChatListScreenState();
}

class _GateChatListScreenState extends State<GateChatListScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _unreadOnly = ValueNotifier<bool>(false);
  bool _searchOpen = false;

  void _openSearch() {
    setState(() => _searchOpen = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _search.clear();
    setState(() => _searchOpen = false);
  }

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
        return _swipeTabs(SharedChatScreen(
          isGuard: true,
          inboxTitle: 'Chats',
          participantField: 'resident_name',
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
                    tooltip: 'Open guard menu',
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
                onPressed: _openSearch,
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
          buildThread: (id, api) => GateChatThreadScreen(
            isGuard: true,
            threadId: id,
            service: api,
          ),
        ));
      },
    );
  }

  // Swipe left for Unread, right for All. A raw Listener (not a drag recognizer) so it
  // never competes with vertical scrolling or the left-edge drawer swipe.
  Offset? _swipeStart;
  DateTime? _swipeAt;

  Widget _swipeTabs(Widget child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _swipeStart = e.position.dx < 24 ? null : e.position;
          _swipeAt = DateTime.now();
        },
        onPointerUp: (e) {
          final start = _swipeStart, at = _swipeAt;
          _swipeStart = null;
          if (start == null || at == null) return;
          final dx = e.position.dx - start.dx, dy = e.position.dy - start.dy;
          final quick = DateTime.now().difference(at).inMilliseconds < 600;
          if (!quick || dx.abs() < 70 || dx.abs() < dy.abs() * 2) return;
          _unreadOnly.value = dx < 0;
        },
        child: child,
      );

  Widget _searchAndTabs(WhatsAppPalette palette) {
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.header),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            if (_searchOpen) ...[
              TextField(
                controller: _search,
                focusNode: _searchFocus,
                style: TextStyle(color: palette.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  hintStyle: TextStyle(color: palette.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: palette.textSecondary, size: 22),
                  suffixIcon: IconButton(
                    tooltip: 'Close search',
                    icon: const Icon(Icons.close_rounded),
                    color: palette.textSecondary,
                    onPressed: _closeSearch,
                  ),
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
            ],
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

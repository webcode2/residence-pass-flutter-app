import 'package:estate/shared/ui/theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:estate/shared/notifications/fcm_service.dart';

typedef ChatHeaderBuilder = PreferredSizeWidget Function(
    BuildContext context, String title, List<Widget> actions);
typedef ChatThreadBuilder = Widget Function(
    String threadId, ChatService service);
typedef ChatInboxTileBuilder = Widget Function(
    BuildContext context, ChatInboxEntry entry, VoidCallback onTap);
typedef ChatInboxFilter = bool Function(ChatInboxEntry entry);

class ChatInboxEntry {
  const ChatInboxEntry({
    required this.name,
    required this.status,
    required this.preview,
    required this.unread,
    required this.emergency,
    this.lastMessageAt,
    this.lastSenderRole,
    this.avatarUrl,
    this.unitAddress,
  });

  final String name;
  final String status;
  final String preview;
  final int unread;
  final bool emergency;

  /// Raw ISO timestamp from the server, formatted by the role-specific tile.
  final String? lastMessageAt;

  /// `resident`, `security` or `system`; lets a tile add a "You:" prefix.
  final String? lastSenderRole;

  /// Optional profile image. The server currently has no photo field, so tiles
  /// fall back to initials when this is null.
  final String? avatarUrl;

  /// Resident unit, used by role-specific tiles as a secondary identifier.
  final String? unitAddress;
}

class _InboxItem {
  const _InboxItem(this.thread, this.entry);

  final Map thread;
  final ChatInboxEntry entry;
}

/// Server-backed inbox and conversation experience for both mobile roles.
class SharedChatScreen extends StatefulWidget {
  const SharedChatScreen({
    super.key,
    required this.isGuard,
    required this.inboxTitle,
    required this.participantField,
    required this.participantFallback,
    required this.buildThread,
    this.buildHeader,
    this.buildInboxTile,
    this.buildEmptyInbox,
    this.buildInboxHeader,
    this.inboxFilter,
    this.inboxPadding,
    this.backgroundColor,
    this.threadId,
    this.service,
  });

  final bool isGuard;
  final String inboxTitle;
  final String participantField;
  final String participantFallback;
  final ChatThreadBuilder buildThread;
  final ChatHeaderBuilder? buildHeader;
  final ChatInboxTileBuilder? buildInboxTile;
  final WidgetBuilder? buildEmptyInbox;
  final WidgetBuilder? buildInboxHeader;
  final ChatInboxFilter? inboxFilter;
  final EdgeInsetsGeometry? inboxPadding;
  final Color? backgroundColor;
  final String? threadId;
  final ChatService? service;

  @override
  State<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends State<SharedChatScreen>
    with WidgetsBindingObserver {
  late final ChatService _api;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _threads = [];
  Map<String, dynamic>? _thread;
  String? _error;
  bool _loading = true, _refreshing = false, _sending = false;
  StreamSubscription<Map<String, dynamic>>? _events;
  bool _reloadRequested = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _api = widget.service ?? ChatService();
    _token = AuthService.instance.accessToken;
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.currentUserNotifier.addListener(_authChanged);
    _load();
    _events = FCMService.instance.chatEvents.listen((data) {
      if (widget.threadId == null || data['thread_id'] == widget.threadId) {
        _load();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _authChanged() {
    if (mounted) {
      _token = AuthService.instance.currentUser == null
          ? null
          : AuthService.instance.accessToken;
      if (widget.isGuard) ChatService.guardUnread.value = 0;
      setState(() {
        _threads = [];
        _thread = null;
        _text.clear();
      });
      _load();
    }
  }

  Future<void> _load() async {
    if (_refreshing) {
      _reloadRequested = true;
      return;
    }
    _refreshing = true;
    final token = _token;
    try {
      final result = await _api.request(widget.threadId == null
          ? 'threads?limit=200'
          : 'threads/${widget.threadId}');
      if (!mounted || token != _token) return;
      if (widget.threadId != null) NotificationInbox.instance.refresh();
      final oldCount = (_thread?['messages'] as List?)?.length ?? 0;
      setState(() {
        if (widget.threadId == null) {
          _threads = result as List;
          if (widget.isGuard) {
            ChatService.guardUnread.value = _threads.fold<int>(
                0, (sum, t) => sum + ((t['guard_unread_count'] as int?) ?? 0));
          }
        } else {
          _thread = Map<String, dynamic>.from(result as Map);
        }
        _error = null;
      });
      if ((_thread?['messages'] as List?)?.length != oldCount) _scrollToEnd();
    } catch (e) {
      if (mounted && token == _token) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _refreshing = false;
      if (mounted) {
        setState(() => _loading = false);
        if (_reloadRequested) {
          _reloadRequested = false;
          _load();
        }
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        final end = _scroll.position.maxScrollExtent;
        if (widget.isGuard || MediaQuery.disableAnimationsOf(context)) {
          _scroll.jumpTo(end);
        } else {
          _scroll.animateTo(end,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      }
    });
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => widget.buildThread(id, _api)));
    if (mounted) _load();
  }

  Future<void> _create() async {
    List<dynamic> gates;
    try {
      gates = await _api.request('gates') as List;
    } catch (e) {
      if (mounted) _notice(e);
      return;
    }
    if (!mounted) return;
    String draft = '';
    String? gate;
    bool emergency = false;
    final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Contact gatehouse'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                        initialValue: gate,
                        decoration: const InputDecoration(labelText: 'Gate'),
                        hint: const Text('Primary gate'),
                        items: gates
                            .map((g) => DropdownMenuItem<String>(
                                value: g['id'] as String,
                                child: Text(g['name'] as String)))
                            .toList(),
                        onChanged: (value) => update(() => gate = value)),
                    TextField(
                        maxLength: 4000,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Message'),
                        onChanged: (value) => update(() => draft = value)),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Emergency'),
                        value: emergency,
                        onChanged: (v) => update(() => emergency = v ?? false)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: draft.trim().isEmpty
                            ? null
                            : () => Navigator.pop(context, {
                                  'initial_message': draft.trim(),
                                  'is_emergency': emergency,
                                  if (gate != null) 'gate_site_id': gate
                                }),
                        child: const Text('Start chat'))
                  ],
                )));
    if (body == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final result = await _api.request('threads', body: body);
      if (mounted) await _open(result['id'] as String);
    } catch (e) {
      if (mounted) _notice(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _notice(Object e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  Future<void> _send({String? text, String? tag, bool resolve = false}) async {
    if (_sending || (!resolve && (text ?? _text.text).trim().isEmpty)) return;
    final draft = _text.text;
    setState(() => _sending = true);
    try {
      await _api.request(
          'threads/${widget.threadId}/${resolve ? 'resolve' : 'messages'}',
          body: resolve
              ? {}
              : {
                  'message': (text ?? draft).trim(),
                  if (tag != null) 'status_tag': tag
                });
      if (!mounted) return;
      if (!resolve && text == null && _text.text == draft) _text.clear();
      await _load();
      _scrollToEnd();
    } catch (e) {
      if (mounted) _notice(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.currentUserNotifier.removeListener(_authChanged);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _participant(Map? thread) =>
      thread?[widget.participantField]?.toString() ??
      widget.participantFallback;

  @override
  Widget build(BuildContext context) {
    final detail = widget.threadId != null;
    final thread = _thread;
    final messages = (thread?['messages'] as List?) ?? [];
    final closed = thread?['status'] == 'closed';
    final resolved = thread?['status'] == 'resolved';
    // A resolved thread is locked for guards until the resident replies and
    // reopens it. Residents keep the composer so they can do exactly that.
    final canSend =
        detail && thread != null && !closed && !(widget.isGuard && resolved);
    final title = detail ? _participant(thread) : widget.inboxTitle;
    final actions = [
      IconButton(
        tooltip: 'Refresh chat',
        onPressed: _load,
        icon: const Icon(Icons.refresh),
      ),
      if (detail && thread?['status'] == 'open')
        TextButton(
          onPressed: _sending ? null : () => _send(resolve: true),
          child: const Text('Resolve'),
        ),
    ];

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.buildHeader?.call(context, title, actions) ??
          AppBar(title: Text(title), actions: actions),
      floatingActionButton: !detail && !widget.isGuard
          ? FloatingActionButton.extended(
              onPressed: _sending ? null : _create,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('New chat'))
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              MaterialBanner(content: Text(_error!), actions: [
                TextButton(onPressed: _load, child: const Text('Retry')),
              ]),
            if (_loading)
              const LinearProgressIndicator(semanticsLabel: 'Loading chat'),
            if (detail && thread != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${_statusLabel(thread['status'])}${thread['has_active_emergency'] == true ? ' • Emergency' : ''}',
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: detail
                    ? _messages(messages)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.buildInboxHeader != null)
                            widget.buildInboxHeader!(context),
                          Expanded(child: _inbox()),
                        ],
                      ),
              ),
            ),
            if (canSend) _composer(),
          ],
        ),
      ),
    );
  }

  String _statusLabel(Object? status) {
    if (widget.isGuard) {
      if (status == 'closed' || status == 'resolved') return 'Resolved';
      if (status == 'open') return 'Open';
    }
    return status?.toString() ?? 'Unknown';
  }

  Widget _inbox() {
    final customEmpty = widget.buildEmptyInbox;
    final items = _threads.whereType<Map>().map((thread) {
      return _InboxItem(
        thread,
        ChatInboxEntry(
          name: _participant(thread),
          status: _statusLabel(thread['status']),
          preview: thread['last_message_text']?.toString() ?? '',
          unread: (thread[widget.isGuard
                  ? 'guard_unread_count'
                  : 'resident_unread_count'] as int?) ??
              0,
          emergency: thread['has_active_emergency'] == true,
          lastMessageAt: thread['last_message_at']?.toString(),
          lastSenderRole: thread['last_sender_role']?.toString(),
          avatarUrl: (thread['resident_avatar_url'] ??
                  thread['avatar_url'])
              ?.toString(),
          unitAddress: thread['unit_address']?.toString(),
        ),
      );
    }).toList();
    final filter = widget.inboxFilter;
    final visible =
        filter == null ? items : items.where((item) => filter(item.entry)).toList();
    final noThreads = _threads.isEmpty;
    final showEmpty = visible.isEmpty &&
        !_loading &&
        (_error == null || customEmpty == null);
    if (showEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: noThreads && customEmpty != null
            ? const EdgeInsets.all(TokenTheme.pageSidePadding)
            : EdgeInsets.zero,
        children: [
          if (noThreads && customEmpty != null)
            customEmpty(context)
          else
            SizedBox(
              height: 180,
              child: Center(
                  child: Text(noThreads ? 'No conversations yet.' : 'No chats found.')),
            ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.inboxPadding ??
          (widget.buildInboxTile == null
              ? const EdgeInsets.only(bottom: 90)
              : const EdgeInsets.fromLTRB(TokenTheme.pageSidePadding, 16,
                  TokenTheme.pageSidePadding, 96)),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final item = visible[index];
        void open() => _open(item.thread['id'] as String);
        return widget.buildInboxTile?.call(context, item.entry, open) ??
            ListTile(
              onTap: open,
              leading: Icon(item.entry.emergency
                  ? Icons.emergency
                  : Icons.chat_bubble_outline),
              title: Text(item.entry.name),
              subtitle: Text('${item.entry.status} • ${item.entry.preview}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: item.entry.unread > 0
                  ? Badge.count(count: item.entry.unread)
                  : null,
            );
      },
    );
  }

  Widget _messages(List messages) {
    final showEmpty =
        widget.isGuard && _thread != null && messages.isEmpty && _error == null;
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: TokenTheme.pageSidePadding, vertical: 16),
      itemCount: showEmpty ? 1 : messages.length,
      itemBuilder: (context, index) => showEmpty
          ? const Center(child: Text('No messages yet.'))
          : _messageBubble(messages[index] as Map),
    );
  }

  Widget _messageBubble(Map message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Keep bubbles on the Residence neutral scale in both apps; the seeded
    // ThemeData container colours are too green for a conversation surface.
    final outgoingBubble =
        isDark ? TokenTheme.darkTint(0.18) : const Color(0xFFE7E9E6);
    final incomingBubble =
        isDark ? TokenTheme.darkCard : const Color(0xFFF0F1EF);
    final mine = message['sender_id'] == AuthService.instance.currentUser?.id;
    final time = DateTime.tryParse(message['created_at'] ?? '')?.toLocal();
    final sender = [
      message['sender_name'],
      message['officer_badge'],
      message['officer_post'],
    ].where((part) => part != null && part.toString().isNotEmpty).join(' • ');
    final metadata = [
      if (time != null)
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      if (mine) message['is_read'] == true ? 'Read' : 'Sent',
    ].join(' • ');

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? outgoingBubble : incomingBubble,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sender.isNotEmpty)
              Text(sender, style: theme.textTheme.labelMedium),
            if (message['status_tag'] != null)
              Text(message['status_tag'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(message['message'] ?? ''),
            if (metadata.isNotEmpty)
              Text(metadata, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _composer() => Column(
        children: [
          if (widget.isGuard)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final entry in const {
                  'CLEARED': 'Visitor cleared through gate',
                  'DELIVERY': 'Package at security desk',
                  'DISPATCHED': 'Officer dispatched to your unit',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ActionChip(
                      label: Text(entry.key),
                      onPressed: _sending
                          ? null
                          : () => _send(text: entry.value, tag: entry.key),
                    ),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  maxLength: 4000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Message', border: OutlineInputBorder()),
                ),
              ),
              if (!widget.isGuard)
                IconButton(
                  tooltip: 'Send as emergency',
                  onPressed: _sending ? null : () => _send(tag: 'EMERGENCY'),
                  icon: const Icon(Icons.emergency_outlined),
                ),
              IconButton(
                tooltip: 'Send message',
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                            semanticsLabel: 'Sending message'))
                    : const Icon(Icons.send),
              ),
            ]),
          ),
        ],
      );
}

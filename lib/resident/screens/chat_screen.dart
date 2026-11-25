import 'package:estate/shared/ui/theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:estate/shared/notifications/notification_inbox.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/chat/chat_service.dart';
import 'package:estate/shared/notifications/fcm_service.dart';

/// Shared server-backed inbox for residents and security officers.
class ChatScreen extends StatefulWidget {
  final bool isGuard;
  final String? threadId;
  final ChatService? service;
  const ChatScreen(
      {super.key, this.isGuard = false, this.threadId, this.service});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
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
      ChatService.guardUnread.value = 0;
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
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(isGuard: widget.isGuard, threadId: id)));
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

  @override
  Widget build(BuildContext context) {
    final detail = widget.threadId != null;
    final messages = (_thread?['messages'] as List?) ?? [];
    final closed = _thread?['status'] == 'closed';
    return Scaffold(
      appBar: AppBar(
          title: Text(detail
              ? (widget.isGuard
                  ? (_thread?['resident_name'] ?? 'Resident')
                  : (_thread?['gate_site_name'] ?? 'Gatehouse'))
              : widget.isGuard
                  ? 'Resident chat'
                  : 'Gatehouse chat'),
          actions: [
            IconButton(
                tooltip: 'Refresh chat',
                onPressed: _load,
                icon: const Icon(Icons.refresh)),
            if (detail && _thread != null && _thread?['status'] == 'open')
              TextButton(
                  onPressed: _sending ? null : () => _send(resolve: true),
                  child: const Text('Resolve')),
          ]),
      floatingActionButton: !detail && !widget.isGuard
          ? FloatingActionButton.extended(
              onPressed: _sending ? null : _create,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('New chat'))
          : null,
      body: SafeArea(
          child: Column(children: [
        if (_error != null)
          MaterialBanner(content: Text(_error!), actions: [
            TextButton(onPressed: _load, child: const Text('Retry'))
          ]),
        if (_loading) const LinearProgressIndicator(),
        if (detail && _thread != null)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                  '${_thread!['status']}${_thread!['has_active_emergency'] == true ? ' • Emergency' : ''}')),
        Expanded(
            child: detail
                ? RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: TokenTheme.pageSidePadding,
                            vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          final mine = m['sender_id'] ==
                              AuthService.instance.currentUser?.id;
                          final time = DateTime.tryParse(m['created_at'] ?? '')
                              ?.toLocal();
                          return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.sizeOf(context).width *
                                              .8),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: mine
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            [
                                              m['sender_name'],
                                              m['officer_badge'],
                                              m['officer_post']
                                            ]
                                                .where((v) =>
                                                    v != null &&
                                                    v.toString().isNotEmpty)
                                                .join(' • '),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium),
                                        if (m['status_tag'] != null)
                                          Text(m['status_tag'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        SelectableText(m['message'] ?? ''),
                                        Text(
                                            '${time == null ? '' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'}${mine ? (m['is_read'] == true ? ' • Read' : ' • Sent') : ''}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                      ])));
                        }))
                : _threads.isEmpty && !_loading
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(
                                  height: 180,
                                  child: Center(
                                      child: Text('No conversations yet.')))
                            ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            itemCount: _threads.length,
                            itemBuilder: (context, index) {
                              final t = _threads[index];
                              final unread = t[widget.isGuard
                                      ? 'guard_unread_count'
                                      : 'resident_unread_count'] ??
                                  0;
                              return ListTile(
                                  onTap: () => _open(t['id']),
                                  leading: Icon(
                                      t['has_active_emergency'] == true
                                          ? Icons.emergency
                                          : Icons.chat_bubble_outline),
                                  title: Text(widget.isGuard
                                      ? t['resident_name'] ?? 'Resident'
                                      : t['gate_site_name'] ?? 'Gatehouse'),
                                  subtitle: Text(
                                      '${t['status']} • ${t['last_message_text'] ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: unread > 0
                                      ? Badge(label: Text('$unread'))
                                      : null);
                            }))),
        if (detail && _thread != null && !closed) ...[
          if (widget.isGuard)
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final entry in {
                    'CLEARED': 'Visitor cleared through gate',
                    'DELIVERY': 'Package at security desk',
                    'DISPATCHED': 'Officer dispatched to your unit'
                  }.entries)
                    Padding(
                        padding: const EdgeInsets.all(4),
                        child: ActionChip(
                            label: Text(entry.key),
                            onPressed: _sending
                                ? null
                                : () =>
                                    _send(text: entry.value, tag: entry.key))),
                ])),
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
                            labelText: 'Message',
                            border: OutlineInputBorder()))),
                if (!widget.isGuard)
                  IconButton(
                      tooltip: 'Send as emergency',
                      onPressed:
                          _sending ? null : () => _send(tag: 'EMERGENCY'),
                      icon: const Icon(Icons.emergency_outlined)),
                IconButton(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator())
                        : const Icon(Icons.send)),
              ])),
        ],
      ])),
    );
  }
}

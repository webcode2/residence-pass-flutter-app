import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationInbox extends ChangeNotifier {
  static final instance = NotificationInbox();
  List<Map<String, dynamic>> items = [];
  int unreadCount = 0;
  bool loading = false;
  bool hasMore = false;
  String? error;
  int _generation = 0;
  Future<void>? _refresh;
  void clear() {
    _generation++;
    _refresh = null;
    items = [];
    unreadCount = 0;
    error = null;
    loading = false;
    hasMore = false;
    _badge();
    notifyListeners();
  }

  Future<Map<String, dynamic>> _request(String path,
      {bool post = false, Map<String, dynamic>? body}) async {
    final auth = AuthService.instance;
    final uri = Uri.parse('${auth.baseUrl}/api/v1/notifications$path');
    final headers = {
      'Authorization': 'Bearer ${auth.accessToken}',
      'X-App-Id': auth.appId,
      'Content-Type': 'application/json'
    };
    final response = await (post
            ? http.post(uri,
                headers: headers, body: body == null ? null : jsonEncode(body))
            : http.get(uri, headers: headers))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Unable to load notifications. Pull to retry.');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<void> refresh() {
    if (!AuthService.instance.isAuthenticated) return Future.value();
    return _refresh ??= _load();
  }

  Future<void> _load() async {
    final generation = _generation;
    if (!AuthService.instance.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _request('');
      if (generation != _generation) return;
      items = (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      unreadCount = (data['unread_count'] as num).toInt();
      hasMore = data['has_more'] == true;
      await _badge();
    } catch (e) {
      if (generation == _generation) {
        error = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        _refresh = null;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    final generation = _generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _request('?offset=${items.length}');
      if (generation != _generation) return;
      final ids = items.map((e) => e['id']).toSet();
      items.addAll((data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => !ids.contains(e['id'])));
      hasMore = data['has_more'] == true;
      unreadCount = (data['unread_count'] as num).toInt();
    } catch (e) {
      if (generation == _generation) {
        error = 'Unable to load more notifications. Please retry.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markEventRead(Map<String, dynamic> event) async {
    final generation = _generation;
    final key = event['alert_id'] != null
        ? 'sos:${event['alert_id']}'
        : event['message_id'] != null
            ? 'chat:${event['message_id']}'
            : event['notification_event_key'];
    if (key == null) return;
    try {
      await _request('/read-event', post: true, body: {'event_key': key});
      if (generation == _generation) await refresh();
    } catch (_) {}
  }

  Future<void> markRead(String? id) async {
    final generation = _generation;
    final data =
        await _request(id == null ? '/read-all' : '/$id/read', post: true);
    if (generation != _generation) return;
    unreadCount = (data['unread_count'] as num).toInt();
    items = [
      for (final item in items)
        {...item, if (id == null || item['id'] == id) 'is_read': true}
    ];
    await _badge();
    notifyListeners();
  }

  Future<void> _badge() async {
    try {
      await const MethodChannel('residence/alarms')
          .invokeMethod('badge', unreadCount);
    } catch (_) {}
  }
}

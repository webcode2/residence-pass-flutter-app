import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  static const key = 'residence.session.v1';
  final FlutterSecureStorage storage;
  Future<void> _pending = Future.value();
  SessionStore({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  Future<void> save(Map<String, dynamic> session) {
    final encoded = jsonEncode({
      ...session,
      'saved_at': DateTime.now().toUtc().millisecondsSinceEpoch
    });
    return _enqueue(() => storage.write(key: key, value: encoded));
  }

  Future<void> clear() => _enqueue(() => storage.delete(key: key));
  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<Map<String, dynamic>?> read(String backendUrl) async {
    await _pending;
    final raw = await storage.read(key: key);
    if (raw == null) return null;
    try {
      final session = jsonDecode(raw) as Map<String, dynamic>;
      final token = session['token'] as String;
      final parts = token.split('.');
      if (parts.length != 3) throw const FormatException();
      final claims = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
          (claims['exp'] as num).toInt() * 1000,
          isUtc: true);
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
          session['saved_at'] as int,
          isUtc: true);
      final user = session['user'] as Map<String, dynamic>;
      if (session['backend'] != backendUrl ||
          claims['app_id'] != session['app_id'] ||
          user['app_id'] != session['app_id'] ||
          claims['sub'] != user['email'] ||
          !expiry.isAfter(DateTime.now().toUtc()) ||
          DateTime.now().toUtc().difference(savedAt) >=
              const Duration(days: 60)) {
        throw const FormatException();
      }
      return session;
    } catch (_) {
      await clear();
      return null;
    }
  }
}

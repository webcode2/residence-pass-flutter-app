import 'dart:async';
import 'dart:convert';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'session_store_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  Future<AuthService> authWith(MockClient client) async {
    final store = SessionStore();
    await store
        .save(fixtures.session(DateTime.now().add(const Duration(days: 30))));
    final auth = AuthService.isolated(store: store, settingsClient: client)
      ..setBaseUrl('http://127.0.0.1:1');
    await auth.restoreSession();
    addTearDown(auth.logout);
    return auth;
  }

  test('settings refresh persists current length and notifies guards',
      () async {
    var calls = 0;
    final auth = await authWith(MockClient((request) async {
      calls++;
      expect(request.url.path, '/api/v1/estates/mobile-settings');
      expect(request.headers['X-App-Id'], 'ESTATE-ONE');
      return http.Response(
          jsonEncode({'app_id': 'ESTATE-ONE', 'token_code_length': 4}), 200);
    }));
    var changes = 0;
    auth.tokenCodeLengthNotifier.addListener(() => changes++);
    await auth.refreshEstateSettings();
    expect(auth.tokenCodeLength, 4);
    expect(changes, 1);
    expect(calls, 1);
    expect((await SessionStore().read(auth.baseUrl))?['code_length'], 4);
  });
  test('offline or foreign-estate responses retain saved settings', () async {
    var calls = 0;
    final auth = await authWith(MockClient((request) async {
      if (calls++ == 0) throw http.ClientException('offline');
      return http.Response(
          jsonEncode({'app_id': 'OTHER', 'token_code_length': 4}), 200);
    }));
    await auth.refreshEstateSettings();
    expect(auth.tokenCodeLength, 8);
    await auth.refreshEstateSettings();
    expect(auth.tokenCodeLength, 8);
  });
  test('FCM invalidation during a fetch schedules a fresh fetch', () async {
    var calls = 0;
    final first = Completer<http.Response>();
    final auth = await authWith(MockClient((request) {
      calls++;
      if (calls == 1) return first.future;
      return Future.value(http.Response(
          jsonEncode({'app_id': 'ESTATE-ONE', 'token_code_length': 4}), 200));
    }));
    final fetch = auth.refreshEstateSettings();
    await Future<void>.delayed(Duration.zero);
    auth.refreshEstateSettings(invalidate: true);
    first.complete(http.Response(
        jsonEncode({'app_id': 'ESTATE-ONE', 'token_code_length': 6}), 200));
    await fetch;
    await Future<void>.delayed(Duration.zero);
    await auth.refreshEstateSettings();
    expect(auth.tokenCodeLength, 4);
    expect(calls, lessThanOrEqualTo(3));
  });
  test('late settings response cannot restore logged out identity', () async {
    final pending = Completer<http.Response>();
    final auth = await authWith(MockClient((request) => pending.future));
    final fetch = auth.refreshEstateSettings();
    auth.logout();
    pending.complete(http.Response(
        jsonEncode({'app_id': 'ESTATE-ONE', 'token_code_length': 4}), 200));
    await fetch;
    expect(auth.isAuthenticated, isFalse);
    expect(auth.tokenCodeLength, 6);
  });
}

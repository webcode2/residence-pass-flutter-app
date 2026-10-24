import 'dart:convert';
import 'package:estate/models/user_model.dart';
import 'package:estate/services/auth_service.dart';
import 'package:estate/services/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

String token(DateTime expiry, {String appId = 'ESTATE-ONE'}) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({
              'exp': expiry.millisecondsSinceEpoch ~/ 1000,
              'sub': 'member@example.com',
              'app_id': appId
            }))).replaceAll('=', '')}.signature';
Map<String, dynamic> session(DateTime expiry) => {
      'token': token(expiry),
      'backend': 'http://127.0.0.1:1',
      'app_id': 'ESTATE-ONE',
      'code_length': 8,
      'view_mode': 'resident',
      'user': UserModel(
              id: 'member',
              email: 'member@example.com',
              roles: ['resident'],
              appId: 'ESTATE-ONE',
              houseNumber: '12')
          .toJson()
    };
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('a fresh app restores encrypted identity without a network login',
      () async {
    final store = SessionStore();
    await store.save(session(DateTime.now().add(const Duration(days: 60))));
    final auth = AuthService.isolated(store: SessionStore())
      ..setBaseUrl('http://127.0.0.1:1');
    await auth.restoreSession();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.houseNumber, '12');
    expect(auth.tokenCodeLength, 8);
    auth.logout();
    expect(await store.read('http://127.0.0.1:1'), isNull);
  });
  test('expired, corrupt, and wrong-estate sessions cannot restore', () async {
    final store = SessionStore();
    await store
        .save(session(DateTime.now().subtract(const Duration(seconds: 1))));
    expect(await store.read('http://127.0.0.1:1'), isNull);
    await store.save({
      ...session(DateTime.now().add(const Duration(days: 60))),
      'token':
          token(DateTime.now().add(const Duration(days: 60)), appId: 'OTHER')
    });
    expect(await store.read('http://127.0.0.1:1'), isNull);
    FlutterSecureStorage.setMockInitialValues({SessionStore.key: 'corrupt'});
    expect(await store.read('http://127.0.0.1:1'), isNull);
  });
  test('a session older than 60 days is deleted even with a longer JWT',
      () async {
    final data = {
      ...session(DateTime.now().add(const Duration(days: 90))),
      'saved_at': DateTime.now()
          .subtract(const Duration(days: 61))
          .millisecondsSinceEpoch
    };
    FlutterSecureStorage.setMockInitialValues(
        {SessionStore.key: jsonEncode(data)});
    expect(await SessionStore().read('http://127.0.0.1:1'), isNull);
  });
  test('queued save followed by logout never resurrects a session', () async {
    final store = SessionStore();
    final save =
        store.save(session(DateTime.now().add(const Duration(days: 60))));
    final clear = store.clear();
    await Future.wait([save, clear]);
    expect(await store.read('http://127.0.0.1:1'), isNull);
  });
}

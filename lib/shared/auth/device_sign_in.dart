import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/biometric_prompt.dart';
import 'package:estate/shared/models/user_model.dart';

/// The resident remembered on this phone for fingerprint sign-in.
class RememberedAccount {
  final String appId, email, userId, keyId;
  final String? name;
  const RememberedAccount(
      {required this.appId, required this.email, required this.userId, required this.keyId, this.name});

  String get displayName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : email;
  String get firstName => displayName.split(' ').first;
}

/// Fingerprint / Face ID sign-in for residents (guards excluded).
///
/// The server issues a sign-in key for this phone; the secret is kept in the phone's
/// secure storage and only sent after a successful fingerprint check. Signing out keeps
/// it, so the login screen can offer "Sign in with fingerprint". It stops working when the
/// password changes or the account is suspended, and is forgotten here when the server
/// refuses it or the resident turns it off.
class DeviceSignIn extends ChangeNotifier {
  static final instance = DeviceSignIn();

  DeviceSignIn({FlutterSecureStorage? storage, BiometricPrompt? biometrics, AuthService? auth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _biometricsOverride = biometrics,
        _authOverride = auth;

  final FlutterSecureStorage _storage;
  final BiometricPrompt? _biometricsOverride;
  final AuthService? _authOverride;
  BiometricPrompt get _biometrics => _biometricsOverride ?? BiometricPrompt.instance;
  AuthService get _auth => _authOverride ?? AuthService.instance;

  RememberedAccount? remembered;
  bool busy = false;

  String get _storageKey => 'residence.device_signin.${_auth.baseUrl}';

  static bool supports(UserModel? user) => user != null && !user.isGuard && !user.mustChangePassword;

  bool enabledFor(UserModel? user) => user != null && remembered?.userId == user.id;

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      final data = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
      remembered = data == null
          ? null
          : RememberedAccount(
              appId: data['app_id'] as String,
              email: data['email'] as String,
              userId: data['user_id'] as String,
              keyId: data['key_id'] as String,
              name: data['name'] as String?);
    } catch (_) {
      remembered = null;
    }
    notifyListeners();
  }

  /// Turn on for the signed-in resident. Returns an error message, or null on success.
  Future<String?> enable() async {
    final user = _auth.currentUser;
    if (!supports(user)) return 'Fingerprint sign-in is available on resident accounts only.';
    if (!await _biometrics.available()) {
      return 'Add a fingerprint or Face ID in your phone settings first.';
    }
    _setBusy(true);
    try {
      final check = await _biometrics.authenticate('Use your fingerprint to sign in to Residence');
      if (check != BiometricResult.success) return 'Fingerprint was not confirmed.';
      final issued = await _auth.enrolDeviceKey('${Platform.operatingSystem} phone');
      if (issued.error != null) return issued.error;
      // One remembered account per phone: this replaces any earlier one.
      await _storage.write(
          key: _storageKey,
          value: jsonEncode({
            'app_id': _auth.appId,
            'email': user!.email,
            'name': user.fullName,
            'user_id': user.id,
            'key_id': issued.keyId,
            'secret': issued.secret,
          }));
      await load();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Turn off on this phone (and on the server while signed in).
  Future<void> disable() async {
    final key = remembered?.keyId;
    if (key != null && enabledFor(_auth.currentUser)) await _auth.revokeDeviceKey(key);
    await forget();
  }

  Future<void> forget() async {
    await _storage.delete(key: _storageKey);
    remembered = null;
    notifyListeners();
  }

  /// Fingerprint, then sign in. Returns null on success or a message to show.
  Future<String?> signIn() async {
    final account = remembered;
    if (account == null || busy) return null;
    _setBusy(true);
    try {
      final check = await _biometrics.authenticate('Sign in to Residence as ${account.firstName}');
      if (check == BiometricResult.cancelled) return null;
      if (check != BiometricResult.success) {
        return check == BiometricResult.lockedOut
            ? 'Too many fingerprint attempts. Sign in with your password.'
            : 'Fingerprint is not available. Sign in with your password.';
      }
      final raw = await _storage.read(key: _storageKey);
      final secret = raw == null ? null : (jsonDecode(raw) as Map<String, dynamic>)['secret'] as String?;
      if (secret == null) {
        await forget();
        return 'Fingerprint sign-in is no longer set up. Sign in with your password.';
      }
      final result =
          await _auth.deviceLogin(appId: account.appId, keyId: account.keyId, secret: secret);
      if (result['success'] == true) return null;
      if (result['invalidKey'] == true) await forget();
      return result['message'] as String?;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    busy = value;
    notifyListeners();
  }
}

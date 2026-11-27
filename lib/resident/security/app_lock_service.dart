import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:estate/shared/auth/biometric_prompt.dart';

/// When the resident app locks after the user leaves it.
enum LockAfter {
  immediately(Duration.zero, 'Every time I leave the app'),
  seconds30(Duration(seconds: 30), 'After 30 seconds'),
  minute1(Duration(minutes: 1), 'After 1 minute'),
  minutes5(Duration(minutes: 5), 'After 5 minutes');

  const LockAfter(this.delay, this.label);
  final Duration delay;
  final String label;
}

/// Resident app lock: 6-digit app PIN, optional fingerprint / Face ID, and the account
/// password as the last fallback. Security officers never get an app lock.
///
/// Locking rules (the same as banking apps):
/// - a cold start of a locked account always shows the lock screen;
/// - leaving the app always shows a privacy cover in the app switcher;
/// - coming back locks only if the user was away for at least the chosen delay;
/// - our own fingerprint prompt never counts as leaving the app, so it cannot relock
///   itself, and the prompt opens automatically at most once per lock.
class AppLockService extends ChangeNotifier {
  static final instance = AppLockService();

  static const pinLength = 6;
  static const maxPinAttempts = 5;
  static const _promptSettle = Duration(milliseconds: 1500);

  AppLockService({FlutterSecureStorage? storage, BiometricPrompt? biometrics, DateTime Function()? clock})
      : _storage = storage ?? const FlutterSecureStorage(),
        _biometricsOverride = biometrics,
        _clock = clock ?? DateTime.now;

  final FlutterSecureStorage _storage;
  final BiometricPrompt? _biometricsOverride;
  final DateTime Function() _clock;
  BiometricPrompt get _biometrics => _biometricsOverride ?? BiometricPrompt.instance;

  String? _identity;
  int _generation = 0;
  bool loading = false;
  bool enabled = false;
  bool fingerprintUnlock = false;
  LockAfter lockAfter = LockAfter.immediately;
  int failedPinAttempts = 0;

  /// The lock screen is showing.
  bool locked = false;

  /// The privacy cover is showing (app in the app switcher or behind a system sheet).
  bool covered = false;

  /// A fingerprint prompt is open.
  bool busy = false;
  String? message;

  bool _autoPromptUsed = false;
  DateTime? _leftAt;
  DateTime? _promptEndedAt;

  bool get pinBlocked => failedPinAttempts >= maxPinAttempts;
  bool get bound => _identity != null;
  bool get canAutoPrompt => locked && fingerprintUnlock && !_autoPromptUsed && !busy && !pinBlocked;

  String _key(String name) => 'residence.applock.$_identity.$name';

  /// Load the lock settings for the signed-in resident (null when signed out or a guard).
  Future<void> bind(String? identity) async {
    if (identity == _identity) return;
    final generation = ++_generation;
    _identity = identity;
    enabled = fingerprintUnlock = locked = covered = false;
    lockAfter = LockAfter.immediately;
    failedPinAttempts = 0;
    message = null;
    _leftAt = null;
    _autoPromptUsed = false;
    loading = identity != null;
    notifyListeners();
    if (identity == null) return;
    try {
      final values = await _storage.readAll();
      if (generation != _generation) return;
      enabled = values[_key('pin')] != null;
      fingerprintUnlock = enabled && values[_key('fingerprint')] == 'true';
      lockAfter = LockAfter.values.firstWhere((v) => v.name == values[_key('after')],
          orElse: () => LockAfter.immediately);
      failedPinAttempts = int.tryParse(values[_key('attempts')] ?? '') ?? 0;
      locked = enabled; // a restored session always starts locked
    } catch (_) {
      if (generation == _generation) {
        // Never show a restored session whose lock settings cannot be read.
        enabled = locked = true;
        message = 'Unable to read your app lock settings. Use your password or sign out.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  // ---------- Lifecycle ----------

  void onLifecycle(AppLifecycleState state) {
    if (!enabled || _identity == null) return;
    final now = _clock();
    final ownPrompt = busy ||
        (_promptEndedAt != null && now.difference(_promptEndedAt!) < _promptSettle);
    if (state == AppLifecycleState.resumed) {
      final leftAt = _leftAt;
      _leftAt = null;
      if (leftAt != null && (locked || now.difference(leftAt) >= lockAfter.delay)) {
        // A real return to a locked app may offer the fingerprint prompt once again.
        locked = true;
        _autoPromptUsed = false;
      }
      covered = false;
      notifyListeners();
      return;
    }
    if (state == AppLifecycleState.detached || ownPrompt) return;
    // inactive (app switcher, notification shade), hidden or paused.
    if (!locked && !covered) {
      covered = true;
      notifyListeners();
    }
    if (state != AppLifecycleState.inactive) _leftAt ??= now;
  }

  // ---------- Unlocking ----------

  Future<bool> unlockWithFingerprint({bool automatic = false}) async {
    if (!locked || !fingerprintUnlock || busy) return false;
    if (automatic) {
      if (_autoPromptUsed) return false;
      _autoPromptUsed = true;
    }
    final result = await _prompt('Unlock Residence');
    if (result == BiometricResult.success) {
      _unlock();
      return true;
    }
    message = const {
      BiometricResult.lockedOut: 'Too many fingerprint attempts. Enter your PIN instead.',
      BiometricResult.unavailable: 'Fingerprint is not available on this phone right now. Enter your PIN.',
      BiometricResult.failed: 'Fingerprint was not recognised. Try again or enter your PIN.',
    }[result];
    notifyListeners();
    return false;
  }

  Future<bool> unlockWithPin(String pin) async {
    if (!locked || pinBlocked) return false;
    if (await _pinMatches(pin)) {
      await _setAttempts(0);
      _unlock();
      return true;
    }
    await _setAttempts(failedPinAttempts + 1);
    final left = maxPinAttempts - failedPinAttempts;
    message = pinBlocked
        ? 'Too many wrong PINs. Sign in with your password to continue.'
        : 'Wrong PIN. $left ${left == 1 ? 'attempt' : 'attempts'} left.';
    notifyListeners();
    return false;
  }

  /// The account password was accepted by the server (password sign-in on the lock screen).
  Future<void> unlockAfterPassword() async {
    await _setAttempts(0);
    _unlock();
  }

  void _unlock() {
    locked = covered = false;
    message = null;
    _leftAt = null;
    notifyListeners();
  }

  // ---------- Settings ----------

  Future<void> enable(String pin) async {
    if (_identity == null) throw StateError('App lock is only available to signed-in residents.');
    _requirePin(pin);
    await _savePin(pin);
    await _storage.write(key: _key('after'), value: lockAfter.name);
    await _setAttempts(0);
    enabled = true;
    locked = covered = false;
    notifyListeners();
  }

  Future<void> disable() async {
    for (final name in ['pin', 'fingerprint', 'after', 'attempts']) {
      await _storage.delete(key: _key(name));
    }
    enabled = fingerprintUnlock = locked = covered = false;
    failedPinAttempts = 0;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) => _pinMatches(pin);

  Future<void> changePin(String pin) async {
    _requirePin(pin);
    await _savePin(pin);
    await _setAttempts(0);
    notifyListeners();
  }

  /// Turning fingerprint unlock on asks for a fingerprint first. Returns an error or null.
  Future<String?> setFingerprintUnlock(bool value) async {
    if (!enabled) return 'Turn on app lock first.';
    if (value) {
      if (!await _biometrics.available()) {
        return 'Add a fingerprint or Face ID in your phone settings first.';
      }
      final result = await _prompt('Use your fingerprint to unlock Residence');
      if (result != BiometricResult.success) {
        return result == BiometricResult.cancelled ? 'Fingerprint was not confirmed.' : 'Fingerprint is not available right now.';
      }
    }
    await _storage.write(key: _key('fingerprint'), value: value.toString());
    fingerprintUnlock = value;
    notifyListeners();
    return null;
  }

  Future<void> setLockAfter(LockAfter value) async {
    await _storage.write(key: _key('after'), value: value.name);
    lockAfter = value;
    notifyListeners();
  }

  /// A fingerprint prompt that is not mistaken for the user leaving the app.
  Future<BiometricResult> confirmFingerprint(String reason) => _prompt(reason);

  Future<BiometricResult> _prompt(String reason) async {
    busy = true;
    notifyListeners();
    try {
      return await _biometrics.authenticate(reason);
    } finally {
      busy = false;
      _promptEndedAt = _clock();
      notifyListeners();
    }
  }

  // ---------- PIN storage (salted, iterated SHA-256; never the PIN itself) ----------

  void _requirePin(String pin) {
    if (!RegExp('^[0-9]{$pinLength}\$').hasMatch(pin)) {
      throw ArgumentError('The PIN must be $pinLength digits.');
    }
  }

  static String _hash(String pin, String salt) {
    List<int> digest = utf8.encode('$salt:$pin');
    for (var i = 0; i < 20000; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64Url.encode(digest);
  }

  Future<void> _savePin(String pin) async {
    final random = Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await _storage.write(key: _key('pin'), value: '$salt.${_hash(pin, salt)}');
  }

  Future<bool> _pinMatches(String pin) async {
    final stored = await _storage.read(key: _key('pin'));
    if (stored == null || !stored.contains('.')) return false;
    final salt = stored.substring(0, stored.indexOf('.'));
    final expected = stored.substring(stored.indexOf('.') + 1);
    final actual = _hash(pin, salt);
    var diff = expected.length ^ actual.length;
    for (var i = 0; i < min(expected.length, actual.length); i++) {
      diff |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> _setAttempts(int value) async {
    failedPinAttempts = value;
    await _storage.write(key: _key('attempts'), value: '$value');
  }
}

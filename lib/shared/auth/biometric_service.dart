import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService extends ChangeNotifier {
  static final instance = BiometricService();
  final FlutterSecureStorage storage;
  final Future<bool> Function()? available;
  final Future<bool> Function(bool)? prompt;
  final _auth = LocalAuthentication();
  BiometricService({FlutterSecureStorage? storage, this.available, this.prompt})
      : storage = storage ?? const FlutterSecureStorage();
  bool enabled = false, unlocked = true, busy = false, loading = false;
  String? error, _key;
  int _generation = 0;

  Future<void> bind(String? identity) async {
    final key = identity == null ? null : 'residence.biometric.$identity';
    if (key == _key) return;
    final generation = ++_generation;
    _key = key;
    enabled = false;
    unlocked = true;
    error = null;
    loading = key != null;
    notifyListeners();
    if (key == null) return;
    try {
      final value = await storage.read(key: key);
      if (generation != _generation) return;
      enabled = value == 'true';
      unlocked = !enabled;
    } catch (_) {
      // Do not expose a restored session if its app-lock preference cannot be read.
      if (generation == _generation) {
        enabled = true;
        unlocked = false;
        error = 'Unable to read app security settings. Unlock or sign out.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _authenticate(bool biometricOnly) async => prompt != null
      ? prompt!(biometricOnly)
      : _auth.authenticate(
          localizedReason: 'Authenticate to unlock Residence',
          biometricOnly: biometricOnly,
          persistAcrossBackgrounding: true);

  Future<bool> setEnabled(bool value) async {
    if (busy || _key == null) return false;
    final key = _key;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (value) {
        final canUse = available != null
            ? await available!()
            : await _auth.isDeviceSupported() &&
                (await _auth.getAvailableBiometrics()).isNotEmpty;
        if (!canUse) {
          error =
              'Set up fingerprint or Face ID in your device settings first.';
          return false;
        }
      }
      final accepted = await _authenticate(value);
      if (!accepted || key != _key) return false;
      await storage.write(key: key!, value: value.toString());
      if (key != _key) return false;
      enabled = value;
      unlocked = true;
      return true;
    } catch (_) {
      error =
          'Authentication was unavailable. Check biometric permissions and device settings, then retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void lock() {
    if (enabled && !busy && !loading) {
      unlocked = false;
      notifyListeners();
    }
  }

  Future<bool> unlock() async {
    if (!enabled) return true;
    if (busy || loading) return false;
    final key = _key;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final accepted = await _authenticate(false);
      if (key == _key) unlocked = accepted;
      return accepted && key == _key;
    } catch (_) {
      error = 'Unlock was not completed. Retry or sign out.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

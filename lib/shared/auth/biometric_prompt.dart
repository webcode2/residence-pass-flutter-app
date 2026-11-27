import 'package:local_auth/local_auth.dart';

/// Result of one fingerprint / Face ID prompt.
enum BiometricResult { success, cancelled, failed, lockedOut, unavailable }

/// The device's fingerprint / Face ID prompt. Biometrics only: the app's own PIN and the
/// account password are the fallbacks, never the phone's screen-lock passcode.
///
/// Android grants USE_BIOMETRIC at install (no runtime dialog). iOS asks once, the first
/// time Face ID is used, with the NSFaceIDUsageDescription text in Info.plist.
class BiometricPrompt {
  static BiometricPrompt instance = BiometricPrompt();

  final LocalAuthentication _auth;
  BiometricPrompt([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  /// True when the phone has biometric hardware and at least one enrolled fingerprint/face.
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
          localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return BiometricResult.cancelled;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricResult.lockedOut;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricResult.unavailable;
        default:
          return BiometricResult.failed;
      }
    } catch (_) {
      return BiometricResult.failed;
    }
  }
}

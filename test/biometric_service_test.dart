import 'package:estate/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
      'biometrics default off and enabling requires a successful native prompt',
      () async {
    var prompts = 0;
    var accepted = false;
    final service = BiometricService(
        available: () async => true,
        prompt: (only) async {
          prompts++;
          expect(only, isTrue);
          return accepted;
        });
    await service.bind('account-one');
    expect(service.enabled, isFalse);
    expect(prompts, 0);
    expect(await service.setEnabled(true), isFalse);
    expect(service.enabled, isFalse);
    accepted = true;
    expect(await service.setEnabled(true), isTrue);
    expect(service.enabled, isTrue);
    final restored = BiometricService(prompt: (_) async => true);
    await restored.bind('account-one');
    expect(restored.enabled, isTrue);
    expect(restored.unlocked, isFalse);
    expect(await restored.unlock(), isTrue);
    expect(restored.unlocked, isTrue);
    restored.lock();
    expect(restored.unlocked, isFalse);
  });
  test('unavailable biometric hardware cannot enable a fake setting', () async {
    var prompted = false;
    final service = BiometricService(
        available: () async => false,
        prompt: (_) async {
          prompted = true;
          return true;
        });
    await service.bind('no-biometrics');
    expect(await service.setEnabled(true), isFalse);
    expect(service.enabled, isFalse);
    expect(prompted, isFalse);
  });
  test('preferences are per account and disabling requires authentication',
      () async {
    var accepted = true;
    final service = BiometricService(
        available: () async => true, prompt: (_) async => accepted);
    await service.bind('first');
    await service.setEnabled(true);
    await service.bind('second');
    expect(service.enabled, isFalse);
    await service.bind('first');
    expect(service.enabled, isTrue);
    accepted = false;
    expect(await service.setEnabled(false), isFalse);
    expect(service.enabled, isTrue);
    accepted = true;
    expect(await service.setEnabled(false), isTrue);
    expect(service.enabled, isFalse);
  });
}

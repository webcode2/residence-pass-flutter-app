import 'package:estate/resident/security/app_lock_gate.dart';
import 'package:estate/resident/security/app_lock_service.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/biometric_prompt.dart';
import 'package:estate/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const pin = '135790';

/// The phone's fingerprint prompt. While it is open Android reports the app as left
/// (paused); some phones report that only after the answer arrives.
class FakePrompt extends BiometricPrompt {
  FakePrompt(this.binding);
  final TestWidgetsFlutterBinding binding;
  BiometricResult answer = BiometricResult.success;
  bool lateBackgroundEvent = false;
  int prompts = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<BiometricResult> authenticate(String reason) async {
    prompts++;
    if (lateBackgroundEvent) {
      Future(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.paused));
    } else {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    }
    return answer;
  }
}

class Clock {
  DateTime now = DateTime(2026, 11, 27, 12);
  DateTime call() => now;
}

String identityOf(String id) => '${AuthService.instance.baseUrl}.$id';

/// Saves lock settings for [userId] as the settings screen would.
Future<void> enableLock(String userId, {bool fingerprint = false, LockAfter after = LockAfter.immediately}) async {
  final setup = AppLockService();
  await setup.bind(identityOf(userId));
  await setup.enable(pin);
  await setup.setLockAfter(after);
  if (fingerprint) {
    await const FlutterSecureStorage().write(key: 'residence.applock.${identityOf(userId)}.fingerprint', value: 'true');
  }
}

Future<AppLockService> pumpApp(WidgetTester tester, FakePrompt prompt, Clock clock,
    {List<String> roles = const ['resident']}) async {
  AuthService.instance.currentUserNotifier.value =
      UserModel(id: 'member', email: 'member@example.com', fullName: 'Ada Obi', roles: roles);
  final service = AppLockService(biometrics: prompt, clock: clock.call);
  await tester.pumpWidget(MaterialApp(
      home: ResidentLockGate(service: service, child: const Scaffold(body: Text('Protected visitor codes')))));
  await tester.pumpAndSettle();
  return service;
}

Future<void> enterPin(WidgetTester tester, String value) async {
  for (final digit in value.split('')) {
    await tester.tap(find.widgetWithText(InkWell, digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> leaveAndReturn(WidgetTester tester, Clock clock, Duration away) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  clock.now = clock.now.add(away);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

const protected = 'Protected visitor codes';

void main() {
  late FakePrompt prompt;
  late Clock clock;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    clock = Clock();
  });

  tearDown(() => AuthService.instance.currentUserNotifier.value = null);

  testWidgets('opening a locked app needs the PIN; wrong PINs are counted', (tester) async {
    prompt = FakePrompt(tester.binding);
    await enableLock('member');
    final service = await pumpApp(tester, prompt, clock);
    expect(find.text(protected), findsNothing);
    expect(find.text('Unlock Residence'), findsOneWidget);
    expect(find.text('Welcome back, Ada'), findsOneWidget);
    expect(prompt.prompts, 0, reason: 'fingerprint unlock is off');

    await enterPin(tester, '000000');
    expect(find.text('Wrong PIN. 4 attempts left.'), findsOneWidget);
    expect(find.text(protected), findsNothing);
    await enterPin(tester, pin);
    expect(find.text(protected), findsOneWidget);
    expect(service.failedPinAttempts, 0);
  });

  testWidgets('a cancelled fingerprint prompt does not reopen on every return', (tester) async {
    prompt = FakePrompt(tester.binding)..answer = BiometricResult.cancelled;
    await enableLock('member', fingerprint: true);
    await pumpApp(tester, prompt, clock);
    expect(prompt.prompts, 1, reason: 'offered once automatically');
    // The prompt closing brings the app back to the foreground several times.
    for (var i = 0; i < 5; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }
    expect(prompt.prompts, 1);
    expect(find.text('Unlock Residence'), findsOneWidget);

    // Tapping the fingerprint key asks again, on request only.
    prompt.answer = BiometricResult.success;
    await tester.tap(find.byIcon(Icons.fingerprint_rounded));
    await tester.pumpAndSettle();
    expect(prompt.prompts, 2);
    expect(find.text(protected), findsOneWidget);
  });

  testWidgets('a late background event after a successful fingerprint does not relock', (tester) async {
    prompt = FakePrompt(tester.binding)..lateBackgroundEvent = true;
    await enableLock('member', fingerprint: true);
    await pumpApp(tester, prompt, clock);
    for (var i = 0; i < 5; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }
    expect(prompt.prompts, 1);
    expect(find.text(protected), findsOneWidget);
  });

  testWidgets('lock timing: every return, or only after the chosen delay', (tester) async {
    prompt = FakePrompt(tester.binding);
    await enableLock('member', after: LockAfter.minute1);
    final service = await pumpApp(tester, prompt, clock);
    await enterPin(tester, pin);
    expect(find.text(protected), findsOneWidget);

    await leaveAndReturn(tester, clock, const Duration(seconds: 30));
    expect(find.text(protected), findsOneWidget, reason: 'away less than 1 minute');
    await leaveAndReturn(tester, clock, const Duration(seconds: 61));
    expect(find.text('Unlock Residence'), findsOneWidget);
    await enterPin(tester, pin);

    await service.setLockAfter(LockAfter.immediately);
    await leaveAndReturn(tester, clock, const Duration(seconds: 1));
    expect(find.text('Unlock Residence'), findsOneWidget, reason: 'locks every time');
  });

  testWidgets('the app switcher shows the privacy cover, not the app', (tester) async {
    prompt = FakePrompt(tester.binding);
    await enableLock('member', after: LockAfter.minutes5);
    await pumpApp(tester, prompt, clock);
    await enterPin(tester, pin);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text(protected), findsNothing);
    expect(find.text('Your details are hidden while Residence is in the background.'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(protected), findsOneWidget);
  });

  testWidgets('five wrong PINs require the account password', (tester) async {
    prompt = FakePrompt(tester.binding);
    await enableLock('member');
    final service = await pumpApp(tester, prompt, clock);
    for (var i = 0; i < AppLockService.maxPinAttempts; i++) {
      await enterPin(tester, '000000');
    }
    expect(service.pinBlocked, isTrue);
    expect(find.text('Enter your account password to continue.'), findsOneWidget);
    expect(find.text('Use PIN instead'), findsNothing);
    expect(find.text(protected), findsNothing);
  });

  testWidgets('security officers are never locked', (tester) async {
    prompt = FakePrompt(tester.binding);
    await enableLock('member', fingerprint: true);
    await pumpApp(tester, prompt, clock, roles: const ['security']);
    expect(find.text(protected), findsOneWidget);
    await leaveAndReturn(tester, clock, const Duration(minutes: 10));
    expect(find.text(protected), findsOneWidget);
    expect(prompt.prompts, 0);
  });
}

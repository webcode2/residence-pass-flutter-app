import 'package:estate/models/user_model.dart';
import 'package:estate/services/auth_service.dart';
import 'package:estate/services/biometric_service.dart';
import 'package:estate/widgets/biometric_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'enabled app lock conceals the navigator until authentication succeeds',
      (tester) async {
    var accepted = false;
    FlutterSecureStorage.setMockInitialValues(
        {'residence.biometric.${AuthService.instance.baseUrl}.member': 'true'});
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'member', email: 'member@example.com', roles: ['resident']);
    final service = BiometricService(prompt: (_) async => accepted);
    await tester.pumpWidget(MaterialApp(
        home: BiometricGate(
            service: service,
            child: const Scaffold(body: Text('Protected token details')))));
    await tester.pumpAndSettle();
    expect(find.text('Protected token details'), findsNothing);
    expect(find.text('Unlock Residence'), findsOneWidget);
    accepted = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Protected token details'), findsOneWidget);
    service.lock();
    await tester.pump();
    expect(find.text('Protected token details'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    AuthService.instance.currentUserNotifier.value = null;
  });
}

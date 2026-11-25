import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/models/user_model.dart';
import 'package:estate/screens/change_password_screen.dart';
import 'package:estate/main.dart';
import 'package:estate/services/auth_service.dart';
import 'package:estate/screens/app_scaffold.dart';

void main() {
  test('Server onboarding requirement survives user model serialization', () {
    final user = UserModel.fromJson({
      'id': 'landlord-id',
      'email': 'host@example.com',
      'roles': ['landlord'],
      'must_change_password': true,
      'phone': '+2348012345678'
    });
    expect(user.mustChangePassword, isTrue);
    expect(user.isLandlord, isTrue);
    expect(UserModel.fromJson(user.toJson()).mustChangePassword, isTrue);
  });
  testWidgets(
      'First-login password form validates before contacting the server',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'temporary-password');
    await tester.enterText(fields.at(1), 'short');
    await tester.enterText(fields.at(2), 'different');
    await tester.tap(find.text('Save password and continue'));
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.text('Choose your own password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Pending landlords cannot reach the app before changing password',
      (tester) async {
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'pending-landlord',
        email: 'host@example.com',
        roles: ['landlord'],
        mustChangePassword: true);
    await tester.pumpWidget(const SecurityTokenApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.byType(AppScaffold), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    AuthService.instance.currentUserNotifier.value = null;
  });
}

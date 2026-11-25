import 'package:estate/shared/models/user_model.dart';
import 'package:estate/resident/models/visitor_pass.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/account/profile_editor_screen.dart';
import 'package:estate/resident/screens/profile_screen.dart';
import 'package:estate/shared/account/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
      'recent activity uses entry codes and departure codes for the matching action',
      () {
    final pass = VisitorPass(
        id: 'pass',
        visitorName: 'Alex',
        code: '12345A',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)));
    expect(pass.activitySummary, 'Alex · Entry code: 12345A');
    final exit =
        pass.copyWith(status: VisitorStatus.checkedOut, bookoutCode: '98765B');
    expect(exit.activitySummary, 'Alex · Exit code: 98765B');
    expect(
        pass.copyWith(status: VisitorStatus.checkedOut).activityCode, '12345A');
  });
  testWidgets(
      'profile displays saved contact and property details and removes fake refresh setting',
      (tester) async {
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'member',
        email: 'member@example.com',
        fullName: 'Alex',
        phone: '+2348012345678',
        houseNumber: '12',
        streetName: 'Palm Street',
        roles: ['resident'],
        appId: 'RP-ONE');
    await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(isDark: false, onToggleTheme: () {})));
    await tester.pumpAndSettle();
    expect(find.text('member@example.com'), findsOneWidget);
    expect(find.text('+2348012345678'), findsOneWidget);
    expect(find.textContaining('Palm Street'), findsOneWidget);
    expect(find.text('RESIDENCE & ACCOUNT'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Edit profile & property'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Edit profile & property'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditorScreen), findsOneWidget);
    await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(isDark: false, onToggleTheme: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Auto-Refresh Expired Tokens'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    AuthService.instance.currentUserNotifier.value = null;
  });
  testWidgets('profile edits submit only personal and property fields',
      (tester) async {
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'member',
        email: 'member@example.com',
        fullName: 'Alex',
        phone: '08000000000',
        houseNumber: '12',
        streetName: 'Palm Street',
        roles: ['resident'],
        appId: 'RP-ONE');
    Map<String, dynamic>? saved;
    await tester
        .pumpWidget(MaterialApp(home: ProfileEditorScreen(save: (body) async {
      saved = body;
      return {'success': false, 'message': 'Retryable network failure'};
    })));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Updated Alex');
    await tester.enterText(fields.at(2), '+2348012345678');
    await tester.enterText(fields.at(3), '20B');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved?['house_number'], '20B');
    expect(saved?['full_name'], 'Updated Alex');
    expect(saved!.containsKey('roles'), isFalse);
    expect(saved!.containsKey('app_id'), isFalse);
    expect(find.text('Retryable network failure'), findsOneWidget);
    expect(find.text('Updated Alex'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    AuthService.instance.currentUserNotifier.value = null;
  });
}

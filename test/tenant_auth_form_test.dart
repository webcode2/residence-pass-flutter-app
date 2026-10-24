import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/screens/login_screen.dart';
import 'package:estate/screens/register_screen.dart';
import 'package:estate/services/auth_service.dart';

void main() {
  testWidgets('Sign-in requires an explicit estate App ID', (tester) async {
    AuthService.instance.setAppId('');
    await tester.pumpWidget(
        MaterialApp(home: LoginScreen(isDark: false, onToggleTheme: () {})));
    expect(find.text('Estate App ID'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('DEMO TEST MODE'), findsNothing);
    expect(find.text('Resident Demo'), findsNothing);
    expect(find.text('Guard Demo'), findsNothing);
    final form = tester.widget<Form>(find.byType(Form));
    expect(form.key is GlobalKey<FormState>, isTrue);
    expect(
        (form.key as GlobalKey<FormState>).currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter the App ID provided by your caretaker'),
        findsOneWidget);
  });
  testWidgets('Resident registration derives estate identity from invitation',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(isDark: false, onToggleTheme: () {})));
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Estate App ID'), findsNothing);
    expect(find.text('Join your household'), findsNothing);
    expect(find.textContaining('Your estate App ID is provided'), findsNothing);
    expect(find.text('DEMO TEST MODE'), findsNothing);
    expect(find.text('Auto-Fill'), findsNothing);
    expect(find.text('Guard Demo'), findsNothing);
  });
}

import 'package:estate/shared/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reinstatement is not offered until the server reports a suspended account',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: LoginScreen(isDark: false, onToggleTheme: () {})));
    expect(find.text('Request account reinstatement'), findsNothing);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

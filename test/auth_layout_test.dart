import 'package:estate/screens/login_screen.dart';
import 'package:estate/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Auth screens fit narrow screens with large text (dark: $dark)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in [
        LoginScreen(isDark: dark, onToggleTheme: () {}),
        RegisterScreen(isDark: dark, onToggleTheme: () {})
      ]) {
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!),
            home: screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Continue with Google'), findsNothing);
        expect(find.text('DEMO TEST MODE'), findsNothing);
        expect(find.byType(Card), findsNothing);
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(find.text('Enter a valid email address'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}

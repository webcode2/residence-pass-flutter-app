import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/gate/screens/gatehouse_home_screen.dart';

void main() {
  testWidgets(
      'GatehouseHomeScreen renders without RenderFlex overflow on small screen',
      (WidgetTester tester) async {
    // Set a compact screen size (width: 360, height: 640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: GatehouseHomeScreen(isDark: false),
      ),
    );
    await tester.pumpAndSettle();

    // Verify key UI elements render
    expect(find.text('VISITOR TOKEN VERIFIER'), findsOneWidget);
    expect(find.text('PASTE'), findsOneWidget);
    expect(find.text('Tap boxes to open device keyboard'), findsOneWidget);

    // The verifier reflects the current estate setting.
    expect(find.text('•'), findsNWidgets(AuthService.instance.tokenCodeLength));

    // No overflow should occur
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GatehouseHomeScreen supports entering alphanumeric token with system keyboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: GatehouseHomeScreen(isDark: false),
      ),
    );
    await tester.pumpAndSettle();

    // Enter alphanumeric token directly into the TextField
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // A sample code must never authorize offline access.
    await tester.enterText(textFieldFinder, '4920CD');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Verify digits and letters appear in the code slots
    expect(find.text('4'), findsWidgets);
    expect(find.text('9'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('0'), findsWidgets);
    expect(find.text('C'), findsWidgets);
    expect(find.text('D'), findsWidgets);

    expect(find.text('AUTHORIZED PASS'), findsNothing);
    expect(find.text('OPEN GATE & CHECK IN'), findsNothing);
    await tester.tap(find.text('VERIFY TOKEN'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign in to verify access'), findsOneWidget);

    // No overflow should occur
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'open guard screen reacts to settings while preserving longer issued codes',
      (tester) async {
    final settings = AuthService.instance.tokenCodeLengthNotifier;
    final saved = settings.value;
    addTearDown(() => settings.value = saved);
    settings.value = 6;
    await tester.pumpWidget(
        const MaterialApp(home: GatehouseHomeScreen(isDark: false)));
    await tester.pumpAndSettle();
    expect(find.text('•'), findsNWidgets(6));
    settings.value = 4;
    await tester.pumpAndSettle();
    expect(find.text('•'), findsNWidgets(4));
    await tester.enterText(find.byType(TextField), '1234567A');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1234567A');
    expect(find.text('A'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'default boxes stay fixed until input exceeds the estate length and shrink back on clear',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AuthService.instance.tokenCodeLengthNotifier;
    final saved = settings.value;
    settings.value = 6;
    addTearDown(() => settings.value = saved);
    await tester.pumpWidget(
        const MaterialApp(home: GatehouseHomeScreen(isDark: false)));
    await tester.pumpAndSettle();
    Finder slots() => find.byWidgetPredicate((widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>)
            .value
            .startsWith('verification-code-slot-'));
    expect(slots(), findsNWidgets(6));
    final field = find.byType(TextField);
    await tester.enterText(field, '12345A');
    await tester.pumpAndSettle();
    expect(slots(), findsNWidgets(6));
    await tester.enterText(field, '123456A');
    await tester.pumpAndSettle();
    expect(slots(), findsNWidgets(7));
    await tester.enterText(field, '12345678901A');
    await tester.pumpAndSettle();
    expect(slots(), findsNWidgets(12));
    expect(tester.widget<TextField>(field).controller!.text, '12345678901A');
    expect(tester.takeException(), isNull);
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(slots(), findsNWidgets(6));
  });
}

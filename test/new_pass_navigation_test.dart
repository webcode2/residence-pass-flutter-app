import 'package:estate/screens/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'New Pass floating button opens the real pass form and Chat is a bottom tab',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: AppScaffold(isDark: false, onToggleTheme: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byTooltip('Contact gatehouse'), findsNothing);
    await tester.tap(find.byTooltip('New Pass'));
    await tester.pumpAndSettle();
    expect(find.text('Generate Pass Token'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

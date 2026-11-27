import 'package:estate/gate/screens/gatehouse_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gate history keeps filters in one row and opens search below',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const MaterialApp(home: GatehouseHistoryScreen(isDark: false)));
    await tester.pumpAndSettle();

    final search = find.byTooltip('Search gate logs');
    final field = find.byType(TextField);
    final filters = find.byType(ChoiceChip);
    expect(field, findsNothing);
    expect(filters, findsNWidgets(4));
    final centers = tester.getCenter(filters.first).dy;
    for (var i = 1; i < 4; i++) {
      expect(tester.getCenter(filters.at(i)).dy, centers);
    }
    expect(tester.getCenter(search).dy, closeTo(centers, 1));
    await tester.ensureVisible(filters.last);
    await tester.pumpAndSettle();
    expect(tester.getCenter(search).dx,
        greaterThan(tester.getCenter(filters.last).dx));

    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(field).dy,
        greaterThan(tester.getBottomLeft(search).dy));
    await tester.enterText(field, 'Visitor');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(field, findsNothing);
    expect(find.text('No gate activity in the last 24 hours.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

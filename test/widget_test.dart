import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/resident/resident_app.dart';
import 'package:estate/resident/screens/profile_screen.dart';

void main() {
  testWidgets('Resident navigation opens profile after billing removal',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: AppScaffold(isDark: false, onToggleTheme: () {})));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Visitors', 'Token', 'Chat', 'User']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byTooltip('Contact gatehouse'), findsNothing);
    expect(find.byTooltip('New Pass'), findsOneWidget);
    expect(find.text('Bills'), findsNothing);
    expect(find.text('Pay Dues'), findsNothing);
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Residence Dues & Invoices'), findsNothing);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Invite Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

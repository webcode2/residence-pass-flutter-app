import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/resident/resident_app.dart';
import 'package:estate/resident/screens/profile_screen.dart';
import 'package:estate/shared/ui/widgets/sos_hold_button.dart';

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
    expect(find.byTooltip('New Token'), findsOneWidget);
    expect(find.byType(SosHoldButton), findsNothing);
    expect(find.text('Bills'), findsNothing);
    expect(find.text('Pay Dues'), findsNothing);
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Residence Dues & Invoices'), findsNothing);
    expect(find.byType(SosHoldButton), findsNothing);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Digital Gate Token'), findsOneWidget);
    expect(find.text('ESTATE ACCESS TOOLS'), findsNothing);
    expect(find.text('Token'), findsNWidgets(2));
    expect(find.text('Visitors'), findsNWidgets(2));
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.byType(SosHoldButton), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

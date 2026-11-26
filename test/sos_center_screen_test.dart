import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/shared/sos/sos_center_screen.dart';
import 'package:estate/shared/ui/widgets/incident_report_widget.dart';
import 'package:estate/shared/ui/widgets/sos_hold_button.dart';

void main() {
  testWidgets('SOS screen centres only the distress alarm', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SosCenterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SOS & emergencies'), findsOneWidget);
    expect(find.byType(SosHoldButton), findsOneWidget);
    expect(find.byType(IncidentReportWidget), findsNothing);
    expect(find.text('Emergency distress alarm'), findsOneWidget);
    expect(find.text('You have not reported any incidents yet.'), findsNothing);

    final viewportBox = tester.widget<ConstrainedBox>(find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(ConstrainedBox),
    ).first);
    expect(viewportBox.constraints.minHeight, greaterThan(0));

    final centeredCard = tester.widget<ConstrainedBox>(find.descendant(
      of: find.byType(Center),
      matching: find.byType(ConstrainedBox),
    ).first);
    expect(centeredCard.constraints.maxWidth, 560);
    expect(tester.takeException(), isNull);
  });
}

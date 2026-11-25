import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/screens/incident_report_screen.dart';

void main() {
  testWidgets('validates, submits a report and refreshes the list',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sent = <Map<String, dynamic>>[];
    var reports = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
        home: IncidentReportScreen(
      load: () async => reports,
      submit: (body) async {
        sent.add(body);
        reports = [
          {
            'title': body['title'],
            'location': body['location'],
            'status': 'open',
            'resolution_note': null
          }
        ];
      },
    )));
    await tester.pumpAndSettle();
    expect(
        find.text('You have not reported any incidents yet.'), findsOneWidget);

    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.text('Title needs at least 3 characters'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Short title'), 'Broken gate light');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'), 'North gate');
    await tester.enterText(find.widgetWithText(TextFormField, 'Details'),
        'Light has been out since Monday.');
    await tester.tap(find.text('High'));
    await tester.tap(find.text('Hide my name from the caretaker'));
    await tester.pump();
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(sent.single, {
      'title': 'Broken gate light',
      'location': 'North gate',
      'description': 'Light has been out since Monday.',
      'severity': 'high',
      'is_anonymous': true,
    });
    expect(find.text('Report sent to your estate caretaker.'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('shows the server error when submission fails', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: IncidentReportScreen(
      load: () async => [],
      submit: (_) async =>
          throw Exception('You have filed several reports recently.'),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Short title'), 'Noise');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Location'), 'Block C');
    await tester.enterText(find.widgetWithText(TextFormField, 'Details'),
        'Loud party past midnight.');
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(
        find.text('You have filed several reports recently.'), findsOneWidget);
  });
}

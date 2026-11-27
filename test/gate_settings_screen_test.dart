import 'package:estate/gate/screens/gate_settings_screen.dart';
import 'package:estate/gate/screens/gatehouse_officers_screen.dart';
import 'package:estate/shared/account/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guard settings use duty controls, not resident preferences',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var toggled = 0;
    await tester.pumpWidget(MaterialApp(
      home: GateSettingsScreen(
        isDark: false,
        onToggleTheme: () => toggled++,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Settings & security'), findsOneWidget);
    for (final label in [
      'Dark appearance',
      'Emergency SOS alerts',
      'Visitor check-in alerts',
      'Resident chat alerts',
      'Duty status',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is guard-relevant');
    }

    for (final residentOnly in [
      'Biometric app lock',
      'App lock & fingerprint',
      'Gate Arrival Alerts',
      'Visitor Departure Alerts',
      'Unit / House',
      'Street Name',
      'Resident Status',
      'Resident account',
    ]) {
      expect(find.text(residentOnly), findsNothing,
          reason: '$residentOnly belongs to the resident app');
    }

    await tester.tap(find.widgetWithText(SwitchListTile, 'Dark appearance'));
    await tester.pump();
    expect(toggled, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('officers tab opens gate settings, not resident settings',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: GatehouseOfficersScreen(isDark: false, onToggleTheme: () {}),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings & security'));
    await tester.pumpAndSettle();

    expect(find.byType(GateSettingsScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

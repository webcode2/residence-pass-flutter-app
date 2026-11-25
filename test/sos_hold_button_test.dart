import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate/shared/ui/widgets/sos_hold_button.dart';

void main() {
  testWidgets('SOS requires four seconds and sends only once', (tester) async {
    var sends = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 200,
                child: SosHoldButton(send: (id) async {
                  sends++;
                  return {
                    'devices_queued': 2,
                    'push_configured': true,
                    'house_location': '12 Palm Street'
                  };
                })))));
    final target = find.byType(SosHoldButton);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final circle = find.byType(ClipOval);
    expect(tester.getSize(circle), const Size(108, 108));
    final short = await tester.startGesture(tester.getCenter(target));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final ring = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('sos-hold-ring')));
    expect(ring.value, closeTo(0.5, 0.01));
    await tester.pump(const Duration(seconds: 1));
    await short.up();
    await tester.pump();
    expect(sends, 0);
    final hold = await tester.startGesture(tester.getCenter(target));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3999));
    expect(sends, 0);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(sends, 1);
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.text('SOS recorded'), findsWidgets);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final repeat = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(seconds: 5));
    await repeat.up();
    expect(sends, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('moving outside cancels the hold', (tester) async {
    var sends = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                    width: 200,
                    child: SosHoldButton(send: (id) async {
                      sends++;
                      return {};
                    }))))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(SosHoldButton)));
    await tester.pump(const Duration(seconds: 2));
    await gesture.moveBy(const Offset(400, 400));
    await tester.pump(const Duration(seconds: 5));
    await gesture.up();
    expect(sends, 0);
  });
}

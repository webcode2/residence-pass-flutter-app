import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/gate/gate_app.dart';
import 'package:estate/gate/state/gatehouse_store.dart';
import 'package:estate/gate/screens/gatehouse_home_screen.dart';
import 'package:estate/shared/ui/widgets/sos_hold_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guard home puts compact activity counts before guest token',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.4)),
        child: child!,
      ),
      home: GatehouseAppScaffold(isDark: false, onToggleTheme: () {}),
    ));
    await tester.pumpAndSettle();

    final heading = find.text('Guest token');
    expect(heading, findsOneWidget);
    for (final label in ['On site', 'Entries today', 'Exits today']) {
      expect(tester.getBottomLeft(find.text(label)).dy,
          lessThan(tester.getTopLeft(heading).dy));
    }
    expect(find.text('PASTE'), findsNothing);
    expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
    expect(find.byType(SosHoldButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home uses the active estate name and keeps header controls',
      (tester) async {
    final estateName = AuthService.instance.estateNameNotifier;
    addTearDown(() => estateName.value = null);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: GatehouseAppScaffold(isDark: false, onToggleTheme: () {}),
    ));
    await tester.pumpAndSettle();

    final appBar = find.byType(AppBar).hitTestable();
    expect(find.descendant(of: appBar, matching: find.text('Home')),
        findsOneWidget);
    const longName = 'Cedar Grove Estate and Community Gardens East Entrance';
    estateName.value = longName;
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
        find.descendant(of: appBar, matching: find.text(longName)));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.byTooltip('Open guard menu').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Notifications').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest token preserves leading zeros, case and longer codes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GatehouseHomeScreen(isDark: false),
    ));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    final input = tester.widget<TextField>(field);
    expect(input.keyboardType, TextInputType.emailAddress);
    expect(input.textCapitalization, TextCapitalization.none);
    expect(input.autocorrect, isFalse);

    final boxes = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('guest-token-box-');
    });
    expect(boxes, findsNWidgets(4));
    expect(tester.getCenter(boxes.first).dx + tester.getCenter(boxes.last).dx,
        closeTo(2 * tester.getCenter(field).dx, 0.1));

    for (final token in ['00a', '00a7', '00a74', '00a742', '00a74', '00a7']) {
      await tester.enterText(field, token);
      await tester.pumpAndSettle();
      expect(boxes, findsNWidgets(token.length.clamp(4, 6)));
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          token.length >= 4 ? isNotNull : isNull);
      expect(find.textContaining('Sign in to verify access'), findsNothing);
    }

    await tester.enterText(field, '00Z12345');
    await tester.pumpAndSettle();
    expect(input.controller!.text, '00Z12345');
    expect(boxes, findsNWidgets(8));

    // Try adding a character at the end, then in the middle of the full field.
    for (final offset in [8, 3]) {
      const code = '00Z12345';
      tester.testTextInput.updateEditingValue(TextEditingValue(
          text: code, selection: TextSelection.collapsed(offset: offset)));
      await tester.pump();
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: code.replaceRange(offset, offset, '9'),
        selection: TextSelection.collapsed(offset: offset + 1),
      ));
      await tester.pump();
      expect(input.controller!.text, code);
      expect(input.controller!.selection.baseOffset, offset);
    }

    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '00Z2345', selection: TextSelection.collapsed(offset: 3)));
    await tester.pump();
    expect(input.controller!.text, '00Z2345');
    expect(boxes, findsNWidgets(7));

    // Pasting into the empty field applies the same filter and limit.
    await tester.enterText(field, '');
    await tester.enterText(field, '00z-12345678901234567890');
    await tester.pumpAndSettle();
    expect(input.controller!.text, '00z12345');
    expect(boxes, findsNWidgets(8));
    expect(find.textContaining('Sign in to verify access'), findsNothing);

    await tester.enterText(field, '00a-7');
    await tester.pumpAndSettle();
    expect(input.controller!.text, '00a7');

    await tester.tap(find.byTooltip('Clear token'));
    await tester.pumpAndSettle();
    expect(input.controller!.text, isEmpty);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('keyboard and cancel never approve, and Approve submits once',
      (tester) async {
    var lookups = 0;
    var approvals = 0;
    VerificationResult result({required bool approved}) => VerificationResult(
          isFound: true,
          isValid: approved,
          visitorName: 'Fixture Visitor',
          hostResident: 'Fixture Host',
          hostUnit: '',
          message: approved ? 'Entry recorded' : 'Confirm entry',
          canCheckIn: !approved,
          canBookOut: false,
        );
    await tester.pumpWidget(MaterialApp(
      home: GatehouseHomeScreen(
        isDark: false,
        previewToken: (code) async {
          expect(code, '00a742');
          lookups++;
          return result(approved: false);
        },
        approveToken: (code, preview) async {
          expect(code, '00a742');
          expect(preview.canCheckIn, isTrue);
          approvals++;
          return result(approved: true);
        },
      ),
    ));
    final field = find.byType(TextField);
    await tester.enterText(field, '00a742');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Host: Fixture Host'), findsOneWidget);
    expect(find.text('Fixture Visitor'), findsOneWidget);
    expect(find.text('Entry authorized'), findsNothing);
    expect(lookups, 1);
    expect(approvals, 0);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(lookups, 1);
    expect(approvals, 0);

    await tester.enterText(field, '00a742');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Look up token'));
    await tester.tap(find.text('Look up token'));
    await tester.pumpAndSettle();
    expect(lookups, 2);
    expect(approvals, 0);
    await tester.ensureVisible(find.text('Approve'));
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(approvals, 1);
    expect(find.text('Entry authorized'), findsOneWidget);
    expect(find.text('Host: Fixture Host'), findsOneWidget);
  });
}

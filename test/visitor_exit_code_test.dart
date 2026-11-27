import 'dart:convert';

import 'package:estate/resident/screens/visitors_screen.dart';
import 'package:estate/resident/state/visitor_store.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
      'expired exit code can be replaced and the new code fits one line',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 780);
    addTearDown(tester.view.reset);

    final auth = AuthService.instance;
    final backend = auth.baseUrl;
    final now = DateTime.now().toUtc();
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({
          'exp':
              now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'app_id': 'ESTATE-ONE',
          'sub': 'member@example.com',
        })))
        .replaceAll('=', '');
    final pass = {
      'id': 'test-pass',
      'visitor_name': 'Alex',
      'code': 'A1234',
      'status': 'checked_in',
      'created_at': now.subtract(const Duration(hours: 25)).toIso8601String(),
      'expires_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'bookout_code': 'B5678',
      'bookout_expires_at':
          now.subtract(const Duration(minutes: 5)).toIso8601String(),
    };
    var generations = 0;

    await http.runWithClient(() async {
      await SessionStore().save({
        'token': 'header.$claims.signature',
        'backend': backend,
        'app_id': 'ESTATE-ONE',
        'code_length': 8,
        'view_mode': 'resident',
        'user': {
          'id': 'member',
          'email': 'member@example.com',
          'roles': ['resident'],
          'app_id': 'ESTATE-ONE',
        },
      });
      await auth.restoreSession();
      await VisitorStore.instance.refresh();

      await tester
          .pumpWidget(const MaterialApp(home: VisitorsScreen(isDark: false)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Book Out'));
      await tester.pumpAndSettle();

      expect(find.textContaining('This exit code has expired'), findsOneWidget);
      expect(find.text('B5678'), findsNothing);
      await tester.tap(find.text('Generate New Exit Code'));
      await tester.pumpAndSettle();

      expect(generations, 1);
      final code = tester.widget<Text>(find.text('1234567A'));
      expect(code.maxLines, 1);
      expect(code.softWrap, isFalse);
      expect(code.style!.fontWeight, FontWeight.w900);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      auth.logout();
      await tester.pump();
    },
        () => MockClient((request) async {
              final path = request.url.path;
              if (path.endsWith('/visitor/history')) {
                return http.Response(jsonEncode([pass]), 200);
              }
              if (path.endsWith('/visitor/test-pass/book-out')) {
                generations++;
                return http.Response(
                    jsonEncode({
                      'bookout_code': '1234567A',
                      'expires_at':
                          now.add(const Duration(hours: 2)).toIso8601String(),
                    }),
                    200);
              }
              return http.Response('{}', 200);
            }));
  });
}

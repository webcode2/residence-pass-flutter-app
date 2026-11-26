import 'package:estate/gate/data/visitor_api.dart';
import 'package:estate/gate/state/guest_token_verification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _missing = VisitorApiError('Token not found', isMissingGuestToken: true);

void main() {
  test('second miss blocks only the normalized code for 60 seconds', () async {
    var now = DateTime.utc(2026);
    final verification = GuestTokenVerification(now: () => now);
    addTearDown(verification.clear);
    final requests = <String>[];

    Future<String> request(String code) async {
      requests.add(code);
      if (code == '00A7') throw _missing;
      return 'authorized';
    }

    final localCooldown = isA<VisitorApiError>().having(
      (error) => error.message,
      'message',
      'Token not found',
    );
    for (final token in ['00a7', ' 00A7 ']) {
      await expectLater(
          verification.verify(token, request), throwsA(same(_missing)));
    }
    expect(requests, ['00A7', '00A7']);

    now = now.add(const Duration(seconds: 20));
    await expectLater(
        verification.verify('00a7', request), throwsA(localCooldown));
    expect(await verification.verify('00b7', request), 'authorized');
    now = now.add(const Duration(seconds: 39));
    await expectLater(
        verification.verify('00a7', request), throwsA(localCooldown));
    expect(requests, ['00A7', '00A7', '00B7']);

    now = now.add(const Duration(seconds: 1));
    await expectLater(
        verification.verify('00a7', request), throwsA(same(_missing)));
    expect(requests.last, '00A7');
    expect(requests, hasLength(4));
  });

  testWidgets(
      'non-miss outcomes never start a cooldown and identity reset clears it',
      (tester) async {
    final verification = GuestTokenVerification();
    addTearDown(verification.clear);
    var requests = 0;
    Future<dynamic> fail(Object error) =>
        verification.verify('00a7', (_) async {
          requests++;
          throw error;
        });

    for (final error in [
      const VisitorApiError('Invalid, expired, or already used code'),
      const VisitorApiError('Access denied'),
      const VisitorApiError('Too many failed attempts'),
      http.ClientException('offline'),
    ]) {
      for (var attempt = 0; attempt < 3; attempt++) {
        await expectLater(fail(error), throwsA(same(error)));
      }
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      await expectLater(fail(_missing), throwsA(same(_missing)));
    }
    expect(requests, 14);
    verification.clear();
    await expectLater(fail(_missing), throwsA(same(_missing)));
    expect(requests, 15);
  });

  test('only the explicit 401 guest-token signal qualifies as missing',
      () async {
    Future<void> check(int status, String? marker, bool missing) async {
      await http.runWithClient(
        () => expectLater(
          VisitorApi.request('verify/token/00A7'),
          throwsA(isA<VisitorApiError>()
              .having((error) => error.isMissingGuestToken,
                  'isMissingGuestToken', missing)
              .having((error) => error.message, 'message', 'Access denied')),
        ),
        () => MockClient((_) async => http.Response(
              '{"detail":"Access denied (2 attempts remaining before temporary cooldown)"}',
              status,
              headers: {
                if (marker != null) 'x-residence-verification-result': marker
              },
            )),
      );
    }

    await check(401, null, false);
    await check(401, 'token_not_found', true);
    await check(401, 'expired', false);
    await check(429, 'token_not_found', false);
  });
}

// Gate module copy: owned by the gate app; change freely without affecting residents.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:estate/shared/auth/auth_service.dart';

class VisitorApiError implements Exception {
  const VisitorApiError(this.message, {this.isMissingGuestToken = false});

  final String message;
  final bool isMissingGuestToken;

  @override
  String toString() => message;
}

class VisitorApi {
  static final _legacyAttempts = RegExp(
    r'\s*\(\d+ attempts? remaining before temporary cooldown\)$',
    caseSensitive: false,
  );

  static bool get isLive =>
      AuthService.instance.accessToken != null &&
      !AuthService.instance.accessToken!.startsWith('demo_');

  static Future<dynamic> request(String path,
      {Map<String, dynamic>? body}) async {
    final auth = AuthService.instance;
    final uri = Uri.parse('${auth.baseUrl}/api/v1/$path');
    final headers = {
      'Authorization': 'Bearer ${auth.accessToken}',
      'X-App-Id': auth.appId,
      'Content-Type': 'application/json'
    };
    final response = await (body == null
            ? http.get(uri, headers: headers)
            : http.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final isTokenVerification = path.startsWith('verify/token/') ||
          path.startsWith('verify/token-preview/');
      final detail = data is Map && data['detail'] is String
          ? data['detail'] as String
          : 'Request failed. Please retry.';
      throw VisitorApiError(
        isTokenVerification ? detail.replaceFirst(_legacyAttempts, '') : detail,
        isMissingGuestToken: isTokenVerification &&
            response.statusCode == 401 &&
            response.headers['x-residence-verification-result'] ==
                'token_not_found',
      );
    }
    return data;
  }
}

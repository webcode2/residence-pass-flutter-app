import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SOSRequestException implements Exception {
  final int statusCode;
  final String message;
  SOSRequestException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class SOSService {
  static Future<Map<String, dynamic>> request(String path,
      {Map<String, dynamic>? body}) async {
    final auth = AuthService.instance;
    if (auth.accessToken == null || auth.accessToken!.startsWith('demo_')) {
      throw Exception('Sign in to your estate server to send an SOS.');
    }
    final uri = Uri.parse('${auth.baseUrl}/api/v1/sos$path');
    final headers = {
      'Authorization': 'Bearer ${auth.accessToken}',
      'X-App-Id': auth.appId,
      'Content-Type': 'application/json'
    };
    final r = await (body == null
            ? http.get(uri, headers: headers)
            : http.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw SOSRequestException(
          r.statusCode,
          data is Map && data['detail'] is String
              ? data['detail']
              : 'SOS could not be confirmed. Please retry.');
    }
    return Map<String, dynamic>.from(data);
  }
}

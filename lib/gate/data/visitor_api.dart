// Gate module copy: owned by the gate app; change freely without affecting residents.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:estate/shared/auth/auth_service.dart';

class VisitorApi {
  static bool get isLive => AuthService.instance.accessToken != null &&
      !AuthService.instance.accessToken!.startsWith('demo_');

  static Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    final auth = AuthService.instance;
    final uri = Uri.parse('${auth.baseUrl}/api/v1/$path');
    final headers = {'Authorization': 'Bearer ${auth.accessToken}',
      'X-App-Id': auth.appId, 'Content-Type': 'application/json'};
    final response = await (body == null ? http.get(uri, headers: headers) :
      http.post(uri, headers: headers, body: jsonEncode(body)))
      .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data is Map && data['detail'] is String ? data['detail'] : 'Request failed. Please retry.');
    }
    return data;
  }
}

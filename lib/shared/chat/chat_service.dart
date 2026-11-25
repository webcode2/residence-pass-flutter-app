import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:estate/shared/auth/auth_service.dart';

class ChatService {
  static final guardUnread = ValueNotifier<int>(0);
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    final auth = AuthService.instance;
    final token = auth.accessToken;
    if (token == null || token.startsWith('demo_')) {
      throw Exception('Sign in to the server to use chat.');
    }
    final uri = Uri.parse('${auth.baseUrl}/api/v1/chat/$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'X-App-Id': auth.appId,
      'Content-Type': 'application/json'
    };
    final response = await (body == null
            ? http.get(uri, headers: headers)
            : http.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'Chat request failed (${response.statusCode}).';
      try {
        final value = jsonDecode(response.body)['detail'];
        if (value is String) detail = value;
      } catch (_) {}
      throw Exception(detail);
    }
    return jsonDecode(response.body);
  }
}

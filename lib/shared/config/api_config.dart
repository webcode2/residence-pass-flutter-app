import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      final uri = Uri.parse(configured);
      if (!uri.hasScheme ||
          uri.host.isEmpty ||
          (!kDebugMode && uri.scheme != 'https')) {
        throw StateError(
            'API_BASE_URL must be a valid HTTPS backend origin for release builds.');
      }
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    return 'https://residence.elastrocloud.com';
  }
}

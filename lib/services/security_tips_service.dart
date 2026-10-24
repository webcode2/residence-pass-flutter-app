import 'api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SecurityTip {
  final int id;
  final String category;
  final String tip;
  final String icon;

  const SecurityTip({
    required this.id,
    required this.category,
    required this.tip,
    required this.icon,
  });

  factory SecurityTip.fromJson(Map<String, dynamic> json) {
    return SecurityTip(
      id: json['id'] as int? ?? 1,
      category: json['category'] as String? ?? 'Security Tip',
      tip: json['tip'] as String? ?? 'Never share your access token with unauthorized personnel.',
      icon: json['icon'] as String? ?? 'shield',
    );
  }
}

class SecurityTipsService extends ChangeNotifier {
  static final SecurityTipsService instance = SecurityTipsService._internal();
  factory SecurityTipsService() => instance;
  SecurityTipsService._internal() {
    fetchTips();
  }

  String _baseUrl = ApiConfig.baseUrl;

  final List<SecurityTip> _defaultTips = const [
    SecurityTip(
      id: 1,
      category: 'Pass Safety',
      tip: 'Only generate visitor passes for people you know and expect.',
      icon: 'shield',
    ),
    SecurityTip(
      id: 2,
      category: 'Exit Verification',
      tip: 'Generate the 4-digit exit code only when your visitor is departing.',
      icon: 'logout',
    ),
    SecurityTip(
      id: 3,
      category: 'Anti-Fraud',
      tip: 'Security guards will never ask for your personal app login password.',
      icon: 'lock',
    ),
    SecurityTip(
      id: 4,
      category: 'Gate Etiquette',
      tip: 'Tailgating at the boom barrier is forbidden. Let each car scan separately.',
      icon: 'car',
    ),
    SecurityTip(
      id: 5,
      category: 'Biometrics',
      tip: 'Enable Biometric App Lock in Settings for faster, secure OTP access.',
      icon: 'fingerprint',
    ),
  ];

  List<SecurityTip> _tips = [];

  List<SecurityTip> get tips => _tips.isNotEmpty ? _tips : _defaultTips;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    fetchTips();
  }

  Future<void> fetchTips() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/estates/security-tips'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tips = data.map((item) => SecurityTip.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {
      // Use resilient default tips if offline
      if (_tips.isEmpty) {
        _tips = List.from(_defaultTips);
        notifyListeners();
      }
    }
  }
}

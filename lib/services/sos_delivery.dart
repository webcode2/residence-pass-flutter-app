import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'session_store.dart';

class SosDelivery {
  static const deliveryWindow = Duration(seconds: 40);
  static const sirenDuration = Duration(seconds: 30);
  static DateTime? raisedAt(Map<String, dynamic> alert) =>
      DateTime.tryParse(alert['created_at']?.toString() ?? '')?.toUtc();
  static bool canRing(Map<String, dynamic> alert, {DateTime? now}) {
    if (alert['type'] == 'sos_missed' || alert['status'] == 'resolved') {
      return false;
    }
    final raised = raisedAt(alert);
    final current = (now ?? DateTime.now()).toUtc();
    if (raised == null ||
        raised.isAfter(current) ||
        current.difference(raised) >= deliveryWindow) {
      return false;
    }
    final expiry =
        DateTime.tryParse(alert['alarm_expires_at']?.toString() ?? '');
    return expiry == null || current.isBefore(expiry.toUtc());
  }

  static Future<void> acknowledge(Map<String, dynamic> data,
      {String? deviceToken, bool background = false}) async {
    if (!canRing(data)) return;
    try {
      final session =
          background ? await SessionStore().read(ApiConfig.baseUrl) : null;
      final auth = AuthService.instance;
      final stored = session ?? <String, dynamic>{};
      final storedUser =
          Map<String, dynamic>.from(stored['user'] as Map? ?? {});
      final bearer = background ? stored['token'] as String? : auth.accessToken;
      final estate = background ? stored['app_id'] : auth.appId;
      final user = background ? storedUser['id'] : auth.currentUser?.id;
      if (bearer == null ||
          estate != data['app_id'] ||
          user == data['sender_id']) {
        return;
      }
      final token = deviceToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final base = background ? ApiConfig.baseUrl : auth.baseUrl;
      await http
          .post(Uri.parse('$base/api/v1/sos/${data['alert_id']}/received'),
              headers: {
                'Authorization': 'Bearer $bearer',
                'X-App-Id': estate.toString(),
                'Content-Type': 'application/json'
              },
              body: jsonEncode({'fcm_token': token}))
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      /* Missing receipts produce a normal report, never a late siren. */
    }
  }
}

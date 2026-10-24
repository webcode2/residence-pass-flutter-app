import 'package:estate/services/sos_delivery.dart';
import 'package:estate/services/fcm_service.dart';
import 'package:estate/services/auth_service.dart';
import 'package:estate/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raised = DateTime.utc(2026, 10, 24, 12);
  Map<String, dynamic> alert() => {
        'type': 'sos_live',
        'status': 'active',
        'created_at': raised.toIso8601String(),
        'alarm_expires_at':
            raised.add(const Duration(seconds: 40)).toIso8601String(),
        'alert_id': 'live-test',
        'app_id': 'ESTATE',
        'sender_id': 'sender'
      };
  tearDown(() {
    FCMService.instance.pendingSOS.value = null;
    FCMService.instance.pendingSOSReport.value = null;
    AuthService.instance.currentUserNotifier.value = null;
  });
  test(
      'delivery eligibility ends at exactly forty seconds, independent of foreground state',
      () {
    expect(SosDelivery.canRing(alert(), now: raised), isTrue);
    expect(
        SosDelivery.canRing(alert(),
            now: raised.add(const Duration(seconds: 39))),
        isTrue);
    expect(
        SosDelivery.canRing(alert(),
            now: raised.add(const Duration(seconds: 40))),
        isFalse);
    expect(
        SosDelivery.canRing(alert(),
            now: raised.add(const Duration(minutes: 5))),
        isFalse);
    expect(SosDelivery.canRing({...alert(), 'status': 'resolved'}, now: raised),
        isFalse);
    expect(SosDelivery.canRing({...alert(), 'type': 'sos_missed'}, now: raised),
        isFalse);
    expect(SosDelivery.canRing({...alert(), 'created_at': null}, now: raised),
        isFalse);
    expect(SosDelivery.sirenDuration, const Duration(seconds: 30));
  });
  test('notification taps and late messages never restart the siren', () {
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'receiver', email: 'receiver@example.com', appId: 'ESTATE');
    final recent = {
      ...alert(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'alarm_expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 40))
          .toIso8601String()
    };
    FCMService.instance.handleChatMessage(recent, opened: true);
    expect(FCMService.instance.pendingSOS.value?['allow_alarm'], isFalse);
    FCMService.instance.pendingSOS.value = null;
    FCMService.instance.handleChatMessage({
      ...alert(),
      'alert_id': 'old-test',
      'created_at': DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 41))
          .toIso8601String()
    });
    expect(FCMService.instance.pendingSOS.value, isNull);
    expect(FCMService.instance.pendingSOSReport.value?['allow_alarm'], isFalse);
  });
}

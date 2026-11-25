import 'package:estate/shared/models/user_model.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/sos/sos_alarm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The initiating account never starts its own SOS alarm',
      (tester) async {
    final calls = <String>[];
    const channel = MethodChannel('residence/alarms');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'sender',
        email: 'sender@example.com',
        roles: ['resident'],
        appId: 'ESTATE');
    final data = <String, dynamic>{
      'type': 'sos_alert',
      'alert_id': 'self-alert',
      'sender_id': 'sender',
      'sender_name': 'Sender',
      'app_id': 'ESTATE',
      'status': 'active'
    };
    FCMService.instance.pendingSOS.value = null;
    FCMService.instance.handleChatMessage(data);
    expect(FCMService.instance.pendingSOS.value, isNull);
    await tester.pumpWidget(MaterialApp(
        home: SosAlarmScreen(alertId: 'self-alert', initialAlert: data)));
    await tester.pumpAndSettle();
    expect(calls, isNot(contains('start')));
    await tester.pumpWidget(const SizedBox());
    AuthService.instance.currentUserNotifier.value = null;
  });
  test('Another resident receives the SOS navigation event', () {
    AuthService.instance.currentUserNotifier.value = UserModel(
        id: 'receiver',
        email: 'receiver@example.com',
        roles: ['resident'],
        appId: 'ESTATE');
    FCMService.instance.handleChatMessage({
      'type': 'sos_alert',
      'alert_id': 'other-alert',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'active',
      'sender_id': 'sender',
      'app_id': 'ESTATE'
    });
    expect(FCMService.instance.pendingSOS.value?['sender_id'], 'sender');
    FCMService.instance.pendingSOS.value = null;
    AuthService.instance.currentUserNotifier.value = null;
  });
}

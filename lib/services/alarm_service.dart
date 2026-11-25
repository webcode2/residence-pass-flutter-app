import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  static const _channel = MethodChannel('residence/alarms');
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod<void>('initialize');
    } catch (_) {}
  }

  static Future<void> start() async {
    try {
      final sound = await rootBundle.load('assets/sos_alarm.wav');
      await _channel.invokeMethod<void>('start', sound.buffer.asUint8List());
    } catch (_) {
      if (!kIsWeb) SystemSound.play(SystemSoundType.alert);
    }
  }

  /// The SOS a user tapped "Respond" on while the app was closed, if any.
  static Future<Map<String, dynamic>?> takeLaunchAlert() async {
    try {
      final alert = await _channel.invokeMethod<Map>('takeLaunchAlert');
      return alert == null ? null : Map<String, dynamic>.from(alert);
    } catch (_) {
      return null;
    }
  }

  /// Called when "Respond" is tapped while the app is already running.
  static void onAlertOpened(void Function(Map<String, dynamic>) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'alertOpened' && call.arguments is Map) {
        handler(Map<String, dynamic>.from(call.arguments as Map));
      }
    });
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}

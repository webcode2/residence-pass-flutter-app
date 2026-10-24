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

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}

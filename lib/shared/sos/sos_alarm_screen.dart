import 'dart:async';
import 'package:flutter/material.dart';
import 'package:estate/shared/sos/sos_delivery.dart';
import 'package:estate/shared/sos/sos_service.dart';
import 'package:estate/shared/sos/alarm_service.dart';
import 'package:estate/shared/auth/auth_service.dart';

class SosAlarmScreen extends StatefulWidget {
  final String alertId;
  final bool allowAlarm;
  final Map<String, dynamic>? initialAlert;
  const SosAlarmScreen(
      {super.key,
      required this.alertId,
      this.initialAlert,
      this.allowAlarm = false});
  @override
  State<SosAlarmScreen> createState() => _SosAlarmScreenState();
}

class _SosAlarmScreenState extends State<SosAlarmScreen> {
  Map<String, dynamic>? _alert;
  String? _error;
  Timer? _ringStop;
  bool _hasRung = false;
  @override
  void initState() {
    super.initState();
    _alert = widget.initialAlert;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SOSService.request('/${widget.alertId}');
      if (!mounted) return;
      setState(() => _alert = data);
      if (widget.allowAlarm &&
          SosDelivery.canRing(data) &&
          data['status'] == 'active' &&
          data['sender_id'] != AuthService.instance.currentUser?.id) {
        if (!_hasRung) {
          _hasRung = true;
          await AlarmService.start();
          _ringStop = Timer(SosDelivery.sirenDuration, () {
            AlarmService.stop();
          });
        }
      } else {
        await AlarmService.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Unable to refresh alert status. Contact estate security directly.');
      }
    }
  }

  @override
  void dispose() {
    _ringStop?.cancel();
    AlarmService.stop();
    super.dispose();
  }

  Future<void> _resolve() async {
    try {
      await SOSService.request('/${widget.alertId}/resolve', body: {});
      await AlarmService.stop();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Resolution was not confirmed. Please retry.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF991B1B),
      appBar: AppBar(
          title: Text(widget.allowAlarm
              ? 'Estate distress alarm'
              : 'Estate SOS report')),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.sos, size: 90, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(_alert?['sender_name'] ?? 'Loading distress alert…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(
                        _alert?['house_location'] ??
                            _error ??
                            'Retrieving estate location',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white)),
                    const SizedBox(height: 24),
                    if (_alert != null)
                      Text(
                          _alert!['status'] == 'active'
                              ? 'Needs urgent assistance'
                              : 'This alert has been resolved',
                          style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 24),
                    if (_alert != null && SosDelivery.raisedAt(_alert!) != null)
                      Text(
                          'Reported: ${SosDelivery.raisedAt(_alert!)!.toLocal()}',
                          style: const TextStyle(color: Colors.white)),
                    if (_error != null)
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                    if (_alert != null &&
                        (_alert!['sender_id'] ==
                                AuthService.instance.currentUser?.id ||
                            AuthService.instance.currentUser?.isGuard == true ||
                            AuthService.instance.currentUser?.isCaretaker ==
                                true))
                      TextButton(
                          onPressed: _resolve,
                          child: const Text('Mark resolved',
                              style: TextStyle(color: Colors.white))),
                    FilledButton(
                        onPressed: () async {
                          await AlarmService.stop();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(widget.allowAlarm
                            ? 'Silence alarm & close'
                            : 'Close'))
                  ])))));
}

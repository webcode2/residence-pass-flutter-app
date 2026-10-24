import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sos_service.dart';

class SosHoldButton extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String)? send;
  const SosHoldButton({super.key, this.send});
  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _hold;
  int? _pointer;
  bool _sending = false;
  bool _sent = false;
  String? _requestId;
  Timer? _cooldown;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hold = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
        animationBehavior: AnimationBehavior.preserve)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _send();
      });
  }

  void _cancel() {
    _pointer = null;
    if (!_sending) _hold.reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  Future<void> _send() async {
    if (_sending || _sent) return;
    _pointer = null;
    setState(() => _sending = true);
    final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _requestId ??=
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    HapticFeedback.heavyImpact();
    try {
      final result = await (widget.send?.call(_requestId!) ??
          SOSService.request('', body: {'request_id': _requestId}));
      if (!mounted) return;
      setState(() => _sent = true);
      _cooldown?.cancel();
      _cooldown = Timer(const Duration(seconds: 60), () {
        if (mounted) {
          setState(() {
            _sent = false;
            _requestId = null;
          });
        }
      });
      final count = result['devices_queued'] ?? 0;
      final message = result['push_configured'] == true && count > 0
          ? 'SOS recorded. Alarm notifications queued for $count registered devices in your estate.'
          : 'SOS recorded, but alarm delivery is unavailable. Contact estate security directly now.';
      await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('SOS recorded'),
                  content: Text(
                      '$message\n\nLocation: ${result['house_location'] ?? 'Not set'}'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('OK'))
                  ]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is SOSRequestException && e.statusCode == 403
                ? e.message
                : 'SOS not confirmed: ${e.toString().replaceFirst('Exception: ', '')} Hold again to retry.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _hold.reset();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldown?.cancel();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
          width: 108,
          height: 108,
          child: Semantics(
              label:
                  'SOS distress alarm. Press and hold for four seconds. Release to cancel.',
              button: true,
              child: ClipOval(
                  child: Listener(
                      onPointerDown: (e) {
                        if (_sending || _sent || _pointer != null) return;
                        _pointer = e.pointer;
                        _hold.forward(from: 0);
                      },
                      onPointerUp: (e) {
                        if (e.pointer == _pointer) _cancel();
                      },
                      onPointerCancel: (e) {
                        if (e.pointer == _pointer) _cancel();
                      },
                      onPointerMove: (e) {
                        if (e.pointer == _pointer &&
                            (e.localPosition - const Offset(54, 54)).distance >
                                54) {
                          _cancel();
                        }
                      },
                      child: AnimatedBuilder(
                          animation: _hold,
                          builder: (context, _) => Container(
                              decoration: const BoxDecoration(
                                  color: Color(0xFFB91C1C),
                                  shape: BoxShape.circle),
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Positioned.fill(
                                    child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: CircularProgressIndicator(
                                            key:
                                                const ValueKey('sos-hold-ring'),
                                            value: _sent
                                                ? 1
                                                : _sending
                                                    ? null
                                                    : _hold.value,
                                            strokeWidth: 4,
                                            color: Colors.white,
                                            backgroundColor: Colors.white24))),
                                Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  _sent
                                                      ? Icons.check_rounded
                                                      : Icons
                                                          .emergency_outlined,
                                                  color: Colors.white,
                                                  size: 24),
                                              Text(
                                                  _sending
                                                      ? 'Sending…'
                                                      : _sent
                                                          ? 'SOS sent'
                                                          : 'SOS',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              const SizedBox(height: 2),
                                              Text(
                                                  _sent
                                                      ? 'Recorded'
                                                      : _hold.value > 0
                                                          ? '${(4 * (1 - _hold.value)).ceil()}s'
                                                          : 'Hold 4s',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12))
                                            ])))
                              ]))))))));
}

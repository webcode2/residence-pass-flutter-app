import 'package:flutter/material.dart';

import 'package:estate/resident/security/app_lock_service.dart';
import 'package:estate/resident/security/pin_pad.dart';
import 'package:estate/shared/auth/biometric_prompt.dart';

/// Full-screen PIN entry for settings.
///
/// [PinEntryScreen.create] returns the new PIN after the user enters it twice.
/// [PinEntryScreen.verify] returns true once the current PIN (or fingerprint) is confirmed.
class PinEntryScreen extends StatefulWidget {
  final String title;
  final bool create;
  final AppLockService service;
  const PinEntryScreen.create({super.key, required this.title, required this.service}) : create = true;
  const PinEntryScreen.verify({super.key, required this.title, required this.service}) : create = false;

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _first;
  String? _message;
  bool _error = false;
  bool _checking = false;
  int _wrong = 0;

  String get _prompt => widget.create
      ? (_first == null ? 'Choose a 6-digit PIN you will use to unlock Residence.' : 'Enter the same PIN again to confirm.')
      : 'Enter your current 6-digit PIN.';

  Future<void> _changed(String value) async {
    setState(() {
      _pin = value;
      _error = false;
      _message = null;
    });
    if (value.length < AppLockService.pinLength) return;
    if (widget.create) {
      if (_first == null) {
        if (RegExp(r'^(\d)\1{5}$').hasMatch(value) || '0123456789'.contains(value) || '9876543210'.contains(value)) {
          setState(() {
            _pin = '';
            _error = true;
            _message = 'Choose a PIN that is harder to guess.';
          });
          return;
        }
        setState(() {
          _first = value;
          _pin = '';
        });
      } else if (value == _first) {
        Navigator.pop(context, value);
      } else {
        setState(() {
          _first = null;
          _pin = '';
          _error = true;
          _message = 'The PINs did not match. Start again.';
        });
      }
      return;
    }
    setState(() => _checking = true);
    final ok = await widget.service.verifyPin(value);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    _wrong++;
    setState(() {
      _checking = false;
      _pin = '';
      _error = true;
      _message = _wrong >= AppLockService.maxPinAttempts
          ? 'Too many wrong PINs. Try again later.'
          : 'Wrong PIN. Try again.';
    });
    if (_wrong >= AppLockService.maxPinAttempts) Navigator.pop(context, false);
  }

  Future<void> _fingerprint() async {
    final result = await widget.service.confirmFingerprint(widget.title);
    if (!mounted) return;
    if (result == BiometricResult.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_outline_rounded, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(_prompt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                PinPad(
                  value: _pin,
                  enabled: !_checking,
                  error: _error,
                  onChanged: _changed,
                  onFingerprint: !widget.create && widget.service.fingerprintUnlock ? _fingerprint : null,
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

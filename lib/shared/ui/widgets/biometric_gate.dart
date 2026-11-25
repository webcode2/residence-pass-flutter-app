import 'package:flutter/material.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/biometric_service.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  final BiometricService? service;
  const BiometricGate({super.key, required this.child, this.service});
  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? BiometricService.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.currentUserNotifier.addListener(_userChanged);
    _userChanged();
  }

  Future<void> _userChanged() async {
    final user = AuthService.instance.currentUser;
    await _service.bind(user == null || user.mustChangePassword
        ? null
        : '${AuthService.instance.baseUrl}.${user.id}');
    if (mounted && _service.enabled && !_service.unlocked) {
      await _service.unlock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _service.lock();
    }
    if (state == AppLifecycleState.resumed &&
        _service.enabled &&
        !_service.unlocked) {
      _service.unlock();
    }
  }

  @override
  void dispose() {
    AuthService.instance.currentUserNotifier.removeListener(_userChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final locked = AuthService.instance.isAuthenticated &&
            AuthService.instance.currentUser?.mustChangePassword != true &&
            (_service.loading || (_service.enabled && !_service.unlocked));
        return Stack(fit: StackFit.expand, children: [
          Offstage(
              offstage: locked,
              child: ExcludeFocus(excluding: locked, child: widget.child)),
          if (locked)
            Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                    child: Center(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fingerprint, size: 64),
                                  const SizedBox(height: 24),
                                  Text('Unlock Residence',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Use biometrics or your device passcode to continue.',
                                      textAlign: TextAlign.center),
                                  if (_service.error != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(_service.error!,
                                            textAlign: TextAlign.center)),
                                  const SizedBox(height: 24),
                                  if (_service.busy || _service.loading)
                                    const CircularProgressIndicator()
                                  else
                                    FilledButton(
                                        onPressed: _service.unlock,
                                        child: const Text('Unlock')),
                                  TextButton(
                                      onPressed: AuthService.instance.logout,
                                      child: const Text('Sign out')),
                                ]))))),
        ]);
      });
}

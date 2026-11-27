import 'package:flutter/material.dart';

import 'package:estate/resident/security/app_lock_service.dart';
import 'package:estate/resident/security/pin_pad.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/models/user_model.dart';

/// Identity used for a resident's lock settings; null for guards and signed-out users.
String? residentLockIdentity(UserModel? user) =>
    user == null || user.isGuard || user.mustChangePassword
        ? null
        : '${AuthService.instance.baseUrl}.${user.id}';

/// Wraps the whole app (MaterialApp.builder). Shows the lock screen or the privacy cover
/// for residents with app lock on. Security officers are never locked.
class ResidentLockGate extends StatefulWidget {
  final Widget child;
  final AppLockService? service;
  const ResidentLockGate({super.key, required this.child, this.service});

  @override
  State<ResidentLockGate> createState() => _ResidentLockGateState();
}

class _ResidentLockGateState extends State<ResidentLockGate> with WidgetsBindingObserver {
  late final AppLockService _service = widget.service ?? AppLockService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.currentUserNotifier.addListener(_userChanged);
    _userChanged();
  }

  Future<void> _userChanged() async {
    await _service.bind(residentLockIdentity(AuthService.instance.currentUser));
    _autoPrompt();
  }

  void _autoPrompt() {
    if (!mounted || !_service.canAutoPrompt) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _service.canAutoPrompt) _service.unlockWithFingerprint(automatic: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _service.onLifecycle(state);
    if (state == AppLifecycleState.resumed) _autoPrompt();
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
          final showLock = _service.bound && (_service.loading || _service.locked);
          final showCover = !showLock && _service.covered;
          return Stack(fit: StackFit.expand, children: [
            Offstage(
                offstage: showLock || showCover,
                child: ExcludeFocus(excluding: showLock || showCover, child: widget.child)),
            if (showLock) _LockHost(service: _service),
            if (showCover) const PrivacyCover(),
          ]);
        },
      );
}

/// The lock screen sits outside the app's navigator, so it brings its own overlay and
/// messenger for text fields and messages.
class _LockHost extends StatefulWidget {
  final AppLockService service;
  const _LockHost({required this.service});
  @override
  State<_LockHost> createState() => _LockHostState();
}

class _LockHostState extends State<_LockHost> {
  late final _navigator = Navigator(
      onGenerateRoute: (_) => PageRouteBuilder(
          pageBuilder: (_, __, ___) => AppLockScreen(service: widget.service)));

  @override
  Widget build(BuildContext context) => ScaffoldMessenger(child: HeroControllerScope.none(child: _navigator));
}

/// The header shared by the lock screen and the privacy cover.
class _LockHeader extends StatelessWidget {
  final String subtitle;
  const _LockHeader({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.fingerprint, size: 64, color: theme.colorScheme.onSurface),
      const SizedBox(height: 20),
      Text('Unlock Residence', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 10),
      Text(subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// Shown in the app switcher and whenever the app is in the background.
class PrivacyCover extends StatelessWidget {
  const PrivacyCover({super.key});
  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: _LockHeader(subtitle: 'Your details are hidden while Residence is in the background.'),
            ),
          ),
        ),
      );
}

enum _Mode { pin, password, newPin, confirmPin }

class AppLockScreen extends StatefulWidget {
  final AppLockService service;
  const AppLockScreen({super.key, required this.service});
  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  AppLockService get _service => widget.service;
  _Mode _mode = _Mode.pin;
  String _pin = '';
  String _firstPin = '';
  bool _checking = false;
  bool _pinError = false;
  String? _localMessage;
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (_service.pinBlocked) _mode = _Mode.password;
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pinChanged(String value) async {
    setState(() {
      _pin = value;
      _pinError = false;
      _localMessage = null;
    });
    if (value.length < AppLockService.pinLength) return;
    if (_mode == _Mode.pin) {
      setState(() => _checking = true);
      final ok = await _service.unlockWithPin(value);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _pin = '';
        _pinError = !ok;
        if (_service.pinBlocked) _mode = _Mode.password;
      });
    } else if (_mode == _Mode.newPin) {
      setState(() {
        _firstPin = value;
        _pin = '';
        _mode = _Mode.confirmPin;
      });
    } else if (_mode == _Mode.confirmPin) {
      if (value != _firstPin) {
        setState(() {
          _pin = '';
          _firstPin = '';
          _pinError = true;
          _mode = _Mode.newPin;
          _localMessage = 'The PINs did not match. Choose your new PIN again.';
        });
        return;
      }
      setState(() => _checking = true);
      await _service.changePin(value);
      await _service.unlockAfterPassword();
    }
  }

  Future<void> _signInWithPassword() async {
    final user = AuthService.instance.currentUser;
    if (user == null || _password.text.isEmpty || _checking) return;
    setState(() {
      _checking = true;
      _localMessage = null;
    });
    final result = await AuthService.instance
        .login(email: user.email, password: _password.text, appId: AuthService.instance.appId);
    if (!mounted) return;
    _password.clear();
    if (result['success'] != true) {
      setState(() {
        _checking = false;
        _localMessage = result['message'] as String? ?? 'Incorrect password.';
      });
      return;
    }
    if (_service.pinBlocked) {
      // The PIN was locked after too many attempts: choose a new one before continuing.
      setState(() {
        _checking = false;
        _mode = _Mode.newPin;
        _pin = '';
      });
      return;
    }
    await _service.unlockAfterPassword();
  }

  String get _subtitle {
    if (_mode == _Mode.password) return 'Enter your account password to continue.';
    if (_mode == _Mode.newPin) return 'Choose a new 6-digit PIN.';
    if (_mode == _Mode.confirmPin) return 'Enter the new PIN again to confirm.';
    return _service.fingerprintUnlock
        ? 'Enter your PIN or use your fingerprint to continue.'
        : 'Enter your 6-digit PIN to continue.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final name = (user?.fullName?.trim().isNotEmpty ?? false) ? user!.fullName!.trim().split(' ').first : null;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _service,
            builder: (context, _) {
              final message = _localMessage ?? _service.message;
              final busy = _checking || _service.busy || _service.loading;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (name != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Welcome back, $name',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      _LockHeader(subtitle: _subtitle),
                      const SizedBox(height: 28),
                      if (_mode == _Mode.password)
                        _passwordForm(theme, busy)
                      else
                        PinPad(
                          value: _pin,
                          enabled: !busy,
                          error: _pinError,
                          onChanged: _pinChanged,
                          onFingerprint: _mode == _Mode.pin && _service.fingerprintUnlock
                              ? () => _service.unlockWithFingerprint()
                              : null,
                        ),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(message,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      if (busy)
                        const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                      const SizedBox(height: 12),
                      if (_mode == _Mode.pin)
                        TextButton(
                            onPressed: busy ? null : () => setState(() {
                                  _mode = _Mode.password;
                                  _localMessage = null;
                                }),
                            child: const Text('Forgot PIN? Use your password')),
                      if (_mode == _Mode.password && !_service.pinBlocked)
                        TextButton(
                            onPressed: busy ? null : () => setState(() => _mode = _Mode.pin),
                            child: const Text('Use PIN instead')),
                      TextButton(
                          onPressed: busy ? null : AuthService.instance.logout,
                          child: const Text('Sign out')),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _passwordForm(ThemeData theme, bool busy) => Column(children: [
        TextField(
          controller: _password,
          enabled: !busy,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signInWithPassword(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : _signInWithPassword,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Continue'),
        ),
      ]);
}

import 'package:flutter/material.dart';

import 'package:estate/resident/security/app_lock_service.dart';
import 'package:estate/resident/security/pin_entry_screen.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/biometric_prompt.dart';
import 'package:estate/shared/auth/device_sign_in.dart';
import 'package:estate/shared/ui/theme.dart';

/// Row in Settings that opens the resident's security settings.
class ResidentSecurityTile extends StatelessWidget {
  const ResidentSecurityTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lock = AppLockService.instance;
    return AnimatedBuilder(
      animation: lock,
      builder: (context, _) => ListTile(
        leading: _IconBadge(icon: Icons.fingerprint_rounded, isDark: isDark),
        title: Text('App lock & fingerprint',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: _primary(isDark))),
        subtitle: Text(
            lock.enabled ? 'On · ${lock.lockAfter.label.toLowerCase()}' : 'Off · protect Residence with a PIN',
            style: TextStyle(fontSize: 12, color: _secondary(isDark))),
        trailing: Icon(Icons.chevron_right_rounded, color: _secondary(isDark)),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
      ),
    );
  }
}

Color _primary(bool isDark) => isDark ? Colors.white : const Color(0xFF111827);
Color _secondary(bool isDark) => isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _IconBadge({required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? TokenTheme.darkAccent.withValues(alpha: 0.12) : const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? TokenTheme.darkAccent : const Color(0xFF10B981), size: 20),
      );
}

class SecuritySettingsScreen extends StatefulWidget {
  final AppLockService? lock;
  final DeviceSignIn? signIn;
  final BiometricPrompt? biometrics;
  const SecuritySettingsScreen({super.key, this.lock, this.signIn, this.biometrics});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late final AppLockService _lock = widget.lock ?? AppLockService.instance;
  late final DeviceSignIn _signIn = widget.signIn ?? DeviceSignIn.instance;
  BiometricPrompt get _biometrics => widget.biometrics ?? BiometricPrompt.instance;
  bool _hasBiometrics = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _signIn.load();
    _biometrics.available().then((value) {
      if (mounted) setState(() => _hasBiometrics = value);
    });
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setAppLock(bool on) => _run(() async {
        if (on) {
          final pin = await Navigator.push<String>(context,
              MaterialPageRoute(builder: (_) => PinEntryScreen.create(title: 'Create PIN', service: _lock)));
          if (pin == null || !mounted) return;
          await _lock.enable(pin);
          if (!mounted) return;
          if (_hasBiometrics) {
            final useFingerprint = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Unlock with fingerprint?'),
                content: const Text('Use your fingerprint or Face ID to open Residence. Your PIN still works.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Use fingerprint')),
                ],
              ),
            );
            if (useFingerprint == true) {
              final error = await _lock.setFingerprintUnlock(true);
              if (error != null && mounted) _say(error);
            }
          }
          if (mounted) _say('App lock is on.');
        } else {
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => PinEntryScreen.verify(title: 'Turn off app lock', service: _lock)));
          if (ok == true) {
            await _lock.disable();
            if (mounted) _say('App lock is off.');
          }
        }
      });

  Future<void> _setFingerprintUnlock(bool on) => _run(() async {
        final error = await _lock.setFingerprintUnlock(on);
        if (error != null && mounted) _say(error);
      });

  Future<void> _changePin() => _run(() async {
        final ok = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => PinEntryScreen.verify(title: 'Change PIN', service: _lock)));
        if (ok != true || !mounted) return;
        final pin = await Navigator.push<String>(context,
            MaterialPageRoute(builder: (_) => PinEntryScreen.create(title: 'New PIN', service: _lock)));
        if (pin == null) return;
        await _lock.changePin(pin);
        if (mounted) _say('Your PIN has been changed.');
      });

  Future<void> _chooseLockAfter() async {
    final choice = await showModalBottomSheet<LockAfter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Lock Residence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          RadioGroup<LockAfter>(
            groupValue: _lock.lockAfter,
            onChanged: (value) => Navigator.pop(ctx, value),
            child: Column(children: [
              for (final option in LockAfter.values)
                RadioListTile<LockAfter>(value: option, title: Text(option.label)),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice != null) await _lock.setLockAfter(choice);
  }

  Future<void> _setFingerprintSignIn(bool on) => _run(() async {
        if (on) {
          final error = await _signIn.enable();
          if (mounted) _say(error ?? 'You can now sign in with your fingerprint on this phone.');
        } else {
          await _signIn.disable();
          if (mounted) _say('Fingerprint sign-in is off on this phone.');
        }
      });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _primary(isDark);
    final secondary = _secondary(isDark);
    final divider = isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9);
    TextStyle title = TextStyle(fontWeight: FontWeight.w600, color: primary, fontSize: 14.5);
    TextStyle sub = TextStyle(fontSize: 12, color: secondary);

    return Scaffold(
      backgroundColor: TokenTheme.pageBg(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('App lock & fingerprint',
            style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_lock, _signIn]),
          builder: (context, _) {
            final busy = _working || _lock.busy || _signIn.busy;
            final user = AuthService.instance.currentUser;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: TokenTheme.pageSidePadding, vertical: 12),
              children: [
                _header('APP LOCK', secondary),
                const SizedBox(height: 10),
                _card(isDark, [
                  SwitchListTile(
                    secondary: _IconBadge(icon: Icons.lock_outline_rounded, isDark: isDark),
                    title: Text('App lock', style: title),
                    subtitle: Text('Ask for your PIN or fingerprint to open Residence', style: sub),
                    value: _lock.enabled,
                    activeTrackColor: TokenTheme.primaryMint,
                    onChanged: busy ? null : _setAppLock,
                  ),
                  if (_lock.enabled) ...[
                    Divider(height: 1, indent: 56, color: divider),
                    SwitchListTile(
                      secondary: _IconBadge(icon: Icons.fingerprint_rounded, isDark: isDark),
                      title: Text('Unlock with fingerprint', style: title),
                      subtitle: Text(
                          _hasBiometrics
                              ? 'Use fingerprint or Face ID instead of your PIN'
                              : 'Add a fingerprint or Face ID in your phone settings to use this',
                          style: sub),
                      value: _lock.fingerprintUnlock,
                      activeTrackColor: TokenTheme.primaryMint,
                      onChanged: busy || (!_hasBiometrics && !_lock.fingerprintUnlock) ? null : _setFingerprintUnlock,
                    ),
                    Divider(height: 1, indent: 56, color: divider),
                    ListTile(
                      leading: _IconBadge(icon: Icons.timer_outlined, isDark: isDark),
                      title: Text('Lock timing', style: title),
                      subtitle: Text(_lock.lockAfter.label, style: sub),
                      trailing: Icon(Icons.chevron_right_rounded, color: secondary),
                      onTap: busy ? null : _chooseLockAfter,
                    ),
                    Divider(height: 1, indent: 56, color: divider),
                    ListTile(
                      leading: _IconBadge(icon: Icons.pin_outlined, isDark: isDark),
                      title: Text('Change PIN', style: title),
                      trailing: Icon(Icons.chevron_right_rounded, color: secondary),
                      onTap: busy ? null : _changePin,
                    ),
                  ],
                ]),
                const SizedBox(height: 24),
                _header('SIGN IN', secondary),
                const SizedBox(height: 10),
                _card(isDark, [
                  SwitchListTile(
                    secondary: _IconBadge(icon: Icons.login_rounded, isDark: isDark),
                    title: Text('Sign in with fingerprint', style: title),
                    subtitle: Text(
                        _hasBiometrics
                            ? 'Skip typing your password when you sign in on this phone'
                            : 'Add a fingerprint or Face ID in your phone settings to use this',
                        style: sub),
                    value: _signIn.enabledFor(user),
                    activeTrackColor: TokenTheme.primaryMint,
                    onChanged: busy || (!_hasBiometrics && !_signIn.enabledFor(user)) ? null : _setFingerprintSignIn,
                  ),
                ]),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                      'Forgot your PIN? On the lock screen, choose "Use your password". '
                      'Fingerprint sign-in stops working if you change your password; turn it on again afterwards.',
                      style: sub),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(String text, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.1)),
      );

  Widget _card(bool isDark, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: TokenTheme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      );
}

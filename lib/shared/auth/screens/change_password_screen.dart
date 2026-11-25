import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:estate/shared/auth/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AuthService.instance
        .changePassword(_current.text, _password.text);
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _busy = false;
        _error = result['message'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('Secure your account'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                    onPressed:
                        _busy ? null : () => AuthService.instance.logout(),
                    child: const Text('Sign out'))
              ]),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                              key: _form,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Icon(Icons.lock_reset, size: 48),
                                    const SizedBox(height: 20),
                                    Text('Choose your own password',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'Replace the temporary password from your welcome email before accessing your estate. Use at least 8 characters.'),
                                    const SizedBox(height: 24),
                                    if (_error != null)
                                      Semantics(
                                          liveRegion: true,
                                          child: Text(_error!,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error))),
                                    TextFormField(
                                        controller: _current,
                                        obscureText: true,
                                        enabled: !_busy,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        decoration: const InputDecoration(
                                            labelText: 'Temporary password'),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Enter the password from your email'
                                            : null),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                        controller: _password,
                                        obscureText: true,
                                        enabled: !_busy,
                                        autofillHints: const [
                                          AutofillHints.newPassword
                                        ],
                                        decoration: const InputDecoration(
                                            labelText: 'New password'),
                                        validator: (v) => v == null ||
                                                v.length < 8
                                            ? 'Use at least 8 characters'
                                            : utf8.encode(v).length > 72
                                                ? 'Use no more than 72 UTF-8 bytes'
                                                : v == _current.text
                                                    ? 'Choose a different password'
                                                    : null),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                        controller: _confirm,
                                        obscureText: true,
                                        enabled: !_busy,
                                        decoration: const InputDecoration(
                                            labelText: 'Confirm new password'),
                                        validator: (v) => v != _password.text
                                            ? 'Passwords do not match'
                                            : null),
                                    const SizedBox(height: 24),
                                    FilledButton(
                                        onPressed: _busy ? null : _submit,
                                        child: Text(_busy
                                            ? 'Saving…'
                                            : 'Save password and continue')),
                                  ]))))))));
}

import 'package:flutter/material.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/auth/device_sign_in.dart';
import 'package:estate/shared/ui/widgets/auth_layout.dart';
import 'package:estate/shared/auth/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const LoginScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appIdController =
      TextEditingController(text: AuthService.instance.appId);
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  // Shown only after the server says this account is suspended (correct password,
  // X-Account-Status: suspended). Never offered to active accounts.
  bool _accountSuspended = false;
  final _deviceSignIn = DeviceSignIn.instance;

  @override
  void initState() {
    super.initState();
    _deviceSignIn.addListener(_remembered);
    _deviceSignIn.load();
  }

  /// Prefill the estate and email of the resident remembered for fingerprint sign-in.
  void _remembered() {
    final account = _deviceSignIn.remembered;
    if (!mounted) return;
    if (account != null && _emailController.text.isEmpty) {
      _appIdController.text = account.appId;
      _emailController.text = account.email;
    }
    setState(() {});
  }

  Future<void> _fingerprintSignIn() async {
    setState(() => _errorMessage = null);
    final error = await _deviceSignIn.signIn();
    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
    } else if (AuthService.instance.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _deviceSignIn.removeListener(_remembered);
    _appIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _accountSuspended = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await AuthService.instance.login(
      appId: _appIdController.text.trim().toUpperCase(),
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      setState(() {
        _accountSuspended = res['suspended'] == true;
        _errorMessage = _accountSuspended
            ? 'This account is suspended. You can ask your estate management team to reinstate it.'
            : res['message'] ?? 'Login failed. Please check your credentials.';
      });
    }
  }

  Future<void> _requestReinstatement() async {
    final estate = _appIdController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    if (estate.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter your estate App ID and email.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final accepted = await AuthService.instance.requestReinstatement(
      appId: estate,
      email: email,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!accepted) {
        _errorMessage = 'Unable to submit the request. Please try again.';
      }
    });
    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'If the account is eligible, your estate management team will receive your request.'),
      ));
    }
  }

  void _navigateToRegister() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
        onToggleTheme: widget.onToggleTheme,
        busy: _isLoading,
        children: [
          Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) AuthError(_errorMessage!),
                    if (_accountSuspended)
                      TextButton(
                        onPressed: _isLoading ? null : _requestReinstatement,
                        child: const Text('Request account reinstatement'),
                      ),
                    TextFormField(
                        controller: _appIdController,
                        onChanged: (_) {
                          if (_accountSuspended) {
                            setState(() => _accountSuspended = false);
                          }
                        },
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: authInput(
                            'Estate App ID', Icons.apartment_outlined),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter the App ID provided by your caretaker'
                            : null),
                    const SizedBox(height: 20),
                    TextFormField(
                        controller: _emailController,
                        onChanged: (_) {
                          if (_accountSuspended) {
                            setState(() => _accountSuspended = false);
                          }
                        },
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email
                        ],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration:
                            authInput('Email Address', Icons.mail_outline),
                        validator: (v) => v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim())
                            ? 'Enter a valid email address'
                            : null),
                    const SizedBox(height: 20),
                    TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _handleLogin();
                        },
                        decoration: authInput('Password', Icons.lock_outline,
                            suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined))),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        }),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Sign In')),
                    if (_deviceSignIn.remembered != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: _isLoading || _deviceSignIn.busy
                              ? null
                              : _fingerprintSignIn,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: Text(
                              'Sign in with fingerprint as ${_deviceSignIn.remembered!.firstName}'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)))),
                      TextButton(
                          onPressed: _isLoading || _deviceSignIn.busy
                              ? null
                              : () async {
                                  await _deviceSignIn.forget();
                                  _emailController.clear();
                                },
                          child: const Text('Not you? Use another account')),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: _isLoading ? null : _navigateToRegister,
                        child: const Text('Have an invitation? Sign Up')),
                  ]))
        ],
      );
}

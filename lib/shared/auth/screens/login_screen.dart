import 'package:flutter/material.dart';
import 'package:estate/shared/auth/auth_service.dart';
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

  @override
  void dispose() {
    _appIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
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
        _errorMessage =
            res['message'] ?? 'Login failed. Please check your credentials.';
      });
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
                    TextFormField(
                        controller: _appIdController,
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
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: _isLoading ? null : _navigateToRegister,
                        child: const Text('Have an invitation? Sign Up')),
                  ]))
        ],
      );
}

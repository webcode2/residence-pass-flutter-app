import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import '../theme.dart';
import 'dart:convert';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const RegisterScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      setState(() {
        _errorMessage =
            'Confirm that your host shared this invitation with you.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await AuthService.instance.registerWithInviteCode(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      inviteCode: _inviteCodeController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  res['message'] ?? 'Account created and verified!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: TokenTheme.primaryMintDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      setState(() {
        _errorMessage = res['message'] ??
            'Registration failed. Please check your invite code.';
      });
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
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
                        controller: _inviteCodeController,
                        enabled: !_isLoading,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration:
                            authInput('Invitation Code', Icons.key_outlined),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your invitation code'
                            : null),
                    const SizedBox(height: 20),
                    TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration:
                            authInput('Full Name', Icons.person_outline),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your full name'
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
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _handleSignUp();
                        },
                        decoration: authInput('Password', Icons.lock_outline,
                            helper:
                                'Use at least 12 characters. Maximum 72 UTF-8 bytes.',
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
                          if (v.length < 12 || utf8.encode(v).length > 72) {
                            return 'Use at least 12 characters and no more than 72 UTF-8 bytes.';
                          }
                          return null;
                        }),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _agreeTerms,
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _agreeTerms = v ?? false),
                        title: const Text(
                            'I confirm this invitation was shared with me by my host.',
                            style: TextStyle(fontSize: 14))),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _isLoading ? null : _handleSignUp,
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
                            : const Text('Sign Up')),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: _isLoading ? null : _navigateToLogin,
                        child: const Text('Already have an account? Sign In')),
                  ]))
        ],
      );
}

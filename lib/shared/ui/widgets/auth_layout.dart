import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';

class AuthLayout extends StatelessWidget {
  final List<Widget> children;
  final bool busy;
  final VoidCallback onToggleTheme;
  const AuthLayout(
      {super.key,
      required this.children,
      required this.onToggleTheme,
      this.busy = false});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        dark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;
    return Scaffold(
      backgroundColor: TokenTheme.pageBg(dark),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(children: [
                  Icon(Icons.shield_outlined,
                      color: dark
                          ? TokenTheme.darkAccent
                          : TokenTheme.primaryMintDark,
                      size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Residence',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: foreground))),
                  IconButton(
                      tooltip:
                          dark ? 'Use light appearance' : 'Use dark appearance',
                      onPressed: onToggleTheme,
                      icon: Icon(dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined)),
                ]),
                const SizedBox(height: 40),
                ...children,
              ])),
        ),
      ))),
    );
  }
}

InputDecoration authInput(String label, IconData icon,
        {String? helper, Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

class AuthError extends StatelessWidget {
  final String message;
  const AuthError(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        child: Text(message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                height: 1.4)),
      ));
}

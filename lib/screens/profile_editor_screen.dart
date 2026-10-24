import '../theme.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';

class ProfileEditorScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? save;
  const ProfileEditorScreen({super.key, this.save});
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final UserModel? _user;
  late final TextEditingController _name, _email, _phone, _house, _street;
  final _password = TextEditingController();
  bool _busy = false, _showPassword = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _user = AuthService.instance.currentUser;
    _name = TextEditingController(text: _user?.fullName);
    _email = TextEditingController(text: _user?.email);
    _phone = TextEditingController(text: _user?.phone);
    _house = TextEditingController(text: _user?.houseNumber);
    _street = TextEditingController(text: _user?.streetName);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _house, _street, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'full_name': _name.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'phone': _phone.text.trim(),
      'house_number': _house.text.trim(),
      'street_name': _street.text.trim()
    };
    if (_email.text.trim().toLowerCase() != _user?.email.toLowerCase()) {
      body['current_password'] = _password.text;
    }
    final result = await (widget.save?.call(body) ??
        AuthService.instance.updateProfile(body));
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error =
            result['message'] as String? ?? 'Unable to save. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile & property')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TokenTheme.pageSidePadding,
                            vertical: 24),
                        child: AutofillGroup(
                            child: Form(
                                key: _form,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_error != null) AuthError(_error!),
                                      Text('Personal details',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                          controller: _name,
                                          enabled: !_busy,
                                          maxLength: 255,
                                          autofillHints: const [
                                            AutofillHints.name
                                          ],
                                          decoration: authInput('Full Name',
                                              Icons.person_outline),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Enter your full name'
                                                  : null),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                          controller: _email,
                                          enabled: !_busy,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.email
                                          ],
                                          decoration: authInput('Email Address',
                                              Icons.mail_outline),
                                          onChanged: (_) => setState(() {}),
                                          validator: (v) => v == null ||
                                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                      .hasMatch(v.trim())
                                              ? 'Enter a valid email address'
                                              : null),
                                      const SizedBox(height: 20),
                                      if (_email.text.trim().toLowerCase() !=
                                          _user?.email.toLowerCase()) ...[
                                        TextFormField(
                                            controller: _password,
                                            enabled: !_busy,
                                            obscureText: !_showPassword,
                                            autofillHints: const [
                                              AutofillHints.password
                                            ],
                                            decoration: authInput(
                                                'Current password',
                                                Icons.lock_outline,
                                                helper:
                                                    'Required to change your sign-in email.',
                                                suffix: IconButton(
                                                    tooltip: _showPassword
                                                        ? 'Hide password'
                                                        : 'Show password',
                                                    onPressed: () => setState(
                                                        () => _showPassword =
                                                            !_showPassword),
                                                    icon: Icon(_showPassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility))),
                                            validator: (v) => v == null ||
                                                    v.isEmpty
                                                ? 'Enter your current password'
                                                : null),
                                        const SizedBox(height: 20),
                                      ],
                                      TextFormField(
                                          controller: _phone,
                                          enabled: !_busy,
                                          maxLength: 40,
                                          keyboardType: TextInputType.phone,
                                          autofillHints: const [
                                            AutofillHints.telephoneNumber
                                          ],
                                          decoration: authInput('Phone number',
                                              Icons.phone_outlined)),
                                      const SizedBox(height: 16),
                                      Text('Property details',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                          controller: _house,
                                          enabled: !_busy,
                                          maxLength: 20,
                                          decoration: authInput('House number',
                                              Icons.home_outlined),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Enter your house number'
                                                  : null),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                          controller: _street,
                                          enabled: !_busy,
                                          maxLength: 100,
                                          autofillHints: const [
                                            AutofillHints.streetAddressLine1
                                          ],
                                          decoration: authInput('Street',
                                              Icons.location_on_outlined)),
                                      const SizedBox(height: 16),
                                      const Text(
                                          'Your estate, host link and access role are managed by your caretaker.',
                                          style: TextStyle(fontSize: 13)),
                                      const SizedBox(height: 24),
                                      FilledButton(
                                          onPressed: _busy ? null : _save,
                                          style: FilledButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(52)),
                                          child: _busy
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : const Text('Save changes')),
                                    ]))))))),
      ));
}

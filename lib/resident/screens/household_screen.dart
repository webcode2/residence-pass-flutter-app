import 'package:estate/shared/ui/theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:estate/shared/auth/auth_service.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});
  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _members = [];
  bool _busy = false;
  String? _error;
  String _relationship = 'family';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<dynamic> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final auth = AuthService.instance;
    final headers = {
      'Content-Type': 'application/json',
      'X-App-Id': auth.appId,
      'Authorization': 'Bearer ${auth.accessToken}'
    };
    final url = Uri.parse(
        '${auth.baseUrl}/api/v1/${path == 'household' ? 'landlords/household' : 'tokens/$path'}');
    final response = await (method == 'GET'
            ? http.get(url, headers: headers)
            : http.post(url, headers: headers, body: jsonEncode(body ?? {})))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['detail'] is String
          ? data['detail']
          : 'Unable to complete request');
    }
    return data;
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _request('GET', 'registration');
      final members = await _request('GET', 'household');
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data as List);
          _members = List<Map<String, dynamic>>.from(members as List);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Unable to load invitations. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _request(
          'POST', 'registration', {'relationship_type': _relationship});
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _request('POST', 'registration/$code/revoke');
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to revoke this invitation. Retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Family & tenants'), actions: [
        IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh invitations')
      ]),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: TokenTheme.pageSidePadding, vertical: 20),
                  children: [
                    Text(AuthService.instance.currentUser?.unitAddress ?? '',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text(
                        'Invite one person per code. Codes expire after 7 days. Every registered family member or tenant is linked to you and your house.'),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                        initialValue: _relationship,
                        decoration: const InputDecoration(
                            labelText: 'Who are you inviting?'),
                        items: const [
                          DropdownMenuItem(
                              value: 'family', child: Text('Family member')),
                          DropdownMenuItem(
                              value: 'tenant', child: Text('Tenant'))
                        ],
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _relationship = v!)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _busy ? null : _create,
                        child:
                            Text(_busy ? 'Please wait…' : 'Create invitation')),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error)))),
                    if (!_busy && _items.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No invitations yet.')),
                    if (_members.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Registered household members',
                          style: Theme.of(context).textTheme.titleMedium),
                      ..._members.map((member) => ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(member['full_name'] as String? ??
                              member['email'] as String),
                          subtitle: Text(
                              '${member['email']} · ${member['relationship_type'] ?? 'Member'}${member['is_revoked'] == true ? ' · Suspended' : ''}'))),
                      const Divider()
                    ],
                    ..._items.map((item) {
                      final expiry =
                          DateTime.tryParse('${item['expires_at']}Z');
                      final used = item['is_used'] == true;
                      final expired =
                          expiry == null || expiry.isBefore(DateTime.now());
                      final code = item['code'] as String;
                      return Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    Text(
                                        '${item['relationship_type'] == 'tenant' ? 'Tenant' : 'Family member'} · ${used ? 'Registered' : expired ? 'Expired' : 'Ready to share'}'),
                                    if (expiry != null)
                                      Text(
                                          'Expires ${expiry.toLocal().toString().split('.').first}'),
                                    if (!used && !expired)
                                      Wrap(spacing: 8, children: [
                                        TextButton.icon(
                                            onPressed: _busy
                                                ? null
                                                : () async {
                                                    await Clipboard.setData(
                                                        ClipboardData(
                                                            text:
                                                                'Residence estate: ${AuthService.instance.appId}\nInvitation code: $code\nUse this code to register in the Residence app.'));
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      'Invitation copied')));
                                                    }
                                                  },
                                            icon: const Icon(Icons.copy),
                                            label:
                                                const Text('Copy invitation')),
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _revoke(code),
                                            child: const Text('Revoke'))
                                      ]),
                                  ])));
                    }),
                  ]))));
}

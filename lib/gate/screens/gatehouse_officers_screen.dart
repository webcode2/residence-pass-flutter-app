import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/account/profile_editor_screen.dart';
import 'package:estate/shared/account/settings_screen.dart';

class GatehouseOfficersScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const GatehouseOfficersScreen(
      {super.key, required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: TokenTheme.pageSidePadding, vertical: 24),
        children: [
          Text('Security account',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.security),
                title: Text(user?.fullName ?? 'Security officer'),
                subtitle: Text(user?.email ?? '')),
            ListTile(
                title: const Text('Estate App ID'), subtitle: Text(auth.appId)),
          ])),
          ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile & property'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditorScreen()))),
          ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings & security'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(
                          isDark: isDark, onToggleTheme: onToggleTheme)))),
          const SizedBox(height: 16),
          SwitchListTile(
              title: const Text('Dark appearance'),
              value: isDark,
              onChanged: (_) => onToggleTheme()),
          if (user?.roles.contains('resident') == true)
            ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Switch to resident view'),
                onTap: () => auth.switchActiveViewMode(AppViewMode.resident)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out')),
        ],
      ),
    );
  }
}

import 'package:estate/gate/screens/gate_settings_screen.dart';
import 'package:estate/gate/ui/gate_profile_header.dart';
import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/account/profile_editor_screen.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/gate/ui/guard_notification_bell.dart';
import 'package:flutter/material.dart';

class GatehouseOfficersScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const GatehouseOfficersScreen(
      {super.key, required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final palette = GatePalette.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: palette.canvas,
      appBar: gateHeader(
        context,
        'Officers',
        overArtwork: true,
        actions: const [GuardNotificationBell()],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ValueListenableBuilder(
          valueListenable: auth.currentUserNotifier,
          builder: (context, user, _) => ListView(
            padding: EdgeInsets.zero,
            children: [
              GateProfileHeader(
                user: user,
                appId: user?.appId ?? auth.appId,
              ),
              SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(TokenTheme.pageSidePadding,
                      6, TokenTheme.pageSidePadding, 24),
                  child: Column(
                    children: [
                      _OfficerAction(
                        child: ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Edit profile & property'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileEditorScreen(),
                            ),
                          ),
                        ),
                      ),
                      _OfficerAction(
                        child: ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Settings & security'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => GateSettingsScreen(
                                isDark: isDark,
                                onToggleTheme: onToggleTheme,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _OfficerAction(
                        child: SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark appearance'),
                          activeThumbColor: palette.accent,
                          value: isDark,
                          onChanged: (_) => onToggleTheme(),
                        ),
                      ),
                      if (user?.roles.contains('resident') == true)
                        _OfficerAction(
                          child: ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: const Text('Switch to resident view'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                auth.switchActiveViewMode(AppViewMode.resident),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficerAction extends StatelessWidget {
  const _OfficerAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.line),
        ),
        child: ListTileTheme(
          textColor: palette.ink,
          iconColor: palette.muted,
          child: child,
        ),
      ),
    );
  }
}

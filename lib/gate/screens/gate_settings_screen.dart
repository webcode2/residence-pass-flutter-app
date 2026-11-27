import 'package:flutter/material.dart';
import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/ui/theme.dart';

/// Gatehouse-only settings. Resident notification, property and account
/// preferences deliberately stay in the resident app; this screen only
/// exposes controls a security officer needs on duty.
class GateSettingsScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const GateSettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<GateSettingsScreen> createState() => _GateSettingsScreenState();
}

class _GateSettingsScreenState extends State<GateSettingsScreen> {
  bool _sosAlerts = true;
  bool _visitorAlerts = true;
  bool _chatAlerts = true;
  // The gatehouse has no app lock: officers share duty phones and must reach the gate fast.

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            TokenTheme.card(Theme.of(ctx).brightness == Brightness.dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out',
            style: TextStyle(
                color: GatePalette.of(ctx).ink, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out of the gatehouse?',
            style: TextStyle(color: GatePalette.of(ctx).muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AuthService.instance.logout();
              Navigator.pop(ctx);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text('Sign out',
                style: TextStyle(
                    color: GatePalette.of(ctx).danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings & security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: palette.line),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TokenTheme.pageSidePadding,
            vertical: 16,
          ),
          children: [
            _section('APPEARANCE'),
            _panel([
              SwitchListTile(
                secondary: Icon(Icons.dark_mode_outlined, color: palette.accent),
                title: const Text('Dark appearance'),
                subtitle: Text(widget.isDark
                    ? 'Currently using dark mode'
                    : 'Currently using light mode'),
                value: widget.isDark,
                activeThumbColor: palette.accent,
                onChanged: (_) => widget.onToggleTheme(),
              ),
            ]),
            const SizedBox(height: 24),
            _section('GATE ALERTS'),
            _panel([
              _alert(
                Icons.sos,
                palette.danger,
                'Emergency SOS alerts',
                'Be notified when a resident raises a distress alarm',
                _sosAlerts,
                (value) => setState(() => _sosAlerts = value),
              ),
              const Divider(height: 1, indent: 56),
              _alert(
                Icons.login_rounded,
                palette.info,
                'Visitor check-in alerts',
                'Get notified when a visitor arrives at the gate',
                _visitorAlerts,
                (value) => setState(() => _visitorAlerts = value),
              ),
              const Divider(height: 1, indent: 56),
              _alert(
                Icons.chat_bubble_outline_rounded,
                palette.accent,
                'Resident chat alerts',
                'Get notified about new resident messages',
                _chatAlerts,
                (value) => setState(() => _chatAlerts = value),
              ),
            ]),
            const SizedBox(height: 24),
            _section('DUTY INFORMATION'),
            _panel([
              _detail(Icons.apartment_outlined, 'Estate App ID',
                  AuthService.instance.appId),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _detail(Icons.badge_outlined, 'Officer',
                  AuthService.instance.currentUser?.displayName ??
                      'Security officer'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _detail(Icons.shield_outlined, 'Post',
                  AuthService.instance.currentUser?.roleTitle ??
                      'Gatehouse Security'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _detail(Icons.mail_outline, 'Email',
                  AuthService.instance.currentUser?.email ?? 'Not provided'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _detail(Icons.circle_rounded, 'Duty status',
                  AuthService.instance.currentUser != null
                      ? 'On duty'
                      : 'Signed out',
                  valueColor: palette.accent),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: Icon(Icons.logout_rounded, color: palette.danger),
                label: Text('Sign out',
                    style: TextStyle(
                        color: palette.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: palette.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Residence Gatehouse v1.0.0 • Build 2026.09',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: GatePalette.of(context).muted,
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _panel(List<Widget> children) => DecoratedBox(
        decoration: BoxDecoration(
          color: GatePalette.of(context).surface,
          border: Border.all(color: GatePalette.of(context).line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      );

  Widget _alert(IconData icon, Color color, String title, String subtitle,
          bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        secondary: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeThumbColor: GatePalette.of(context).accent,
        onChanged: onChanged,
      );

  Widget _detail(IconData icon, String label, String value,
          {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: GatePalette.of(context).muted, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, color: GatePalette.of(context).muted)),
            ),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      color: valueColor ?? GatePalette.of(context).ink,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

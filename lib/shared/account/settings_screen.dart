import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/auth/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  /// App lock and fingerprint settings, provided by the resident app (guards have none).
  final Widget? securityTile;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.securityTile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _gateArrivalAlerts = true;
  bool _bookOutAlerts = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = TokenTheme.pageBg(isDark);
    final cardBg = TokenTheme.card(isDark);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings & Preferences',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: TokenTheme.pageSidePadding, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Appearance & Theme
            _buildSectionHeader('APPEARANCE', secondaryTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? TokenTheme.darkTint(0.18) : TokenTheme.primaryMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark ? TokenTheme.darkAccent : TokenTheme.primaryMintDark,
                      size: 20,
                    ),
                  ),
                  title: Text('Dark Theme Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor)),
                  subtitle: Text(
                    isDark
                        ? 'Currently using dark mode'
                        : 'Currently using light mode',
                    style: TextStyle(fontSize: 12.5, color: secondaryTextColor),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeTrackColor: TokenTheme.primaryMint,
                    onChanged: (_) => widget.onToggleTheme(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Push Notifications & Alerts
            _buildSectionHeader(
                'PUSH NOTIFICATIONS & ALERTS', secondaryTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDark ? TokenTheme.darkInfo.withValues(alpha: 0.12) : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.login_rounded,
                            color: isDark ? TokenTheme.darkInfo : const Color(0xFF3B82F6), size: 20),
                      ),
                      title: Text('Gate Arrival Alerts',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                              fontSize: 14.5)),
                      subtitle: Text(
                          'Get notified immediately when your visitor checks in at the gate',
                          style: TextStyle(
                              fontSize: 12, color: secondaryTextColor)),
                      value: _gateArrivalAlerts,
                      activeTrackColor: TokenTheme.primaryMint,
                      onChanged: (val) =>
                          setState(() => _gateArrivalAlerts = val),
                    ),
                    Divider(height: 1, indent: 56, color: dividerColor),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDark ? TokenTheme.darkWarning.withValues(alpha: 0.12) : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.logout_rounded,
                            color: isDark ? TokenTheme.darkWarning : const Color(0xFFF59E0B), size: 20),
                      ),
                      title: Text('Visitor Departure Alerts',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                              fontSize: 14.5)),
                      subtitle: Text(
                          'Receive departure confirmation when your guest books out',
                          style: TextStyle(
                              fontSize: 12, color: secondaryTextColor)),
                      value: _bookOutAlerts,
                      activeTrackColor: TokenTheme.primaryMint,
                      onChanged: (val) => setState(() => _bookOutAlerts = val),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.securityTile != null) ...[
            const SizedBox(height: 24),

            // Security & Passcode
            _buildSectionHeader(
                'SECURITY & ACCESS CONTROL', secondaryTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: widget.securityTile,
              ),
            ),
            ],

            const SizedBox(height: 24),

            // Estate & Property Info
            _buildSectionHeader('PROPERTY DETAILS', secondaryTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              ),
              child: Column(
                children: [
                  _buildPropertyRow('Community', AuthService.instance.appId,
                      primaryTextColor, secondaryTextColor),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: dividerColor),
                  _buildPropertyRow(
                      'Unit / House',
                      AuthService.instance.currentUser?.houseNumber ??
                          'Not provided',
                      primaryTextColor,
                      secondaryTextColor),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: dividerColor),
                  _buildPropertyRow(
                      'Street Name',
                      AuthService.instance.currentUser?.streetName ??
                          'Not provided',
                      primaryTextColor,
                      secondaryTextColor),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: dividerColor),
                  _buildPropertyRow(
                      'Resident Status',
                      AuthService.instance.currentUser != null
                          ? 'Signed in'
                          : 'Signed out',
                      const Color(0xFF10B981),
                      secondaryTextColor),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Log Out',
                          style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold)),
                      content: Text(
                          'Are you sure you want to log out of your Resident account?',
                          style: TextStyle(color: secondaryTextColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel',
                              style: TextStyle(color: secondaryTextColor)),
                        ),
                        TextButton(
                          onPressed: () {
                            AuthService.instance.logout();
                            Navigator.pop(ctx);
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/', (route) => false);
                          },
                          child: Text('Log Out',
                              style: TextStyle(
                                  color: isDark ? TokenTheme.darkError : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.logout_rounded,
                    color: isDark ? TokenTheme.darkError : const Color(0xFFEF4444), size: 20),
                label: Text(
                  'Log Out',
                  style: TextStyle(
                    color: isDark ? TokenTheme.darkError : const Color(0xFFEF4444),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? TokenTheme.darkError : const Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                'Residence Mobile v1.0.0 • Build 2026.09',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPropertyRow(
      String label, String value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: labelColor,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

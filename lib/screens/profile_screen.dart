import 'household_screen.dart';
import 'profile_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'settings_screen.dart';
import 'visitors_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onNavigateToVisitors;

  const ProfileScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigateToVisitors,
  });

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isDark: isDark,
          onToggleTheme: onToggleTheme ?? () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, user, _) => _buildProfile(context));

  Widget _buildProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = TokenTheme.pageBg(isDark);
    final cardBg = TokenTheme.card(isDark);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final sectionHeaderColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor =
        isDark ? const Color(0xFF263238) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
            onRefresh: AuthService.instance.refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(
                  horizontal: TokenTheme.pageSidePadding, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: "Profile" + Settings Gear Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF263238)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: TokenTheme.primaryMintDark,
                          ),
                          onPressed: () => _openSettings(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Avatar with Verified Security Badge in Theme Colors
                  Center(
                    child: Builder(
                      builder: (context) {
                        final currentUser = AuthService.instance.currentUser;
                        final displayName =
                            currentUser?.displayName ?? 'Resident';
                        final initials = displayName
                            .split(' ')
                            .where((s) => s.isNotEmpty)
                            .map((s) => s[0].toUpperCase())
                            .take(2)
                            .join();

                        return Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        TokenTheme.primaryMintLight,
                                        TokenTheme.primaryMintDark,
                                        Color(0xFF047857),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: TokenTheme.primaryMintDark
                                            .withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials.isNotEmpty ? initials : 'DL',
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: TokenTheme.primaryMintDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: bgColor,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (currentUser != null) ...[
                              Text(currentUser.email,
                                  style: TextStyle(color: secondaryTextColor)),
                              if (currentUser.phone?.isNotEmpty == true)
                                Text(currentUser.phone!,
                                    style:
                                        TextStyle(color: secondaryTextColor)),
                              Text(currentUser.appId ?? '',
                                  style: TextStyle(color: secondaryTextColor)),
                              const SizedBox(height: 6),
                            ],
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: TokenTheme.primaryMintDark,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Resident • ${currentUser?.unitAddress ?? ""}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Multi-Role Mode Switcher (If user holds Guard/Security role)
                  Builder(
                    builder: (context) {
                      final user = AuthService.instance.currentUser;
                      if (user?.canSwitchToGatehouse != true) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.security_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SECURITY GUARD ROLE DETECTED',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Switch to Gatehouse Terminal to verify codes & open gate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                AuthService.instance.switchActiveViewMode(
                                    AppViewMode.gatehouse);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF064E3B),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Switch',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Residence Security Gate Pass Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF0D2818),
                                const Color(0xFF163E26),
                                const Color(0xFF047857)
                              ]
                            : [
                                const Color(0xFF064E3B),
                                const Color(0xFF047857),
                                TokenTheme.primaryMintDark
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047857).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.vpn_key_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resident account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Visitor access is verified by estate security',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // RESIDENCE & ACCOUNT Section Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: TokenTheme.primaryMintDark,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RESIDENCE & ACCOUNT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: sectionHeaderColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF263238)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.edit_outlined,
                          iconBgColor: const Color(0xFFECFDF5),
                          iconColor: TokenTheme.primaryMintDark,
                          title: 'Edit profile & property',
                          primaryTextColor: primaryTextColor,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const ProfileEditorScreen())),
                        ),
                        Divider(height: 1, indent: 68, color: dividerColor),
                        _buildMenuItem(
                          icon: Icons.people_alt_rounded,
                          iconBgColor: const Color(0xFFEFF4FF),
                          iconColor: const Color(0xFF0284C7),
                          title: 'Frequent Guests & Passes',
                          primaryTextColor: primaryTextColor,
                          isDark: isDark,
                          onTap: () {
                            if (onNavigateToVisitors != null) {
                              onNavigateToVisitors!();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VisitorsScreen(isDark: isDark),
                                ),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, indent: 68, color: dividerColor),
                        if (AuthService.instance.currentUser?.isLandlord ==
                            true) ...[
                          _buildMenuItem(
                              icon: Icons.group_add_outlined,
                              iconBgColor: const Color(0xFFECFDF5),
                              iconColor: const Color(0xFF0D9488),
                              title: 'Family & tenant invitations',
                              primaryTextColor: primaryTextColor,
                              isDark: isDark,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const HouseholdScreen()))),
                          Divider(height: 1, indent: 68, color: dividerColor),
                        ],
                        _buildMenuItem(
                          icon: Icons.settings_rounded,
                          iconBgColor: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Settings & Security Alerts',
                          primaryTextColor: primaryTextColor,
                          isDark: isDark,
                          onTap: () => _openSettings(context),
                        ),
                        Divider(height: 1, indent: 68, color: dividerColor),
                        if (AuthService
                                .instance.currentUser?.canSwitchToGatehouse ==
                            true) ...[
                          _buildMenuItem(
                            icon: Icons.security_rounded,
                            iconBgColor: const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF0D9488),
                            title: 'Switch to Gatehouse Terminal',
                            badgeCount: 'GUARD',
                            primaryTextColor: primaryTextColor,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              AuthService.instance
                                  .switchActiveViewMode(AppViewMode.gatehouse);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? badgeCount,
    required Color primaryTextColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      isDark ? iconColor.withValues(alpha: 0.16) : iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ),
              if (badgeCount != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

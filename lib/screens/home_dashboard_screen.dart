import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/notification_bell.dart';
import '../services/auth_service.dart';
import '../services/visitor_store.dart';
import '../widgets/sos_hold_button.dart';
import '../widgets/security_tips_carousel.dart';
import 'create_token_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNavigateToToken;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToVisitors;

  const HomeDashboardScreen({
    super.key,
    required this.isDark,
    required this.onNavigateToToken,
    this.onNavigateToProfile,
    this.onNavigateToVisitors,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?.fullName ?? 'Estate member';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = TokenTheme.pageBg(isDark);
    final cardBg = TokenTheme.card(isDark);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
            onRefresh: VisitorStore.instance.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(
                  horizontal: TokenTheme.pageSidePadding, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Avatar & Greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Profile Avatar
                            GestureDetector(
                              onTap: onNavigateToProfile,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFFB8F532), // Vibrant Lime Green
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFB8F532)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF10B981), // Online badge
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: bgColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome home,',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const NotificationBell(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Security Token Banner
                  GestureDetector(
                    onTap: onNavigateToToken,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF065F46),
                            Color(0xFF047857),
                            TokenTheme.primaryMintDark
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: TokenTheme.primaryMintDark
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ESTATE ACCESS TOOLS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Digital Gate Token',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const SecurityTipsCarousel(),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.vpn_key_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions Grid
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickAction(
                        'Invite Guest',
                        Icons.person_add_alt_1_rounded,
                        const Color(0xFF3B82F6),
                        cardBg,
                        primaryTextColor,
                        isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CreateTokenScreen(isDark: isDark)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SosHoldButton()),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent Access Activity
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.09),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: VisitorStore.instance,
                      builder: (context, _) {
                        final store = VisitorStore.instance;
                        final passes = [
                          ...store.activePasses,
                          ...store.pastPasses
                        ]..sort((a, b) =>
                            (b.checkedOutAt ?? b.checkedInAt ?? b.createdAt)
                                .compareTo(a.checkedOutAt ??
                                    a.checkedInAt ??
                                    a.createdAt));
                        if (store.loading && passes.isEmpty) {
                          return const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator());
                        }
                        if (store.error != null) {
                          return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(children: [
                                Text('Unable to load activity.',
                                    style: TextStyle(color: primaryTextColor)),
                                TextButton(
                                    onPressed: store.refresh,
                                    child: const Text('Retry'))
                              ]));
                        }
                        if (passes.isEmpty) {
                          return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('No visitor activity yet.',
                                  style: TextStyle(color: secondaryTextColor)));
                        }
                        return Column(children: [
                          for (final pass in passes.take(3))
                            _buildActivityItem(
                                pass.statusLabel,
                                pass.activitySummary,
                                MaterialLocalizations.of(context)
                                    .formatTimeOfDay(TimeOfDay.fromDateTime(
                                        pass.checkedOutAt ??
                                            pass.checkedInAt ??
                                            pass.createdAt)),
                                Icons.person_outline,
                                TokenTheme.primaryMint,
                                primaryTextColor,
                                secondaryTextColor)
                        ]);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    Color cardBg,
    Color textColor,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.09),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color iconColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

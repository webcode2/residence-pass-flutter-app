import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/resident/state/visitor_store.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/resident/screens/home_dashboard_screen.dart';
import 'package:estate/resident/screens/visitors_screen.dart';
import 'package:estate/resident/screens/token_screen.dart';
import 'package:estate/resident/screens/profile_screen.dart';

class AppScaffold extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const AppScaffold({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => VisitorStore.instance.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      VisitorStore.instance.refresh();
      AuthService.instance.refreshProfile();
    }
  }

  @override
  void dispose() {
    _newPassRequests.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final _newPassRequests = ValueNotifier<int>(0);
  bool _chatOpened = false;
  int _selectedIndex = 0; // Default to Home tab

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? TokenTheme.darkSurface : Colors.white;
    final activeColor =
        isDark ? TokenTheme.darkAccent : TokenTheme.primaryMintDark;
    final unselectedColor =
        isDark ? TokenTheme.darkTextSecondary : const Color(0xFF94A3B8);

    final List<Widget> screens = [
      HomeDashboardScreen(
        isDark: isDark,
        onNavigateToToken: () => setState(() => _selectedIndex = 2),
        onNavigateToProfile: () => setState(() => _selectedIndex = 4),
        onNavigateToVisitors: () => setState(() => _selectedIndex = 1),
      ),
      VisitorsScreen(isDark: isDark),
      TokenScreen(
        newPassRequests: _newPassRequests,
        onToggleTheme: widget.onToggleTheme,
        isDark: isDark,
      ),
      _chatOpened ? const ChatScreen() : const SizedBox.shrink(),
      ProfileScreen(
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
        onNavigateToVisitors: () => setState(() => _selectedIndex = 1),
      ),
    ];

    return Scaffold(
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              tooltip: 'New Token',
              backgroundColor:
                  isDark ? TokenTheme.darkAccent : TokenTheme.primaryMint,
              foregroundColor: isDark ? TokenTheme.darkBg : Colors.white,
              onPressed: () {
                setState(() => _selectedIndex = 2);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _newPassRequests.value++;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('New Token'),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(
              color: isDark ? TokenTheme.darkBorder : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', activeColor,
                    unselectedColor),
                _buildNavItem(1, Icons.people_alt_rounded, 'Visitors',
                    activeColor, unselectedColor),
                _buildNavItem(2, Icons.vpn_key_rounded, 'Token', activeColor,
                    unselectedColor),
                _buildNavItem(3, Icons.chat_outlined, 'Chat', activeColor,
                    unselectedColor),
                _buildNavItem(4, Icons.person_rounded, 'User', activeColor,
                    unselectedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    Color unselectedColor,
  ) {
    final isSelected = _selectedIndex == index;

    return Expanded(
        child: InkWell(
      onTap: () => setState(() {
        _selectedIndex = index;
        if (index == 3) _chatOpened = true;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

import '../../widgets/sos_hold_button.dart';
import 'package:flutter/material.dart';
import '../../services/gatehouse_store.dart';
import '../../services/chat_service.dart';
import 'gatehouse_home_screen.dart';
import 'gatehouse_chat_screen.dart';
import 'gatehouse_history_screen.dart';
import 'gatehouse_officers_screen.dart';

class GatehouseAppScaffold extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const GatehouseAppScaffold({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<GatehouseAppScaffold> createState() => _GatehouseAppScaffoldState();
}

class _GatehouseAppScaffoldState extends State<GatehouseAppScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF111827) : Colors.white;
    const activeColor = Color(0xFF0D9488); // Tactical Gatehouse Emerald
    final unselectedColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final borderColor =
        isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0);

    final List<Widget> screens = [
      GatehouseHomeScreen(isDark: isDark),
      GatehouseChatScreen(isDark: isDark),
      GatehouseHistoryScreen(isDark: isDark),
      GatehouseOfficersScreen(
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return AnimatedBuilder(
      animation:
          Listenable.merge([GatehouseStore.instance, ChatService.guardUnread]),
      builder: (context, _) {
        final unreadChats = ChatService.guardUnread.value;

        return Scaffold(
          floatingActionButton: const SosHoldButton(),
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: activeColor,
              unselectedItemColor: unselectedColor,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800, letterSpacing: 0.2),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.shield_outlined),
                  activeIcon: Icon(Icons.verified_user_rounded),
                  label: 'Verifier',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (unreadChats > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadChats',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_rounded),
                      if (unreadChats > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadChats',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  activeIcon: Icon(Icons.manage_history_rounded),
                  label: 'History',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.badge_outlined),
                  activeIcon: Icon(Icons.badge_rounded),
                  label: 'Officers',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

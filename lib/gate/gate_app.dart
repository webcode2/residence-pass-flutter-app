import 'package:flutter/material.dart';
import 'package:estate/gate/screens/gatehouse_chat_screen.dart';
import 'package:estate/gate/screens/gatehouse_history_screen.dart';
import 'package:estate/gate/screens/gatehouse_home_screen.dart';
import 'package:estate/gate/screens/gatehouse_officers_screen.dart';
import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/gate/ui/gate_drawer.dart';
import 'package:estate/shared/chat/chat_service.dart';

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

  void _selectTab(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    return Scaffold(
      drawer:
          GateDrawer(selectedIndex: _selectedIndex, onSelectTab: _selectTab),
      drawerEnableOpenDragGesture: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          GatehouseHomeScreen(isDark: palette.dark),
          GatehouseChatScreen(isDark: palette.dark),
          GatehouseHistoryScreen(isDark: palette.dark),
          GatehouseOfficersScreen(
            isDark: palette.dark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.line)),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: ChatService.guardUnread,
          builder: (context, unread, _) {
            Widget chatIcon(IconData icon) => Badge.count(
                  count: unread,
                  isLabelVisible: unread > 0,
                  backgroundColor: palette.action,
                  textColor: palette.dark ? TokenTheme.darkBg : Colors.white,
                  child: Icon(icon),
                );
            return NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    color: selected ? palette.ink : palette.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  return IconThemeData(
                    color: states.contains(WidgetState.selected)
                        ? palette.accent
                        : palette.muted,
                  );
                }),
              ),
              child: NavigationBar(
                height: 68,
                elevation: 0,
                animationDuration: Duration.zero,
                backgroundColor: palette.surface,
                surfaceTintColor: Colors.transparent,
                indicatorColor: palette.tint,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectTab,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.verified_user_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: chatIcon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: chatIcon(Icons.chat_bubble_rounded),
                    label: 'Chat',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.history_rounded),
                    label: 'History',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded),
                    label: 'Officers',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

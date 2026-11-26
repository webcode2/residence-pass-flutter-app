import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:flutter/material.dart';

class GateDrawer extends StatelessWidget {
  const GateDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  static const _labels = ['Home', 'Chat', 'History', 'Officers'];
  static const _icons = [
    Icons.shield_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.history_rounded,
    Icons.badge_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    final auth = AuthService.instance;
    return Drawer(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      semanticLabel: 'Guard menu',
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                GateIcon(Icons.shield_outlined, palette.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Gatehouse',
                      style: TextStyle(
                          color: palette.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Close guard menu',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 28, color: palette.line),
            for (var index = 0; index < _labels.length; index++)
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                selected: selectedIndex == index,
                selectedTileColor: palette.tint,
                selectedColor: palette.accent,
                textColor: palette.ink,
                iconColor: palette.muted,
                leading: Icon(_icons[index]),
                title: Text(_labels[index]),
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(index);
                },
              ),
            Divider(height: 28, color: palette.line),
            ListTile(
              textColor: palette.danger,
              iconColor: palette.danger,
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../chat_screen.dart';

class GatehouseChatScreen extends StatelessWidget {
  final bool isDark;
  const GatehouseChatScreen({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) => const ChatScreen(isGuard: true);
}

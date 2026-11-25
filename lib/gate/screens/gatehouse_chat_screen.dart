import 'package:flutter/material.dart';
import 'package:estate/gate/screens/gate_chat_thread_screen.dart';

class GatehouseChatScreen extends StatelessWidget {
  final bool isDark;
  const GatehouseChatScreen({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) => const GateChatThreadScreen(isGuard: true);
}

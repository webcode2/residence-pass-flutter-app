import 'package:estate/gate/screens/gate_chat_list_screen.dart';
import 'package:flutter/material.dart';

class GatehouseChatScreen extends StatelessWidget {
  final bool isDark;
  const GatehouseChatScreen({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) => const GateChatListScreen();
}

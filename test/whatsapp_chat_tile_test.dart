import 'package:estate/gate/ui/whatsapp_chat_tile.dart';
import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChatInboxEntry entry({
  String name = 'Tomi Adeyemi',
  String preview = 'Thank you. I’ll meet the courier at the gate.',
  int unread = 0,
  bool emergency = false,
  String? lastMessageAt,
}) {
  return ChatInboxEntry(
    name: name,
    status: 'Open',
    preview: preview,
    unread: unread,
    emergency: emergency,
    lastMessageAt: lastMessageAt,
  );
}

Widget tileHarness(ChatInboxEntry value, double width) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: WhatsAppChatTile(
            entry: value,
            onTap: () {},
            dark: false,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('guard palette follows the Residence theme in both modes', () {
    const light = WhatsAppPalette(false);
    const dark = WhatsAppPalette(true);

    expect(light.header, TokenTheme.primaryMint);
    expect(light.canvas, TokenTheme.lightPageBg);
    expect(light.surface, TokenTheme.lightCard);
    expect(dark.header, TokenTheme.darkSurface);
    expect(dark.canvas, TokenTheme.darkBg);
    expect(dark.surface, TokenTheme.darkCard);
    expect(dark.onUnread, TokenTheme.darkBg);
  });

  testWidgets('guard rows show an avatar, timestamp and unread count',
      (tester) async {
    final now = DateTime.now().toIso8601String();
    await tester.pumpWidget(tileHarness(entry(unread: 2, lastMessageAt: now), 360));

    expect(find.text('TA'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      chatTimestamp(now),
      matches(RegExp(r'^\d{2}:\d{2}$')),
    );
  });

  testWidgets('long previews stop at two lines and fade the trailing text',
      (tester) async {
    const longPreview = 'Please send an officer to the courtyard because the '
        'visitor is still waiting at the main gate with two large parcels '
        'and the resident has asked for an urgent update';
    await tester.pumpWidget(tileHarness(entry(preview: longPreview), 280));

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);
  });

  testWidgets('short previews are not faded', (tester) async {
    await tester.pumpWidget(tileHarness(entry(), 600));

    expect(find.byType(ShaderMask), findsNothing);
  });
}

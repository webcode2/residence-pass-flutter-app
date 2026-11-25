import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/resident/screens/visitors_screen.dart';
import 'package:estate/resident/screens/all_active_passes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'chat_screen_test.dart' show FakeChatService;

void main() {
  testWidgets('empty visitors and passes remain pull-refreshable',
      (tester) async {
    for (final page in <Widget>[
      const VisitorsScreen(isDark: false),
      AllActivePassesScreen(isDark: false, onOpenPassModal: (_, pass) {})
    ]) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('pull refresh fetches empty chat inbox and open thread',
      (tester) async {
    for (final thread in <String?>[null, 'thread-1']) {
      final api = FakeChatService();
      await tester.pumpWidget(MaterialApp(
          home: ChatScreen(
              key: ValueKey(thread), threadId: thread, service: api)));
      await tester.pumpAndSettle();
      expect(api.reads, 1);
      await tester.drag(find.byType(ListView).first, const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(api.reads, 2);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

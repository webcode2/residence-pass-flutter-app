// Keeps the resident and gate apps fully separate inside one install.
//
//   lib/shared/    sign-in and app-wide pieces; may not import resident/ or gate/
//   lib/resident/  resident app; may import shared/ only
//   lib/gate/      gate (security) app; may import shared/ only
//   lib/main.dart  the only file that knows about both, to pick one after sign-in
//
// See .claude/skills/residence-architecture/SKILL.md for the reasoning.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(r'''^\s*(?:import|export)\s+'package:estate/([a-z_]+)/''', multiLine: true);

Map<String, Set<String>> _crossImports(String module, Set<String> forbidden) {
  final found = <String, Set<String>>{};
  for (final entity in Directory('lib/$module').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final match in _import.allMatches(entity.readAsStringSync())) {
      final target = match.group(1)!;
      if (forbidden.contains(target)) {
        found.putIfAbsent(entity.path.replaceAll(r'\', '/'), () => {}).add(target);
      }
    }
  }
  return found;
}

void main() {
  test('gate module never imports the resident module', () {
    expect(_crossImports('gate', {'resident'}), isEmpty);
  });

  test('resident module never imports the gate module', () {
    expect(_crossImports('resident', {'gate'}), isEmpty);
  });

  test('shared code never depends on either module', () {
    expect(_crossImports('shared', {'resident', 'gate'}), isEmpty);
  });

  test('nothing outside the three modules except main.dart and generated code', () {
    final loose = Directory('lib')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.dart'))
        .toSet();
    expect(loose, {'main.dart', 'firebase_options.dart'});
  });
}

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('no package:dartzen_payments/src imports', () async {
    final repoRoot = Directory.current; // run under package root via melos
    final files = repoRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final violations = <String>[];

    for (final f in files) {
      final content = await f.readAsString();
      if (content.contains('package:dartzen_payments/src/')) {
        // allow imports that are inside this package's own package folder
        // (lib/, test/, example/). Disallow imports from other packages.
        if (!f.path.contains('packages/dartzen_payments/')) {
          violations.add(f.path);
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found forbidden imports of package:dartzen_payments/src in:\n${violations.join('\n')}',
      );
    }
  });
}

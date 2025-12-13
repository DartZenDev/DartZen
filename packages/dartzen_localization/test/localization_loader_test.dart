import 'dart:io';

import 'package:dartzen_localization/src/zen_localization_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ZenLocalizationLoader (Integration)', () {
    test('loads file from disk (IO)', () async {
      // Setup temporary file
      final tempDir = await Directory.systemTemp.createTemp('zen_loc_test');
      final file = File(p.join(tempDir.path, 'test.json'));
      await file.writeAsString('{"test": "content"}');

      try {
        final loader = ZenLocalizationLoader();
        // On CLI test runner, this should use IO loader
        final content = await loader.load(file.path);
        expect(content, '{"test": "content"}');
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws on missing file', () async {
      final loader = ZenLocalizationLoader();
      expect(
        () => loader.load('/path/to/non/existent/file.json'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

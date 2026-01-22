import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('No cross-package package:*/src/ imports', () async {
    final repoRoot = Directory.current;
    final roots = <Directory>[];
    final packagesDir = Directory('${repoRoot.path}/packages');
    final appsDir = Directory('${repoRoot.path}/apps');
    final exampleDir = Directory(
      '${repoRoot.path}/packages/dartzen_jobs/example',
    );
    if (packagesDir.existsSync()) roots.add(packagesDir);
    if (appsDir.existsSync()) roots.add(appsDir);
    if (exampleDir.existsSync()) roots.add(exampleDir);

    final violations = <String>[];
    final regex = RegExp("import\\s+['\"]package:([a-zA-Z0-9_]+)/src/");

    for (final root in roots) {
      final queue = <Directory>[root];
      while (queue.isNotEmpty) {
        final dir = queue.removeLast();
        try {
          await for (final entity in dir.list(followLinks: false)) {
            try {
              if (entity is File) {
                if (!entity.path.endsWith('.dart')) continue;
                final content = await entity.readAsString();
                for (final m in regex.allMatches(content)) {
                  final pkg = m.group(1);
                  // Determine owner package of this file by path
                  final path = entity.path.replaceAll('\\', '/');
                  String? owner;
                  final pkgMatch = RegExp(
                    r'/packages/([^/]+)/',
                  ).firstMatch(path);
                  if (pkgMatch != null) owner = pkgMatch.group(1);
                  final appMatch = RegExp(
                    r'/apps/[^/]+/([^/]+)/',
                  ).firstMatch(path);
                  if (appMatch != null) owner = appMatch.group(1);

                  if (owner == null) {
                    continue; // ignore files not in a package/app
                  }
                  if (pkg != owner) {
                    violations.add(
                      '${entity.path}: imports package:$pkg/src/ (owner=$owner)',
                    );
                  }
                }
              } else if (entity is Directory) {
                final pathLower = entity.path.toLowerCase();
                if (pathLower.contains('coverage') ||
                    pathLower.contains('.dart_tool') ||
                    pathLower.contains('build')) {
                  continue;
                }
                queue.add(entity);
              }
            } catch (_) {
              // ignore errors reading individual files
            }
          }
        } catch (_) {
          // ignore directories we cannot list
        }
      }
    }

    if (violations.isNotEmpty) {
      final msg = ['Found cross-package src imports:', ...violations];
      fail(msg.join('\n'));
    }
  }, timeout: Timeout.none);
}

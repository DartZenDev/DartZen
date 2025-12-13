// Note: In a real app, you would import 'dart:io' to get current directory or similar.
import 'dart:io';

import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:path/path.dart' as p;

// ignore_for_file: avoid_print

void main() async {
  print('--- DartZen Localization Server Example ---');

  // 1. Configure the service
  // For server, we usually use absolute paths or paths relative to execution.
  final config = ZenLocalizationConfig(
    globalPath: p.join(Directory.current.path, 'assets', 'l10n'),
  );

  final service = ZenLocalizationService(config: config);

  // 2. Load Global Messages
  print('Loading global messages (en)...');
  try {
    await service.loadGlobalMessages('en');
    print('Global loaded.');
  } catch (e) {
    print('Error loading global: $e');
  }

  // 3. Load Module Messages
  print('Loading module "auth" (en)...');
  try {
    await service.loadModuleMessages(
      'auth',
      'en',
      modulePath: p.join(Directory.current.path, 'modules', 'auth', 'l10n'),
    );
    print('Module "auth" loaded.');
  } catch (e) {
    print('Error loading module: $e');
  }

  // 4. Translate
  try {
    final title = service.translate('app.title', language: 'en');
    print('Translated app.title: $title');

    final loginBtn = service.translate(
      'login.btn',
      language: 'en',
      module: 'auth',
    );
    print('Translated auth.login.btn: $loginBtn');

    final greeting = service.translate(
      'greeting',
      language: 'en',
      params: {'name': 'Developer'},
    );
    print('Translated greeting: $greeting');
  } catch (e) {
    print('Translation error: $e');
  }
}

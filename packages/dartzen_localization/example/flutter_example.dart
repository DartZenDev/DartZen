import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/widgets.dart'; // Depending on context, might need mock or real widget context

/// Minimal Flutter example demonstrating service usage.
///
/// This is not a full app, but shows how to initialize and use the service
/// within a Flutter context (e.g. in a Provider or Bloc).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configure
  // On Flutter, paths are typically asset keys.
  const config = ZenLocalizationConfig();

  final service = ZenLocalizationService(config: config);

  // 2. Load
  // Ensure you have added assets to pubspec.yaml
  await service.loadGlobalMessages('en');

  // 3. Translate
  // In a Widget build method:
  final title = service.translate('app.title', language: 'en');
  debugPrint('Title: $title');
}

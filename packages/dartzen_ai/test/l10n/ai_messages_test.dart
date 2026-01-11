import 'package:dartzen_ai/src/l10n/ai_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

class _TestLoader implements ZenLocalizationLoader {
  final Map<String, String> files = {
    'lib/l10n/ai.en.json': '''
{
  "ai.budget_exceeded": "AI budget limit has been exceeded",
  "ai.quota_exceeded": "AI service quota has been exceeded",
  "ai.invalid_request": "Invalid AI request",
  "ai.service_unavailable": "AI service is currently unavailable",
  "ai.authentication_failed": "AI service authentication failed",
  "ai.request_cancelled": "AI request was cancelled"
}
''',
  };

  @override
  Future<String> load(String path) async {
    if (files.containsKey(path)) {
      return files[path]!;
    }
    throw Exception('File not found: $path');
  }
}

void main() {
  group('AIMessages', () {
    late AIMessages messages;
    late ZenLocalizationService service;

    setUp(() async {
      final loader = _TestLoader();
      service = ZenLocalizationService(
        config: const ZenLocalizationConfig(isProduction: false),
        loader: loader,
      );

      // Load AI module messages
      await service.loadModuleMessages('ai', 'en', modulePath: 'lib/l10n');

      messages = AIMessages(service, 'en');
    });

    test('budgetExceeded returns localized message', () {
      final result = messages.budgetExceeded();
      expect(result, 'AI budget limit has been exceeded');
    });

    test('quotaExceeded returns localized message', () {
      final result = messages.quotaExceeded();
      expect(result, 'AI service quota has been exceeded');
    });

    test('invalidRequest returns localized message', () {
      final result = messages.invalidRequest();
      expect(result, 'Invalid AI request');
    });

    test('serviceUnavailable returns localized message', () {
      final result = messages.serviceUnavailable();
      expect(result, 'AI service is currently unavailable');
    });

    test('authenticationFailed returns localized message', () {
      final result = messages.authenticationFailed();
      expect(result, 'AI service authentication failed');
    });

    test('requestCancelled returns localized message', () {
      final result = messages.requestCancelled();
      expect(result, 'AI request was cancelled');
    });
  });
}

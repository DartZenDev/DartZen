import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

void main() {
  group('ExecutorMessages', () {
    late ZenLocalizationService localization;
    late ExecutorMessages messages;

    setUp(() async {
      // Use default localization service
      localization = ZenLocalizationService(
        config: const ZenLocalizationConfig(isProduction: false),
      );

      // Load module messages for executor
      await localization.loadModuleMessages(
        'executor',
        'en',
        modulePath: 'lib/src/l10n',
      );

      messages = ExecutorMessages(localization, 'en');
    });

    test('provides taskExecutionFailed message', () {
      final message = messages.taskExecutionFailed('TestTask');
      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('task'));
    });

    test('provides heavyTaskRequired message', () {
      final message = messages.heavyTaskRequired;
      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('heavy'));
    });

    test('provides invalidEnvelope message', () {
      final message = messages.invalidEnvelope;
      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('envelope'));
    });

    test('provides routedToIsolate message', () {
      final message = messages.routedToIsolate;
      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('isolate'));
    });

    test('provides heavyTaskDispatched message', () {
      final message = messages.heavyTaskDispatched('task-123');
      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('dispatch'));
    });
  });
}

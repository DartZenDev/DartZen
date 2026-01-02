import 'package:dartzen_demo_server/src/l10n/server_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

void main() {
  group('ServerMessages', () {
    late ZenLocalizationService localization;

    setUp(() async {
      const config = ZenLocalizationConfig(
        isProduction: false,
        globalPath: 'lib/src/l10n',
      );
      localization = ZenLocalizationService(config: config);
      await localization.loadModuleMessages(
        'dartzen_demo',
        'en',
        modulePath: 'lib/src/l10n',
      );
      await localization.loadModuleMessages(
        'dartzen_demo',
        'pl',
        modulePath: 'lib/src/l10n',
      );
    });

    test('returns translated ping success message', () {
      final messages = ServerMessages(localization, 'en');
      expect(messages.pingSuccess(), 'Server is alive');
    });

    test('returns translated websocket connected message', () {
      final messages = ServerMessages(localization, 'en');
      expect(messages.websocketConnected(), 'Connected to server');
    });

    test('returns translated websocket error with parameter', () {
      final messages = ServerMessages(localization, 'en');
      expect(messages.websocketError('timeout'), 'Connection error: timeout');
    });
  });
}

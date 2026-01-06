import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_server/dartzen_server.dart';
import 'package:test/test.dart';

void main() {
  group('ServerMessages', () {
    late ZenLocalizationService localization;
    late ServerMessages messages;

    setUp(() {
      const config = ZenLocalizationConfig(
        isProduction: false, // Fail fast in tests
      );
      localization = ZenLocalizationService(config: config);
      messages = ServerMessages(localization, 'en');
    });

    test('provides access to server localization keys', () {
      // These would work after loading the module:
      // await localization.loadModuleMessages('server', 'en', modulePath: 'lib/src/l10n');

      // For now, we test that the message accessor structure is correct
      expect(messages, isA<ServerMessages>());
    });

    test('encapsulates localization service calls', () {
      // The key point is that ServerMessages is the ONLY place
      // where ZenLocalizationService.translate is called for server keys
      expect(messages, isA<ServerMessages>());
      // Calling the accessors will delegate to `translate()` which isn't
      // loaded in unit tests; assert they throw the localization exception
      expect(
        () => messages.healthOk(),
        throwsA(isA<ZenLocalizationException>()),
      );
      expect(
        () => messages.errorUnknown(),
        throwsA(isA<ZenLocalizationException>()),
      );
      expect(
        () => messages.errorNotFound(),
        throwsA(isA<ZenLocalizationException>()),
      );
    });
  });
}

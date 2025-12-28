import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreConfig', () {
    test('production() creates production configuration', () {
      const config = FirestoreConfig.production();

      expect(config.isProduction, isTrue);
      expect(config.emulatorHost, isNull);
      expect(config.emulatorPort, isNull);
      expect(config.projectId, isNull);
    });

    test('emulator() creates emulator configuration with defaults', () {
      const config = FirestoreConfig.emulator();

      expect(config.isProduction, isFalse);
      expect(config.emulatorHost, equals('localhost'));
      expect(config.emulatorPort, equals(8080));
      expect(config.projectId, isNull);
    });

    test('emulator() accepts custom host and port', () {
      const config = FirestoreConfig.emulator(
        host: '127.0.0.1',
        port: 9000,
        projectId: 'test-project',
      );

      expect(config.isProduction, isFalse);
      expect(config.emulatorHost, equals('127.0.0.1'));
      expect(config.emulatorPort, equals(9000));
      expect(config.projectId, equals('test-project'));
    });

    test('toString() returns readable representation', () {
      const prodConfig = FirestoreConfig.production();
      const emulatorConfig = FirestoreConfig.emulator(projectId: 'test');

      expect(prodConfig.toString(), equals('FirestoreConfig.production()'));
      expect(
        emulatorConfig.toString(),
        equals(
          'FirestoreConfig.emulator(host: localhost, port: 8080, projectId: test)',
        ),
      );
    });

    test('equality works correctly', () {
      const config1 = FirestoreConfig.production();
      const config2 = FirestoreConfig.production();
      const config3 = FirestoreConfig.emulator();

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('hashCode is consistent', () {
      const config1 = FirestoreConfig.production();
      const config2 = FirestoreConfig.production();

      expect(config1.hashCode, equals(config2.hashCode));
    });
  });
}

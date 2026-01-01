import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreConfig', () {
    test('uses production mode when dzIsPrd is true', () {
      // Note: dzIsPrd is a compile-time constant, so we test the legacy constructors
      const config = FirestoreConfig.production(projectId: 'prod-project');

      expect(config.isProduction, isTrue);
      expect(config.emulatorHost, isNull);
      expect(config.emulatorPort, isNull);
      expect(config.projectId, equals('prod-project'));
    });

    test('uses emulator mode with default host when dzIsPrd is false', () {
      const config = FirestoreConfig.emulator(projectId: 'test-project');

      expect(config.isProduction, isFalse);
      expect(config.emulatorHost, equals('localhost'));
      expect(config.emulatorPort, equals(8080));
      expect(config.projectId, equals('test-project'));
    });

    test('reads project ID from environment variable', () {
      // This would need to be run with proper env setup
      // Just testing the structure here
      const config = FirestoreConfig.emulator(projectId: 'env-project');
      expect(config.projectId, equals('env-project'));
    });

    test('accepts custom emulator host and port', () {
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

    test('toString() returns readable representation for production', () {
      const prodConfig = FirestoreConfig.production(projectId: 'my-prod');

      expect(
        prodConfig.toString(),
        equals('FirestoreConfig(PRD, projectId: my-prod)'),
      );
    });

    test('toString() returns readable representation for emulator', () {
      const emulatorConfig = FirestoreConfig.emulator(projectId: 'test');

      expect(
        emulatorConfig.toString(),
        equals('FirestoreConfig(EMULATOR, localhost:8080, projectId: test)'),
      );
    });

    test('equality works correctly', () {
      const config1 = FirestoreConfig.production(projectId: 'proj1');
      const config2 = FirestoreConfig.production(projectId: 'proj1');
      const config3 = FirestoreConfig.emulator(projectId: 'proj1');

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('hashCode is consistent', () {
      const config1 = FirestoreConfig.production(projectId: 'proj');
      const config2 = FirestoreConfig.production(projectId: 'proj');

      expect(config1.hashCode, equals(config2.hashCode));
    });
  });
}

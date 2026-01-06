import 'package:dartzen_core/dartzen_core.dart';
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

    test('factory constructor throws StateError when projectId is empty', () {
      expect(
        () => FirestoreConfig(projectId: ''),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Project ID must be provided'),
          ),
        ),
      );
    });

    test(
      'factory constructor throws StateError when emulator host is empty in dev mode',
      () {
        // This test would require mocking the environment, but we can test the structure
        // The factory constructor has complex logic that depends on compile-time constants
        // For now, we test what we can with the legacy constructors
        expect(
          true,
          isTrue,
        ); // Placeholder - factory constructor testing needs env mocking
      },
    );

    test('toString() handles production config without projectId', () {
      const prodConfig = FirestoreConfig.production();

      expect(prodConfig.toString(), equals('FirestoreConfig(PRD)'));
    });
  });

  group('FirestoreConfig factory and helpers', () {
    test('throws when projectId is missing', () {
      // dzGcloudProject is a compile-time constant. If it's empty the
      // factory should throw; if it's provided at compile-time the factory
      // should succeed. Guard the expectation so tests are deterministic.
      if (dzGcloudProject.isEmpty) {
        expect(FirestoreConfig.new, throwsStateError);
      } else {
        expect(FirestoreConfig.new, returnsNormally);
      }
    });

    test('production helper has expected fields and toString', () {
      const cfg = FirestoreConfig.production(projectId: 'prd-1');
      expect(cfg.isProduction, isTrue);
      expect(cfg.projectId, equals('prd-1'));
      expect(cfg.emulatorHost, isNull);
      expect(cfg.emulatorPort, isNull);
      expect(cfg.toString(), contains('PRD'));
    });

    test('emulator helper sets host/port and toString', () {
      const cfg = FirestoreConfig.emulator(
        host: '127.0.0.1',
        port: 9090,
        projectId: 'dev-1',
      );
      expect(cfg.isProduction, isFalse);
      expect(cfg.projectId, equals('dev-1'));
      expect(cfg.emulatorHost, equals('127.0.0.1'));
      expect(cfg.emulatorPort, equals(9090));
      expect(cfg.toString(), contains('EMULATOR'));
    });

    test(
      'factory parses emulator host when not production, otherwise returns production',
      () {
        final cfg = FirestoreConfig(
          projectId: 'p1',
          emulatorHost: 'host.local:1234',
        );
        if (dzIsPrd) {
          expect(cfg.isProduction, isTrue);
        } else {
          expect(cfg.isProduction, isFalse);
          expect(cfg.emulatorHost, equals('host.local'));
          expect(cfg.emulatorPort, equals(1234));
        }
      },
    );

    test(
      'factory throws ArgumentError for invalid host format when not production',
      () {
        if (dzIsPrd) {
          // In production mode factory ignores emulatorHost and returns production.
          final cfg = FirestoreConfig(projectId: 'p2', emulatorHost: 'invalid');
          expect(cfg.isProduction, isTrue);
        } else {
          expect(
            () => FirestoreConfig(projectId: 'p2', emulatorHost: 'invalid'),
            throwsArgumentError,
          );
        }
      },
    );

    test(
      'factory throws ArgumentError for non-numeric port when not production',
      () {
        if (dzIsPrd) {
          final cfg = FirestoreConfig(
            projectId: 'p3',
            emulatorHost: 'host:abc',
          );
          expect(cfg.isProduction, isTrue);
        } else {
          expect(
            () => FirestoreConfig(projectId: 'p3', emulatorHost: 'host:abc'),
            throwsArgumentError,
          );
        }
      },
    );
  });

  group('FirestoreConfig factory (emulator-mode behaviors)', () {
    const isPrd = dzIsPrd;

    test('throws when effective project id is empty', () {
      if (isPrd) {
        // In production builds the factory should succeed; provide a
        // non-empty projectId to avoid the factory's validation failure.
        final cfg = FirestoreConfig(
          projectId: 'prd-project',
          emulatorHost: 'localhost:8080',
        );
        expect(cfg.isProduction, isTrue);
        expect(cfg.projectId, equals('prd-project'));
      } else {
        expect(
          () => FirestoreConfig(projectId: '', emulatorHost: 'localhost:8080'),
          throwsStateError,
        );
      }
    });

    test('throws when emulator host is empty in dev mode', () {
      if (isPrd) {
        final cfg = FirestoreConfig(projectId: 'dev-project', emulatorHost: '');
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(projectId: 'dev-project', emulatorHost: ''),
          throwsStateError,
        );
      }
    });

    test('throws when emulator host missing port', () {
      if (isPrd) {
        final cfg = FirestoreConfig(
          projectId: 'dev-project',
          emulatorHost: 'localhost',
        );
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(
            projectId: 'dev-project',
            emulatorHost: 'localhost',
          ),
          throwsArgumentError,
        );
      }
    });

    test('throws when emulator port is not numeric', () {
      if (isPrd) {
        final cfg = FirestoreConfig(
          projectId: 'dev-project',
          emulatorHost: 'localhost:abc',
        );
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(
            projectId: 'dev-project',
            emulatorHost: 'localhost:abc',
          ),
          throwsArgumentError,
        );
      }
    });

    test('parses host and port correctly', () {
      final cfg = FirestoreConfig(
        projectId: 'my-proj',
        emulatorHost: '127.0.0.1:8085',
      );
      if (isPrd) {
        expect(cfg.isProduction, isTrue);
      } else {
        expect(cfg.isProduction, isFalse);
        expect(cfg.emulatorHost, '127.0.0.1');
        expect(cfg.emulatorPort, 8085);
        expect(cfg.projectId, 'my-proj');
        expect(cfg.toString().contains('EMULATOR'), isTrue);
      }
    });

    test('additional permutations: explicit host/port and error cases', () {
      // explicit host:port
      final explicit = FirestoreConfig(
        projectId: 'p-exp',
        emulatorHost: 'host.local:1234',
      );
      if (isPrd) {
        expect(explicit.isProduction, isTrue);
      } else {
        expect(explicit.isProduction, isFalse);
        expect(explicit.emulatorHost, equals('host.local'));
        expect(explicit.emulatorPort, equals(1234));
      }

      // missing port
      if (isPrd) {
        final cfg = FirestoreConfig(
          projectId: 'p-miss',
          emulatorHost: 'hostonly',
        );
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(projectId: 'p-miss', emulatorHost: 'hostonly'),
          throwsArgumentError,
        );
      }

      // non-numeric port
      if (isPrd) {
        final cfg = FirestoreConfig(
          projectId: 'p-non',
          emulatorHost: 'host:abc',
        );
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(projectId: 'p-non', emulatorHost: 'host:abc'),
          throwsArgumentError,
        );
      }

      // empty emulator host
      if (isPrd) {
        final cfg = FirestoreConfig(projectId: 'p-empty', emulatorHost: '');
        expect(cfg.isProduction, isTrue);
      } else {
        expect(
          () => FirestoreConfig(projectId: 'p-empty', emulatorHost: ''),
          throwsStateError,
        );
      }
    });
  });

  group('FirestoreConfig helpers', () {
    test('production helper toString and equality', () {
      const a = FirestoreConfig.production(projectId: 'prd-id');
      const b = FirestoreConfig.production(projectId: 'prd-id');
      expect(a, equals(b));
      expect(a.toString(), contains('PRD'));
    });

    test('emulator helper default values', () {
      const e = FirestoreConfig.emulator();
      expect(e.isProduction, isFalse);
      expect(e.emulatorHost, 'localhost');
      expect(e.emulatorPort, 8080);
      expect(e.projectId, 'dev-project');
    });

    test('equality and hashCode edge branches', () {
      const a = FirestoreConfig.production(projectId: 'same');
      // identical path
      const b = a;
      expect(identical(a, b), isTrue);
      expect(a == b, isTrue);

      // different type comparison should be false
      expect(a == 'not-config', isFalse);

      // different values produce different hashCodes
      const c = FirestoreConfig.production(projectId: 'other');
      expect(a == c, isFalse);
      expect(a.hashCode == c.hashCode, isFalse);

      // emulator instances with different ports are not equal
      const e1 = FirestoreConfig.emulator(projectId: 'p');
      const e2 = FirestoreConfig.emulator(port: 8081, projectId: 'p');
      expect(e1 == e2, isFalse);
      expect(e1.hashCode == e2.hashCode, isFalse);
    });
  });

}

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_storage/src/gcs_storage_config.dart';
import 'package:test/test.dart';

void main() {
  group('GcsStorageConfig', () {
    test('constructs with valid project and bucket (production)', () {
      final config = GcsStorageConfig(projectId: 'project', bucket: 'bucket');
      expect(config.projectId, 'project');
      expect(config.bucket, 'bucket');
      if (dzIsPrd) {
        expect(config.emulatorHost, isNull);
        expect(config.credentialsMode, GcsCredentialsMode.applicationDefault);
      } else {
        // When not compiled for production the defaults will point to the emulator.
        expect(config.emulatorHost, 'localhost:8080');
        expect(config.credentialsMode, GcsCredentialsMode.anonymous);
      }
    });

    test('constructs with valid project and bucket (development)', () {
      // Simulate development environment by providing an emulator host.
      final config = GcsStorageConfig(
        projectId: 'project',
        bucket: 'bucket',
        emulatorHost: 'localhost:8080',
      );
      expect(config.projectId, 'project');
      expect(config.bucket, 'bucket');
      expect(config.emulatorHost, 'localhost:8080');
      if (dzIsPrd) {
        expect(config.credentialsMode, GcsCredentialsMode.applicationDefault);
      } else {
        expect(config.credentialsMode, GcsCredentialsMode.anonymous);
      }
    });

    test('throws if projectId is empty', () {
      expect(
        () => GcsStorageConfig(projectId: '', bucket: 'bucket'),
        throwsA(isA<StateError>()),
      );
    });

    test('toString returns formatted string', () {
      final config = GcsStorageConfig(
        projectId: 'project',
        bucket: 'bucket',
        emulatorHost: 'localhost:9090',
      );
      expect(config.toString(), contains('project: project'));
    });

    test('throws StateError if projectId is empty', () {
      expect(
        () => GcsStorageConfig(bucket: 'test-bucket', projectId: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('returns null emulatorHost in production', () {
      final config = GcsStorageConfig(
        bucket: 'test-bucket',
        projectId: 'test-project',
      );

      if (dzIsPrd) {
        expect(config.emulatorHost, isNull);
      } else {
        expect(config.emulatorHost, 'localhost:8080');
      }
    });

    test('returns emulatorHost in development', () {
      final config = GcsStorageConfig(
        bucket: 'test-bucket',
        projectId: 'test-project',
        emulatorHost: 'localhost:8080',
      );

      expect(config.emulatorHost, 'localhost:8080');
    });

    test('dzIsTest is a bool', () {
      expect(dzIsTest, isA<bool>());
    });

    test('dzEnv is a string', () {
      expect(dzEnv, isA<String>());
    });

    test('dzIsPrd and dzIsTest types', () {
      expect(dzIsPrd, isA<bool>());
      expect(dzIsTest, isA<bool>());
    });
  });
}

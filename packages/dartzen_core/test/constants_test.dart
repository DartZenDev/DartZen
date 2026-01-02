import 'package:dartzen_core/src/dartzen_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartZen Constants', () {
    test('dzPlatform returns correct value', () {
      // In test environment, should return the constant value
      expect(dzPlatform, isA<String>());
    });

    test('dzEnv returns correct value', () {
      expect(dzEnv, isA<String>());
    });

    test('dzIsPrd evaluates correctly', () {
      expect(dzIsPrd, isA<bool>());
      // Default is 'prd', so dzIsPrd should be true unless DZ_ENV=dev
      expect(dzIsPrd, isTrue);
    });

    test('dzGcloudProject returns string', () {
      expect(dzGcloudProject, isA<String>());
    });

    test('environment variable keys are defined', () {
      expect(dzGcloudProjectEnvVar, 'GCLOUD_PROJECT');
      expect(
        dzIdentityToolkitEmulatorHostEnvVar,
        'IDENTITY_TOOLKIT_EMULATOR_HOST',
      );
      expect(dzFirestoreEmulatorHostEnvVar, 'FIRESTORE_EMULATOR_HOST');
      expect(dzStorageEmulatorHostEnvVar, 'FIREBASE_STORAGE_EMULATOR_HOST');
    });

    test('dzIdentityToolkitEmulatorHost returns string', () {
      expect(dzIdentityToolkitEmulatorHost, isA<String>());
    });
  });
}

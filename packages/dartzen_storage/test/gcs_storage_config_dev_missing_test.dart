import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

const bool _isDev = String.fromEnvironment('DZ_ENV') == 'dev';

void main() {
  group('GcsStorageConfig (dev - missing env)', () {
    test('throws if emulator host missing in dev', () {
      // When running in dev without an emulator host defined (compile-time),
      // calling emulatorHost (getter) should throw.
      expect(
        () => GcsStorageConfig(projectId: 'p', bucket: 'b').emulatorHost,
        throwsA(isA<StateError>()),
      );
    }, skip: !_isDev);
  });
}

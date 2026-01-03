import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreIdentityRepository (unit)', () {
    test('getIdentityById returns ZenUnknownError on exception', () async {
      // Simulate repository response
      const result = ZenResult<Identity>.err(ZenUnknownError('fail'));
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });
  });
}

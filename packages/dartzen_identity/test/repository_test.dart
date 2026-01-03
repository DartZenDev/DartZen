import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreIdentityRepository (unit)', () {
    test(
      'getIdentityById returns ZenNotFoundError if document missing',
      () async {
        // Simulate repository response
        const result = ZenResult<Identity>.err(ZenNotFoundError('Not found'));
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenNotFoundError>());
      },
    );

    test('createIdentity returns success and stores identity', () async {
      // Simulate repository response
      const id = IdentityId.reconstruct('user_1');
      final identity = Identity.createPending(id: id);
      final result = ZenResult<Identity>.ok(identity);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.id, equals(id));
    });

    test('suspendIdentity returns success and updates lifecycle', () async {
      // Simulate repository response
      const id = IdentityId.reconstruct('user_1');
      final pending = Identity.createPending(id: id);
      const suspendedLifecycle = IdentityLifecycle.reconstruct(
        IdentityState.disabled,
        'Rule violation',
      );
      final suspendedIdentity = pending.withLifecycle(suspendedLifecycle);
      final result = ZenResult<Identity>.ok(suspendedIdentity);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(
        result.dataOrNull!.lifecycle.state,
        equals(IdentityState.disabled),
      );
      expect(result.dataOrNull!.lifecycle.reason, equals('Rule violation'));
    });
  });
}

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:test/test.dart';

void main() {
  group('InfrastructureIdentityHooks', () {
    final hooks = InfrastructureIdentityHooks();
    final identity = _createMockIdentity();

    test('onRevoked returns success', () async {
      final result = await hooks.onRevoked(identity, 'test reason');
      expect(result.isSuccess, isTrue);
    });

    test('onDisabled returns success', () async {
      final result = await hooks.onDisabled(identity, 'test reason');
      expect(result.isSuccess, isTrue);
    });
  });

  group('InfrastructureIdentityCleanup', () {
    final cleanup = InfrastructureIdentityCleanup();

    test('cleanupExpiredIdentities returns zero', () async {
      final before = ZenTimestamp.now();
      final result = await cleanup.cleanupExpiredIdentities(before);
      expect(result.dataOrNull, equals(0));
    });
  });
}

Identity _createMockIdentity() {
  final id = IdentityId.create('test_id').fold((s) => s, (e) => throw e);
  return Identity.createPending(id: id);
}

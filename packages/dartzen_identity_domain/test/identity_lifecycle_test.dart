import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityLifecycle', () {
    test('initial state should be pending', () {
      final lifecycle = IdentityLifecycle.initial();
      expect(lifecycle.state, IdentityState.pending);
      expect(lifecycle.state.canAct, isFalse);
    });

    test('should activate from pending', () {
      final lifecycle = IdentityLifecycle.initial();
      final result = lifecycle.activate();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.state, IdentityState.active);
      expect(result.dataOrNull?.state.canAct, isTrue);
    });

    test('should revoke with reason', () {
      final lifecycle = IdentityLifecycle.initial();
      final result = lifecycle.revoke('test reason');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.state, IdentityState.revoked);
      expect(result.dataOrNull?.reason, 'test reason');
      expect(result.dataOrNull?.state.isFinal, isTrue);
    });

    test('should not activate if revoked', () {
      final lifecycle = IdentityLifecycle.initial()
          .revoke('reason')
          .dataOrNull!;
      final result = lifecycle.activate();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('has been revoked'));
    });

    test('should not disable if revoked', () {
      final lifecycle = IdentityLifecycle.initial()
          .revoke('reason')
          .dataOrNull!;
      final result = lifecycle.disable('new reason');
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('has been revoked'));
    });

    test('should disable from active', () {
      final lifecycle = IdentityLifecycle.initial().activate().dataOrNull!;
      final result = lifecycle.disable('maintenance');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.state, IdentityState.disabled);
      expect(result.dataOrNull?.state.canAct, isFalse);
    });
  });
}

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_contract/dartzen_identity_contract.dart'
    as contract;
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart' as domain;
import 'package:dartzen_ui_identity/src/state/identity_repository.dart';
import 'package:dartzen_ui_identity/src/state/identity_session_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIdentityRepository extends Mock
    implements contract.IdentityRepository {}

void main() {
  late MockIdentityRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockIdentityRepository();
    // Default mock for getCurrentIdentity
    when(
      () => repository.getCurrentIdentity(),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    container = ProviderContainer(
      overrides: [identityRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('IdentitySessionStore', () {
    test('initial state is data(null)', () async {
      await container.read(identitySessionStoreProvider.future);

      final state = container.read(identitySessionStoreProvider);
      expect(state, const AsyncValue<domain.Identity?>.data(null));
    });

    test('login success updates state', () async {
      final model = contract.IdentityModel(
        id: const contract.IdentityId('user-1'),
        lifecycle: contract.IdentityLifecycleState.active,
        authority: const contract.Authority(
          identityId: contract.IdentityId('user-1'),
        ),
        createdAt: ZenTimestamp.now(),
      );

      when(
        () => repository.loginWithEmail(
          email: 'test@example.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => ZenResult.ok(model));

      final store = container.read(identitySessionStoreProvider.notifier);
      final result = await store.login('test@example.com', 'password');

      expect(result.isSuccess, isTrue);
      expect(
        container.read(identitySessionStoreProvider).value?.id.value,
        'user-1',
      );
    });

    test('login failure does not update state with error', () async {
      when(
        () => repository.loginWithEmail(
          email: 'test@example.com',
          password: 'wrong',
        ),
      ).thenAnswer(
        (_) async => const ZenResult.err(ZenUnauthorizedError('Invalid')),
      );

      final store = container.read(identitySessionStoreProvider.notifier);
      final result = await store.login('test@example.com', 'wrong');

      expect(result.isFailure, isTrue);
      expect(container.read(identitySessionStoreProvider).value, isNull);
    });

    test('logout clears state', () async {
      final model = contract.IdentityModel(
        id: const contract.IdentityId('user-1'),
        lifecycle: contract.IdentityLifecycleState.active,
        authority: const contract.Authority(
          identityId: contract.IdentityId('user-1'),
        ),
        createdAt: ZenTimestamp.now(),
      );

      when(
        () => repository.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => ZenResult.ok(model));
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      final store = container.read(identitySessionStoreProvider.notifier);
      await store.login('test@example.com', 'password');
      expect(
        container.read(identitySessionStoreProvider).value?.id.value,
        'user-1',
      );

      await store.logout();
      expect(container.read(identitySessionStoreProvider).value, isNull);
    });
  });
}

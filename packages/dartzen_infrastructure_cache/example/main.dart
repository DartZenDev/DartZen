import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_cache/dartzen_infrastructure_cache.dart';

/// A mock provider to demonstrate caching behavior.
class MockProvider implements IdentityProvider {
  int callCount = 0;

  @override
  Future<ZenResult<ExternalIdentity>> getIdentity(String subject) async {
    callCount++;
    return ZenResult.ok(FakeExternalIdentity(subject));
  }

  @override
  Future<ZenResult<IdentityId>> resolveId(ExternalIdentity external) async =>
      IdentityId.create(external.subject);
}

class FakeExternalIdentity implements ExternalIdentity {
  FakeExternalIdentity(this.subject);
  @override
  final String subject;
  @override
  final Map<String, dynamic> claims = {};
}

void main() async {
  final delegate = MockProvider();
  final repository = CacheIdentityRepository(
    delegate: delegate,
    store: createCacheStore(),
    config: const CacheConfig(ttl: Duration(minutes: 1)),
  );

  ZenLogger.instance.info('--- First call (Cache Miss) ---');
  await repository.getIdentity('user_1');
  ZenLogger.instance.info('Delegate calls: ${delegate.callCount}');

  ZenLogger.instance.info('\n--- Second call (Cache Hit) ---');
  await repository.getIdentity('user_1');
  ZenLogger.instance.info('Delegate calls: ${delegate.callCount}');

  ZenLogger.instance.info('\n--- Call for different user (Cache Miss) ---');
  await repository.getIdentity('user_2');
  ZenLogger.instance.info('Delegate calls: ${delegate.callCount}');

  ZenLogger.instance.info('\n--- Manual Invalidation ---');
  await repository.invalidate('user_1');
  await repository.getIdentity('user_1');
  ZenLogger.instance.info('Delegate calls: ${delegate.callCount}');
}

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_cache/dartzen_infrastructure_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockIdentityProvider extends Mock implements IdentityProvider {}

class MockExternalIdentity extends Mock implements ExternalIdentity {}

void main() {
  late MockIdentityProvider mockDelegate;
  late CacheIdentityRepository repository;
  late CacheConfig config;

  setUp(() {
    mockDelegate = MockIdentityProvider();
    config = const CacheConfig(ttl: Duration(seconds: 1));
    repository = CacheIdentityRepository(
      delegate: mockDelegate,
      store: InMemoryCacheStore(),
      config: config,
    );
  });

  group('CacheIdentityRepository', () {
    test('getIdentity should call delegate and cache result on first call',
        () async {
      const subject = 'user_123';
      final mockExternal = MockExternalIdentity();
      when(() => mockExternal.subject).thenReturn(subject);
        when(() => mockExternal.claims).thenReturn({'role': 'admin'});
      when(() => mockDelegate.getIdentity(subject))
          .thenAnswer((_) async => ZenResult.ok(mockExternal));

      // First call: cache miss
      final result1 = await repository.getIdentity(subject);
      expect(result1.isSuccess, isTrue);
      verify(() => mockDelegate.getIdentity(subject)).called(1);

      // Second call: cache hit
      final result2 = await repository.getIdentity(subject);
      expect(result2.isSuccess, isTrue);
        // Checks value equality since serialization creates a new instance
        expect(result2.dataOrNull!.subject, subject);
        expect(result2.dataOrNull!.claims, {'role': 'admin'});
      verifyNoMoreInteractions(mockDelegate);
    });

    test('getIdentity should fall back to delegate if cache entry is expired',
        () async {
      const subject = 'user_123';
      final mockExternal = MockExternalIdentity();
      when(() => mockExternal.subject).thenReturn(subject);
        when(() => mockExternal.claims).thenReturn({});
      when(() => mockDelegate.getIdentity(subject))
          .thenAnswer((_) async => ZenResult.ok(mockExternal));

      // Populating cache
      await repository.getIdentity(subject);

      // Wait for expiration
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Next call: cache expired, calls delegate again
      await repository.getIdentity(subject);
      verify(() => mockDelegate.getIdentity(subject)).called(2);
    });

    test('resolveId should call delegate and cache result', () async {
      final mockExternal = MockExternalIdentity();
      const idValue = 'user_123';
      final id = IdentityId.create(idValue).dataOrNull!;
      when(() => mockExternal.subject).thenReturn(idValue);
      when(() => mockDelegate.resolveId(mockExternal))
          .thenAnswer((_) async => ZenResult.ok(id));

      // First call
      final result1 = await repository.resolveId(mockExternal);
      expect(result1.isSuccess, isTrue);
      verify(() => mockDelegate.resolveId(mockExternal)).called(1);

      // Second call
      final result2 = await repository.resolveId(mockExternal);
      expect(result2.isSuccess, isTrue);
      expect(result2.dataOrNull, id); // Value equality for IdentityId
      verifyNoMoreInteractions(mockDelegate);
    });
  });
}

class MockIdentity extends Mock implements Identity {}

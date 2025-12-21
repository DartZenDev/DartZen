import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

import 'cache_config.dart';
import 'cache_store.dart';

/// A transparent caching wrapper for IdentityProvider and IdentityHooks.
///
/// It follows the 'Optimistic Accelerator' pattern using a pluggable [_store].
class CacheIdentityRepository implements IdentityProvider, IdentityHooks {
  /// Creates a [CacheIdentityRepository] wrapping a [delegate].
  CacheIdentityRepository({
    required IdentityProvider delegate,
    required CacheStore store,
    CacheConfig config = const CacheConfig(),
  })  : _delegate = delegate,
       _store = store,
        _config = config;

  final IdentityProvider _delegate;
  final CacheStore _store;
  final CacheConfig _config;

  @override
  Future<ZenResult<ExternalIdentity>> getIdentity(String subject) async {
    final key = 'identity:$subject';
    final cached = await _store.get(key);
    
    if (cached.isSuccess && cached.dataOrNull != null) {
      try {
        final data = jsonDecode(cached.dataOrNull!) as Map<String, dynamic>;
        final identity = _CachedExternalIdentity(
          subject: data['subject'] as String,
          claims: data['claims'] as Map<String, dynamic>,
        );
        return ZenResult.ok(identity);
      } catch (e) {
        // Serialization error, fall back transparently
        ZenLogger.instance.info('Cache invalidation error: $e');
      }
    }

    // Cache miss or error (accelerator fails safe to delegate)
    final result = await _delegate.getIdentity(subject);

    if (result.isSuccess) {
      final value = result.dataOrNull!;
      try {
        final json = jsonEncode({
          'subject': value.subject,
          'claims': value.claims,
        });
        await _store.set(key, json, _config.ttl);
      } catch (e) {
        ZenLogger.instance.info('Cache write error: $e');
      }
    }

    return result;
  }

  @override
  Future<ZenResult<IdentityId>> resolveId(ExternalIdentity external) async {
    final key = 'id:${external.subject}';
    final cached = await _store.get(key);
    
    if (cached.isSuccess && cached.dataOrNull != null) {
      final idResult = IdentityId.create(cached.dataOrNull!);
      if (idResult.isSuccess) {
        return idResult;
      }
    }

    final result = await _delegate.resolveId(external);

    if (result.isSuccess) {
      await _store.set(key, result.dataOrNull!.value, _config.ttl);
    }

    return result;
  }

  /// Manually invalidates a cache entry for the given [subject].
  Future<ZenResult<void>> invalidate(String subject) async {
    await _store.delete('identity:$subject');
    await _store.delete('id:$subject');
    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<void>> onRevoked(Identity identity, String reason) async {
    if (_delegate is IdentityHooks) {
      return (_delegate as IdentityHooks).onRevoked(identity, reason);
    }
    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<void>> onDisabled(Identity identity, String reason) async {
    if (_config.invalidateOnHooks) {
      await invalidate(identity.id.value);
    }

    if (_delegate is IdentityHooks) {
      return (_delegate as IdentityHooks).onDisabled(identity, reason);
    }
    return const ZenResult.ok(null);
  }
}

/// A concrete implementation of [ExternalIdentity] for cache rehydration.
class _CachedExternalIdentity implements ExternalIdentity {
  _CachedExternalIdentity({required this.subject, required this.claims});

  @override
  final String subject;

  @override
  final Map<String, dynamic> claims;
}

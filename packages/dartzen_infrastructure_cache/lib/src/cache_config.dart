/// Configuration for the caching layer.
class CacheConfig {
  /// Creates a [CacheConfig] with optional overrides.
  ///
  /// Default values:
  /// - [ttl]: 5 minutes
  /// - [maxEntries]: 1000
  /// - [invalidateOnHooks]: true
  const CacheConfig({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 1000,
    this.invalidateOnHooks = true,
  });

  /// The duration for which an entry is considered valid.
  final Duration ttl;

  /// The maximum number of entries to keep in the cache.
  final int maxEntries;

  /// Whether to invalidate the cache on hook events (revocation, disablement).
  final bool invalidateOnHooks;
}

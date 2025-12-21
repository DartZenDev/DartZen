/// Encapsulates all localization keys of the cache package.
///
/// Under Zen Architecture, caching is strictly silent. These messages
/// are reserved for internal logging or catastrophic failures.
abstract class CacheMessages {
  /// Message for an internal cache failure.
  static String internalCacheFailure() => 'Internal caching failure occurred';

  /// Message for a cache eviction event (usually not shown to user).
  static String cacheEntryEvicted(String key) => 'Cache entry evicted: $key';
}

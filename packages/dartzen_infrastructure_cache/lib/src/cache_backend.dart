import 'package:dartzen_core/dartzen_core.dart';

import 'cache_store.dart';
import 'in_memory_cache_store.dart';
import 'memorystore_cache_store.dart';

/// Provides the compile-time selected cache backend.
///
/// Uses [dzIsDev] and [dzIsPrd] from `dartzen_core` to branch.
/// Tree-shaking will remove the unused backend.
CacheStore createCacheStore() {
  if (dzIsDev) {
    return InMemoryCacheStore();
  }

  // Production branch
  return MemorystoreCacheStore();
}

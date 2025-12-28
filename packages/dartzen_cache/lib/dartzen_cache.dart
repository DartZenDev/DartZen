/// Simple, explicit, and predictable caching for the DartZen ecosystem.
///
/// Automatically selects the appropriate backend based on environment:
/// - Production (dzIsPrd == true): GCP Memorystore (Redis)
/// - Development (dzIsPrd == false): In-memory cache (Map-based)
///
/// Example usage:
/// ```dart
/// import 'package:dartzen_cache/dartzen_cache.dart';
///
/// void main() async {
///   // Automatically uses in-memory cache in dev, Memorystore in production
///   final cache = CacheFactory.create(
///     CacheConfig(
///       defaultTtl: Duration(minutes: 10),
///       memorystoreHost: 'memorystore.example.com',
///       memorystorePort: 6379,
///     ),
///   );
///
///   await cache.set('key', {'data': 'value'});
///   final value = await cache.get<Map<String, dynamic>>('key');
///   print(value); // {data: value}
/// }
/// ```
library;

export 'src/cache_client.dart';
export 'src/cache_config.dart';
export 'src/cache_errors.dart';
export 'src/cache_factory.dart';
export 'src/in_memory_cache.dart';
export 'src/memorystore_cache.dart';

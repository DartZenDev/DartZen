import 'package:dartzen_core/dartzen_core.dart';

import 'cache_client.dart';
import 'cache_config.dart';
import 'in_memory_cache.dart';
import 'memorystore_cache.dart';

/// Factory for creating cache clients based on configuration.
///
/// Automatically selects the appropriate backend based on the environment:
/// - Production (dzIsPrd == true): GCP Memorystore
/// - Development (dzIsPrd == false): In-memory cache
///
/// Example:
/// ```dart
/// final config = CacheConfig(
///   defaultTtl: Duration(minutes: 5),
///   memorystoreHost: 'memorystore.example.com',
///   memorystorePort: 6379,
/// );
/// final cache = CacheFactory.create(config);
/// ```
class CacheFactory {
  CacheFactory._();

  /// Creates a [CacheClient] instance based on the provided [config].
  ///
  /// The backend is automatically selected based on [dzIsPrd]:
  /// - In production: uses Memorystore with [CacheConfig.memorystoreHost] and [CacheConfig.memorystorePort]
  /// - In development: uses in-memory cache
  ///
  /// Throws [ArgumentError] if Memorystore configuration is missing in production.
  ///
  /// Example:
  /// ```dart
  /// final cache = CacheFactory.create(
  ///   CacheConfig(
  ///     defaultTtl: Duration(minutes: 10),
  ///     memorystoreHost: '10.0.0.3',
  ///     memorystorePort: 6379,
  ///   ),
  /// );
  /// ```
  static CacheClient create(CacheConfig config) {
    if (dzIsPrd) {
      // Production: use Memorystore
      final host = config.memorystoreHost;
      final port = config.memorystorePort;

      if (host == null || host.isEmpty) {
        throw ArgumentError(
          'memorystoreHost is required in production (dzIsPrd == true)',
        );
      }

      if (port == null) {
        throw ArgumentError(
          'memorystorePort is required in production (dzIsPrd == true)',
        );
      }

      return MemorystoreCache(
        host: host,
        port: port,
        useTls: config.useTls,
        defaultTtl: config.defaultTtl,
      );
    } else {
      // Development: use in-memory cache
      return InMemoryCache(defaultTtl: config.defaultTtl);
    }
  }
}

import 'package:meta/meta.dart';

/// Configuration for cache initialization.
///
/// The cache backend is automatically selected based on the environment:
/// - Production (dzIsPrd == true): Uses GCP Memorystore (Redis)
/// - Development (dzIsPrd == false): Uses in-memory cache
///
/// Example:
/// ```dart
/// final config = CacheConfig(
///   defaultTtl: Duration(minutes: 5),
///   memorystoreHost: 'memorystore.example.com',
///   memorystorePort: 6379,
/// );
/// ```
@immutable
class CacheConfig {
  /// Default time-to-live for cache entries. Can be overridden per operation.
  final Duration? defaultTtl;

  /// Redis host address. Required when running in production (dzIsPrd == true).
  /// Ignored in development mode.
  final String? memorystoreHost;

  /// Redis port. Required when running in production (dzIsPrd == true).
  /// Ignored in development mode.
  final int? memorystorePort;

  /// Whether to use TLS for Redis connection.
  /// Only applies in production mode. Defaults to true.
  final bool useTls;

  /// Creates a cache configuration.
  ///
  /// The backend is automatically selected based on dzIsPrd from dartzen_core:
  /// - In production: uses Memorystore with [memorystoreHost] and [memorystorePort]
  /// - In development: uses in-memory cache (host/port ignored)
  const CacheConfig({
    this.defaultTtl,
    this.memorystoreHost,
    this.memorystorePort,
    this.useTls = true,
  });
}

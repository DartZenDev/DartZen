import 'dart:async';

/// Configuration for Zone-based service injection in task execution.
///
/// [ZoneConfiguration] manages the lifecycle of runtime services that are
/// injected into tasks via Dart's [Zone] API. This design ensures that task
/// payloads remain pure and serializable, while runtime dependencies are
/// provided just-in-time during execution.
///
/// **Supported Service Keys:**
/// - `dartzen.executor` (bool): Marks code running inside the executor context
/// - `dartzen.ai.service`: AI service instance for model inference
/// - `dartzen.http.client`: HTTP client for network requests
/// - `dartzen.logger`: Logging instance for structured logging
/// - `dartzen.storage`: Storage service for file operations (optional)
///
/// **Usage Example:**
/// ```dart
/// final config = ZoneConfiguration(
///   services: {
///     'dartzen.executor': true,
///     'dartzen.logger': logger,
///   },
/// );
///
/// final result = await config.runWithServices(() async {
///   // Zone.current['dartzen.executor'] == true
///   final logger = Zone.current['dartzen.logger'] as Logger?;
///   logger?.info('Executing in zone');
///   return 42;
/// });
/// ```
///
/// **Thread Safety:**
/// Zones are inherently thread-safe in Dart. Each async operation maintains
/// its own zone context, preventing service leakage across concurrent tasks.
///
/// See also:
/// - [docs/execution_model.md] for the complete zone contract
/// - [dart:async.Zone] for Zone API documentation
class ZoneConfiguration {
  /// Creates a zone configuration with the specified services.
  ///
  /// The [services] map contains key-value pairs where the key is a
  /// well-known service identifier (e.g., 'dartzen.logger') and the value
  /// is the service instance.
  ///
  /// Service keys should follow the naming convention: `dartzen.<category>`
  const ZoneConfiguration({required this.services});

  /// Services registered in this zone configuration.
  ///
  /// Keys follow the format `dartzen.<category>` where category identifies
  /// the service type (e.g., 'logger', 'ai.service', 'http.client').
  final Map<String, dynamic> services;

  /// Runs the provided [callback] inside a Zone with injected services.
  ///
  /// The callback can access services via [Zone.current] lookups:
  /// ```dart
  /// final logger = Zone.current['dartzen.logger'] as Logger?;
  /// ```
  ///
  /// The zone is properly isolated from the outer scope, ensuring that
  /// service access is scoped to this execution context only.
  ///
  /// **Type Safety:**
  /// Services are stored as [dynamic] and must be cast to the expected type
  /// by the consumer. This is by design to keep the zone API flexible and
  /// avoid tight coupling to specific service interfaces.
  ///
  /// **Async Support:**
  /// The zone context is preserved across async boundaries, so services
  /// remain accessible in async/await code.
  ///
  /// Returns the result of the callback execution.
  R runWithServices<R>(R Function() callback) =>
      runZoned(callback, zoneValues: services);

  /// Gets a service from the current zone context.
  ///
  /// This is a convenience method for accessing services from within
  /// the zone. Returns null if:
  /// - Not running in a zone created by [ZoneConfiguration]
  /// - The service key is not registered
  ///
  /// **Usage:**
  /// ```dart
  /// final logger = ZoneConfiguration.get<Logger>('dartzen.logger');
  /// logger?.info('Message');
  /// ```
  ///
  /// **Note:** This method can be called from anywhere, but will only
  /// return a value when called from within a zone created by
  /// [runWithServices].
  static T? get<T>(String key) => Zone.current[key] as T?;

  /// Checks if the current execution context is within a DartZen executor zone.
  ///
  /// Returns true if [Zone.current] has the 'dartzen.executor' key set to true.
  ///
  /// This is useful for code that needs to behave differently when running
  /// inside an executor vs. in a test or direct invocation context.
  ///
  /// **Usage:**
  /// ```dart
  /// if (ZoneConfiguration.isInExecutorZone) {
  ///   // Access executor services
  ///   final logger = ZoneConfiguration.get<Logger>('dartzen.logger');
  /// } else {
  ///   // Fallback behavior for non-executor contexts
  /// }
  /// ```
  static bool get isInExecutorZone => Zone.current['dartzen.executor'] == true;

  /// Creates a copy of this configuration with updated services.
  ///
  /// Useful for adding or overriding services in a derived configuration:
  /// ```dart
  /// final baseConfig = ZoneConfiguration(services: {'dartzen.executor': true});
  /// final extendedConfig = baseConfig.copyWith(
  ///   services: {'dartzen.logger': logger},
  /// );
  /// ```
  ///
  /// The new services are merged with existing ones, with new values
  /// overriding existing keys.
  ZoneConfiguration copyWith({Map<String, dynamic>? services}) =>
      ZoneConfiguration(services: {...this.services, ...?services});

  @override
  String toString() {
    final keys = services.keys.join(', ');
    return 'ZoneConfiguration(services: [$keys])';
  }
}

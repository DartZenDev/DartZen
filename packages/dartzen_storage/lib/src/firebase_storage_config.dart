import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// Configuration for Firebase Storage Emulator reader.
///
/// This configuration is designed specifically for Firebase Storage Emulator
/// and automatically determines the emulator host from environment variables.
///
/// **Important**: This is for development/testing only. For production,
/// use the GCS storage reader instead.
@immutable
class FirebaseStorageConfig {
  /// Creates a [FirebaseStorageConfig].
  ///
  /// The [bucket] is required and specifies the Firebase Storage bucket name.
  ///
  /// The emulator host is automatically read from the [dzStorageEmulatorHost]
  /// constant (FIREBASE_STORAGE_EMULATOR_HOST environment variable).
  ///
  /// For testing purposes, [emulatorHost] can be explicitly provided to
  /// override the environment variable.
  ///
  /// Example:
  /// ```dart
  /// final config = FirebaseStorageConfig(
  ///   bucket: 'demo-bucket',
  ///   prefix: 'uploads/',
  /// );
  /// ```
  factory FirebaseStorageConfig({
    required String bucket,
    String? prefix,
    @visibleForTesting String? emulatorHost,
  }) {
    // Determine effective emulator host
    final effectiveHost = emulatorHost ?? dzStorageEmulatorHost;

    if (effectiveHost.isEmpty) {
      throw StateError(
        'Firebase Storage Emulator host must be configured via '
        '$dzStorageEmulatorHostEnvVar environment variable.',
      );
    }

    return FirebaseStorageConfig._(
      bucket: bucket,
      prefix: prefix,
      emulatorHost: effectiveHost,
    );
  }

  const FirebaseStorageConfig._({
    required this.bucket,
    this.prefix,
    required this.emulatorHost,
  });

  /// The Firebase Storage bucket name.
  final String bucket;

  /// Optional prefix for all object keys (e.g. 'images/').
  final String? prefix;

  /// The Firebase Storage Emulator host (e.g., 'localhost:9199').
  final String emulatorHost;

  @override
  String toString() =>
      'FirebaseStorageConfig(bucket: $bucket, emulator: $emulatorHost)';
}

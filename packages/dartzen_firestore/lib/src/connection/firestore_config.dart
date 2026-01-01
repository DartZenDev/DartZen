import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// Immutable configuration for Firestore connection.
///
/// This configuration automatically determines whether to use the
/// production Firestore service or a local emulator based on [dzIsPrd].
///
/// ### Environment Configuration
///
/// - **Production**: When `dzIsPrd` is true, configures for real Google Cloud usage.
/// - **Development**: When `dzIsPrd` is false, automatically configures for
///   the Firestore Emulator (host must be set via [dzFirestoreEmulatorHostEnvVar]).
@immutable
final class FirestoreConfig {
  /// Whether this configuration is for production.
  final bool isProduction;

  /// Emulator host (e.g., 'localhost'). Only used if [isProduction] is false.
  final String? emulatorHost;

  /// Emulator port (e.g., 8080). Only used if [isProduction] is false.
  final int? emulatorPort;

  /// GCP project ID.
  ///
  /// If not provided, attempts to read from [dzGcloudProjectEnvVar].
  final String? projectId;

  /// Creates a Firestore configuration.
  ///
  /// If [projectId] is omitted, it will attempt to read `GCLOUD_PROJECT` from environment.
  ///
  /// If executing in a non-production environment (i.e. `dzIsPrd` is false),
  /// this will automatically configure for the Firestore Emulator.
  factory FirestoreConfig({
    String? projectId,
    @visibleForTesting String? emulatorHost,
  }) {
    // 1. Determine Project ID
    final effectiveProjectId = projectId ?? dzGcloudProject;
    if (effectiveProjectId.isEmpty) {
      throw StateError(
        'Project ID must be provided via constructor or $dzGcloudProjectEnvVar environment variable.',
      );
    }

    // 2. Production Mode
    if (dzIsPrd) {
      return FirestoreConfig._(
        isProduction: true,
        projectId: effectiveProjectId,
        emulatorHost: null,
        emulatorPort: null,
      );
    }

    // 3. Emulator Mode - get from environment variable (required)
    final effectiveHostPort = emulatorHost ?? dzFirestoreEmulatorHost;

    if (effectiveHostPort.isEmpty) {
      throw StateError(
        'Firestore Emulator host must be configured via $dzFirestoreEmulatorHostEnvVar environment variable in development mode.',
      );
    }

    final parts = effectiveHostPort.split(':');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid emulator host format. Expected "host:port", got "$effectiveHostPort". '
        'Please set $dzFirestoreEmulatorHostEnvVar environment variable correctly.',
      );
    }

    final host = parts[0];
    final port = int.tryParse(parts[1]);
    if (port == null) {
      throw ArgumentError(
        'Invalid port in emulator host "$effectiveHostPort". Port must be a number.',
      );
    }

    return FirestoreConfig._(
      isProduction: false,
      projectId: effectiveProjectId,
      emulatorHost: host,
      emulatorPort: port,
    );
  }

  const FirestoreConfig._({
    required this.isProduction,
    required this.projectId,
    required this.emulatorHost,
    required this.emulatorPort,
  });

  /// Legacy helper for testing production specifically (discouraged).
  @visibleForTesting
  const FirestoreConfig.production({this.projectId})
    : isProduction = true,
      emulatorHost = null,
      emulatorPort = null;

  /// Legacy helper for testing emulator specifically (discouraged).
  @visibleForTesting
  const FirestoreConfig.emulator({
    String host = 'localhost',
    int port = 8080,
    this.projectId = 'dev-project',
  }) : isProduction = false,
       emulatorHost = host,
       emulatorPort = port;

  @override
  String toString() {
    if (isProduction) {
      return projectId != null
          ? 'FirestoreConfig(PRD, projectId: $projectId)'
          : 'FirestoreConfig(PRD)';
    }
    return 'FirestoreConfig(EMULATOR, $emulatorHost:$emulatorPort, projectId: $projectId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreConfig &&
          runtimeType == other.runtimeType &&
          isProduction == other.isProduction &&
          emulatorHost == other.emulatorHost &&
          emulatorPort == other.emulatorPort &&
          projectId == other.projectId;

  @override
  int get hashCode =>
      isProduction.hashCode ^
      (emulatorHost?.hashCode ?? 0) ^
      (emulatorPort?.hashCode ?? 0) ^
      (projectId?.hashCode ?? 0);
}

import 'package:meta/meta.dart';

/// Immutable configuration for Firestore connection.
///
/// Determines whether to connect to production Firestore or the emulator.
@immutable
final class FirestoreConfig {
  /// Whether this configuration is for production.
  final bool isProduction;

  /// Emulator host (e.g., 'localhost'). Only used if [isProduction] is false.
  final String? emulatorHost;

  /// Emulator port (e.g., 8080). Only used if [isProduction] is false.
  final int? emulatorPort;

  /// GCP project ID. Required for emulator mode.
  final String? projectId;

  /// Creates a production Firestore configuration.
  const FirestoreConfig.production()
    : isProduction = true,
      emulatorHost = null,
      emulatorPort = null,
      projectId = null;

  /// Creates an emulator Firestore configuration.
  ///
  /// [host] defaults to 'localhost'.
  /// [port] defaults to 8080.
  /// [projectId] is optional but recommended.
  const FirestoreConfig.emulator({
    String host = 'localhost',
    int port = 8080,
    this.projectId,
  }) : isProduction = false,
       emulatorHost = host,
       emulatorPort = port;

  /// Creates a Firestore configuration from environment variables.
  ///
  /// Reads `FIRESTORE_EMULATOR_HOST` to determine emulator mode.
  /// Format: `host:port` (e.g., `localhost:8080`).
  ///
  /// Reads `GCP_PROJECT` for project ID.
  ///
  /// If `FIRESTORE_EMULATOR_HOST` is not set, defaults to production mode.
  factory FirestoreConfig.fromEnvironment() {
    const emulatorHost = String.fromEnvironment('FIRESTORE_EMULATOR_HOST');
    const projectId = String.fromEnvironment('GCP_PROJECT');

    if (emulatorHost.isEmpty) {
      return const FirestoreConfig.production();
    }

    // Parse host:port
    final parts = emulatorHost.split(':');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid FIRESTORE_EMULATOR_HOST format. Expected "host:port", got "$emulatorHost"',
      );
    }

    final host = parts[0];
    final port = int.tryParse(parts[1]);

    if (port == null) {
      throw ArgumentError(
        'Invalid port in FIRESTORE_EMULATOR_HOST: "${parts[1]}"',
      );
    }

    return FirestoreConfig.emulator(
      host: host,
      port: port,
      projectId: projectId.isEmpty ? null : projectId,
    );
  }

  @override
  String toString() => isProduction
      ? 'FirestoreConfig.production()'
      : 'FirestoreConfig.emulator(host: $emulatorHost, port: $emulatorPort, projectId: $projectId)';

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

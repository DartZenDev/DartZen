import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import 'gcs_storage_reader.dart' show GcsStorageReader;

/// Configuration for the [GcsStorageReader].
///
/// This configuration automatically determines whether to use the
/// production GCS service or a local emulator based on [dzIsPrd].
@immutable
class GcsStorageConfig {
  /// Creates a [GcsStorageConfig].
  ///
  /// If [projectId] is omitted, it must be set via the `GCLOUD_PROJECT` environment variable.
  ///
  /// If executing in a non-production environment (i.e. `dzIsPrd` is false),
  /// this will automatically configure for the GCS Emulator.
  factory GcsStorageConfig({
    String? projectId,
    required String bucket,
    String? prefix,
    String? emulatorHost, // Added named parameter
    GcsCredentialsMode? credentialsMode,
  }) {
    final effectiveProjectId = projectId ?? dzGcloudProject;
    if (effectiveProjectId.isEmpty) {
      throw StateError(
        'Project ID must be provided via constructor or environment variable.',
      );
    }

    final effectiveEmulatorHost =
        emulatorHost ?? (dzIsPrd ? null : 'localhost:8080');

    final effectiveCredentialsMode =
        credentialsMode ??
        (dzIsPrd
            ? GcsCredentialsMode.applicationDefault
            : GcsCredentialsMode.anonymous);

    return GcsStorageConfig._(
      projectId: effectiveProjectId,
      bucket: bucket,
      prefix: prefix,
      emulatorHost: effectiveEmulatorHost, // Store emulatorHost
      credentialsMode: effectiveCredentialsMode, // Store credentials mode
    );
  }

  const GcsStorageConfig._({
    required this.projectId,
    required this.bucket,
    this.prefix,
    this.emulatorHost, // Store emulatorHost
    required this.credentialsMode, // Store credentials mode
  });

  /// The Google Cloud Project ID.
  ///
  /// If not provided, attempts to read from `GCLOUD_PROJECT` environment variable.
  final String projectId;

  /// The GCS bucket name.
  final String bucket;

  /// Optional prefix for all object keys (e.g. 'images/').
  final String? prefix;

  /// Returns the effective emulator host if running in non-production mode.
  ///
  /// Returns `null` if in production mode.
  final String? emulatorHost; // The field to store emulatorHost

  /// The credentials mode to use.
  final GcsCredentialsMode credentialsMode;

  @override
  String toString() =>
      'GcsStorageConfig(project: $projectId, bucket: $bucket, mode: ${dzIsPrd ? 'PRD' : 'EMULATOR'})';
}

/// Defines how credentials should be obtained for GCS.
enum GcsCredentialsMode {
  /// Use Application Default Credentials (ADC).
  applicationDefault,

  /// Use anonymous access (no credentials).
  anonymous,
}

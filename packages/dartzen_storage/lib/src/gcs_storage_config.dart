import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import '../dartzen_storage.dart' show GcsStorageReader;
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
    @visibleForTesting String? emulatorHost,
  }) {
    final effectiveProjectId = projectId ?? dzGcloudProject;
    if (effectiveProjectId.isEmpty) {
      throw StateError(
        'Project ID must be provided via constructor or $dzGcloudProjectEnvVar environment variable.',
      );
    }

    return GcsStorageConfig._(
      projectId: effectiveProjectId,
      bucket: bucket,
      prefix: prefix,
      emulatorHostOverride: emulatorHost,
    );
  }

  const GcsStorageConfig._({
    required this.projectId,
    required this.bucket,
    this.prefix,
    String? emulatorHostOverride,
  }) : _emulatorHostOverride = emulatorHostOverride;

  /// The Google Cloud Project ID.
  ///
  /// If not provided, attempts to read from `GCLOUD_PROJECT` environment variable.
  final String projectId;

  /// The GCS bucket name.
  final String bucket;

  /// Optional prefix for all object keys (e.g. 'images/').
  final String? prefix;

  /// The host to use for connection.
  ///
  /// In production, this is ignored (standard GCS).
  /// In non-production, this must be set via [dzStorageEmulatorHostEnvVar].
  final String? _emulatorHostOverride;

  /// Returns the effective emulator host if running in non-production mode.
  ///
  /// Returns `null` if in production mode.
  String? get emulatorHost {
    if (dzIsPrd) return null;

    // 1. Explicit override (testing)
    if (_emulatorHostOverride != null) return _emulatorHostOverride;

    // 2. Environment variable (required in development)
    const envHost = dzStorageEmulatorHost;
    if (envHost.isEmpty) {
      throw StateError(
        'Storage Emulator host must be configured via $dzStorageEmulatorHostEnvVar environment variable in development mode.',
      );
    }
    return envHost;
  }

  /// The credentials mode to use.
  GcsCredentialsMode get credentialsMode => dzIsPrd
      ? GcsCredentialsMode.applicationDefault
      : GcsCredentialsMode.anonymous;

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

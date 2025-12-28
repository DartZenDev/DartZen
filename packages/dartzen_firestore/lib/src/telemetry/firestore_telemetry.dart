import 'package:dartzen_core/dartzen_core.dart';

/// Interface for Firestore telemetry hooks.
///
/// Implement this to track Firestore operations, performance, and errors.
///
/// ### Metadata Structure
/// All hooks accept an optional `metadata` map. Standardized keys include:
/// - `batchSize`: Number of operations in a batch.
/// - `retryCount`: Number of retries attempted for the operation.
/// - `targetModule`: The functional module name (e.g., 'identity', 'catalog').
/// - `isRetry`: Whether this specific operation is a retry.
abstract interface class FirestoreTelemetry {
  /// Called when a single document is read.
  void onRead(String path, Duration latency, {Map<String, dynamic>? metadata});

  /// Called when a single document is written.
  void onWrite(String path, Duration latency, {Map<String, dynamic>? metadata});

  /// Called when a batch operation is committed.
  void onBatchCommit(
    int operationCount,
    Duration latency, {
    Map<String, dynamic>? metadata,
  });

  /// Called when a transaction is completed.
  void onTransactionComplete(
    Duration latency,
    bool success, {
    Map<String, dynamic>? metadata,
  });

  /// Called when a document lookup fails.
  void onNotFound(String path, {Map<String, dynamic>? metadata});

  /// Called when a Firestore operation fails.
  void onError(
    String operation,
    ZenError error, {
    Map<String, dynamic>? metadata,
  });
}

/// No-op implementation of [FirestoreTelemetry].
class NoOpFirestoreTelemetry implements FirestoreTelemetry {
  /// Creates a [NoOpFirestoreTelemetry].
  const NoOpFirestoreTelemetry();

  @override
  void onRead(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onWrite(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onBatchCommit(
    int operationCount,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onTransactionComplete(
    Duration latency,
    bool success, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onNotFound(String path, {Map<String, dynamic>? metadata}) {}

  @override
  void onError(
    String operation,
    ZenError error, {
    Map<String, dynamic>? metadata,
  }) {}
}

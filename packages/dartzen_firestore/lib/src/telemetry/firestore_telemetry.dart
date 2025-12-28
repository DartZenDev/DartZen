import 'package:dartzen_core/dartzen_core.dart';

/// Interface for Firestore telemetry hooks.
///
/// Implement this to track Firestore operations, performance, and errors.
abstract interface class FirestoreTelemetry {
  /// Called when a single document is read.
  void onRead(String path, Duration latency);

  /// Called when a single document is written.
  void onWrite(String path, Duration latency);

  /// Called when a batch operation is committed.
  void onBatchCommit(int operationCount, Duration latency);

  /// Called when a transaction is completed.
  void onTransactionComplete(Duration latency, bool success);

  /// Called when a document lookup fails.
  void onNotFound(String path);

  /// Called when a Firestore operation fails.
  void onError(String operation, ZenError error);
}

/// No-op implementation of [FirestoreTelemetry].
class NoOpFirestoreTelemetry implements FirestoreTelemetry {
  /// Creates a [NoOpFirestoreTelemetry].
  const NoOpFirestoreTelemetry();

  @override
  void onRead(String path, Duration latency) {}

  @override
  void onWrite(String path, Duration latency) {}

  @override
  void onBatchCommit(int operationCount, Duration latency) {}

  @override
  void onTransactionComplete(Duration latency, bool success) {}

  @override
  void onNotFound(String path) {}

  @override
  void onError(String operation, ZenError error) {}
}

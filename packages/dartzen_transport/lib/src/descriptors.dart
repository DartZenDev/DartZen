import 'package:meta/meta.dart';

/// Public descriptor for a transport operation.
///
/// Descriptors are immutable, environment-agnostic, and registered once.
@immutable
class TransportDescriptor {
  /// Creates a transport descriptor.
  const TransportDescriptor({
    required this.id,
    required this.channel,
    required this.reliability,
    this.timeout,
  });

  /// Unique, stable identifier of the transport operation.
  final String id;

  /// The transport channel (e.g., http, queue, event, webhook).
  final TransportChannel channel;

  /// Desired delivery semantics.
  final TransportReliability reliability;

  /// Optional timeout for the operation.
  final Duration? timeout;
}

/// Supported transport channels.
enum TransportChannel {
  /// HTTP-style request/response channel.
  http,

  /// Queue-based asynchronous delivery.
  queue,

  /// Event broadcast channel.
  event,

  /// Webhook callback channel.
  webhook,
}

/// Delivery semantics for transport execution.
enum TransportReliability {
  /// Best-effort delivery without retries.
  atMostOnce,

  /// Retries allowed; receivers must be idempotent.
  atLeastOnce,

  /// Requires deduplication/idempotency guarantees.
  exactlyOnce,
}

/// Result of a transport execution.
@immutable
class TransportResult {
  /// Creates a transport execution result.
  const TransportResult({
    required this.success,
    this.status,
    this.data,
    this.error,
    this.requestId,
  });

  /// Whether the operation completed successfully.
  final bool success;

  /// Optional status code (e.g., HTTP status).
  final int? status;

  /// Optional response payload.
  final Object? data;

  /// Optional error message.
  final String? error;

  /// Optional underlying request identifier.
  final String? requestId;

  /// Convenience factory for success results.
  factory TransportResult.ok({int? status, Object? data, String? requestId}) =>
      TransportResult(
        success: true,
        status: status,
        data: data,
        requestId: requestId,
      );

  /// Convenience factory for error results.
  factory TransportResult.err({
    int? status,
    String? error,
    String? requestId,
  }) => TransportResult(
    success: false,
    status: status,
    error: error,
    requestId: requestId,
  );
}

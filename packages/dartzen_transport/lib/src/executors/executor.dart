part of '../zen_transport.dart';

/// Internal executor contract for executing transport operations.
abstract class TransportExecutor {
  /// Executes the descriptor with provided payload and optional idempotency
  /// key, returning a [TransportResult].
  Future<TransportResult> send(
    TransportDescriptor descriptor, {
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  });
}

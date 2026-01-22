import 'package:meta/meta.dart';

import 'payment_descriptor.dart';
import 'payment_result.dart';

/// Executor is the sole runtime entrypoint for executing payment descriptors.
@immutable
abstract class Executor {
  /// Prepare executor resources.
  Future<void> start();

  /// Shutdown and release resources.
  Future<void> shutdown();

  /// Execute the provided immutable `descriptor` with optional `payload`.
  ///
  /// The executor is responsible for provider selection, idempotency,
  /// retries, timeouts, and mapping provider errors into `PaymentError`.
  Future<PaymentResult> execute(
    PaymentDescriptor descriptor, {
    Map<String, Object?>? payload,
    String? idempotencyKey,
  });
}

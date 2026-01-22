import 'package:meta/meta.dart';

import 'payment_policy.dart';

/// Describes a payment operation. Must be provided for every execution.
@immutable
final class PaymentDescriptor {
  /// Unique descriptor id within the application.
  final String id;

  /// The operation type (charge, authorize, capture, refund, cancel).
  final PaymentOperation operation;

  /// Immutable policy for how this payment should be executed.
  final PaymentPolicy policy;

  /// Optional static metadata for the operation.
  final Map<String, Object?> metadata;

  /// Create a [PaymentDescriptor].
  ///
  /// [id] must be unique within the application and non-empty. The
  /// [operation] indicates which payment action will be executed. [policy]
  /// controls retries, timeouts and idempotency behavior for this descriptor.
  const PaymentDescriptor({
    required this.id,
    required this.operation,
    this.policy = const PaymentPolicy.strict(),
    this.metadata = const {},
  });
}

/// The kind of payment operation described by a `PaymentDescriptor`.
///
/// Use this to indicate whether the descriptor is a charge, authorization,
/// capture, refund, or cancel operation.
enum PaymentOperation {
  /// Charge a payment immediately.
  charge,

  /// Authorize a payment without immediate capture.
  authorize,

  /// Capture a previously authorized payment.
  capture,

  /// Refund a settled payment.
  refund,

  /// Cancel a payment attempt or authorization.
  cancel,
}

import 'package:meta/meta.dart';

import 'payment_error.dart';

/// Result of executing a payment descriptor.
@immutable
final class PaymentResult {
  /// Status of the result, success or failed.
  final PaymentResultStatus status;

  /// Optional provider-specific reference id (e.g. payment id).
  final String? providerReference;

  /// Optional provider metadata returned with the operation.
  final Map<String, Object?>? providerMeta;

  /// Optional error when the result is a failure.
  final PaymentError? error;

  const PaymentResult._({
    required this.status,
    this.providerReference,
    this.providerMeta,
    this.error,
  });

  /// Construct a successful [PaymentResult].
  const PaymentResult.success({
    String? providerReference,
    Map<String, Object?>? providerMeta,
  }) : this._(
         status: PaymentResultStatus.success,
         providerReference: providerReference,
         providerMeta: providerMeta,
         error: null,
       );

  /// Construct a failed [PaymentResult] with the provided [error].
  const PaymentResult.failed(PaymentError error)
    : this._(status: PaymentResultStatus.failed, error: error);
}

/// Status for a [PaymentResult], indicating success or failure.
enum PaymentResultStatus {
  /// Operation completed successfully.
  success,

  /// Operation failed with an error.
  failed,
}

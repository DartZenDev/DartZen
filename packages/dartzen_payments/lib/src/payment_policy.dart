import 'package:meta/meta.dart';

/// Immutable execution policy for payments.
@immutable
final class PaymentPolicy {
  /// Max attempts for transient failures.
  final int maxRetries;

  /// Timeout per attempt.
  final Duration timeout;

  /// Idempotency window duration.
  final Duration idempotencyWindow;

  /// Backoff base (exponential multiplier in ms).
  final Duration backoffBase;

  /// Create a [PaymentPolicy].
  ///
  /// All fields are required and the policy is immutable.
  const PaymentPolicy({
    required this.maxRetries,
    required this.timeout,
    required this.idempotencyWindow,
    required this.backoffBase,
  });

  /// Explicit strict defaults — chosen to be safe and conservative.
  const PaymentPolicy.strict()
    : maxRetries = 3,
      timeout = const Duration(seconds: 15),
      idempotencyWindow = const Duration(minutes: 5),
      backoffBase = const Duration(seconds: 1);
}

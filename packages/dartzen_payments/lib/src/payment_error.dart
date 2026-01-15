import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// Base class for all payment-related errors.
@immutable
sealed class PaymentError extends ZenError {
  /// Creates a payment error.
  const PaymentError(super.message, {super.internalData, super.stackTrace});
}

/// Payment was declined by the provider for business reasons.
final class PaymentDeclinedError extends PaymentError {
  /// Creates a declined error with the provider message.
  const PaymentDeclinedError(super.message, {Map<String, dynamic>? metadata})
    : super(internalData: metadata);
}

/// Payment failed due to insufficient funds.
final class PaymentInsufficientFundsError extends PaymentError {
  /// Creates an insufficient funds error.
  const PaymentInsufficientFundsError({Map<String, dynamic>? metadata})
    : super('Insufficient funds', internalData: metadata);
}

/// Payment amount is invalid or violates provider constraints.
final class PaymentInvalidAmountError extends PaymentError {
  /// Creates an invalid amount error with provider details.
  const PaymentInvalidAmountError(
    super.message, {
    Map<String, dynamic>? metadata,
  }) : super(internalData: metadata);
}

/// Payment resource not found or missing provider reference.
final class PaymentNotFoundError extends PaymentError {
  /// Creates a not-found error.
  const PaymentNotFoundError(super.message, {Map<String, dynamic>? metadata})
    : super(internalData: metadata);
}

/// Payment operation is not allowed in the current state.
final class PaymentStateError extends PaymentError {
  /// Creates a state error.
  const PaymentStateError(super.message, {Map<String, dynamic>? metadata})
    : super(internalData: metadata);
}

/// Catch-all for provider-originated failures; provider details live in metadata.
final class PaymentProviderError extends PaymentError {
  /// Creates a provider error.
  const PaymentProviderError(super.message, {Map<String, dynamic>? metadata})
    : super(internalData: metadata);
}

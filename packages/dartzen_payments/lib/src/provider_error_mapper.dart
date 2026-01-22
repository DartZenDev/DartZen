// Domain-level normalization utility for mapping HTTP responses to
// payment-specific `ZenError`s.
//
// This helper intentionally lives alongside the payments domain to avoid
// provider-specific leakage and to keep error semantics consistent across
// implementations (e.g., Strapi, Adyen). It should only translate generic
// HTTP status codes and optional response payload into `PaymentError`s.
// It is not infrastructure; rather, it is shared domain logic used by
// provider services.
//
// Rationale:
// - Centralizes HTTP→domain error mapping for consistency
// - Prevents duplication across provider services
// - Keeps error handling within domain boundaries and testable without
//   network coupling
import 'payment_error.dart';
import 'payment_http_response.dart';

/// Maps HTTP response status codes to domain payment errors.
PaymentError mapResponseToError(PaymentHttpResponse response) {
  final message = response.error ?? 'Payment operation failed';
  final metadata = {
    'status': response.statusCode,
    if (response.data is Map<String, dynamic>) 'response': response.data,
  };

  switch (response.statusCode) {
    case 400:
      return PaymentInvalidAmountError(message, metadata: metadata);
    case 402:
      return PaymentInsufficientFundsError(metadata: metadata);
    case 404:
      return PaymentNotFoundError(message, metadata: metadata);
    case 409:
      return PaymentStateError(message, metadata: metadata);
    default:
      return PaymentProviderError(message, metadata: metadata);
  }
}

/// AI-specific error types.
///
/// All AI errors extend [ZenError] and provide semantic error codes
/// for proper error handling and localization.
library;

import 'package:dartzen_core/dartzen_core.dart';

/// Base class for all AI-related errors.
sealed class AIError extends ZenError {
  /// Creates an AI error with the given message.
  const AIError(super.message);
}

/// Error thrown when budget limit is exceeded.
final class AIBudgetExceededError extends AIError {
  /// Creates a budget exceeded error.
  const AIBudgetExceededError({
    required this.limit,
    required this.current,
    String? method,
  }) : super(
         method != null
             ? 'Budget exceeded for method $method: $current/$limit'
             : 'Global budget exceeded: $current/$limit',
       );

  /// The budget limit.
  final double limit;

  /// The current usage.
  final double current;
}

/// Error thrown when GCP quota is exceeded.
final class AIQuotaExceededError extends AIError {
  /// Creates a quota exceeded error.
  const AIQuotaExceededError({required this.quotaType})
    : super('GCP quota exceeded: $quotaType');

  /// The type of quota that was exceeded.
  final String quotaType;
}

/// Error thrown when request parameters are invalid.
final class AIInvalidRequestError extends AIError {
  /// Creates an invalid request error.
  const AIInvalidRequestError({required this.reason})
    : super('Invalid AI request: $reason');

  /// The reason the request is invalid.
  final String reason;
}

/// Error thrown when AI service is unavailable.
final class AIServiceUnavailableError extends AIError {
  /// Creates a service unavailable error.
  const AIServiceUnavailableError({this.retryAfter})
    : super('AI service is currently unavailable');

  /// Optional retry-after duration.
  final Duration? retryAfter;
}

/// Error thrown when authentication fails.
final class AIAuthenticationError extends AIError {
  /// Creates an authentication error.
  const AIAuthenticationError({required this.reason})
    : super('AI authentication failed: $reason');

  /// The reason authentication failed.
  final String reason;
}

/// Error thrown when request is cancelled.
final class AICancelledError extends AIError {
  /// Creates a cancelled error.
  const AICancelledError() : super('AI request was cancelled');
}

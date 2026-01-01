import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

import '../l10n/firestore_messages.dart';
import 'firestore_error_codes.dart';

/// Maps HTTP and REST exceptions to semantic [ZenError] types.
///
/// This mapper normalizes REST API responses into DartZen's
/// error hierarchy, providing consistent error handling across the ecosystem.
abstract final class FirestoreErrorMapper {
  /// Maps a Firestore REST exception or response to a [ZenError].
  static ZenError mapException(
    Object error,
    StackTrace? stack,
    FirestoreMessages messages,
  ) {
    if (error is http.ClientException) {
      return _mapHttpError(error, stack, messages);
    }

    // Default to unknown error for other exception types
    return ZenUnknownError(
      messages.unknown(),
      internalData: {'originalError': error.toString()},
      stackTrace: stack,
    );
  }

  /// Maps a [http.ClientException] or similar to a [ZenError].
  static ZenError _mapHttpError(
    http.ClientException error,
    StackTrace? stack,
    FirestoreMessages messages,
  ) {
    // Try to extract status code if encoded in message (as done in FirestoreRestClient)
    final message = error.message;

    if (message.contains('403')) {
      return ZenUnauthorizedError(
        messages.permissionDenied(),
        internalData: {
          'errorCode': FirestoreErrorCodes.permissionDenied,
          'originalError': message,
        },
        stackTrace: stack,
      );
    }

    if (message.contains('404')) {
      return ZenNotFoundError(
        messages.notFound(),
        internalData: {'originalError': message},
        stackTrace: stack,
      );
    }

    if (message.contains('409')) {
      return ZenConflictError(
        messages.operationFailed(),
        internalData: {'originalError': message},
        stackTrace: stack,
      );
    }

    if (message.contains('503') || message.contains('504')) {
      return _createInfrastructureError(
        messages.unavailable(),
        FirestoreErrorCodes.unavailable,
        message,
        stack,
      );
    }

    return _createInfrastructureError(
      messages.operationFailed(),
      FirestoreErrorCodes.operationFailed,
      message,
      stack,
    );
  }

  /// Helper to create a [ZenUnknownError] with standardized infrastructure metadata.
  static ZenError _createInfrastructureError(
    String message,
    String errorCode,
    Object originalError,
    StackTrace? stack,
  ) => ZenUnknownError(
    message,
    internalData: {'errorCode': errorCode, 'originalError': originalError},
    stackTrace: stack,
  );
}

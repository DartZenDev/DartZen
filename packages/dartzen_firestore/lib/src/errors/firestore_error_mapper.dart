import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/errors/firestore_error_codes.dart';
import 'package:dartzen_firestore/src/l10n/firestore_messages.dart';
import 'package:firebase_core/firebase_core.dart';

/// Maps Firestore exceptions to semantic [ZenError] types.
///
/// This mapper normalizes Firestore SDK exceptions into DartZen's
/// error hierarchy, providing consistent error handling across the ecosystem.
abstract final class FirestoreErrorMapper {
  /// Maps a Firestore exception to a [ZenError].
  ///
  /// [error] is the caught exception.
  /// [stack] is the optional stack trace.
  /// [messages] provides localized error messages.
  ///
  /// Returns appropriate [ZenError] subtype based on exception code.
  static ZenError mapException(
    Object error,
    StackTrace? stack,
    FirestoreMessages messages,
  ) {
    if (error is FirebaseException) {
      return _mapFirebaseException(error, stack, messages);
    }

    // Unknown exception type
    return ZenUnknownError(
      messages.unknown(),
      internalData: {'originalError': error.toString()},
      stackTrace: stack,
    );
  }

  /// Maps a [FirebaseException] to a [ZenError].
  static ZenError _mapFirebaseException(
    FirebaseException error,
    StackTrace? stack,
    FirestoreMessages messages,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return ZenUnauthorizedError(
          messages.permissionDenied(),
          internalData: {
            'errorCode': FirestoreErrorCodes.permissionDenied,
            'originalError': error,
          },
          stackTrace: stack,
        );

      case 'not-found':
        return ZenNotFoundError(
          messages.notFound(),
          internalData: {'originalError': error},
          stackTrace: stack,
        );

      case 'already-exists':
        return ZenConflictError(
          messages.operationFailed(),
          internalData: {'originalError': error},
          stackTrace: stack,
        );

      case 'unavailable':
        return _createInfrastructureError(
          messages.unavailable(),
          FirestoreErrorCodes.unavailable,
          error,
          stack,
        );

      case 'deadline-exceeded':
        return _createInfrastructureError(
          messages.timeout(),
          FirestoreErrorCodes.timeout,
          error,
          stack,
        );

      default:
        return _createInfrastructureError(
          messages.operationFailed(),
          FirestoreErrorCodes.operationFailed,
          error,
          stack,
        );
    }
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

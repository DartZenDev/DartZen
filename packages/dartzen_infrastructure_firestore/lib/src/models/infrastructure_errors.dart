import 'package:dartzen_core/dartzen_core.dart';

/// Semantic error codes for infrastructure failures.
///
/// These codes can be stored in [ZenInfrastructureError.internalData]
/// for granular error categorization.
abstract class InfrastructureErrorCode {
  /// Generic infrastructure error.
  static const String infrastructureError = 'INFRASTRUCTURE_ERROR';

  /// Firestore permission denied.
  static const String permissionDenied = 'FIRESTORE_PERMISSION_DENIED';

  /// Firestore operation timeout.
  static const String timeout = 'FIRESTORE_TIMEOUT';

  /// Firestore service unavailable.
  static const String unavailable = 'FIRESTORE_UNAVAILABLE';

  /// Invalid or corrupted data in storage.
  static const String corruptedData = 'FIRESTORE_CORRUPTED_DATA';

  /// Generic storage operation failure.
  static const String storageFailure = 'FIRESTORE_STORAGE_FAILURE';
}

/// Represents a failure in the infrastructure layer (e.g. database, network).
class ZenInfrastructureError extends ZenError {
  /// Creates a [ZenInfrastructureError] with optional error code.
  ///
  /// [errorCode] should be one of [InfrastructureErrorCode] constants.
  ZenInfrastructureError(
    super.message, {
    String? errorCode,
    Object? originalError,
    super.stackTrace,
  }) : super(
         internalData: {
           if (errorCode != null) 'errorCode': errorCode,
           if (originalError != null) 'originalError': originalError,
         },
       );
}

import 'package:meta/meta.dart';

import '../result/zen_error.dart';

/// A universal response contract for DartZen services.
///
/// This structure is used across boundaries (e.g. Server -> Client).
@immutable
final class BaseResponse<T> {
  /// Whether the operation completed successfully.
  final bool success;

  /// A descriptive message for the user or logs.
  final String message;

  /// The payload data, if any.
  final T? data;

  /// A code identifying the error type, if any.
  final String? errorCode;

  /// The UTC timestamp when the response was created.
  final DateTime timestamp;

  const BaseResponse._({
    required this.success,
    required this.message,
    required this.timestamp,
    this.data,
    this.errorCode,
  });

  /// Creates a successful response.
  factory BaseResponse.success(
    T data, {
    String message = 'Success',
  }) {
    return BaseResponse._(
      success: true,
      message: message,
      data: data,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Creates a failure response.
  factory BaseResponse.failure(
    String message, {
    String? errorCode,
    T? data,
  }) {
    return BaseResponse._(
      success: false,
      message: message,
      errorCode: errorCode ?? 'UNKNOWN_ERROR',
      data: data,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Creates a failure response from a [ZenError].
  factory BaseResponse.fromError(
    ZenError error, {
    T? data,
  }) {
    // Map ZenError types to error codes if desired, or use class name
    String code = 'UNKNOWN_ERROR';
    if (error is ZenValidationError) code = 'VALIDATION_ERROR';
    if (error is ZenNotFoundError) code = 'NOT_FOUND_ERROR';
    if (error is ZenUnauthorizedError) code = 'UNAUTHORIZED_ERROR';
    if (error is ZenConflictError) code = 'CONFLICT_ERROR';

    return BaseResponse._(
      success: false,
      message: error.message,
      errorCode: code,
      data: data,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  String toString() {
    return 'BaseResponse(success: $success, message: "$message", data: $data, errorCode: $errorCode, timestamp: $timestamp)';
  }
}

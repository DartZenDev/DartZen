import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:shelf/shelf.dart';

/// Translates domain [ZenResult] into transport-level responses.
///
/// The translation follows a strict order:
/// 1. Map [ZenResult] to [ZenResponse] (preserving domain meaning).
/// 2. Map [ZenResponse] to [Response] (protocol-specific adapter).
class ZenResponseTranslator {
  /// Translates a [ZenResult] into a Shelf [Response].
  ///
  /// The [requestId] is used to correlate the response with the request.
  /// The [format] determines the encoding of the response body.
  static Response translate<T>({
    required ZenResult<T> result,
    required String requestId,
    required ZenTransportFormat format,
  }) {
    final zenResponse = _toZenResponse(result, requestId);
    return _toShelfResponse(zenResponse, format);
  }

  /// Maps [ZenResult] to [ZenResponse].
  ///
  /// This step preserves the domain intent and maps domain errors to
  /// appropriate HTTP-style status codes within the [ZenResponse].
  static ZenResponse _toZenResponse<T>(ZenResult<T> result, String requestId) =>
      result.fold(
        (data) => ZenResponse(id: requestId, status: 200, data: data),
        (error) {
          final status = _mapErrorToStatus(error);

          // Log all errors using ZenLogger
          ZenLogger.instance.error(
            'Request $requestId failed with status $status: ${error.message}',
            error,
            error.stackTrace,
          );

          // Hide internal error details in production for 500 errors
          final message = (status == 500 && dzIsPrd)
              ? 'An unexpected error occurred.'
              : error.message;

          return ZenResponse(id: requestId, status: status, error: message);
        },
      );

  /// Maps [ZenResponse] to Shelf [Response].
  ///
  /// This is the final protocol-specific adapter step.
  static Response _toShelfResponse(
    ZenResponse zenResponse,
    ZenTransportFormat format,
  ) =>
      // We use the context to pass the data to the transportMiddleware
      // which will handle the actual encoding based on the format.
      Response(zenResponse.status, context: {'zen_data': zenResponse.toMap()});

  /// Maps [ZenError] types to HTTP-style status codes.
  static int _mapErrorToStatus(ZenError error) {
    if (error is ZenValidationError) return 400;
    if (error is ZenUnauthorizedError) return 401;
    if (error is ZenNotFoundError) return 404;
    if (error is ZenConflictError) return 409;
    return 500;
  }
}

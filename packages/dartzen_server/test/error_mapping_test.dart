import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_server/src/zen_response_translator.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ZenResponseTranslator Error Mapping', () {
    const requestId = 'error-test';
    const format = ZenTransportFormat.json;

    test('maps ZenValidationError to 400', () {
      const result = ZenResult<void>.err(ZenValidationError('Invalid'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );
      expect(response.statusCode, 400);
    });

    test('maps ZenUnauthorizedError to 401', () {
      const result = ZenResult<void>.err(ZenUnauthorizedError('Denied'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );
      expect(response.statusCode, 401);
    });

    test('maps ZenNotFoundError to 404', () {
      const result = ZenResult<void>.err(ZenNotFoundError('Missing'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );
      expect(response.statusCode, 404);
    });

    test('maps ZenConflictError to 409', () {
      const result = ZenResult<void>.err(ZenConflictError('Conflict'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );
      expect(response.statusCode, 409);
    });

    test('maps ZenUnknownError to 500', () {
      final result = ZenResult<void>.err(ZenUnknownError('Unexpected error'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );
      expect(response.statusCode, 500);
    });

    test('hides error details in production for 500 errors', () {
      final result = ZenResult<void>.err(ZenUnknownError('Sensitive details'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );

      final zenData = response.context['zen_data'] as Map<String, dynamic>;
      expect(zenData['error'], 'An unexpected error occurred.');
    });
  });
}

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_server/src/zen_response_translator.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ZenResponseTranslator', () {
    const requestId = 'test-id';
    const format = ZenTransportFormat.json;

    test('translates ZenSuccess to 200 Response', () {
      const result = ZenResult.ok({'foo': 'bar'});
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );

      expect(response.statusCode, 200);
      final zenData = response.context['zen_data'] as Map<String, dynamic>;
      expect(zenData['id'], requestId);
      expect(zenData['status'], 200);
      expect(zenData['data'], const {'foo': 'bar'});
    });

    test('translates ZenValidationError to 400 Response', () {
      const result = ZenResult<void>.err(ZenValidationError('Invalid input'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );

      expect(response.statusCode, 400);
      final zenData = response.context['zen_data'] as Map<String, dynamic>;
      expect(zenData['status'], 400);
      expect(zenData['error'], 'Invalid input');
    });

    test('translates ZenNotFoundError to 404 Response', () {
      const result = ZenResult<void>.err(ZenNotFoundError('Not found'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );

      expect(response.statusCode, 404);
    });

    test('translates ZenUnknownError to 500 Response', () {
      const result = ZenResult<void>.err(ZenUnknownError('Server error'));
      final response = ZenResponseTranslator.translate(
        result: result,
        requestId: requestId,
        format: format,
      );

      expect(response.statusCode, 500);
    });
  });
}

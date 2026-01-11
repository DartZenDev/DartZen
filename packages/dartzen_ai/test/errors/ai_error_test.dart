import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AIError', () {
    test('AIBudgetExceededError creates with method', () {
      const error = AIBudgetExceededError(
        limit: 100.0,
        current: 105.0,
        method: 'textGeneration',
      );

      expect(error.limit, 100.0);
      expect(error.current, 105.0);
      expect(error.message, contains('textGeneration'));
      expect(error.message, contains('105.0'));
      expect(error.message, contains('100.0'));
    });

    test('AIBudgetExceededError creates without method', () {
      const error = AIBudgetExceededError(limit: 50.0, current: 55.0);

      expect(error.message, contains('Global budget'));
    });

    test('AIQuotaExceededError', () {
      const error = AIQuotaExceededError(quotaType: 'rate_limit');

      expect(error.quotaType, 'rate_limit');
      expect(error.message, contains('rate_limit'));
    });

    test('AIInvalidRequestError', () {
      const error = AIInvalidRequestError(reason: 'Missing parameter');

      expect(error.reason, 'Missing parameter');
      expect(error.message, contains('Missing parameter'));
    });

    test('AIServiceUnavailableError', () {
      const error = AIServiceUnavailableError(
        retryAfter: Duration(seconds: 30),
      );

      expect(error.retryAfter, const Duration(seconds: 30));
    });

    test('AIAuthenticationError', () {
      const error = AIAuthenticationError(reason: 'Invalid credentials');

      expect(error.reason, 'Invalid credentials');
      expect(error.message, contains('Invalid credentials'));
    });

    test('AICancelledError', () {
      const error = AICancelledError();

      expect(error.message, contains('cancelled'));
    });
  });
}

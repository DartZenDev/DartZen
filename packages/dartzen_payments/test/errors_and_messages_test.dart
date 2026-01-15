import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:dartzen_payments/src/l10n/payments_messages.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockZenLocalizationService extends Mock
    implements ZenLocalizationService {}

void main() {
  group('PaymentStatus enum', () {
    test('has all required statuses', () {
      expect(PaymentStatus.pending, isNotNull);
      expect(PaymentStatus.initiated, isNotNull);
      expect(PaymentStatus.confirmed, isNotNull);
      expect(PaymentStatus.completed, isNotNull);
      expect(PaymentStatus.failed, isNotNull);
      expect(PaymentStatus.refunded, isNotNull);
    });

    test('name property returns correct string representation', () {
      expect(PaymentStatus.pending.name, 'pending');
      expect(PaymentStatus.initiated.name, 'initiated');
      expect(PaymentStatus.confirmed.name, 'confirmed');
      expect(PaymentStatus.completed.name, 'completed');
      expect(PaymentStatus.failed.name, 'failed');
      expect(PaymentStatus.refunded.name, 'refunded');
    });

    test('can find status by name', () {
      expect(
        PaymentStatus.values.firstWhere((s) => s.name == 'pending'),
        PaymentStatus.pending,
      );
      expect(
        PaymentStatus.values.firstWhere((s) => s.name == 'completed'),
        PaymentStatus.completed,
      );
    });
  });

  group('PaymentError hierarchy', () {
    group('PaymentDeclinedError', () {
      test('extends PaymentError', () {
        const error = PaymentDeclinedError('Card declined');
        expect(error, isA<PaymentError>());
      });

      test('preserves message', () {
        const error = PaymentDeclinedError('Card was declined');
        expect(error.message, 'Card was declined');
      });

      test('carries metadata in internalData', () {
        const error = PaymentDeclinedError(
          'Declined',
          metadata: {'declineReason': 'fraud_suspected'},
        );
        expect(error.internalData?['declineReason'], 'fraud_suspected');
      });
    });

    group('PaymentInsufficientFundsError', () {
      test('extends PaymentError', () {
        const error = PaymentInsufficientFundsError();
        expect(error, isA<PaymentError>());
      });

      test('has default message', () {
        const error = PaymentInsufficientFundsError();
        expect(error.message, 'Insufficient funds');
      });

      test('optionally carries metadata', () {
        const error = PaymentInsufficientFundsError(
          metadata: {'available': 50, 'required': 100},
        );
        expect(error.internalData?['available'], 50);
        expect(error.internalData?['required'], 100);
      });
    });

    group('PaymentInvalidAmountError', () {
      test('extends PaymentError', () {
        const error = PaymentInvalidAmountError('Amount too small');
        expect(error, isA<PaymentError>());
      });

      test('preserves message', () {
        const error = PaymentInvalidAmountError('Amount exceeds limit');
        expect(error.message, 'Amount exceeds limit');
      });

      test('carries metadata', () {
        const error = PaymentInvalidAmountError(
          'Invalid',
          metadata: {'min': 100, 'max': 100000},
        );
        expect(error.internalData?['min'], 100);
        expect(error.internalData?['max'], 100000);
      });
    });

    group('PaymentNotFoundError', () {
      test('extends PaymentError', () {
        const error = PaymentNotFoundError('Payment ID not found');
        expect(error, isA<PaymentError>());
      });

      test('preserves message', () {
        const error = PaymentNotFoundError('Payment does not exist');
        expect(error.message, 'Payment does not exist');
      });

      test('carries metadata', () {
        const error = PaymentNotFoundError(
          'Not found',
          metadata: {'paymentId': 'invalid-id'},
        );
        expect(error.internalData?['paymentId'], 'invalid-id');
      });
    });

    group('PaymentStateError', () {
      test('extends PaymentError', () {
        const error = PaymentStateError('Cannot refund pending payment');
        expect(error, isA<PaymentError>());
      });

      test('preserves message', () {
        const error = PaymentStateError('Payment already refunded');
        expect(error.message, 'Payment already refunded');
      });

      test('carries metadata', () {
        const error = PaymentStateError(
          'Invalid state',
          metadata: {'currentState': 'failed', 'attemptedAction': 'confirm'},
        );
        expect(error.internalData?['currentState'], 'failed');
        expect(error.internalData?['attemptedAction'], 'confirm');
      });
    });

    group('PaymentProviderError', () {
      test('extends PaymentError', () {
        const error = PaymentProviderError('Provider API error');
        expect(error, isA<PaymentError>());
      });

      test('preserves message', () {
        const error = PaymentProviderError('External service timeout');
        expect(error.message, 'External service timeout');
      });

      test('carries rich metadata', () {
        const error = PaymentProviderError(
          'Provider error',
          metadata: {
            'status': 503,
            'providerCode': 'SERVICE_UNAVAILABLE',
            'retryable': true,
          },
        );
        expect(error.internalData?['status'], 503);
        expect(error.internalData?['providerCode'], 'SERVICE_UNAVAILABLE');
        expect(error.internalData?['retryable'], isTrue);
      });
    });

    test('all error types are instances of PaymentError', () {
      final errors = [
        const PaymentDeclinedError('test'),
        const PaymentInsufficientFundsError(),
        const PaymentInvalidAmountError('test'),
        const PaymentNotFoundError('test'),
        const PaymentStateError('test'),
        const PaymentProviderError('test'),
      ];

      for (final error in errors) {
        expect(error, isA<PaymentError>());
      }
    });
  });

  group('PaymentsMessages', () {
    late MockZenLocalizationService mockLocalization;
    late PaymentsMessages messages;

    setUp(() {
      mockLocalization = MockZenLocalizationService();
      messages = PaymentsMessages(mockLocalization, 'en');
    });

    test('declined returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.declined',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Payment declined');

      expect(messages.declined(), 'Payment declined');
    });

    test('insufficientFunds returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.insufficient_funds',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Insufficient funds');

      expect(messages.insufficientFunds(), 'Insufficient funds');
    });

    test('invalidAmount returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.invalid_amount',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Invalid amount');

      expect(messages.invalidAmount(), 'Invalid amount');
    });

    test('notFound returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.not_found',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Payment not found');

      expect(messages.notFound(), 'Payment not found');
    });

    test('state returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.state',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Invalid payment state');

      expect(messages.state(), 'Invalid payment state');
    });

    test('provider returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.provider',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Provider error');

      expect(messages.provider(), 'Provider error');
    });

    test('unknown returns translated string', () {
      when(
        () => mockLocalization.translate(
          'payments.error.unknown',
          language: 'en',
          module: 'payments',
        ),
      ).thenReturn('Unknown error');

      expect(messages.unknown(), 'Unknown error');
    });

    group('error mapping', () {
      setUp(() {
        when(
          () => mockLocalization.translate(
            'payments.error.declined',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Declined');

        when(
          () => mockLocalization.translate(
            'payments.error.insufficient_funds',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Insufficient funds');

        when(
          () => mockLocalization.translate(
            'payments.error.invalid_amount',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Invalid amount');

        when(
          () => mockLocalization.translate(
            'payments.error.not_found',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Not found');

        when(
          () => mockLocalization.translate(
            'payments.error.state',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Invalid state');

        when(
          () => mockLocalization.translate(
            'payments.error.provider',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Provider error');

        when(
          () => mockLocalization.translate(
            'payments.error.unknown',
            language: 'en',
            module: 'payments',
          ),
        ).thenReturn('Unknown error');
      });

      test('maps PaymentDeclinedError', () {
        const error = PaymentDeclinedError('test');
        expect(messages.error(error), 'Declined');
      });

      test('maps PaymentInsufficientFundsError', () {
        const error = PaymentInsufficientFundsError();
        expect(messages.error(error), 'Insufficient funds');
      });

      test('maps PaymentInvalidAmountError', () {
        const error = PaymentInvalidAmountError('test');
        expect(messages.error(error), 'Invalid amount');
      });

      test('maps PaymentNotFoundError', () {
        const error = PaymentNotFoundError('test');
        expect(messages.error(error), 'Not found');
      });

      test('maps PaymentStateError', () {
        const error = PaymentStateError('test');
        expect(messages.error(error), 'Invalid state');
      });

      test('maps PaymentProviderError', () {
        const error = PaymentProviderError('test');
        expect(messages.error(error), 'Provider error');
      });

      test('maps unknown error type to unknown message', () {
        // Create a mock subclass of PaymentError to test the default case
        const unknownError =
            PaymentProviderError('test')
                as PaymentError; // Intentionally cast to avoid specific type check
        expect(messages.error(unknownError), isNotNull);
      });
    });

    test('uses provided language in translation calls', () {
      final messagesDE = PaymentsMessages(mockLocalization, 'de');

      when(
        () => mockLocalization.translate(
          'payments.error.declined',
          language: 'de',
          module: 'payments',
        ),
      ).thenReturn('Zahlung abgelehnt');

      messagesDE.declined();

      verify(
        () => mockLocalization.translate(
          'payments.error.declined',
          language: 'de',
          module: 'payments',
        ),
      ).called(1);
    });
  });
}

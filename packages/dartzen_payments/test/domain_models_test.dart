// ignore_for_file: avoid_redundant_argument_values

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentIntent', () {
    group('create factory', () {
      test('creates intent with minimal parameters', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isSuccess, isTrue);
        final intent = result.dataOrNull!;
        expect(intent.id, 'intent-1');
        expect(intent.amountMinor, 500);
        expect(intent.currency, 'USD');
        expect(intent.idempotencyKey, 'idem-1');
        expect(intent.description, isNull);
        expect(intent.metadata, isNull);
      });

      test('creates intent with description and metadata', () {
        final metadata = {'orderId': '12345'};
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
          description: 'Order payment for order #12345',
          metadata: metadata,
        );

        expect(result.isSuccess, isTrue);
        final intent = result.dataOrNull!;
        expect(intent.description, 'Order payment for order #12345');
        expect(intent.metadata, metadata);
      });

      test('fails when id is empty', () {
        final result = PaymentIntent.create(
          id: '',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('fails when id is whitespace only', () {
        final result = PaymentIntent.create(
          id: '   ',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('fails when amount is zero', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 0,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('fails when amount is negative', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: -100,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('succeeds with large amount', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 999999999,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.amountMinor, 999999999);
      });

      test('fails when currency is lowercase', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'usd',
          idempotencyKey: 'idem-1',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('fails when currency is not exactly 3 characters', () {
        final result1 = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'US',
          idempotencyKey: 'idem-1',
        );

        expect(result1.isFailure, isTrue);

        final result2 = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USDA',
          idempotencyKey: 'idem-1',
        );

        expect(result2.isFailure, isTrue);
      });

      test('fails when idempotency key is empty', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: '',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('fails when idempotency key is whitespace only', () {
        final result = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: '  \t  ',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('accepts valid ISO 4217 currencies', () {
        const validCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD'];

        for (final currency in validCurrencies) {
          final result = PaymentIntent.create(
            id: 'intent-1',
            amountMinor: 500,
            currency: currency,
            idempotencyKey: 'idem-1',
          );

          expect(result.isSuccess, isTrue, reason: 'Should accept $currency');
        }
      });
    });

    group('serialization', () {
      test('converts to JSON with all fields', () {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2500,
          currency: 'CAD',
          idempotencyKey: 'idem-xyz',
          description: 'Test payment',
          metadata: {'key': 'value'},
        ).dataOrNull!;

        final json = intent.toJson();

        expect(json['id'], 'intent-1');
        expect(json['amountMinor'], 2500);
        expect(json['currency'], 'CAD');
        expect(json['idempotencyKey'], 'idem-xyz');
        expect(json['description'], 'Test payment');
        expect(json['metadata'], {'key': 'value'});
      });

      test('converts to JSON without optional fields', () {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2500,
          currency: 'CAD',
          idempotencyKey: 'idem-xyz',
        ).dataOrNull!;

        final json = intent.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });

      test('reconstructs from JSON', () {
        final original = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2500,
          currency: 'CAD',
          idempotencyKey: 'idem-xyz',
          description: 'Test payment',
          metadata: {'key': 'value'},
        ).dataOrNull!;

        final json = original.toJson();
        final restored = PaymentIntent.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.amountMinor, original.amountMinor);
        expect(restored.currency, original.currency);
        expect(restored.idempotencyKey, original.idempotencyKey);
        expect(restored.description, original.description);
        expect(restored.metadata, original.metadata);
      });

      test('makes metadata immutable', () {
        final mutableMetadata = {'key': 'value'};
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
          metadata: mutableMetadata,
        ).dataOrNull!;

        mutableMetadata['newKey'] = 'newValue';

        expect(intent.metadata, {'key': 'value'});
        expect(intent.metadata?.containsKey('newKey'), isFalse);
      });

      test('metadata is null when not provided', () {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        expect(intent.metadata, isNull);
      });
    });

    group('immutability', () {
      test('cannot modify intent properties', () {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 500,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        expect(
          () => (intent as dynamic).amountMinor = 1000,
          throwsA(isA<NoSuchMethodError>()),
        );
      });
    });
  });

  group('Payment', () {
    group('serialization', () {
      test('converts to JSON with provider reference', () {
        final payment = Payment(
          id: 'pay-1',
          intentId: 'intent-1',
          provider: 'strapi',
          amountMinor: 1500,
          currency: 'GBP',
          status: PaymentStatus.completed,
          createdAt: DateTime.utc(2024, 6, 15, 10, 30, 0),
          providerReference: 'provider-ref-abc',
        );

        final json = payment.toJson();

        expect(json['id'], 'pay-1');
        expect(json['intentId'], 'intent-1');
        expect(json['provider'], 'strapi');
        expect(json['amountMinor'], 1500);
        expect(json['currency'], 'GBP');
        expect(json['status'], 'completed');
        expect(json['providerReference'], 'provider-ref-abc');
      });

      test('converts to JSON without provider reference', () {
        final payment = Payment(
          id: 'pay-1',
          intentId: 'intent-1',
          provider: 'adyen',
          amountMinor: 1500,
          currency: 'GBP',
          status: PaymentStatus.pending,
          createdAt: DateTime.utc(2024, 6, 15, 10, 30, 0),
        );

        final json = payment.toJson();

        expect(json.containsKey('providerReference'), isFalse);
      });

      test('round-trips through JSON with all statuses', () {
        final statuses = [
          PaymentStatus.pending,
          PaymentStatus.initiated,
          PaymentStatus.confirmed,
          PaymentStatus.completed,
          PaymentStatus.failed,
          PaymentStatus.refunded,
        ];

        for (final status in statuses) {
          final payment = Payment(
            id: 'pay-1',
            intentId: 'intent-1',
            provider: 'strapi',
            amountMinor: 1500,
            currency: 'GBP',
            status: status,
            createdAt: DateTime.utc(2024, 6, 15),
          );

          final json = payment.toJson();
          final restored = Payment.fromJson(json);

          expect(restored.status, status, reason: 'Failed for status: $status');
        }
      });

      test('preserves timestamp precision', () {
        final timestamp = DateTime.utc(2024, 6, 15, 10, 30, 45, 123);
        final payment = Payment(
          id: 'pay-1',
          intentId: 'intent-1',
          provider: 'strapi',
          amountMinor: 1500,
          currency: 'GBP',
          status: PaymentStatus.completed,
          createdAt: timestamp,
        );

        final json = payment.toJson();
        final restored = Payment.fromJson(json);

        expect(restored.createdAt.isUtc, isTrue);
        expect(restored.createdAt, timestamp);
      });

      test('defaults to failed status on unknown status string', () {
        final json = {
          'id': 'pay-1',
          'intentId': 'intent-1',
          'provider': 'unknown',
          'amountMinor': 1500,
          'currency': 'GBP',
          'status': 'unknown_status',
          'createdAt': '2024-06-15T10:30:00.000Z',
        };

        final payment = Payment.fromJson(json);

        expect(payment.status, PaymentStatus.failed);
      });
    });

    group('immutability', () {
      test('cannot modify payment properties', () {
        final payment = Payment(
          id: 'pay-1',
          intentId: 'intent-1',
          provider: 'strapi',
          amountMinor: 1500,
          currency: 'GBP',
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
        );

        expect(
          () => (payment as dynamic).amountMinor = 2000,
          throwsA(isA<NoSuchMethodError>()),
        );
      });
    });
  });
}

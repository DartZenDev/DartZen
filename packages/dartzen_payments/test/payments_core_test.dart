// ignore_for_file: avoid_redundant_argument_values

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentIntent.create', () {
    test('returns ok for valid input', () {
      final result = PaymentIntent.create(
        id: 'intent-1',
        amountMinor: 100,
        currency: 'EUR',
        idempotencyKey: 'idem-1',
      );

      expect(result.isSuccess, isTrue);
      final intent = result.dataOrNull!;
      expect(intent.amountMinor, 100);
      expect(intent.currency, 'EUR');
      expect(intent.idempotencyKey, 'idem-1');
    });

    test('fails for invalid currency', () {
      final result = PaymentIntent.create(
        id: 'intent-1',
        amountMinor: 100,
        currency: 'eur',
        idempotencyKey: 'idem-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenValidationError>());
    });

    test('fails for non-positive amount', () {
      final result = PaymentIntent.create(
        id: 'intent-1',
        amountMinor: 0,
        currency: 'USD',
        idempotencyKey: 'idem-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenValidationError>());
    });
  });

  group('Payment serialization', () {
    test('round-trips with toJson/fromJson', () {
      final payment = Payment(
        id: 'pay-1',
        intentId: 'intent-1',
        provider: 'strapi',
        amountMinor: 500,
        currency: 'USD',
        status: PaymentStatus.initiated,
        createdAt: DateTime.utc(2024, 1, 1),
        providerReference: 'ref-1',
      );

      final json = payment.toJson();
      final restored = Payment.fromJson(json);

      expect(restored.id, payment.id);
      expect(restored.intentId, payment.intentId);
      expect(restored.provider, payment.provider);
      expect(restored.amountMinor, payment.amountMinor);
      expect(restored.currency, payment.currency);
      expect(restored.status, PaymentStatus.initiated);
      expect(restored.providerReference, payment.providerReference);
    });
  });
}

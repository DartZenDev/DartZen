import 'package:dartzen_payments/src/adyen/adyen_mapper.dart';
import 'package:dartzen_payments/src/adyen/adyen_models.dart';
import 'package:dartzen_payments/src/payment_status.dart';
import 'package:dartzen_payments/src/strapi/strapi_mapper.dart';
import 'package:dartzen_payments/src/strapi/strapi_models.dart';
import 'package:test/test.dart';

void main() {
  group('Strapi mapping', () {
    test('maps status to domain', () {
      expect(strapiStatusToDomain('pending'), PaymentStatus.pending);
      expect(strapiStatusToDomain('succeeded'), PaymentStatus.completed);
      expect(strapiStatusToDomain('failed'), PaymentStatus.failed);
    });

    test('maps model to payment', () {
      const mapper = StrapiPaymentMapper();
      final model = StrapiPaymentModel(
        id: 'pay-1',
        intentId: 'intent-1',
        status: 'succeeded',
        amountMinor: 123,
        currency: 'USD',
        createdAt: DateTime.now().toUtc(),
      );

      final payment = mapper.toDomain(model: model);
      expect(payment.provider, 'strapi');
      expect(payment.intentId, 'intent-1');
      expect(payment.status, PaymentStatus.completed);
    });
  });

  group('Adyen mapping', () {
    test('maps resultCode to domain', () {
      expect(adyenStatusToDomain('Authorised'), PaymentStatus.confirmed);
      expect(adyenStatusToDomain('Refunded'), PaymentStatus.refunded);
      expect(adyenStatusToDomain('Refused'), PaymentStatus.failed);
    });

    test('maps model to payment', () {
      const mapper = AdyenPaymentMapper();
      final model = AdyenPaymentModel(
        paymentId: 'pay-2',
        intentId: 'intent-2',
        resultCode: 'Authorised',
        amountMinor: 999,
        currency: 'EUR',
        pspReference: 'psp-123',
        createdAt: DateTime.now().toUtc(),
      );

      final payment = mapper.toDomain(model);
      expect(payment.provider, 'adyen');
      expect(payment.status, PaymentStatus.confirmed);
      expect(payment.providerReference, 'psp-123');
    });
  });
}

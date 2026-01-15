import 'dart:developer' as developer;

import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:dartzen_payments/src/strapi/strapi_payments_service.dart';

Future<void> main() async {
  final service = StrapiPaymentsService(
    const StrapiPaymentsConfig(
      baseUrl: 'https://payments.example.com',
      apiToken: '<token>',
    ),
  );

  final intentResult = PaymentIntent.create(
    id: 'intent-123',
    amountMinor: 2499,
    currency: 'USD',
    idempotencyKey: 'idem-123',
    description: 'Order #123',
  );

  if (intentResult.isFailure) {
    developer.log(
      'Invalid intent: ${intentResult.errorOrNull?.message}',
      name: 'payments.example',
    );
    return;
  }

  final intent = intentResult.dataOrNull!;
  final createResult = await service.createPayment(intent);

  createResult.fold(
    (payment) => developer.log(
      'Created payment ${payment.id} with status ${payment.status}',
      name: 'payments.example',
    ),
    (error) => developer.log(
      'Payment failed: ${error.message}',
      name: 'payments.example',
      level: 1000,
    ),
  );

  service.close();
}

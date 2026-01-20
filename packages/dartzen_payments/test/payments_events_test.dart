import 'package:dartzen_payments/src/payment_events.dart';
import 'package:dartzen_payments/src/payment_status.dart';
import 'package:test/test.dart';

void main() {
  test('paymentInitiated builds expected payload', () {
    final event = paymentInitiated(
      paymentId: 'pay-1',
      intentId: 'intent-1',
      provider: 'strapi',
      amountMinor: 100,
      currency: 'USD',
      timestamp: DateTime.utc(2024),
    );

    expect(event.name, 'payment.initiated');
    expect(event.scope, 'payments');
    expect(event.payload?['paymentId'], 'pay-1');
    expect(event.payload?['status'], PaymentStatus.initiated.name);
  });

  test('paymentFailed includes reason when provided', () {
    final event = paymentFailed(
      paymentId: 'pay-2',
      intentId: 'intent-2',
      provider: 'adyen',
      amountMinor: 200,
      currency: 'EUR',
      reason: 'declined',
      timestamp: DateTime.utc(2024),
    );

    expect(event.payload?['reason'], 'declined');
    expect(event.payload?['status'], PaymentStatus.failed.name);
  });
}

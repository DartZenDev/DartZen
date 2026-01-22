// ignore_for_file: avoid_print

import 'package:dartzen_payments/dartzen_payments.dart';

// Example using `TestExecutor` to run a payment descriptor locally.
Future<void> main() async {
  final executor = TestExecutor();
  await executor.start();

  const charge = PaymentDescriptor(
    id: 'charge_order',
    operation: PaymentOperation.charge,
  );

  final result = await executor.execute(
    charge,
    payload: {'amountMinor': 2499, 'currency': 'USD', 'intentId': 'intent-123'},
    idempotencyKey: 'idem-123',
  );

  if (result.status == PaymentResultStatus.success) {
    print('Payment succeeded: ${result.providerReference}');
  } else {
    print('Payment failed: ${result.error?.message}');
  }

  await executor.shutdown();
}

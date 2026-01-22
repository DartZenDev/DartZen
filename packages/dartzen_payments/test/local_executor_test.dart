import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_payments/src/local_executor.dart';
import 'package:dartzen_payments/src/payment.dart';
import 'package:dartzen_payments/src/payment_descriptor.dart';
import 'package:dartzen_payments/src/payment_error.dart';
import 'package:dartzen_payments/src/payment_intent.dart';
import 'package:dartzen_payments/src/payment_result.dart';
import 'package:dartzen_payments/src/payment_status.dart';
import 'package:dartzen_payments/src/payments_service.dart';
import 'package:test/test.dart';

class _FakeService implements PaymentsService {
  int createCalls = 0;
  ZenResult<Payment> createResult = ZenResult.ok(
    Payment(
      id: 'p',
      intentId: 'i',
      provider: 'fake',
      amountMinor: 100,
      currency: 'USD',
      status: PaymentStatus.completed,
      createdAt: DateTime.utc(2020),
      providerReference: 'r',
    ),
  );

  @override
  FutureOr<void> close() async {}

  @override
  Future<ZenResult<Payment>> confirmPayment(
    String paymentId, {
    Map<String, dynamic>? confirmationData,
  }) async => ZenResult.ok(
    Payment(
      id: 'p',
      intentId: 'i',
      provider: 'fake',
      amountMinor: 100,
      currency: 'USD',
      status: PaymentStatus.completed,
      createdAt: DateTime.utc(2020),
      providerReference: 'r',
    ),
  );

  @override
  Future<ZenResult<Payment>> createPayment(PaymentIntent intent) async {
    createCalls++;
    return createResult;
  }

  @override
  Future<ZenResult<Payment>> refundPayment(
    String paymentId, {
    String? reason,
  }) async => ZenResult.ok(
    Payment(
      id: 'p',
      intentId: 'i',
      provider: 'fake',
      amountMinor: 100,
      currency: 'USD',
      status: PaymentStatus.refunded,
      createdAt: DateTime.utc(2020),
      providerReference: 'r',
    ),
  );
}

void main() {
  test('throws for empty descriptor id', () async {
    final le = LocalExecutor(providers: const {});
    const desc = PaymentDescriptor(
      id: '   ',
      operation: PaymentOperation.charge,
    );
    expect(() => le.execute(desc), throwsArgumentError);
  });

  test('returns state error when provider not selected', () async {
    final le = LocalExecutor(providers: const {});
    const desc = PaymentDescriptor(
      id: 'd1',
      operation: PaymentOperation.charge,
    );
    final res = await le.execute(desc);
    expect(res.status, equals(PaymentResultStatus.failed));
    expect(res.error, isA<PaymentStateError>());
  });

  test('unknown provider returns provider error', () async {
    final le = LocalExecutor(providers: {'x': _FakeService()});
    const desc = PaymentDescriptor(
      id: 'd1',
      operation: PaymentOperation.charge,
      metadata: {'provider': 'bad'},
    );
    final res = await le.execute(
      desc,
      payload: {
        'intentId': 'i',
        'amountMinor': 100,
        'currency': 'USD',
        'idempotencyKey': 'k',
      },
    );
    expect(res.status, equals(PaymentResultStatus.failed));
    expect(res.error, isA<PaymentProviderError>());
  });

  test('charge succeeds and idempotency caches result', () async {
    final svc = _FakeService();
    final le = LocalExecutor(providers: {'fake': svc});
    const desc = PaymentDescriptor(
      id: 'd2',
      operation: PaymentOperation.charge,
      metadata: {'provider': 'fake'},
    );

    final res1 = await le.execute(
      desc,
      payload: {
        'intentId': 'i',
        'amountMinor': 100,
        'currency': 'USD',
        'idempotencyKey': 'idem-1',
      },
      idempotencyKey: 'idem-1',
    );
    expect(res1.status, equals(PaymentResultStatus.success));
    expect(svc.createCalls, equals(1));

    final res2 = await le.execute(
      desc,
      payload: {
        'intentId': 'i',
        'amountMinor': 100,
        'currency': 'USD',
        'idempotencyKey': 'idem-1',
      },
      idempotencyKey: 'idem-1',
    );
    expect(res2.status, equals(PaymentResultStatus.success));
    // service not called again due to cache
    expect(svc.createCalls, equals(1));
  });

  test('invalid intent fields produce invalid amount error', () async {
    final svc = _FakeService();
    final le = LocalExecutor(providers: {'fake': svc});
    const desc = PaymentDescriptor(
      id: 'd3',
      operation: PaymentOperation.charge,
      metadata: {'provider': 'fake'},
    );

    final res = await le.execute(
      desc,
      payload: {
        'intentId': '', // invalid
        'amountMinor': -1,
        'currency': 'usd',
        'idempotencyKey': '',
      },
    );
    expect(res.status, equals(PaymentResultStatus.failed));
    expect(res.error, isA<PaymentInvalidAmountError>());
  });
}

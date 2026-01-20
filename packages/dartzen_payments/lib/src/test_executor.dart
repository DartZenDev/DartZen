import 'dart:async';

import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import 'descriptor_helpers.dart';
import 'executor.dart';
import 'payment_descriptor.dart';
import 'payment_error.dart';
import 'payment_events.dart';
import 'payment_result.dart';

/// A simple TestExecutor for local development and tests.
/// It simulates provider behavior and emits telemetry when provided.
final class TestExecutor implements Executor {
  /// Optional telemetry client used to emit payment events during execution.
  final TelemetryClient? telemetry;

  /// Create a [TestExecutor].
  ///
  /// The optional [telemetry] client will receive initiated/completed events.
  TestExecutor({this.telemetry});

  @override
  Future<void> start() async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<PaymentResult> execute(
    PaymentDescriptor descriptor, {
    Map<String, Object?>? payload,
    String? idempotencyKey,
  }) async {
    ensureValidDescriptor(descriptor);

    // Minimal payload expectations for the example. Fail fast with typed error.
    final amount = payload?['amountMinor'];
    final currency = payload?['currency'];
    final intentId = payload?['intentId'];

    if (amount is! int || currency is! String || intentId is! String) {
      return const PaymentResult.failed(
        PaymentInvalidAmountError(
          'Missing or invalid payload: amountMinor/currency/intentId',
        ),
      );
    }

    final providerRef = 'test-${DateTime.now().microsecondsSinceEpoch}';

    // Emit telemetry for initiated/completed
    await telemetry?.emitEvent(
      paymentInitiated(
        paymentId: providerRef,
        intentId: intentId,
        provider: 'test',
        amountMinor: amount,
        currency: currency,
      ),
    );

    // Simulate work
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await telemetry?.emitEvent(
      paymentCompleted(
        paymentId: providerRef,
        intentId: intentId,
        provider: 'test',
        amountMinor: amount,
        currency: currency,
      ),
    );

    return PaymentResult.success(providerReference: providerRef);
  }
}

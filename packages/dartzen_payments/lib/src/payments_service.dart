import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';

import 'payment.dart';
import 'payment_intent.dart';

/// Contract for payment operations supported by DartZen.
///
/// Providers may optionally hold resources that need explicit shutdown.
/// Implementations should provide a `close()` method to release those
/// resources; callers can invoke it during application shutdown.
abstract class PaymentsService {
  /// Creates a payment with the underlying provider based on the [intent].
  Future<ZenResult<Payment>> createPayment(PaymentIntent intent);

  /// Confirms or authorizes a payment previously created.
  Future<ZenResult<Payment>> confirmPayment(
    String paymentId, {
    Map<String, dynamic>? confirmationData,
  });

  /// Refunds a completed payment.
  Future<ZenResult<Payment>> refundPayment(String paymentId, {String? reason});

  /// Release any owned resources (transport clients, sockets, etc.).
  ///
  /// Implementations that don't own resources can perform a no-op.
  FutureOr<void> close();
}

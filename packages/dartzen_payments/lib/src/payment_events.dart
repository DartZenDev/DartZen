import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import 'payment_status.dart';

const _scope = 'payments';

/// Telemetry payload builder for payment events.
///
/// The payload is intentionally minimal to avoid overexposure of domain
/// objects and to remain compliant-ready for future privacy policies:
/// - paymentId
/// - intentId
/// - provider
/// - amountMinor
/// - currency
/// - status
///
/// No raw `Payment` objects or provider responses are emitted.
TelemetryEvent paymentInitiated({
  required String paymentId,
  required String intentId,
  required String provider,
  required int amountMinor,
  required String currency,
  DateTime? timestamp,
}) => TelemetryEvent(
  name: 'payment.initiated',
  timestamp: (timestamp ?? DateTime.now()).toUtc(),
  scope: _scope,
  source: TelemetrySource.server,
  payload: {
    'paymentId': paymentId,
    'intentId': intentId,
    'provider': provider,
    'amountMinor': amountMinor,
    'currency': currency,
    'status': PaymentStatus.initiated.name,
  },
);

/// Telemetry payload builder for payment completion.
/// See `paymentInitiated` for payload design considerations.
TelemetryEvent paymentCompleted({
  required String paymentId,
  required String intentId,
  required String provider,
  required int amountMinor,
  required String currency,
  DateTime? timestamp,
}) => TelemetryEvent(
  name: 'payment.completed',
  timestamp: (timestamp ?? DateTime.now()).toUtc(),
  scope: _scope,
  source: TelemetrySource.server,
  payload: {
    'paymentId': paymentId,
    'intentId': intentId,
    'provider': provider,
    'amountMinor': amountMinor,
    'currency': currency,
    'status': PaymentStatus.completed.name,
  },
);

/// Telemetry payload builder for payment failure.
/// Same minimal payload with optional `reason` when available.
TelemetryEvent paymentFailed({
  required String paymentId,
  required String intentId,
  required String provider,
  required int amountMinor,
  required String currency,
  String? reason,
  DateTime? timestamp,
}) => TelemetryEvent(
  name: 'payment.failed',
  timestamp: (timestamp ?? DateTime.now()).toUtc(),
  scope: _scope,
  source: TelemetrySource.server,
  payload: {
    'paymentId': paymentId,
    'intentId': intentId,
    'provider': provider,
    'amountMinor': amountMinor,
    'currency': currency,
    'status': PaymentStatus.failed.name,
    if (reason != null) 'reason': reason,
  },
);

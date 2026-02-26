import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:meta/meta.dart';

import '../http_client.dart';
import '../payment.dart';
import '../payment_error.dart';
import '../payment_events.dart';
import '../payment_intent.dart';
import '../payments_service.dart';
import '../provider_error_mapper.dart';
import 'adyen_mapper.dart';
import 'adyen_models.dart';

/// Internal: provider adapter (Adyen). Not part of the public API.
/// Do not import `package:dartzen_payments/src/...` from outside this package.
///
/// Configuration for Adyen payments integration.
class AdyenPaymentsConfig {
  /// Adyen API base URL.
  final String baseUrl;

  /// Private API key for server-to-server calls.
  final String apiKey;

  /// Merchant account identifier.
  final String merchantAccount;

  /// Creates an Adyen configuration object.
  const AdyenPaymentsConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.merchantAccount,
  });
}

/// Adyen implementation of [PaymentsService].
@internal
final class AdyenPaymentsService implements PaymentsService {
  /// Creates an Adyen payments service.
  AdyenPaymentsService(
    this._config, {
    PaymentsHttpClient? client,
    TelemetryClient? telemetry,
    AdyenPaymentMapper mapper = const AdyenPaymentMapper(),
  }) : _client = client ?? DefaultPaymentsHttpClient(baseUrl: _config.baseUrl),
       _ownsClient = client == null,
       _telemetry = telemetry,
       _mapper = mapper;

  final AdyenPaymentsConfig _config;
  final PaymentsHttpClient _client;
  final TelemetryClient? _telemetry;
  final AdyenPaymentMapper _mapper;
  final bool _ownsClient;

  @override
  Future<ZenResult<Payment>> createPayment(PaymentIntent intent) async {
    final response = await _client.post('/payments', {
      'merchantAccount': _config.merchantAccount,
      'reference': intent.id,
      'amount': {'value': intent.amountMinor, 'currency': intent.currency},
      if (intent.description != null) 'description': intent.description,
      if (intent.metadata != null) 'metadata': intent.metadata,
    }, headers: _headers(intent.idempotencyKey));

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(modelResult.dataOrNull!);

    await _emit(
      paymentInitiated(
        paymentId: payment.id,
        intentId: payment.intentId,
        provider: payment.provider,
        amountMinor: payment.amountMinor,
        currency: payment.currency,
      ),
    );

    return ZenResult.ok(payment);
  }

  @override
  Future<ZenResult<Payment>> confirmPayment(
    String paymentId, {
    Map<String, dynamic>? confirmationData,
  }) async {
    final response = await _client.post(
      '/payments/$paymentId/confirm',
      confirmationData,
      headers: _headers(null),
    );

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(modelResult.dataOrNull!);

    await _emit(
      paymentCompleted(
        paymentId: payment.id,
        intentId: payment.intentId,
        provider: payment.provider,
        amountMinor: payment.amountMinor,
        currency: payment.currency,
      ),
    );

    return ZenResult.ok(payment);
  }

  @override
  Future<ZenResult<Payment>> refundPayment(
    String paymentId, {
    String? reason,
  }) async {
    final response = await _client.post('/payments/$paymentId/refund', {
      'reason': ?reason,
    }, headers: _headers(null));

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(modelResult.dataOrNull!);

    await _emit(
      paymentCompleted(
        paymentId: payment.id,
        intentId: payment.intentId,
        provider: payment.provider,
        amountMinor: payment.amountMinor,
        currency: payment.currency,
      ),
    );

    return ZenResult.ok(payment);
  }

  Map<String, String> _headers(String? idempotencyKey) => {
    'Authorization': 'Api-Key ${_config.apiKey}',
    'Idempotency-Key': ?idempotencyKey,
  };

  ZenResult<AdyenPaymentModel> _parseModel(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const ZenResult.err(
        PaymentProviderError('Unexpected response payload'),
      );
    }
    return ZenResult.ok(AdyenPaymentModel.fromJson(data));
  }

  Future<void> _emit(TelemetryEvent event) async {
    if (_telemetry == null) return;
    await _telemetry.emitEvent(event);
  }

  /// Closes the owned transport client when created internally.
  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

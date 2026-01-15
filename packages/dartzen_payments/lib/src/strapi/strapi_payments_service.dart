import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:dartzen_transport/dartzen_transport.dart';

import '../payment.dart';
import '../payment_error.dart';
import '../payment_events.dart';
import '../payment_intent.dart';
import '../payments_service.dart';
import '../provider_error_mapper.dart';
import 'strapi_mapper.dart';
import 'strapi_models.dart';

/// Configuration for Strapi payments integration.
class StrapiPaymentsConfig {
  /// Strapi API base URL.
  final String baseUrl;

  /// Bearer token for authenticated requests.
  final String apiToken;

  /// Creates a Strapi payments configuration.
  const StrapiPaymentsConfig({required this.baseUrl, required this.apiToken});
}

/// Strapi implementation of [PaymentsService].
final class StrapiPaymentsService implements PaymentsService {
  /// Creates a Strapi payments service.
  StrapiPaymentsService(
    this._config, {
    ZenClient? client,
    TelemetryClient? telemetry,
    StrapiPaymentMapper mapper = const StrapiPaymentMapper(),
  }) : _client = client ?? ZenClient(baseUrl: _config.baseUrl),
       _ownsClient = client == null,
       _telemetry = telemetry,
       _mapper = mapper;

  final StrapiPaymentsConfig _config;
  final ZenClient _client;
  final TelemetryClient? _telemetry;
  final StrapiPaymentMapper _mapper;
  final bool _ownsClient;

  @override
  Future<ZenResult<Payment>> createPayment(PaymentIntent intent) async {
    final response = await _client.post('/payments', {
      'intent_id': intent.id,
      'amount_minor': intent.amountMinor,
      'currency': intent.currency,
      'idempotency_key': intent.idempotencyKey,
      if (intent.description != null) 'description': intent.description,
      if (intent.metadata != null) 'metadata': intent.metadata,
    }, headers: _headers());

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(model: modelResult.dataOrNull!);

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
      headers: _headers(),
    );

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(model: modelResult.dataOrNull!);

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
    final response = await _client.post(
      '/payments/$paymentId/refund',
      reason == null ? null : {'reason': reason},
      headers: _headers(),
    );

    if (response.isError) {
      return ZenResult.err(mapResponseToError(response));
    }

    final modelResult = _parseModel(response.data);
    if (modelResult.isFailure) {
      return ZenResult.err(modelResult.errorOrNull!);
    }

    final payment = _mapper.toDomain(model: modelResult.dataOrNull!);

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

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_config.apiToken}',
  };

  ZenResult<StrapiPaymentModel> _parseModel(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const ZenResult.err(
        PaymentProviderError('Unexpected response payload'),
      );
    }
    return ZenResult.ok(StrapiPaymentModel.fromJson(data));
  }

  Future<void> _emit(TelemetryEvent event) async {
    if (_telemetry == null) return;
    await _telemetry.emitEvent(event);
  }

  /// Closes the owned transport client when created internally.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

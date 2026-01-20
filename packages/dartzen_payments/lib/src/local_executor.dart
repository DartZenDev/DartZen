import 'dart:async';

import 'package:meta/meta.dart';

import 'executor.dart';
import 'payment_descriptor.dart';
import 'payment_error.dart';
import 'payment_intent.dart';
import 'payment_result.dart';
import 'payments_service.dart';

class _CacheEntry {
  final PaymentResult result;
  final DateTime storedAt;

  _CacheEntry(this.result) : storedAt = DateTime.now().toUtc();
}

/// A LocalExecutor that delegates to internal provider implementations.
///
/// This executor uses an explicit provider map rather than global discovery.
@immutable
final class LocalExecutor implements Executor {
  final Map<String, PaymentsService> _providers;
  final Map<String, _CacheEntry> _idempotencyCache = {};

  /// Create a LocalExecutor with a map of providerName -> PaymentsService.
  /// Example provider names: 'adyen', 'strapi'.
  LocalExecutor({required Map<String, PaymentsService> providers})
    : _providers = Map.unmodifiable(providers);

  @override
  Future<void> start() async {}

  @override
  Future<void> shutdown() async {
    // Close providers that expose a `close()` implementation.
    for (final p in _providers.values) {
      try {
        // `close()` may be synchronous or return a Future.
        await Future<void>.value(p.close());
      } catch (_) {
        // Best-effort: ignore provider shutdown failures.
      }
    }
  }

  @override
  Future<PaymentResult> execute(
    PaymentDescriptor descriptor, {
    Map<String, Object?>? payload,
    String? idempotencyKey,
  }) async {
    // Validate descriptor
    if (descriptor.id.trim().isEmpty) {
      throw ArgumentError('descriptor.id must be non-empty');
    }

    final policy = descriptor.policy;

    // Idempotency check
    if (idempotencyKey != null) {
      final cached = _idempotencyCache[idempotencyKey];
      if (cached != null) {
        final age = DateTime.now().toUtc().difference(cached.storedAt);
        if (age <= policy.idempotencyWindow) return cached.result;
      }
    }

    // Provider selection: descriptor.metadata['provider'] or payload['provider']
    final providerName =
        (descriptor.metadata['provider'] ?? payload?['provider']) as String?;
    if (providerName == null) {
      return const PaymentResult.failed(
        PaymentStateError(
          'Provider selection required in descriptor.metadata["provider"] or payload["provider"]',
        ),
      );
    }

    final provider = _providers[providerName];
    if (provider == null) {
      return PaymentResult.failed(
        PaymentProviderError('Unknown provider: $providerName'),
      );
    }

    // Execute with retries
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final result = await _invokeProvider(
          provider,
          descriptor,
          payload,
          idempotencyKey,
        );

        // Cache idempotency
        if (idempotencyKey != null) {
          _idempotencyCache[idempotencyKey] = _CacheEntry(result);
        }

        return result;
      } catch (e) {
        // Non-returnable exception; convert to PaymentProviderError and retry as needed
        if (attempt > policy.maxRetries) {
          return PaymentResult.failed(
            PaymentProviderError(
              'Execution failed after $attempt attempts: $e',
              metadata: {'error': e.toString()},
            ),
          );
        }
        // backoff
        await Future<void>.delayed(policy.backoffBase * attempt);
        continue;
      }
    }
  }

  Future<PaymentResult> _invokeProvider(
    PaymentsService provider,
    PaymentDescriptor descriptor,
    Map<String, Object?>? payload,
    String? idempotencyKey,
  ) async {
    switch (descriptor.operation) {
      case PaymentOperation.charge:
      case PaymentOperation.authorize:
        // Build PaymentIntent from payload
        final intentId = payload?['intentId'] as String? ?? '';
        final amount = payload?['amountMinor'] as int?;
        final currency = payload?['currency'] as String?;
        final idem = idempotencyKey ?? (payload?['idempotencyKey'] as String?);

        if (intentId.isEmpty ||
            amount == null ||
            currency == null ||
            idem == null) {
          return const PaymentResult.failed(
            PaymentInvalidAmountError(
              'Missing intentId/amountMinor/currency/idempotencyKey',
            ),
          );
        }

        final intentResult = PaymentIntent.create(
          id: intentId,
          amountMinor: amount,
          currency: currency,
          idempotencyKey: idem,
          description: payload?['description'] as String?,
        );

        if (intentResult.isFailure) {
          final zenErr = intentResult.errorOrNull!;
          return PaymentResult.failed(
            PaymentInvalidAmountError(zenErr.message),
          );
        }

        final createResult = await provider.createPayment(
          intentResult.dataOrNull!,
        );
        if (createResult.isFailure) {
          return PaymentResult.failed(
            createResult.errorOrNull! as PaymentError,
          );
        }

        return PaymentResult.success(
          providerReference: createResult.dataOrNull!.providerReference,
        );

      case PaymentOperation.capture:
      case PaymentOperation.cancel:
      case PaymentOperation.refund:
        final paymentId = payload?['paymentId'] as String?;
        if (paymentId == null) {
          return const PaymentResult.failed(
            PaymentStateError('paymentId required for this operation'),
          );
        }
        if (descriptor.operation == PaymentOperation.refund) {
          final reason = payload?['reason'] as String?;
          final refundResult = await provider.refundPayment(
            paymentId,
            reason: reason,
          );
          if (refundResult.isFailure) {
            return PaymentResult.failed(
              refundResult.errorOrNull! as PaymentError,
            );
          }

          return PaymentResult.success(
            providerReference: refundResult.dataOrNull!.providerReference,
          );
        }
        // capture / cancel use confirmPayment
        final confirmResult = await provider.confirmPayment(
          paymentId,
          confirmationData:
              payload?['confirmationData'] as Map<String, dynamic>?,
        );
        if (confirmResult.isFailure) {
          return PaymentResult.failed(
            confirmResult.errorOrNull! as PaymentError,
          );
        }

        return PaymentResult.success(
          providerReference: confirmResult.dataOrNull!.providerReference,
        );
    }
  }
}

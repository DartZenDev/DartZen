# DartZen Payments

[![pub package](https://img.shields.io/pub/v/dartzen_payments.svg)](https://pub.dev/packages/dartzen_payments)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Payment domain and provider implementations for DartZen (Strapi, Adyen).

> This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🧘 What is dartzen_payments?

`dartzen_payments` defines the payment domain (intent, payment, status, errors) and concrete
provider integrations for Strapi and Adyen. It enforces deterministic payment lifecycle,
idempotent operations, and telemetry hooks.

## 🤔 Why does it exist?

DartZen needs a first-class payment capability that is:

- Explicit about lifecycle and errors
- Deterministic and idempotent by default (idempotency keys required)
- Ready for production without mocks or stubs
- Observable via structured telemetry

## 🧩 How it fits into DartZen

- Uses `dartzen_core` for results/errors and validation
- Uses `dartzen_transport` for HTTP with consistent headers and codecs
- Emits telemetry via `dartzen_telemetry` using package-local helpers
- Localizes user-facing strings via `dartzen_localization` messages layer

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_payments:
    path: ../dartzen_payments
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_payments: ^latest_version
```

## 🚀 Minimal usage example

```dart
import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:dartzen_payments/src/strapi/strapi_payments_service.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

Future<void> main() async {
  final telemetry = TelemetryClient(store: /* your store */);
  final service = StrapiPaymentsService(
    const StrapiPaymentsConfig(
      baseUrl: 'https://payments.example.com',
      apiToken: 'strapi_token',
    ),
    telemetry: telemetry,
  );

  final intent = PaymentIntent.create(
    id: 'intent-1',
    amountMinor: 1999,
    currency: 'EUR',
    idempotencyKey: 'idem-123',
    description: 'Order #123',
  ).dataOrNull!;

  final result = await service.createPayment(intent);
  result.fold(
    (payment) => print('Payment created: ${payment.id} status=${payment.status}'),
    (error) => print('Payment failed: ${error.message}'),
  );
}
```

## ⚠️ Error handling philosophy

- All provider failures map into the unified `PaymentError` sealed hierarchy
- Provider-specific details live only in `PaymentProviderError.internalData`
- Validation errors use `ZenValidationError` through `PaymentIntent.create`

## 📡 Telemetry

Use the package-local helpers in `payment_events.dart` to emit:

- `payment.initiated`
- `payment.completed`
- `payment.failed`

Payload fields: `paymentId`, `intentId`, `status`, `provider`, `amountMinor`, `currency`.

## 🔒 Idempotency

`PaymentIntent.idempotencyKey` is required and must be provided by callers. Providers rely on it to
ensure safe retries; no automatic business-level retries happen inside the package.

## 🚫 Out of scope for v0.0.1

- Subscriptions
- Recurring payments
- Invoices
- Taxes
- Partial captures
- Webhooks

## 🛡️ Stability guarantees

- Version: `0.0.1`
- Deterministic behavior across environments
- No global state; explicit configuration only

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

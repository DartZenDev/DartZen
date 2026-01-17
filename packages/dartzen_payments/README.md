# DartZen Payments

[![pub package](https://img.shields.io/pub/v/dartzen_payments.svg)](https://pub.dev/packages/dartzen_payments)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Deterministic payments. Explicit lifecycle. Zero ambiguity.**

Payment domain and production-grade provider integrations for DartZen (Strapi, Adyen).

> Part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 What is `dartzen_payments`?

`dartzen_payments` is a **strict payment domain** with **real provider implementations**.

Not helpers. Not SDK wrappers. A payment system that treats money as a **state machine**, not a side effect.

## 💣 Why this package exists

Most payment codebases fail in the same places:

- unclear lifecycle
- retry chaos
- silent double-charges
- provider-specific error soup
- no observability

`dartzen_payments` exists to **remove ambiguity**.

You get:

- Explicit payment lifecycle
- Mandatory idempotency
- Deterministic state transitions
- Unified error model
- Telemetry-first design

No magic. No guessing.

---

## 🧠 Core principles

- **Lifecycle is explicit**: Every payment has a well-defined state.
- **Idempotency is mandatory**: No key → no payment.
- **Providers are replaceable**: Domain first. Providers second.
- **Errors are semantic**: One unified error hierarchy.
- **Observability is built-in**: Payments emit events, not surprises.

## 🧩 How it fits into DartZen

- `dartzen_core`: Results, errors, validation
- `dartzen_transport`: HTTP with consistent headers and codecs
- `dartzen_telemetry`: Structured payment events
- `dartzen_localization`: User-facing messages

No hidden dependencies. No global state.

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_payments:
    path: ../dartzen_payments
```

### External usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_payments: ^latest_version
```

## 🚀 Minimal usage

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
    (payment) =>
      print('Payment ${payment.id} → ${payment.status}'),
    (error) =>
      print('Payment failed: ${error.message}'),
  );
}
```

## 🧱 Payment lifecycle (simplified)

- `intent_created`
- `payment_created`
- `completed` | `failed`

No hidden transitions. No implicit retries.

## ⚠️ Error model

- All failures map to **`PaymentError`**
- Provider details are isolated in: `PaymentProviderError.internalData`
- Validation errors are caught **before** provider calls

Your business logic never depends on provider-specific enums.

## 🔁 Idempotency

Idempotency is **required**, not optional.

- `PaymentIntent.idempotencyKey` must be provided
- Providers rely on it for safe retries
- Package never retries business logic implicitly

If a request is retried, the outcome is deterministic.

## 📡 Telemetry

Use the package-local helpers in `payment_events.dart` to emit:

- `payment.initiated`
- `payment.completed`
- `payment.failed`

## 🚫 Explicitly out of scope (v0.0.1)

- Subscriptions
- Recurring payments
- Invoices
- Taxes
- Partial captures
- Webhooks

## 🛡 Stability guarantees

- Version: `0.0.1`
- Deterministic behavior across environments
- No singletons
- No global mutable state
- Explicit configuration only

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

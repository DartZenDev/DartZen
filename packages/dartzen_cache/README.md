# DartZen Cache

[![pub package](https://img.shields.io/pub/v/dartzen_core.svg)](https://pub.dev/packages/dartzen_core)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Simple, explicit, and predictable caching for the DartZen ecosystem.**

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🧘🏻 What is dartzen_cache?

`dartzen_cache` is a foundational, domain-agnostic caching package with automatic backend selection:

- **Development mode** — In-memory cache for local development and tests
- **Production mode** — GCP Memorystore (Redis) for production environments

The backend is automatically selected based on the `dzIsPrd` environment constant from `dartzen_core`.

## 🤔 Why does it exist?

DartZen requires a **boring, predictable cache** that:

- Has no hidden behavior
- Fails fast in development
- Provides safe UX in production
- Is easy to test and reason about
- Works consistently across environments
- Automatically adapts to deployment context

## 🧩 How it fits into DartZen

`dartzen_cache` is a **foundation-layer package**. It provides:

- A single, stable caching interface
- Automatic backend selection based on environment
- Zero magic, zero surprises
- Clear ownership boundaries

Other DartZen packages can depend on it for caching needs without coupling to specific infrastructure.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_cache:
    path: ../dartzen_cache
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_cache: ^latest_version
```

## 🚀 Usage

### Basic Usage

The cache automatically selects the appropriate backend based on your environment:

```dart
import 'package:dartzen_cache/dartzen_cache.dart';

void main() async {
  // Create configuration
  // In dev: uses in-memory cache (host/port ignored)
  // In prod: uses Memorystore with specified host/port
  final config = CacheConfig(
    defaultTtl: Duration(minutes: 10),
    memorystoreHost: 'memorystore.example.com',
    memorystorePort: 6379,
  );

  final cache = CacheFactory.create(config);

  // Set a value
  await cache.set('user:123', {'name': 'Alice', 'role': 'admin'});

  // Get a value
  final user = await cache.get<Map<String, dynamic>>('user:123');
  print(user); // {name: Alice, role: admin}

  // Delete a key
  await cache.delete('user:123');

  // Clear all keys
  await cache.clear();
}
```

### Environment Configuration

Set the environment via compile-time constant:

```bash
# Development mode (in-memory cache)
dart run

# Production mode (Memorystore)
dart run --define=DZ_ENV=prd
```
  );

  final cache = CacheFactory.create(config);

  await cache.set('session:abc', {'userId': '456'});
  final session = await cache.get<Map<String, dynamic>>('session:abc');
}
```

### Custom TTL per operation

```dart
// Override default TTL for specific keys
await cache.set(
  'temp:token',
  'xyz',
  ttl: Duration(seconds: 30),
);
```

## 🛑 Error Handling Philosophy

`dartzen_cache` **does not swallow exceptions**. All errors are surfaced explicitly:

- `CacheConnectionError` — Cannot connect to cache backend
- `CacheSerializationError` — Cannot serialize/deserialize value
- `CacheOperationError` — General cache operation failure

Applications must handle errors appropriately:

```dart
try {
  await cache.set('key', value);
} on CacheConnectionError catch (e) {
  logger.error('Cache unavailable', error: e);
  // Fallback logic
} on CacheSerializationError catch (e) {
  logger.error('Invalid cache value', error: e);
}
```

## 🛡️ Stability Guarantees

- **Version 0.0.1** — Initial release
- **Breaking changes** may occur before 1.0.0
- **API stability** prioritized once 1.0.0 is reached

This package follows [Semantic Versioning 2.0.0](https://semver.org/).

## 🏗️ Architecture Principles

`dartzen_cache` follows the Zen Architecture:

- **Explicit over implicit** — No magic, no hidden state
- **Flat structure** — No unnecessary abstraction layers
- **Fail fast** — Errors are surfaced immediately
- **Deterministic** — Same inputs produce same outputs
- **Boring is good** — Predictable is better than clever

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

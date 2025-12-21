# dartzen_infrastructure_cache

[![pub package](https://img.shields.io/pub/v/dartzen_infrastructure_cache.svg)](https://pub.dev/packages/dartzen_infrastructure_cache)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A transparent, pluggable caching accelerator for DartZen Identity infrastructure.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

The `dartzen_infrastructure_cache` package provides a transient caching layer that wraps `IdentityProvider` and `IdentityHooks` to reduce latency and infrastructure costs (e.g., Firestore reads).

## 🏗 Why It Exists

In many Identity-driven applications, identity metadata (roles, metadata, state) is read frequently but changes rarely. This package allows services to maintain high responsiveness by keeping hot identity data in memory without leaking domain logic into the caching mechanism.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_cache:
    path: ../dartzen_infrastructure_cache
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_cache: ^latest_version
```

## 🚀 Usage

```dart
final firestoreRepository = FirestoreIdentityRepository(firestore: FirebaseFirestore.instance);

final identityProvider = CacheIdentityRepository(
  delegate: firestoreRepository,
  store: createCacheStore(), // Pluggable backend (InMemory or Memorystore)
  config: const CacheConfig(
    ttl: Duration(minutes: 5),
    maxEntries: 1000,
  ),
);

// Subsequent calls will hit the cache
final result = await identityProvider.getIdentity('user_123');
```

## 🛡 Stability Guarantees

This package is in early development (`0.0.1`). Always falls back to the underlying delegate. Does not contain any domain logic.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

# DartZen Infrastructure Identity

[![pub package](https://img.shields.io/pub/v/dartzen_infrastructure_identity.svg)](https://pub.dev/packages/dartzen_infrastructure_identity)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Concrete infrastructure adapters for DartZen Identity.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

This package connects the pure **Identity Domain** with real-world authentication systems. It implements domain-defined ports and provides mapping logic to translate external authentication facts (claims, subjects) into stable domain [Identity] aggregates.

## 🤔 Why it exists

In Zen Architecture, the domain must remain pure and oblivious to infrastructure details like HTTP, JWTs, or specific IdP SDKs. This package acts as the bridge:
1. It implements `IdentityProvider`, `IdentityHooks`, and `IdentityCleanup` interfaces.
2. It translates IdP-specific data into domain models.
3. It handles side-effects of identity lifecycle changes (e.g., token revocation).

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_identity:
    path: ../dartzen_infrastructure_identity
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_identity: ^latest_version
```

## 🚀 Usage

```dart
final mapper = IdentityMapper();
final external = InfrastructureExternalIdentity(
  subject: 'user_123',
  claims: {
    'email_verified': true,
    'roles': ['MEMBER'],
  },
);

final identityResult = mapper.mapToDomain(
  id: IdentityId('internal_id'),
  external: external,
  createdAt: ZenTimestamp.now(),
);
```

## 🐛 Error Handling

This package maps infrastructure failures (network timeouts, IdP errors) to semantic `ZenResult` errors. It never leaks raw IdP exceptions to the domain.

## 🛡️ Stability Guarantees

Version `0.0.1` is an initial release. The internal mapping logic and implementation details may change, but the implementation will always adhere to the interfaces defined in `dartzen_identity_domain`.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

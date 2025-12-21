# DartZen Identity Domain

[![pub package](https://img.shields.io/pub/v/dartzen_localization.svg)](https://pub.dev/packages/dartzen_localization)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Domain Identity module for DartZen. Represents identity as a semantic, stable domain concept.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 📚 Overview

`dartzen_identity_domain` provides the core domain types and logic for managing identity within a DartZen application. It is strictly decoupled from authentication mechanisms, infrastructure providers (like Firebase or GCP Identity Platform), and transport layers.

In Zen Architecture, Identity is a permanent anchor for authority and state, while Authentication is a transient infrastructure concern.

## 🤖 Features

- **IdentityId**: A strongly-typed, validated Value Object for identifiers.
- **IdentityLifecycle**: Explicit state management (pending, active, revoked, disabled).
- **Authority Model**: Coarse-grained Roles and fine-grained Capabilities.
- **Domain Errors**: Semantic, infrastructure-agnostic failure types.
- **Localization**: Package-scoped messages for identity-related feedback.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_identity_domain:
    path: ../dartzen_identity_domain
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_identity_domain: ^latest_version
```

## 🚀 Usage

### 1. Creating an Identity

```dart
final idResult = IdentityId.create('user_123');
if (idResult.isSuccess) {
  final identity = Identity.createPending(id: idResult.data);
  print(identity.lifecycle.state); // IdentityState.pending
}
```

### 2. Authority Evaluation

```dart
final capability = Capability('can_edit');
final result = identity.can(capability);

result.fold(
  onSuccess: (canAct) => print('Can act: $canAct'),
  onFailure: (error) => print('Error: ${error.message}'),
);
```

## 🐛 Error Handling Philosophy

This package uses `ZenResult` for all operations that can fail. Errors are modeled as semantic domain types:
- `IdentityRevokedError`
- `IdentityInactiveError`
- `InsufficientPermissionsError`

## 🛡️ Stability Guarantees

This package is in early development (`0.0.1`). The domain model is intended to be stable, but API changes may occur as the ecosystem evolves.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

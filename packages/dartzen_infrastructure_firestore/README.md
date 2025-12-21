# DartZen Infrastructure Firestore

[![pub package](https://img.shields.io/pub/v/dartzen_infrastructure_firestore.svg)](https://pub.dev/packages/dartzen_infrastructure_firestore)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

This package implements a **pure persistence adapter** for DartZen Identity using Cloud Firestore.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

*   Provide concrete implementation of `IdentityRepository` (implicit) and `IdentityProvider` (domain).
*   Map domain aggregates to/from Firestore documents.
*   Isolate all Firestore-specific logic, types, and dependencies from the domain layer.

## 🏗 Architecture

This package strictly follows the **Zen Architecture**:
*   **Adapter Pattern**: It adapts Firestore's document model to DartZen's domain model.
*   **Domain Purity**: It depends on `dartzen_identity_domain` but never modifies it.
*   **Contract-Driven**: It uses `dartzen_identity_contract` concepts where applicable.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_firestore:
    path: ../dartzen_infrastructure_firestore
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_firestore: ^latest_version
```

## 🚀 Usage

This package is intended for use by the application layer (composition root) to configure the identity system.

```dart
final firestoreRepository = FirestoreIdentityRepository(
  firestore: FirebaseFirestore.instance,
);

// Use as IdentityProvider (Read)
final identityProvider = firestoreRepository;

// Use as Repository (Write - Application Layer Only)
await firestoreRepository.save(newIdentity);
```

## 🛡️ Stability & Guarantees

*   **Version 0.0.1**: Initial release. API may change.
*   **Error Handling**: All operations return `ZenResult` and map Firestore exceptions to semantic `ZenFailure` types.
*   **Type Safety**: Strict linting and analysis enabled.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

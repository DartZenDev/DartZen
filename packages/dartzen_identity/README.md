# DartZen Identity

[![pub package](https://img.shields.io/pub/v/dartzen_identity.svg)](https://pub.dev/packages/dartzen_identity)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Cohesive identity feature package for DartZen.**

This package follows the **feature-first** principle, providing a flat structure and Firestore-first persistence.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🧘 Architecture

- **Feature-first**: Identity is a single feature, not a collection of technical layers.
- **Flat structure**: No unnecessary nesting. One repository, one mapper, one source of truth.
- **Firestore-first**: Persistence is handled via `dartzen_firestore` primitives.
- **Strict Boundaries**: Prevents Firestore SDK leakage into domain logic via `ZenFirestoreData` and `ZenFirestoreDocument`.

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_identity:
    path: ../dartzen_identity
```

### External Usage

```yaml
dependencies:
  dartzen_identity:
    version: ^latest_version
```

## 🚀 Usage

### 1. Identity Domain Model

The `Identity` aggregate manages the lifecycle and authority.

```dart
final identity = Identity(
  id: IdentityId.create('user_123'),
  lifecycle: IdentityLifecycle.initial(),
  authority: Authority(roles: {Role.user}),
  createdAt: ZenTimestamp.now(),
);
```

### 2. Firestore Repository

Use `IdentityRepository` to persist and retrieve identities.

```dart
final repository = IdentityRepository(firestore: firestore);

// Create
await repository.createIdentity(identity);

// Get by ID
final result = await repository.getIdentityById(identity.id);

// Lifecycle transition
await repository.verifyEmail(identity.id);
```

### 3. Contracts for Transport

`IdentityContract` provides a serializable representation for client-server communication.

```dart
final contract = IdentityContract.fromDomain(identity);
final json = contract.toJson();
```

## ⚙️ Real-world Usage

### Repository Integration
Use the `IdentityRepository` to manage identity persistence in Firestore and handle domain-specific errors.

```dart
final repo = IdentityRepository(firestore: FirebaseFirestore.instance);

// Get identity and handle specific errors
final result = await repo.getIdentityById(id);
result.fold(
  (identity) => print('Found: ${identity.id}'),
  (error) {
    if (error is ZenNotFoundError) {
      print('Identity does not exist');
    } else {
      print('Unknown error: ${error.message}');
    }
  },
);
```

### Mapping for Storage
Use `IdentityMapper` to convert between Firestore data and domain models without leaking SDK details.

```dart
// To Firestore
final data = IdentityMapper.toFirestore(identity);
await firestore.collection('users').doc(id.value).set(data);

// From Firestore
final result = IdentityMapper.fromFirestore(doc.id, doc.data()!);
```

## 🛡️ Stability Guarantees

This package is in early development (0.0.1). Expect breaking changes as the DartZen ecosystem evolves.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

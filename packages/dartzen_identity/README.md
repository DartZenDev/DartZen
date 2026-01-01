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

### 4. Server-Side Token Verification

For server-side applications, use the `server.dart` library to verify ID tokens issued by Firebase Auth / Identity Platform.

```dart
import 'package:dartzen_identity/server.dart';

final verifier = IdentityTokenVerifier(
  config: IdentityTokenVerifierConfig(
    projectId: 'your-gcp-project-id',
    emulatorHost: 'localhost:9099', // only used in dev mode
  ),
);

// Verify a token from an HTTP request
final result = await verifier.verifyToken(idToken);

result.fold(
  (identity) {
    // Token is valid
    print('Authenticated user: ${identity.userId}');
    print('Email: ${identity.email}');
  },
  (error) {
    // Token is invalid
    if (error is ZenUnauthorizedError) {
      print('Invalid or expired token');
    } else {
      print('Verification error: ${error.message}');
    }
  },
);

// Don't forget to close when done
verifier.close();
```

#### Production vs Emulator

The verifier automatically switches between production and emulator endpoints:

- **Production (`dzIsPrd == true`)**: Uses Google Identity Toolkit cloud endpoint
- **Development (`dzIsPrd == false`)**: Uses Identity Toolkit Emulator at configured host

Set the environment when running:
```bash
# Development mode with emulator
dart run -DDZ_ENV=dev your_server.dart

# Production mode
dart run -DDZ_ENV=prd your_server.dart
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

## 📦 Package Structure

```
lib/
  dartzen_identity.dart      # Main library (domain + repository)
  server.dart                # Server-only library (token verification)
  src/
    identity_models.dart     # Domain models
    identity_contracts.dart  # Serializable transport contracts
    identity_mapper.dart     # Firestore mapping
    identity_repository.dart # Firestore repository
    server/
      identity_token_verifier.dart  # Server-side token verification
```

**Important**: The `server.dart` library should only be imported by server-side code. Client applications should use the main `dartzen_identity.dart` library.

## 🛡️ Stability Guarantees

This package is in early development (0.1.0). Expect breaking changes as the DartZen ecosystem evolves.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

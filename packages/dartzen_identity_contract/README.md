# DartZen Identity Contract

[![pub package](https://img.shields.io/pub/v/dartzen_transport.svg)](https://pub.dev/packages/dartzen_transport)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The **contract layer** for the DartZen identity domain.

This package exposes **serializable data structures** and **error contracts** representing identity concepts. It is designed to be shared between the domain logic (server-side) and consumers (clients, transport layers), ensuring a unified language across the system.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

*   **Defines Identity Models**: `IdentityId`, `Role`, `Capability`, `Authority`, `IdentityLifecycleState`.
*   **Defines Error Contracts**: `IdentityFailure`, `AuthorityFailure`, `ValidationFailure`.
*   **Serialization Support**: Built-in `toJson` and `fromJson` for easy transport over HTTP/WebSocket.
*   **Zero Logic**: Contains no business logic or infrastructure dependencies. Pure data and contracts.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_identity_contract: 
    path: ../dartzen_identity_contract
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_identity_contract: ^latest_version
```

## 🚀 Usage

### Models

Use `IdentityId` for type-safe identifiers and `Authority` to represent permissions.

```dart
import 'package:dartzen_identity_contract/dartzen_identity_contract.dart';

void main() {
  // Create an ID
  final id = IdentityId('user-123');

  // Define Capabilities
  final readPosts = Capability(resource: 'posts', action: 'read');
  final writePosts = Capability(resource: 'posts', action: 'write');

  // Define a Role
  final adminRole = Role(
    id: 'admin',
    name: 'Administrator',
    capabilities: [readPosts, writePosts],
  );

  // Create Authority
  final authority = Authority(
    identityId: id,
    roles: [adminRole],
    effectiveCapabilities: [readPosts, writePosts],
  );

  print(authority.hasCapability('posts', 'write')); // true
}
```

### Serialization

All models support standard JSON serialization.

```dart
// Serialize
final jsonMap = authority.toJson();

// Deserialize
final restored = Authority.fromJson(jsonMap);
```

### Errors

Use `IdentityContractFailure` implementations to return typed errors across boundaries.

```dart
Result<IdentityId, IdentityContractFailure> deleteUser(String id) {
  if (id == 'admin') {
     return Result.failure(
       AuthorityFailure.permissionDenied('users', 'delete')
     );
  }
  // ...
}
```

## 🛡️ Stability

This package adheres to Semantic Versioning. As a contract package, breaking changes will be minimized and strictly versioned.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

# DartZen Core

The **core layer** for the DartZen ecosystem.  
A framework-agnostic, zero-dependency library providing the core building blocks for robust, clean architecture in Dart.

[![pub package](https://img.shields.io/pub/v/dartzen_core.svg)](https://pub.dev/packages/dartzen_core)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🧘 Why `dartzen_core`?

In the Zen Architecture, we believe in:
- **Universality**: Code should be shared between backend (Dart/Server) and frontend (Flutter).
- **Correctness**: Invalid states should be unrepresentable.
- **Safety**: Errors should be explicit values, not unchecked exceptions.
- **Simplicity**: No magic, no reflection, minimal dependencies.

This package implements these principles by providing:
- **Functional Result primitives** (`ZenResult`) to replace exceptions.
- **Universal Response Contracts** (`BaseResponse`) for API communication.
- **Strict Value Objects** (`EmailAddress`, `ZenTimestamp`) that validate themselves on creation.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_core:
    path: ../dartzen_core
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_core: ^0.0.1
```

## 🚀 Usage Guide

### 1. Functional Results

Stop throwing exceptions. Return a `ZenResult`.

```dart
import 'package:dartzen_core/dartzen_core.dart';

ZenResult<int> divide(int a, int b) {
  if (b == 0) {
    return ZenResult.err(
      ZenValidationError('Cannot divide by zero'),
    );
  }
  return ZenResult.ok(a ~/ b);
}

void main() {
  final result = divide(10, 0);

  result.fold(
    (data) => print('Result: $data'),
    (error) => print('Error: ${error.message}'), // Prints: Error: Cannot divide by zero
  );
}
```

### 2. Universal API Responses

Ensure your server and client speak the same language.

```dart
// Server-side
BaseResponse<User> createUser(User user) {
  return BaseResponse.success(user, message: 'User created successfully');
}

// Client-side
void handleResponse(BaseResponse response) {
  if (response.success) {
    print('Success: ${response.data}');
  } else {
    print('Failed: ${response.message} (Code: ${response.errorCode})');
  }
}
```

### 3. Safe Value Objects

Don't pass raw strings around. Use validated types.

```dart
// This handles validation internally. You can't create an invalid EmailAddress.
final emailResult = EmailAddress.create('invalid-email');

if (emailResult is ZenFailure) {
  print(emailResult.error.message); // "Invalid email format"
}

// If successful, you have a safe, immutable object
final validEmail = (EmailAddress.create('zen@example.com') as ZenSuccess).data;
```

### 4. Utilities

Protect your code with `ZenGuard` and `ZenTry`.

```dart
// Convert exceptions to failures
final result = ZenTry.call(() => int.parse('not-a-number'));
// result is ZenFailure(ZenUnknownError)

// Guard clauses
final guard = ZenGuard.notNull(someValue, 'someValue');
if (guard.isFailure) return guard;
```

## 🛡️ Stability Guarantees

This package is designed to be **extremely stable**.  
Breaking changes will be avoided at all costs to ensure it can serve as a long-term foundation for large-scale applications.

## 🔮 Future

This is just the beginning. The DartZen ecosystem will grow to include:
- `dartzen_transport`: Network abstraction (Dio/Http) implementation.
- `dartzen_server`: Specialized backend tools.
- `dartzen_localization`: Shared translation management.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

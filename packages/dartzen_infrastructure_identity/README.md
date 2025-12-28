# dartzen_infrastructure_identity

[![pub package](https://img.shields.io/pub/v/dartzen_infrastructure_identity.svg)](https://pub.dev/packages/dartzen_infrastructure_identity)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Pure infrastructure adapter that bridges external authentication systems with the DartZen Identity domain.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 What it is

`dartzen_infrastructure_identity` is a **pure infrastructure adapter** that maps verified external authentication facts to domain identity operations. It answers exactly one question:

**"Given a verified external authentication result, how does it map to a domain Identity?"**

Nothing more.

## 🤔 Why it exists

In Zen Architecture, the domain must remain pure and isolated from infrastructure concerns. This package exists to:

1. Bridge **external auth facts** (from GCP Identity Toolkit, Firebase Auth, etc.) to **domain identity**
2. Delegate persistence operations to a configurable port (no direct storage)
3. Map infrastructure failures to semantic contract errors
4. Log all operations without exposing PII
5. Enable auth provider replacement without domain changes

## 📦 How it fits into DartZen

This package sits between:
- **External authentication systems** (GCP Identity Toolkit, Firebase, OAuth providers)
- **DartZen Identity Domain** (`dartzen_identity_domain`)

It implements infrastructure adapters defined by domain ports, ensuring the domain remains oblivious to:
- Authentication protocols
- Token formats
- Provider SDKs
- Network transports

## 🚀 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_identity:
    path: ../dartzen_infrastructure_identity
```

### External Usage

```yaml
dependencies:
  dartzen_infrastructure_identity: ^0.0.1
```

## 💻 Usage

### Minimal Example

```dart
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

// 1. Parse verified auth claims from your authentication system
final claims = AuthClaims(
  subject: 'firebase-uid-12345',
  providerId: 'google.com',
  email: 'user@example.com',
  emailVerified: true,
);

// 2. Create a messages instance for localization
final messages = InfrastructureIdentityMessages(
  localization: ZenLocalizationService(config: myConfig),
  language: 'en',
);

// 3. Create resolver with your persistence port implementation
final resolver = IdentityResolver(
  persistencePort: MyPersistenceImplementation(),
  messages: messages,
);

// 4. Resolve to domain identity
final result = await resolver.resolve(claims);

result.fold(
  onOk: (identity) => print('Identity resolved: ${identity.id}'),
  onErr: (error) => print('Resolution failed: $error'),
);
```

## 🛡️ Error Handling Philosophy

This package:
- Maps all infrastructure failures to semantic `ZenResult` errors
- Never leaks raw SDK exceptions to the domain
- Treats auth failures as facts, NOT as identity failures
- Logs errors without exposing PII

Auth data is assumed to be **already verified**. Token validation happens outside this package.

## 🔒 What is NOT in scope

This package explicitly does NOT:
- ❌ Validate tokens or credentials
- ❌ Handle passwords
- ❌ Infer roles or permissions from claims
- ❌ Make authorization decisions
- ❌ Trigger lifecycle transitions
- ❌ Create identities by default
- ❌ Normalize or enrich domain models
- ❌ Persist data directly

## 🧩 Wiring is Explicit

Connecting this adapter to your application requires explicit configuration:
- Implement `IdentityPersistencePort` for your storage backend
- Configure localization service
- Wire the resolver into your application layer
- Pass verified auth claims from your authentication middleware

No magic. No hidden defaults. All behavior is traceable.

## 📐 Stability Guarantees

Version `0.0.1` is an initial release. The public API may evolve, but the package will always:
- Implement domain-defined ports
- Map auth facts to domain identity
- Preserve domain purity
- Maintain explicit behavior

Replacing your auth provider should only require changes to this package.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

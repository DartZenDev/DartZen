# Zen Demo Contracts

Shared contracts for ZenDemo client-server communication.

## Purpose

This package defines the data contracts used between the ZenDemo Flutter client and Dart server. Contracts ensure type-safe communication without code generation.

## Contracts

- **PingContract**: Server ping response with message and timestamp
- **ProfileContract**: User profile with ID, status, and roles
- **TermsContract**: Terms and conditions content with MIME type
- **WebSocketMessageContract**: WebSocket message with type and payload

## Usage

```dart
import 'package:dartzen_demo_contracts/dartzen_demo_contracts.dart';

final ping = PingContract(
  message: 'Hello Zen',
  timestamp: '2025-12-31T12:00:00Z',
);

final json = ping.toJson();
final decoded = PingContract.fromJson(json);
```

## License

See [LICENSE](../../../LICENSE)

# DartZen Transport

[![pub package](https://img.shields.io/pub/v/dartzen_transport.svg)](https://pub.dev/packages/dartzen_transport)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**DartZen transport layer for serialization, codec selection, and WebSocket communication.**

`dartzen_transport` is a foundational package in the DartZen ecosystem that provides:

- **Dual-format serialization**: JSON and MessagePack
- **Automatic codec selection**: Based on environment (DEV/PRD) and platform (web/native)
- **Transport envelopes**: Structured request/response messages
- **WebSocket helper**: Simple WebSocket communication with automatic codec support
- **Platform-aware treeshaking**: Unused code is automatically removed

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🧘🏻 Why This Package Exists

Modern applications need efficient data serialization that adapts to different environments and platforms:

- **Development**: Human-readable JSON for debugging
- **Production (Web)**: JSON for browser compatibility
- **Production (Native)**: MessagePack for binary efficiency on mobile, server, and desktop

`dartzen_transport` handles this complexity automatically while maintaining a simple, consistent API.

## 🎯 Philosophy

`dartzen_transport` follows the Zen Architecture principles:

- **Simplicity**: One clear way to do things
- **Consistency**: Uniform API across all platforms
- **Explicitness**: No magic, clear behavior
- **Efficiency**: Automatic optimization without manual intervention
- **Treeshaking**: Only include what you use

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_transport:
    path: ../dartzen_transport
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_transport: ^latest_version
```

## 🚀 Quick Start

### Basic Request/Response

```dart
import 'package:dartzen_transport/dartzen_transport.dart';

// Create a request
final request = ZenRequest(
  id: 'req-001',
  path: '/api/users',
  data: {'name': 'Alice', 'email': 'alice@example.com'},
);

// Encode using the default codec (auto-selected)
final bytes = request.encode();

// Decode the response
final response = ZenResponse.decode(responseBytes);

if (response.isSuccess) {
  print('Success: ${response.data}');
} else {
  print('Error: ${response.error}');
}
```

### WebSocket Communication

```dart
// Connect to WebSocket server
final ws = ZenWebSocket(Uri.parse('ws://localhost:8080'));

// Listen for responses
ws.responses.listen((response) {
  print('Received: ${response.data}');
});

// Send a request
ws.send(ZenRequest(
  id: 'ws-001',
  path: '/subscribe',
  data: {'channel': 'updates'},
));

// Close when done
await ws.close();
```

## 🪧 Codec Selection

### Automatic Selection

The package automatically selects the appropriate codec based on:

1. **Environment** (set via `DZ_ENV` compile-time constant)
2. **Platform** (web vs. native)

| Environment | Platform | Codec |
|-------------|----------|-------|
| DEV | Any | JSON |
| PRD | Web | JSON |
| PRD | Native (mobile/server/desktop) | MessagePack |

### Manual Override

You can explicitly specify the codec:

```dart
// Force JSON
final bytes = request.encodeWith(ZenTransportFormat.json);
final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.json);

// Force MessagePack
final bytes = request.encodeWith(ZenTransportFormat.msgpack);
final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.msgpack);

// WebSocket with specific codec
final ws = ZenWebSocket(
  Uri.parse('ws://localhost:8080'),
  format: ZenTransportFormat.msgpack,
);
```

## 🚂 Transport Header

For HTTP-based communication, use the `X-DZ-Transport` header to negotiate format:

```dart
// Header name
print(zenTransportHeaderName); // 'X-DZ-Transport'

// Valid values
ZenTransportFormat.json.value;    // 'json'
ZenTransportFormat.msgpack.value; // 'msgpack'

// Parse from header
final format = ZenTransportFormat.parse('msgpack');
```

If the header value is invalid, a `ZenTransportException` is thrown.

## ✉️ Message Types

### ZenRequest

Represents a client request:

```dart
final request = ZenRequest(
  id: 'unique-id',        // Request identifier
  path: '/api/endpoint',  // Endpoint or action
  data: {'key': 'value'}, // Optional payload
);
```

### ZenResponse

Represents a server response:

```dart
final response = ZenResponse(
  id: 'matching-request-id', // Matches request ID
  status: 200,               // HTTP-style status code
  data: {'result': 'ok'},    // Optional response data
  error: null,               // Optional error message
);

// Convenience methods
response.isSuccess; // true for 200-299
response.isError;   // true for 400+
```

## 🏗 ️Environment Variables

Set the environment at compile time:

```bash
# Development mode (JSON everywhere)
dart run --define=DZ_ENV=dev example/main.dart

# Production mode (platform-specific codec)
dart run --define=DZ_ENV=prd example/main.dart
```

Default is `prd` if not specified.

## ⚖️ JSON vs MessagePack

### When to Use JSON

- **Development**: Easy to read and debug
- **Web platform**: Browser compatibility
- **Small payloads**: Minimal size difference

### When to Use MessagePack

- **Production (native)**: Smaller binary size
- **Large payloads**: Significant bandwidth savings
- **Binary data**: More efficient encoding

### Size Comparison

```dart
final data = {'items': List.generate(100, (i) => {'id': i, 'value': i * 2})};

final jsonBytes = ZenEncoder.encode(data, ZenTransportFormat.json);
final msgpackBytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);

print('JSON: ${jsonBytes.length} bytes');
print('MessagePack: ${msgpackBytes.length} bytes');
// MessagePack is typically 20-50% smaller
```

## 🐛 Error Handling

All transport errors throw `ZenTransportException`:

```dart
try {
  final format = ZenTransportFormat.parse('invalid');
} on ZenTransportException catch (e) {
  print('Transport error: ${e.message}');
}
```

## 📚 API Reference

### Core Classes

- `ZenRequest` - Request envelope
- `ZenResponse` - Response envelope
- `ZenWebSocket` - WebSocket helper
- `ZenEncoder` - Low-level encoder
- `ZenDecoder` - Low-level decoder

### Enums

- `ZenTransportFormat` - `json` or `msgpack`

### Functions

- `selectDefaultCodec()` - Get the default codec for current environment/platform

### Constants

- `zenTransportHeaderName` - `'X-DZ-Transport'`

### Exceptions

- `ZenTransportException` - All transport errors

## 🧪 Testing

Run tests:

```bash
cd packages/dartzen_transport
dart test
```

Run example:

```bash
dart run example/main.dart
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

# DartZen Server Transport

[![pub package](https://img.shields.io/pub/v/dartzen_server_transport.svg)](https://pub.dev/packages/dartzen_server_transport)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Minimal Shelf middleware for DartZen transport layer.**

Provides automatic format negotiation and encoding/decoding for Shelf-based servers.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## ⚙️ Features

- Automatic format negotiation via `X-DZ-Transport` header
- Content-Type detection
- Request/response encoding/decoding
- Minimal, functional API
- Zero configuration required

## 📦 Installation

```yaml
dependencies:
  dartzen_server_transport:
    path: ../dartzen_server_transport
```

## 🚀 Usage

### Basic Server

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:dartzen_server_transport/dartzen_server_transport.dart';

void main() async {
  final handler = Pipeline()
      .addMiddleware(transportMiddleware())
      .addMiddleware(logRequests())
      .addHandler(_handleRequest);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
}

Response _handleRequest(Request request) {
  // Access decoded data
  final data = request.context['decoded_data'];
  
  // Return encoded response
  return zenResponse(200, {
    'message': 'Hello from DartZen!',
    'received': data,
  });
}
```

### Format Negotiation

The middleware automatically negotiates format based on:

1. **X-DZ-Transport header** (highest priority)
   ```
   X-DZ-Transport: msgpack
   ```

2. **Content-Type header**
   ```
   Content-Type: application/msgpack
   Content-Type: application/json
   ```

3. **Default**: JSON if no headers present

### Accessing Request Data

```dart
Response _handleRequest(Request request) {
  // Get negotiated format
  final format = request.context['transport_format'] as ZenTransportFormat;
  
  // Get decoded data
  final data = request.context['decoded_data'];
  
  return zenResponse(200, {'echo': data});
}
```

### Creating Responses

Use the `zenResponse` helper:

```dart
// Success response
return zenResponse(200, {'status': 'ok'});

// Error response
return zenResponse(400, {'error': 'Bad request'});

// With custom headers
return zenResponse(200, {'data': 'value'}, headers: {
  'X-Custom-Header': 'value',
});
```

## ⚙️ API

### `transportMiddleware()`

Creates Shelf middleware for transport negotiation.

**Returns**: `Middleware` function for Shelf pipeline

### `zenResponse(int statusCode, Object? data, {Map<String, String>? headers})`

Helper to create responses with automatic encoding.

**Parameters**:
- `statusCode`: HTTP status code
- `data`: Data to encode (will be encoded based on negotiated format)
- `headers`: Optional custom headers

**Returns**: `Response` with encoded body

## 🛠️ Integration with dartzen_transport

This package is a thin wrapper around `dartzen_transport`. It:
- Uses `ZenEncoder`/`ZenDecoder` for serialization
- Respects `ZenTransportFormat` negotiation
- Follows the same platform/environment rules

## 📊 Example Server

See `/example/server.dart` for a complete working example.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

# DartZen Client Transport

[![pub package](https://img.shields.io/pub/v/dartzen_client_transport.svg)](https://pub.dev/packages/dartzen_client_transport)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Minimal HTTP client wrapper for DartZen transport layer.**

Provides automatic format negotiation and encoding/decoding for HTTP clients.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🤖 Features

- Automatic format negotiation via headers
- Request/response encoding/decoding
- Support for GET, POST, PUT, DELETE
- Minimal, functional API
- Easy to test with injectable HTTP client

## 📦 Installation

```yaml
dependencies:
  dartzen_client_transport:
    path: ../dartzen_client_transport
```

## 🚀 Usage

### Basic Client

```dart
import 'package:dartzen_client_transport/dartzen_client_transport.dart';

void main() async {
  final client = ZenClient(baseUrl: 'http://localhost:8080');

  // POST request
  final user = await client.post('/api/users', {
    'name': 'Alice',
    'email': 'alice@example.com',
  });
  print('Created user: ${user['id']}');

  // GET request
  final users = await client.get('/api/users');
  print('Users: $users');

  client.close();
}
```

### Format Selection

```dart
// Use JSON (default)
final jsonClient = ZenClient(
  baseUrl: 'http://localhost:8080',
  format: ZenTransportFormat.json,
);

// Use MessagePack
final msgpackClient = ZenClient(
  baseUrl: 'http://localhost:8080',
  format: ZenTransportFormat.msgpack,
);
```

### Custom Headers

```dart
final response = await client.post(
  '/api/users',
  {'name': 'Bob'},
  headers: {'Authorization': 'Bearer token123'},
);
```

### All HTTP Methods

```dart
// GET
final data = await client.get('/api/resource');

// POST
final created = await client.post('/api/resource', {'key': 'value'});

// PUT
final updated = await client.put('/api/resource/1', {'key': 'new value'});

// DELETE
await client.delete('/api/resource/1');
```

## ⚙️ API

### `ZenClient`

HTTP client with automatic transport negotiation.

**Constructor**:
```dart
ZenClient({
  required String baseUrl,
  ZenTransportFormat format = ZenTransportFormat.json,
  http.Client? httpClient,
})
```

**Methods**:
- `Future<dynamic> get(String path, {Map<String, String>? headers})`
- `Future<dynamic> post(String path, Object? data, {Map<String, String>? headers})`
- `Future<dynamic> put(String path, Object? data, {Map<String, String>? headers})`
- `Future<dynamic> delete(String path, {Map<String, String>? headers})`
- `void close()`

## 🧪 Testing

Inject a mock HTTP client for testing:

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('client sends correct request', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, equals('/api/test'));
      return http.Response('{"result": "ok"}', 200);
    });

    final client = ZenClient(
      baseUrl: 'http://localhost',
      httpClient: mockClient,
    );

    final response = await client.get('/api/test');
    expect(response['result'], equals('ok'));
  });
}
```

## 🛠️ Integration with dartzen_transport

This package is a thin wrapper around `dartzen_transport`. It:
- Uses `ZenEncoder`/`ZenDecoder` for serialization
- Respects `ZenTransportFormat` negotiation
- Follows the same platform/environment rules

## 📊 Example

See `/example/client.dart` for a complete working example.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

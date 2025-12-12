// ignore_for_file: avoid_print

import 'package:dartzen_transport/dartzen_transport.dart';

void main() {
  print('=== DartZen Transport Example ===\n');

  // Example 1: JSON Encoding/Decoding
  jsonExample();

  // Example 2: MessagePack Encoding/Decoding
  msgpackExample();

  // Example 3: Request/Response
  requestResponseExample();

  // Example 4: WebSocket (conceptual - requires server)
  websocketExample();
}

void jsonExample() {
  print('--- JSON Example ---');

  const request = ZenRequest(
    id: 'req-001',
    path: '/api/users',
    data: {
      'name': 'Alice',
      'email': 'alice@example.com',
      'roles': ['admin', 'user'],
    },
  );

  // Encode using JSON
  final bytes = request.encodeWith(ZenTransportFormat.json);
  print('Encoded size (JSON): ${bytes.length} bytes');

  // Decode back
  final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.json);
  print('Decoded request: ${decoded.path}');
  print('Data: ${decoded.data}\n');
}

void msgpackExample() {
  print('--- MessagePack Example ---');

  final request = ZenRequest(
    id: 'req-002',
    path: '/api/data',
    data: {
      'items': List.generate(50, (i) => {'id': i, 'value': i * 2}),
    },
  );

  // Encode using MessagePack
  final msgpackBytes = request.encodeWith(ZenTransportFormat.msgpack);
  print('Encoded size (MessagePack): ${msgpackBytes.length} bytes');

  // Compare with JSON
  final jsonBytes = request.encodeWith(ZenTransportFormat.json);
  print('Encoded size (JSON): ${jsonBytes.length} bytes');
  print('Savings: ${jsonBytes.length - msgpackBytes.length} bytes\n');

  // Decode back
  final decoded = ZenRequest.decodeWith(
    msgpackBytes,
    ZenTransportFormat.msgpack,
  );
  print('Decoded successfully: ${decoded.id}\n');
}

void requestResponseExample() {
  print('--- Request/Response Example ---');

  // Create a request
  const request = ZenRequest(
    id: 'req-003',
    path: '/api/login',
    data: {'username': 'bob', 'password': 'secret123'},
  );

  print('Request: ${request.path}');

  // Simulate a successful response
  final successResponse = ZenResponse(
    id: request.id,
    status: 200,
    data: {
      'token': 'jwt-token-here',
      'user': {'id': 123, 'name': 'Bob'},
    },
  );

  print('Response status: ${successResponse.status}');
  print('Is success: ${successResponse.isSuccess}');
  print('Response data: ${successResponse.data}');

  // Simulate an error response
  final errorResponse = ZenResponse(
    id: request.id,
    status: 401,
    error: 'Invalid credentials',
  );

  print('\nError response status: ${errorResponse.status}');
  print('Is error: ${errorResponse.isError}');
  print('Error message: ${errorResponse.error}\n');
}

void websocketExample() {
  print('--- WebSocket Example (Conceptual) ---');
  print('To use WebSocket, you need a running server.\n');

  print('Example code:');
  print('''
  // Connect to WebSocket server
  final ws = ZenWebSocket(
    Uri.parse('ws://localhost:8080'),
    format: ZenTransportFormat.msgpack, // Optional: override default
  );

  // Listen for responses
  ws.responses.listen((response) {
    print('Received: \${response.data}');
  });

  // Send a request
  final request = ZenRequest(
    id: 'ws-001',
    path: '/subscribe',
    data: {'channel': 'updates'},
  );
  ws.send(request);

  // Close when done
  await ws.close();
  ''');

  print('\nCodec selection:');
  print('- DEV mode: JSON everywhere');
  print('- PRD mode (web): JSON');
  print('- PRD mode (native): MessagePack');
  print('\nCurrent default codec: ${selectDefaultCodec().value}');
}

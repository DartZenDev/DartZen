// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';

void main() {
  ZenLogger.instance.info('=== DartZen Transport Example ===\n');

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
  ZenLogger.instance.info('--- JSON Example ---');

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
  ZenLogger.instance.info('Encoded size (JSON): ${bytes.length} bytes');

  // Decode back
  final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.json);
  ZenLogger.instance.info('Decoded request: ${decoded.path}');
  ZenLogger.instance.info('Data: ${decoded.data}\n');
}

void msgpackExample() {
  ZenLogger.instance.info('--- MessagePack Example ---');

  final request = ZenRequest(
    id: 'req-002',
    path: '/api/data',
    data: {
      'items': List.generate(50, (i) => {'id': i, 'value': i * 2}),
    },
  );

  // Encode using MessagePack
  final msgpackBytes = request.encodeWith(ZenTransportFormat.msgpack);
  ZenLogger.instance.info(
    'Encoded size (MessagePack): ${msgpackBytes.length} bytes',
  );

  // Compare with JSON
  final jsonBytes = request.encodeWith(ZenTransportFormat.json);
  ZenLogger.instance.info('Encoded size (JSON): ${jsonBytes.length} bytes');
  ZenLogger.instance.info(
    'Savings: ${jsonBytes.length - msgpackBytes.length} bytes\n',
  );

  // Decode back
  final decoded = ZenRequest.decodeWith(
    msgpackBytes,
    ZenTransportFormat.msgpack,
  );
  ZenLogger.instance.info('Decoded successfully: ${decoded.id}\n');
}

void requestResponseExample() {
  ZenLogger.instance.info('--- Request/Response Example ---');

  // Create a request
  const request = ZenRequest(
    id: 'req-003',
    path: '/api/login',
    data: {'username': 'bob', 'password': 'secret123'},
  );

  ZenLogger.instance.info('Request: ${request.path}');

  // Simulate a successful response
  final successResponse = ZenResponse(
    id: request.id,
    status: 200,
    data: {
      'token': 'jwt-token-here',
      'user': {'id': 123, 'name': 'Bob'},
    },
  );

  ZenLogger.instance.info('Response status: ${successResponse.status}');
  ZenLogger.instance.info('Is success: ${successResponse.isSuccess}');
  ZenLogger.instance.info('Response data: ${successResponse.data}');

  // Simulate an error response
  final errorResponse = ZenResponse(
    id: request.id,
    status: 401,
    error: 'Invalid credentials',
  );

  ZenLogger.instance.info('\nError response status: ${errorResponse.status}');
  ZenLogger.instance.info('Is error: ${errorResponse.isError}');
  ZenLogger.instance.info('Error message: ${errorResponse.error}\n');
}

void websocketExample() {
  ZenLogger.instance.info('--- WebSocket Example (Conceptual) ---');
  ZenLogger.instance.info('To use WebSocket, you need a running server.\n');

  ZenLogger.instance.info('Example code:');
  ZenLogger.instance.info('''
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

  ZenLogger.instance.info('\nCodec selection:');
  ZenLogger.instance.info('- DEV mode: JSON everywhere');
  ZenLogger.instance.info('- PRD mode (web): JSON');
  ZenLogger.instance.info('- PRD mode (native): MessagePack');
  ZenLogger.instance.info(
    '\nCurrent default codec: ${selectDefaultCodec().value}',
  );
}

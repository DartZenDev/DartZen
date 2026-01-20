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
  ZenLogger.instance.info('--- WebSocket & HTTP Transport ---');
  ZenLogger.instance.info(
    'IMPORTANT: All transport operations must execute via ZenExecutor.\n',
  );

  ZenLogger.instance.info(
    'This package provides protocol abstractions (ZenRequest/ZenResponse)',
  );
  ZenLogger.instance.info(
    'and serialization utilities (ZenEncoder/ZenDecoder).',
  );
  ZenLogger.instance.info('');

  ZenLogger.instance.info('Direct HTTP or WebSocket usage is NOT supported:');
  ZenLogger.instance.info('  ❌ ZenClient direct instantiation');
  ZenLogger.instance.info('  ❌ ZenWebSocket outside of tasks');
  ZenLogger.instance.info('  ❌ Server middleware without framework\n');

  ZenLogger.instance.info('All network operations must be performed in');
  ZenLogger.instance.info('ZenTask subclasses executed via ZenExecutor:');
  ZenLogger.instance.info('''
  class FetchUserTask extends ZenTask<User> {
    FetchUserTask(this.userId);
    final String userId;

    @override
    Future<User> execute() async {
      // Framework provides HTTP client
      // WebSocket channel managed by framework
      // All I/O happens here safely
    }
  }

  final user = await zen.execute(FetchUserTask('123'));
  ''');

  ZenLogger.instance.info('\nCodec selection (automatic):');
  ZenLogger.instance.info('- DEV mode: JSON everywhere');
  ZenLogger.instance.info('- PRD mode (web): JSON');
  ZenLogger.instance.info('- PRD mode (native): MessagePack');
  ZenLogger.instance.info(
    '\nCurrent default codec: ${selectDefaultCodec().value}',
  );
}

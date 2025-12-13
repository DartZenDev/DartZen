// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_msgpack/dartzen_msgpack.dart';

void main() {
  ZenLogger.instance.info('=== DartZen MessagePack Example ===\n');

  // Example 1: Simple data
  simpleExample();

  // Example 2: Complex nested structures
  complexExample();

  // Example 3: Binary data
  binaryExample();
}

void simpleExample() {
  ZenLogger.instance.info('--- Simple Example ---');

  final data = {'name': 'Alice', 'age': 30, 'active': true};

  final bytes = encode(data);
  ZenLogger.instance.info('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  ZenLogger.instance.info('Name: ${decoded['name']}');
  ZenLogger.instance.info('Age: ${decoded['age']}');
  ZenLogger.instance.info('Active: ${decoded['active']}\n');
}

void complexExample() {
  ZenLogger.instance.info('--- Complex Example ---');

  final data = {
    'users': [
      {'id': 1, 'name': 'Alice', 'score': 95.5},
      {'id': 2, 'name': 'Bob', 'score': 87.3},
    ],
    'metadata': {
      'version': '1.0',
      'timestamp': 1234567890,
      'tags': ['production', 'verified'],
    },
  };

  final bytes = encode(data);
  ZenLogger.instance.info('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  final users = decoded['users'] as List<dynamic>;
  final firstUser = users[0] as Map<String, dynamic>;
  final metadata = decoded['metadata'] as Map<String, dynamic>;
  ZenLogger.instance.info('First user: ${firstUser['name']}');
  ZenLogger.instance.info('Metadata version: ${metadata['version']}\n');
}

void binaryExample() {
  ZenLogger.instance.info('--- Binary Example ---');

  final binaryData = [0x01, 0x02, 0x03, 0x04, 0x05];
  final data = {'type': 'binary', 'payload': binaryData};

  final bytes = encode(data);
  ZenLogger.instance.info('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  ZenLogger.instance.info('Type: ${decoded['type']}');
  ZenLogger.instance.info('Payload: ${decoded['payload']}\n');
}

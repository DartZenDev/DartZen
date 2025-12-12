// ignore_for_file: avoid_print

import 'package:dartzen_msgpack/dartzen_msgpack.dart';

void main() {
  print('=== DartZen MessagePack Example ===\n');

  // Example 1: Simple data
  simpleExample();

  // Example 2: Complex nested structures
  complexExample();

  // Example 3: Binary data
  binaryExample();
}

void simpleExample() {
  print('--- Simple Example ---');

  final data = {'name': 'Alice', 'age': 30, 'active': true};

  final bytes = encode(data);
  print('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  print('Name: ${decoded['name']}');
  print('Age: ${decoded['age']}');
  print('Active: ${decoded['active']}\n');
}

void complexExample() {
  print('--- Complex Example ---');

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
  print('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  final users = decoded['users'] as List<dynamic>;
  final firstUser = users[0] as Map<String, dynamic>;
  final metadata = decoded['metadata'] as Map<String, dynamic>;
  print('First user: ${firstUser['name']}');
  print('Metadata version: ${metadata['version']}\n');
}

void binaryExample() {
  print('--- Binary Example ---');

  final binaryData = [0x01, 0x02, 0x03, 0x04, 0x05];
  final data = {'type': 'binary', 'payload': binaryData};

  final bytes = encode(data);
  print('Encoded ${bytes.length} bytes');

  final decoded = decode(bytes) as Map<String, dynamic>;
  print('Type: ${decoded['type']}');
  print('Payload: ${decoded['payload']}\n');
}

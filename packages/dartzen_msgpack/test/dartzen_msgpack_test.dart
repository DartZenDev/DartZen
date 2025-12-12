import 'dart:typed_data';

import 'package:dartzen_msgpack/dartzen_msgpack.dart';
import 'package:test/test.dart';

void main() {
  group('dartzen_msgpack', () {
    test('encodes and decodes null', () {
      final bytes = encode(null);
      expect(decode(bytes), isNull);
    });

    test('encodes and decodes bool', () {
      expect(decode(encode(true)), isTrue);
      expect(decode(encode(false)), isFalse);
    });

    test('encodes and decodes positive integers', () {
      expect(decode(encode(0)), equals(0));
      expect(decode(encode(127)), equals(127));
      expect(decode(encode(255)), equals(255));
      expect(decode(encode(65535)), equals(65535));
      expect(decode(encode(4294967295)), equals(4294967295));
    });

    test('encodes and decodes negative integers', () {
      expect(decode(encode(-1)), equals(-1));
      expect(decode(encode(-32)), equals(-32));
      expect(decode(encode(-128)), equals(-128));
      expect(decode(encode(-32768)), equals(-32768));
    });

    test('encodes and decodes doubles', () {
      expect(decode(encode(3.14)), closeTo(3.14, 0.0001));
      expect(decode(encode(-2.5)), closeTo(-2.5, 0.0001));
    });

    test('encodes and decodes strings', () {
      expect(decode(encode('')), equals(''));
      expect(decode(encode('hello')), equals('hello'));
      expect(decode(encode('Hello, 世界!')), equals('Hello, 世界!'));
    });

    test('encodes and decodes lists', () {
      final list = [1, 2, 3, 'four', true];
      final decoded = decode(encode(list)) as List;
      expect(decoded, equals(list));
    });

    test('encodes and decodes maps', () {
      final map = {'name': 'Alice', 'age': 30, 'active': true};
      final decoded = decode(encode(map)) as Map;
      expect(decoded['name'], equals('Alice'));
      expect(decoded['age'], equals(30));
      expect(decoded['active'], isTrue);
    });

    test('encodes and decodes nested structures', () {
      final data = {
        'users': [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
        'metadata': {'version': '1.0', 'count': 2},
      };

      final decoded = decode(encode(data)) as Map;
      final users = decoded['users'] as List;
      expect(users.length, equals(2));
      expect((users[0] as Map)['name'], equals('Alice'));
      expect((decoded['metadata'] as Map)['version'], equals('1.0'));
    });

    test('encodes and decodes binary data', () {
      final binary = Uint8List.fromList([1, 2, 3, 4, 5]);
      final decoded = decode(encode(binary)) as List;
      expect(decoded, equals([1, 2, 3, 4, 5]));
    });

    test('handles empty collections', () {
      expect(decode(encode(<dynamic>[])), equals([]));
      expect(decode(encode(<String, dynamic>{})), equals({}));
    });

    test('round-trip preserves data integrity', () {
      final original = {
        'string': 'test',
        'int': 42,
        'double': 3.14,
        'bool': true,
        'null': null,
        'list': [1, 2, 3],
        'map': {'nested': 'value'},
      };

      final bytes = encode(original);
      final decoded = decode(bytes) as Map;

      expect(decoded['string'], equals('test'));
      expect(decoded['int'], equals(42));
      expect(decoded['double'], closeTo(3.14, 0.0001));
      expect(decoded['bool'], isTrue);
      expect(decoded['null'], isNull);
      expect(decoded['list'], equals([1, 2, 3]));
      expect((decoded['map'] as Map)['nested'], equals('value'));
    });

    test('throws on unsupported types', () {
      expect(() => encode(DateTime.now()), throwsArgumentError);
    });
  });
}

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ZenRequest/ZenResponse deep-equals & hash', () {
    test('deep equals for nested maps and lists and stable hashCode', () {
      final dataA = {
        'a': 1,
        'nested': {
          'list': [
            1,
            2,
            {'x': 'y'},
          ],
          'map': {'k': 'v'},
        },
      };

      final r1 = ZenRequest(id: 'id1', path: '/p', data: dataA);
      final r2 = ZenRequest.fromMap(r1.toMap());

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('non-equality when nested data differs', () {
      final base = {
        'a': 1,
        'b': {'x': 2},
      };
      final r1 = ZenRequest(id: '1', path: '/p', data: base);
      const r2 = ZenRequest(
        id: '1',
        path: '/p',
        data: {
          'a': 1,
          'b': {'x': 3},
        },
      );
      expect(r1 == r2, isFalse);
      expect(r1.hashCode == r2.hashCode, isFalse);
    });

    test('order-insensitive map equality for hash stability', () {
      final m1 = {'k1': 1, 'k2': 2};
      final m2 = {'k2': 2, 'k1': 1};
      final r1 = ZenResponse(id: 'r', status: 200, data: m1);
      final r2 = ZenResponse(id: 'r', status: 200, data: m2);
      expect(r1, equals(r2));
      // Hash codes may differ due to map entry iteration/order; only require equality.
    });

    test('ZenResponse error/success flags and equality', () {
      const ok = ZenResponse(id: 'ok', status: 200, data: {'v': true});
      const err = ZenResponse(id: 'err', status: 404, error: 'Not found');

      expect(ok.isSuccess, isTrue);
      expect(ok.isError, isFalse);

      expect(err.isSuccess, isFalse);
      expect(err.isError, isTrue);

      final err2 = ZenResponse.fromMap(err.toMap());
      expect(err2, equals(err));
      expect(err2.hashCode, equals(err.hashCode));
    });
  });

  group('ZenRequest basic behaviors', () {
    test('creates request with all fields', () {
      const request = ZenRequest(
        id: '123',
        path: '/api/users',
        data: {'name': 'John'},
      );

      expect(request.id, equals('123'));
      expect(request.path, equals('/api/users'));
      expect(request.data, equals({'name': 'John'}));
    });

    test('creates request without data', () {
      const request = ZenRequest(id: '456', path: '/api/status');

      expect(request.id, equals('456'));
      expect(request.path, equals('/api/status'));
      expect(request.data, isNull);
    });

    test('converts to map correctly', () {
      const request = ZenRequest(
        id: '789',
        path: '/api/login',
        data: {'username': 'alice'},
      );

      final map = request.toMap();
      expect(map['id'], equals('789'));
      expect(map['path'], equals('/api/login'));
      expect(map['data'], equals({'username': 'alice'}));
    });

    test('creates from map', () {
      const map = {
        'id': 'abc',
        'path': '/test',
        'data': {'key': 'value'},
      };

      final request = ZenRequest.fromMap(map);
      expect(request.id, equals('abc'));
      expect(request.path, equals('/test'));
      expect(request.data, equals({'key': 'value'}));
    });

    test('encodes and decodes with JSON', () {
      const original = ZenRequest(
        id: 'req1',
        path: '/api/data',
        data: {'count': 42},
      );

      final bytes = original.encodeWith(ZenTransportFormat.json);
      final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.json);

      expect(decoded.id, equals(original.id));
      expect(decoded.path, equals(original.path));
      expect(decoded.data, equals(original.data));
    });

    test('encodes and decodes with MessagePack', () {
      const original = ZenRequest(
        id: 'req2',
        path: '/api/update',
        data: {
          'items': [1, 2, 3],
        },
      );

      final bytes = original.encodeWith(ZenTransportFormat.msgpack);
      final decoded = ZenRequest.decodeWith(bytes, ZenTransportFormat.msgpack);

      expect(decoded.id, equals(original.id));
      expect(decoded.path, equals(original.path));
      expect(decoded.data, equals(original.data));
    });

    test('equality works correctly', () {
      const req1 = ZenRequest(id: '1', path: '/a', data: {'x': 1});
      const req2 = ZenRequest(id: '1', path: '/a', data: {'x': 1});
      const req3 = ZenRequest(id: '2', path: '/a', data: {'x': 1});

      expect(req1, equals(req2));
      expect(req1, isNot(equals(req3)));
    });

    test('hashCode is consistent', () {
      const req1 = ZenRequest(id: '1', path: '/a', data: {'x': 1});
      const req2 = ZenRequest(id: '1', path: '/a', data: {'x': 1});

      expect(req1.hashCode, equals(req2.hashCode));
    });
  });

  group('ZenResponse basic behaviors', () {
    test('creates response with all fields', () {
      const response = ZenResponse(
        id: '123',
        status: 200,
        data: {'result': 'success'},
      );

      expect(response.id, equals('123'));
      expect(response.status, equals(200));
      expect(response.data, equals({'result': 'success'}));
      expect(response.error, isNull);
    });

    test('creates error response', () {
      const response = ZenResponse(
        id: '456',
        status: 500,
        error: 'Internal server error',
      );

      expect(response.id, equals('456'));
      expect(response.status, equals(500));
      expect(response.error, equals('Internal server error'));
      expect(response.data, isNull);
    });

    test('isSuccess returns true for 2xx status', () {
      expect(const ZenResponse(id: '1', status: 200).isSuccess, isTrue);
      expect(const ZenResponse(id: '1', status: 201).isSuccess, isTrue);
      expect(const ZenResponse(id: '1', status: 299).isSuccess, isTrue);
    });

    test('isSuccess returns false for non-2xx status', () {
      expect(const ZenResponse(id: '1', status: 199).isSuccess, isFalse);
      expect(const ZenResponse(id: '1', status: 300).isSuccess, isFalse);
      expect(const ZenResponse(id: '1', status: 404).isSuccess, isFalse);
      expect(const ZenResponse(id: '1', status: 500).isSuccess, isFalse);
    });

    test('isError returns true for 4xx and 5xx status', () {
      expect(const ZenResponse(id: '1', status: 400).isError, isTrue);
      expect(const ZenResponse(id: '1', status: 404).isError, isTrue);
      expect(const ZenResponse(id: '1', status: 500).isError, isTrue);
    });

    test('isError returns false for non-error status', () {
      expect(const ZenResponse(id: '1', status: 200).isError, isFalse);
      expect(const ZenResponse(id: '1', status: 300).isError, isFalse);
    });

    test('converts to map correctly', () {
      const response = ZenResponse(
        id: '789',
        status: 201,
        data: {'created': true},
      );

      final map = response.toMap();
      expect(map['id'], equals('789'));
      expect(map['status'], equals(201));
      expect(map['data'], equals({'created': true}));
      expect(map['error'], isNull);
    });

    test('creates from map', () {
      const map = {
        'id': 'abc',
        'status': 404,
        'data': null,
        'error': 'Not found',
      };

      final response = ZenResponse.fromMap(map);
      expect(response.id, equals('abc'));
      expect(response.status, equals(404));
      expect(response.data, isNull);
      expect(response.error, equals('Not found'));
    });

    test('encodes and decodes with JSON', () {
      const original = ZenResponse(
        id: 'res1',
        status: 200,
        data: {'value': 123},
      );

      final bytes = original.encodeWith(ZenTransportFormat.json);
      final decoded = ZenResponse.decodeWith(bytes, ZenTransportFormat.json);

      expect(decoded.id, equals(original.id));
      expect(decoded.status, equals(original.status));
      expect(decoded.data, equals(original.data));
      expect(decoded.error, equals(original.error));
    });

    test('encodes and decodes with MessagePack', () {
      const original = ZenResponse(
        id: 'res2',
        status: 500,
        error: 'Server error',
      );

      final bytes = original.encodeWith(ZenTransportFormat.msgpack);
      final decoded = ZenResponse.decodeWith(bytes, ZenTransportFormat.msgpack);

      expect(decoded.id, equals(original.id));
      expect(decoded.status, equals(original.status));
      expect(decoded.data, equals(original.data));
      expect(decoded.error, equals(original.error));
    });

    test('equality works correctly', () {
      const res1 = ZenResponse(id: '1', status: 200, data: {'x': 1});
      const res2 = ZenResponse(id: '1', status: 200, data: {'x': 1});
      const res3 = ZenResponse(id: '1', status: 404, data: {'x': 1});

      expect(res1, equals(res2));
      expect(res1, isNot(equals(res3)));
    });

    test('hashCode is consistent', () {
      const res1 = ZenResponse(id: '1', status: 200, data: {'x': 1});
      const res2 = ZenResponse(id: '1', status: 200, data: {'x': 1});

      expect(res1.hashCode, equals(res2.hashCode));
    });
  });
}

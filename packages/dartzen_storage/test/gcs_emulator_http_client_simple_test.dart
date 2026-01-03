import 'dart:async';
import 'dart:convert';

import 'package:dartzen_storage/src/gcs_storage_reader.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _FakeInnerClient extends http.BaseClient {
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final body = utf8.encode('ok');
    final stream = Stream<List<int>>.fromIterable([body]);
    return http.StreamedResponse(stream, 200, request: request);
  }
}

class _FakeBaseRequest extends http.BaseRequest {
  _FakeBaseRequest(super.method, super.url, this._bytes);
  final List<int> _bytes;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(Stream.fromIterable([_bytes]));
  }
}

void main() {
  test('EmulatorHttpClient rewrites host and port for GET', () async {
    final inner = _FakeInnerClient();
    final client = EmulatorHttpClient(inner, '127.0.0.1:8080');

    final req = http.Request(
      'GET',
      Uri.parse('https://storage.googleapis.com/bucket/object'),
    );
    final resp = await client.send(req);

    expect(resp.statusCode, 200);
    expect(inner.lastRequest, isNotNull);
    expect(inner.lastRequest!.url.host, '127.0.0.1');
    expect(inner.lastRequest!.url.port, 8080);
  });

  test(
    'EmulatorHttpClient copies finalize stream bytes for non-Request',
    () async {
      final inner = _FakeInnerClient();
      final client = EmulatorHttpClient(inner, 'localhost:9090');

      final fake = _FakeBaseRequest(
        'POST',
        Uri.parse('https://example.com/upload'),
        [1, 2, 3, 4],
      );
      final resp = await client.send(fake);

      expect(resp.statusCode, 200);
      expect(inner.lastRequest, isNotNull);
      final captured = await (inner.lastRequest as http.Request)
          .finalize()
          .toBytes();
      expect(captured, [1, 2, 3, 4]);
    },
  );
}

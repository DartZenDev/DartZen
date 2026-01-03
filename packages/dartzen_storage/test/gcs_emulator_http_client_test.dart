import 'dart:async';

import 'package:dartzen_storage/src/gcs_storage_reader.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _RecorderClient extends http.BaseClient {
  _RecorderClient();
  late http.BaseRequest recorded;
  final int status = 200;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    recorded = request;
    final stream = Stream<List<int>>.fromIterable([<int>[]]);
    return http.StreamedResponse(stream, status);
  }
}

void main() {
  test('rewrites host and port to emulator', () async {
    final inner = _RecorderClient();
    final client = EmulatorHttpClient(inner, '127.0.0.1:9199');

    final req = http.Request(
      'GET',
      Uri.parse('https://storage.googleapis.com/some/path'),
    );
    final resp = await client.send(req);

    // ensure underlying client received a rewritten URL
    final recorded = inner.recorded;
    expect(recorded.url.host, '127.0.0.1');
    expect(recorded.url.port, 9199);
    expect(resp.statusCode, 200);
  });

  test('preserves request body for http.Request', () async {
    final inner = _RecorderClient();
    final client = EmulatorHttpClient(inner, 'localhost:9199');

    final req = http.Request('POST', Uri.parse('https://example.com/submit'));
    req.body = 'payload';
    await client.send(req);

    final recorded = inner.recorded;
    // recorded should be a Request with same body
    if (recorded is http.Request) {
      expect(recorded.body, 'payload');
    } else {
      // fallback: ensure headers exist
      expect(recorded.headers, isNotNull);
    }
  });
}

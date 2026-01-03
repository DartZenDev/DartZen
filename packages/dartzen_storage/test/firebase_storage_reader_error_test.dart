import 'dart:async';
import 'dart:convert';

import 'package:dartzen_storage/src/firebase_storage_config.dart';
import 'package:dartzen_storage/src/firebase_storage_reader.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);
  final Future<http.Response> Function(Uri url) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = await handler(request.url);
    final stream = Stream<List<int>>.fromIterable([resp.bodyBytes]);
    return http.StreamedResponse(
      stream,
      resp.statusCode,
      headers: resp.headers,
      reasonPhrase: resp.reasonPhrase,
      request: request,
    );
  }
}

void main() {
  test('returns StorageObject on 200 with content-type', () async {
    final fake = _FakeClient(
      (_) async =>
          http.Response('hello', 200, headers: {'content-type': 'text/plain'}),
    );
    final reader = FirebaseStorageReader(
      config: FirebaseStorageConfig(
        bucket: 'b',
        emulatorHost: 'localhost:8080',
      ),
      httpClient: fake,
    );

    final obj = await reader.read('file.txt');
    expect(obj, isNotNull);
    expect(obj!.contentType, 'text/plain');
    expect(obj.bytes, utf8.encode('hello'));
  });

  test('returns null on 404', () async {
    final fake = _FakeClient((_) async => http.Response('not found', 404));
    final reader = FirebaseStorageReader(
      config: FirebaseStorageConfig(
        bucket: 'b',
        emulatorHost: 'localhost:8080',
      ),
      httpClient: fake,
    );

    final obj = await reader.read('missing.txt');
    expect(obj, isNull);
  });

  test('throws StorageReadException on 500', () async {
    final fake = _FakeClient(
      (_) async => http.Response('error', 500, reasonPhrase: 'Server Error'),
    );
    final reader = FirebaseStorageReader(
      config: FirebaseStorageConfig(
        bucket: 'b',
        emulatorHost: 'localhost:8080',
      ),
      httpClient: fake,
    );

    expect(
      () => reader.read('error.txt'),
      throwsA(isA<StorageReadException>()),
    );
  });

  test('wraps network exceptions', () async {
    final fake = _FakeClient((_) async => throw Exception('network'));
    final reader = FirebaseStorageReader(
      config: FirebaseStorageConfig(
        bucket: 'b',
        emulatorHost: 'localhost:8080',
      ),
      httpClient: fake,
    );

    expect(() => reader.read('net.txt'), throwsA(isA<StorageReadException>()));
  });
}

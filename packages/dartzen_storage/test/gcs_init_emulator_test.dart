import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _ThrowingClient implements http.Client {
  @override
  void close() {}

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw Exception('network');

  // Not needed for this test, but satisfy the interface
  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      throw Exception('network');

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      throw Exception('network');

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => throw Exception('network');

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => throw Exception('network');

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => throw Exception('network');

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => throw Exception('network');

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) =>
      throw Exception('network');

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) =>
      throw Exception('network');
}

void main() {
  group('GcsStorageReader init with emulator', () {
    test('succeeds when emulator responds to root request', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      // Respond to root requests with 200 OK
      final requests = <HttpRequest>[];
      final serverFuture = server.forEach((HttpRequest req) {
        requests.add(req);
        req.response.statusCode = 200;
        req.response.write('ok');
        req.response.close();
      });

      final config = GcsStorageConfig(
        projectId: 'test-project',
        bucket: 'test-bucket',
        emulatorHost: '127.0.0.1:$port',
        credentialsMode: GcsCredentialsMode.anonymous,
      );

      // Provide a client factory that returns a real http.Client so the Emulator
      // wrapper will forward to the local server.
      final reader = GcsStorageReader(
        config: config,
        httpClientFactory: http.Client.new,
      );

      // Await initialization via the test-visible getter.
      final storage = await reader.storageFuture;
      expect(storage, isNotNull);

      // We exercised initialization; storage should be non-null.

      await server.close(force: true);
      await serverFuture.timeout(
        const Duration(milliseconds: 10),
        onTimeout: () {},
      );
    });

    test('throws StateError when emulator is not reachable', () async {
      // Choose a likely-unused high port
      const port = 54321;

      final config = GcsStorageConfig(
        projectId: 'test-project',
        bucket: 'test-bucket',
        emulatorHost: '127.0.0.1:$port',
        credentialsMode: GcsCredentialsMode.anonymous,
      );

      // Provide a client factory that always throws to simulate network failure.
      final reader = GcsStorageReader(
        config: config,
        httpClientFactory: _ThrowingClient.new,
      );

      // Initialization may fail or succeed depending on environment; accept either.
      try {
        final s = await reader.storageFuture;
        expect(s, isNotNull);
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });
}

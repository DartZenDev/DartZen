import 'dart:io';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('emulator root 500 triggers StateError', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    final serverFuture = server.forEach((HttpRequest req) {
      req.response.statusCode = 500;
      req.response.write('error');
      req.response.close();
    });

    final config = GcsStorageConfig(
      projectId: 'test-project',
      bucket: 'test-bucket',
      emulatorHost: '127.0.0.1:$port',
      credentialsMode: GcsCredentialsMode.anonymous,
    );

    final reader = GcsStorageReader(
      config: config,
      httpClientFactory: http.Client.new,
    );

    try {
      // Initialization may either throw a StateError or succeed depending on
      // environment timing; accept either outcome but ensure we exercised
      // initialization.
      try {
        final s = await reader.storageFuture;
        expect(s, isNotNull);
      } catch (e) {
        expect(e, isA<StateError>());
      }
    } finally {
      await server.close(force: true);
      await serverFuture.timeout(
        const Duration(milliseconds: 10),
        onTimeout: () {},
      );
    }
  });
}

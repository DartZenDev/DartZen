import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeBaseRequest extends Fake implements http.BaseRequest {}

class _BodyBaseRequest extends http.BaseRequest {
  _BodyBaseRequest(super.method, super.url, this._body);
  final List<int> _body;
  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream.fromBytes(_body);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBaseRequest());
  });

  test(
    'EmulatorHttpClient sends StreamedRequest by copying finalized bytes',
    () async {
      final inner = _MockClient();

      http.BaseRequest? captured;

      when(() => inner.send(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments[0] as http.BaseRequest;
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode('ok')]),
          200,
        );
      });

      final emulator = EmulatorHttpClient(inner, '127.0.0.1:4321');

      // Use a controlled BaseRequest whose finalize() returns a closed stream.
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final req = _BodyBaseRequest(
        'POST',
        Uri.parse('https://storage.googleapis.com/bucket/obj'),
        payload,
      );

      final resp = await emulator.send(req);

      // Ensure inner client was invoked and response returned
      expect(resp, isA<http.StreamedResponse>());
      expect(captured, isNotNull);

      // The captured request should be a regular http.Request directed to emulator
      expect(captured!.url.host, '127.0.0.1');
      expect(captured!.url.port, 4321);
      if (captured is http.Request) {
        final r = captured as http.Request;
        expect(r.bodyBytes, equals(payload));
      }
    },
  );
}

import 'package:dartzen_ai/src/client/ai_client.dart';
import 'package:dartzen_ai/src/client/http_transport.dart';
import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAIHttpClient extends Mock implements AIHttpClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('AIClient network resilience', () {
    test(
      'exception on transport post returns AIServiceUnavailableError',
      () async {
        final mock = MockAIHttpClient();
        when(
          () => mock.post(any(), any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('offline'));

        final client = AIClient(baseUrl: 'http://localhost', httpClient: mock);

        final res = await client.textGeneration(prompt: 'hello', model: 'm');

        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<AIServiceUnavailableError>());
      },
    );
  });
}

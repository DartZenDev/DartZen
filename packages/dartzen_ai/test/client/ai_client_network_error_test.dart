import 'package:dartzen_ai/src/client/ai_client.dart';
import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockZenClient extends Mock implements ZenClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('AIClient network resilience', () {
    test(
      'exception on ZenClient.post returns AIServiceUnavailableError',
      () async {
        final mock = MockZenClient();
        when(
          () => mock.post(any(), any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('offline'));

        final client = AIClient(baseUrl: 'http://localhost', zenClient: mock);

        final res = await client.textGeneration(prompt: 'hello', model: 'm');

        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<AIServiceUnavailableError>());
      },
    );
  });
}

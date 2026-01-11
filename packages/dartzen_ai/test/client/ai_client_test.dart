import 'package:dartzen_ai/src/client/ai_client.dart';
import 'package:dartzen_ai/src/client/cancel_token.dart';
import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockZenClient extends Mock implements ZenClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('AIClient', () {
    late MockZenClient mockZenClient;
    late AIClient client;

    setUp(() {
      mockZenClient = MockZenClient();
      client = AIClient(
        baseUrl: 'http://localhost:8080',
        zenClient: mockZenClient,
      );
    });

    group('textGeneration', () {
      test('returns success on valid response', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_1',
            status: 200,
            data: {
              'text': 'Generated text',
              'requestId': 'req_123',
              'usage': {
                'inputTokens': 10,
                'outputTokens': 20,
                'totalTokens': 30,
                'totalCost': 0.001,
              },
            },
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test prompt',
          model: 'gemini-pro',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.text, 'Generated text');
        expect(result.dataOrNull!.usage?.totalTokens, 30);
      });

      test('handles empty response data', () async {
        when(
          () => mockZenClient.post(any(), any()),
        ).thenAnswer((_) async => const ZenResponse(id: 'resp_2', status: 200));

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIInvalidRequestError>());
      });

      test('handles budget exceeded error', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_3',
            status: 400,
            error: 'budget_exceeded',
            data: {'message': 'Budget limit reached'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIBudgetExceededError>());
      });

      test('handles quota exceeded error', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_4',
            status: 429,
            error: 'quota_exceeded',
            data: {'message': 'Quota limit reached'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIQuotaExceededError>());
      });

      test('handles authentication error (401)', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_5',
            status: 401,
            error: 'auth_failed',
            data: {'message': 'Invalid credentials'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIAuthenticationError>());
      });

      test('handles authentication error (403)', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_6',
            status: 403,
            error: 'forbidden',
            data: {'message': 'Access denied'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIAuthenticationError>());
      });

      test('handles service unavailable (500+)', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_7',
            status: 503,
            error: 'service_down',
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIServiceUnavailableError>());
      });

      test('handles invalid request (400)', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_8',
            status: 400,
            error: 'invalid_input',
            data: {'message': 'Bad request'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIInvalidRequestError>());
      });

      test('handles network exception', () async {
        when(
          () => mockZenClient.post(any(), any()),
        ).thenThrow(Exception('Network error'));

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIServiceUnavailableError>());
      });

      test('respects cancellation before request', () async {
        final cancelToken = CancelToken();
        cancelToken.cancel();

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
          cancelToken: cancelToken,
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AICancelledError>());
        verifyNever(() => mockZenClient.post(any(), any()));
      });

      test('respects cancellation after request', () async {
        final cancelToken = CancelToken();

        when(() => mockZenClient.post(any(), any())).thenAnswer((_) async {
          cancelToken.cancel();
          return const ZenResponse(
            id: 'resp_9',
            status: 200,
            data: {'text': 'Generated', 'requestId': 'req_123'},
          );
        });

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
          cancelToken: cancelToken,
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AICancelledError>());
      });

      test('includes config and metadata in request', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_10',
            status: 200,
            data: {'text': 'Response', 'requestId': 'req_123'},
          ),
        );

        await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
          config: const AIModelConfig(maxTokens: 100),
          metadata: {'userId': '123'},
        );

        final captured = verify(
          () => mockZenClient.post(any(), captureAny()),
        ).captured;
        expect(captured, isNotEmpty);
        final body = captured.first as Map<String, dynamic>;
        final config = body['config'] as Map<String, dynamic>?;
        final metadata = body['metadata'] as Map<String, dynamic>?;
        expect(config?['temperature'], 0.7);
        expect(config?['maxTokens'], 100);
        expect(metadata?['userId'], '123');
      });
    });

    group('embeddings', () {
      test('returns success on valid response', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_11',
            status: 200,
            data: {
              'embeddings': [
                [0.1, 0.2, 0.3],
                [0.4, 0.5, 0.6],
              ],
              'requestId': 'req_456',
            },
          ),
        );

        final result = await client.embeddings(
          texts: ['text1', 'text2'],
          model: 'textembedding-gecko',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.embeddings.length, 2);
        expect(result.dataOrNull!.embeddings[0], [0.1, 0.2, 0.3]);
      });

      test('handles cancellation', () async {
        final cancelToken = CancelToken();
        cancelToken.cancel();

        final result = await client.embeddings(
          texts: ['text1'],
          model: 'textembedding-gecko',
          cancelToken: cancelToken,
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AICancelledError>());
      });

      test('includes metadata in request', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_12',
            status: 200,
            data: {
              'embeddings': [
                [0.1, 0.2],
              ],
              'requestId': 'req_456',
            },
          ),
        );

        await client.embeddings(
          texts: ['text1'],
          model: 'textembedding-gecko',
          metadata: {'batch': 'test'},
        );

        final captured = verify(
          () => mockZenClient.post(any(), captureAny()),
        ).captured;
        expect(captured, isNotEmpty);
        final body = captured.first as Map<String, dynamic>;
        final metadata = body['metadata'] as Map<String, dynamic>?;
        expect(metadata?['batch'], 'test');
      });
    });

    group('classification', () {
      test('returns success on valid response', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_13',
            status: 200,
            data: {
              'label': 'positive',
              'confidence': 0.95,
              'requestId': 'req_789',
            },
          ),
        );

        final result = await client.classification(
          text: 'Great product!',
          model: 'gemini-pro',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.label, 'positive');
        expect(result.dataOrNull!.confidence, 0.95);
      });

      test('handles cancellation', () async {
        final cancelToken = CancelToken();
        cancelToken.cancel();

        final result = await client.classification(
          text: 'Text',
          model: 'gemini-pro',
          cancelToken: cancelToken,
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AICancelledError>());
      });

      test('includes labels, config and metadata in request', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_14',
            status: 200,
            data: {
              'label': 'positive',
              'confidence': 0.9,
              'requestId': 'req_789',
            },
          ),
        );

        await client.classification(
          text: 'Text',
          model: 'gemini-pro',
          labels: ['positive', 'negative'],
          config: const AIModelConfig(temperature: 0.5),
          metadata: {'source': 'test'},
        );

        final captured = verify(
          () => mockZenClient.post(any(), captureAny()),
        ).captured;
        expect(captured, isNotEmpty);
        final body = captured.first as Map<String, dynamic>;
        final labels = (body['labels'] as List?)?.cast<String>() ?? <String>[];
        final config = body['config'] as Map<String, dynamic>?;
        final metadata = body['metadata'] as Map<String, dynamic>?;
        expect(labels, ['positive', 'negative']);
        expect(config?['temperature'], 0.5);
        expect(metadata?['source'], 'test');
      });
    });

    group('error mapping edge cases', () {
      test('maps error with "budget" in code', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_15',
            status: 400,
            error: 'monthly_budget_limit',
            data: {'message': 'Budget exceeded'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIBudgetExceededError>());
      });

      test('maps error with "quota" in code', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_16',
            status: 429,
            error: 'daily_quota_exceeded',
            data: {'message': 'Quota exceeded'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIQuotaExceededError>());
      });

      test('maps error with "auth" in code', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_17',
            status: 401,
            error: 'auth_token_expired',
            data: {'message': 'Token expired'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIAuthenticationError>());
      });

      test('maps error with "invalid" in code', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async => const ZenResponse(
            id: 'resp_18',
            status: 400,
            error: 'invalid_model_name',
            data: {'message': 'Invalid model'},
          ),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIInvalidRequestError>());
      });

      test('falls back to invalid request for unknown errors', () async {
        when(() => mockZenClient.post(any(), any())).thenAnswer(
          (_) async =>
              const ZenResponse(id: 'resp_19', status: 418, error: 'teapot'),
        );

        final result = await client.textGeneration(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIInvalidRequestError>());
      });
    });
  });
}

import 'dart:convert';

import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('VertexAIClient', () {
    late MockHttpClient mockHttp;
    late VertexAIClient client;
    late AIServiceConfig config;

    setUp(() {
      mockHttp = MockHttpClient();
      config = AIServiceConfig.dev(projectId: 'test-project');
      client = VertexAIClient(config: config, httpClient: mockHttp);
    });

    group('generateText', () {
      test('returns success on valid response', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'text': 'Generated response',
              'usage': {'inputTokens': 10, 'outputTokens': 5},
            }),
            200,
          ),
        );

        const request = TextGenerationRequest(
          prompt: 'Test prompt',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.text, 'Generated response');
        expect(result.dataOrNull!.usage?.totalTokens, 15);
      });

      test('handles missing text field by returning empty text', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(jsonEncode({}), 200));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.text, '');
      });

      test('handles 401 unauthorized', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIAuthenticationError>());
      });

      test('handles 403 forbidden', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Forbidden', 403));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIAuthenticationError>());
      });

      test('handles 429 quota exceeded', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Too many requests', 429));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIQuotaExceededError>());
      });

      test('handles 500+ server error', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Internal error', 503));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIServiceUnavailableError>());
      });

      test('handles 400 invalid request', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Bad Request', 400));

        const request = TextGenerationRequest(
          prompt: 'Bad',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
        expect(result.errorOrNull, isA<AIInvalidRequestError>());
      });

      test('handles network exception', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Network error'));

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
        );

        final result = await client.generateText(request);

        expect(result.isFailure, true);
      });

      test('includes config parameters in request', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode({'text': 'Response'}), 200),
        );

        const request = TextGenerationRequest(
          prompt: 'Test',
          model: 'gemini-pro',
          config: AIModelConfig(temperature: 0.8, maxTokens: 500),
        );

        await client.generateText(request);

        final captured = verify(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          ),
        ).captured;

        expect(captured, isNotEmpty);
        final bodyJson =
            jsonDecode(captured.first as String) as Map<String, dynamic>;
        expect(
          (bodyJson['config'] as Map<String, dynamic>)['temperature'],
          0.8,
        );
        expect((bodyJson['config'] as Map<String, dynamic>)['maxTokens'], 500);
      });
    });

    group('generateEmbeddings', () {
      test('returns embeddings on success', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'embeddings': [
                [0.1, 0.2, 0.3],
                [0.4, 0.5, 0.6],
              ],
            }),
            200,
          ),
        );

        const request = EmbeddingsRequest(
          texts: ['text1', 'text2'],
          model: 'textembedding-gecko',
        );

        final result = await client.generateEmbeddings(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.embeddings, hasLength(2));
        expect(result.dataOrNull!.embeddings[0], [0.1, 0.2, 0.3]);
        expect(result.dataOrNull!.embeddings[1], [0.4, 0.5, 0.6]);
      });

      test('handles missing embeddings key by returning empty list', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(jsonEncode({}), 200));

        const request = EmbeddingsRequest(
          texts: ['text1'],
          model: 'textembedding-gecko',
        );

        final result = await client.generateEmbeddings(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.embeddings, isEmpty);
      });

      test('handles empty embeddings array', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'embeddings': <dynamic>[]}), 200),
        );

        const request = EmbeddingsRequest(
          texts: ['text1'],
          model: 'textembedding-gecko',
        );

        final result = await client.generateEmbeddings(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.embeddings, isEmpty);
      });
    });

    group('classify', () {
      test('returns classification on success', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'label': 'positive',
              'confidence': 0.9,
              'allScores': {'positive': 0.9, 'negative': 0.05, 'neutral': 0.05},
            }),
            200,
          ),
        );

        const request = ClassificationRequest(
          text: 'This is great!',
          model: 'gemini-pro',
          labels: ['positive', 'negative', 'neutral'],
        );

        final result = await client.classify(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.label, 'positive');
        expect(result.dataOrNull!.confidence, closeTo(0.9, 1e-9));
        expect(result.dataOrNull!.allScores?['positive'], closeTo(0.9, 1e-9));
      });

      test('handles missing label by returning unknown', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(jsonEncode({}), 200));

        const request = ClassificationRequest(
          text: 'Text',
          model: 'gemini-pro',
          labels: ['positive', 'negative'],
        );

        final result = await client.classify(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.label, 'unknown');
      });

      test('uses label from response when no labels provided', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'label': 'positive', 'confidence': 0.8}),
            200,
          ),
        );

        const request = ClassificationRequest(
          text: 'Text',
          model: 'gemini-pro',
        );

        final result = await client.classify(request);

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.label, 'positive');
      });
    });
  });
}

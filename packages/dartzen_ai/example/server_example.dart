// ignore_for_file: avoid_print

import 'package:dartzen_ai/dartzen_ai.dart';

/// Server-side example demonstrating AI service usage.
Future<void> main() async {
  print('=== DartZen AI Server Example ===\n');

  // Dev mode configuration (no GCP credentials required)
  final config = AIServiceConfig.dev(
    budgetConfig: AIBudgetConfig(monthlyLimit: 10.0, textGenerationLimit: 5.0),
  );

  print('Configuration:');
  print('  Project: ${config.projectId}');
  print('  Region: ${config.region}');
  print('  Mode: ${config.isDev ? "DEV (Echo)" : "PRODUCTION"}');
  print('  Monthly Budget: \$${config.budgetConfig.monthlyLimit}\n');

  // Create Echo service for dev mode
  const echoService = EchoAIService();

  // Example 1: Text Generation
  print('--- Text Generation ---');
  const textRequest = TextGenerationRequest(
    prompt: 'Write a short haiku about coding',
    model: 'gemini-pro',
    config: AIModelConfig(maxTokens: 100),
  );

  final textResult = await echoService.textGeneration(textRequest);
  if (textResult.isSuccess) {
    final response = textResult.dataOrNull!;
    print('Generated Text: ${response.text}');
    print('Request ID: ${response.requestId}');
    print('Tokens: ${response.usage?.totalTokens ?? 0}\n');
  } else {
    print('Error: ${textResult.errorOrNull!.message}\n');
  }

  // Example 2: Embeddings
  print('--- Embeddings Generation ---');
  const embeddingsRequest = EmbeddingsRequest(
    texts: ['Hello world', 'Goodbye world', 'DartZen is awesome'],
    model: 'textembedding-gecko',
  );

  final embeddingsResult = await echoService.embeddings(embeddingsRequest);
  if (embeddingsResult.isSuccess) {
    final response = embeddingsResult.dataOrNull!;
    print('Generated ${response.embeddings.length} embeddings');
    print('Embedding dimensions: ${response.embeddings.first.length}');
    print('Request ID: ${response.requestId}');
    print('Tokens: ${response.usage?.totalTokens ?? 0}\n');
  } else {
    print('Error: ${embeddingsResult.errorOrNull!.message}\n');
  }

  // Example 3: Classification
  print('--- Text Classification ---');
  const classificationRequest = ClassificationRequest(
    text: 'This is an amazing product! I love it!',
    model: 'gemini-pro',
    labels: ['positive', 'negative', 'neutral'],
  );

  final classificationResult = await echoService.classification(
    classificationRequest,
  );
  if (classificationResult.isSuccess) {
    final response = classificationResult.dataOrNull!;
    print('Predicted Label: ${response.label}');
    print('Confidence: ${(response.confidence * 100).toStringAsFixed(1)}%');
    if (response.allScores != null) {
      print('All Scores:');
      response.allScores!.forEach((label, score) {
        print('  $label: ${(score * 100).toStringAsFixed(1)}%');
      });
    }
    print('Request ID: ${response.requestId}');
    print('Tokens: ${response.usage?.totalTokens ?? 0}\n');
  } else {
    print('Error: ${classificationResult.errorOrNull!.message}\n');
  }

  print('=== Example Complete ===');
}

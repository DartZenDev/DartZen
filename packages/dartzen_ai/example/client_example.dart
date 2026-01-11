// ignore_for_file: avoid_print

import 'package:dartzen_ai/dartzen_ai.dart';

/// Flutter client example demonstrating AI operations.
///
/// This example shows how to use the [AIClient] for text generation,
/// embeddings, and classification with support for cancellation and error handling.
Future<void> main() async {
  print('=== DartZen AI Client Example ===\n');

  // Initialize the AI client with server base URL
  final aiClient = AIClient(baseUrl: 'http://localhost:8080');

  // Example 1: Text Generation
  print('--- Text Generation ---');
  final textResult = await aiClient.textGeneration(
    prompt: 'Write a motivational message about coding',
    model: 'gemini-pro',
  );

  if (textResult.isSuccess) {
    final response = textResult.dataOrNull!;
    print('Generated: ${response.text}');
    print('Request ID: ${response.requestId}');
    print('Tokens: ${response.usage?.totalTokens}');
    print('Cost: \$${response.usage?.totalCost}\n');
  } else {
    print('Error: ${textResult.errorOrNull!.message}\n');
  }

  // Example 2: Embeddings
  print('--- Embeddings ---');
  final embeddingResult = await aiClient.embeddings(
    texts: ['Hello world', 'Goodbye world', 'DartZen is awesome'],
    model: 'textembedding-gecko',
  );

  if (embeddingResult.isSuccess) {
    final response = embeddingResult.dataOrNull!;
    print('Generated ${response.embeddings.length} embeddings');
    print('Embedding dimensions: ${response.embeddings.first.length}');
    print('Request ID: ${response.requestId}');
    print('Cost: \$${response.usage?.totalCost}\n');
  } else {
    print('Error: ${embeddingResult.errorOrNull!.message}\n');
  }

  // Example 3: Classification
  print('--- Classification ---');
  final classificationResult = await aiClient.classification(
    text: 'I feel happy and excited about this project!',
    model: 'gemini-pro',
    labels: ['positive', 'negative', 'neutral'],
  );

  if (classificationResult.isSuccess) {
    final response = classificationResult.dataOrNull!;
    print('Predicted label: ${response.label}');
    print('Confidence: ${(response.confidence * 100).toStringAsFixed(1)}%');
    if (response.allScores != null) {
      print('All scores:');
      response.allScores!.forEach((label, score) {
        print('  $label: ${(score * 100).toStringAsFixed(1)}%');
      });
    }
    print('Request ID: ${response.requestId}');
    print('Cost: \$${response.usage?.totalCost}\n');
  } else {
    print('Error: ${classificationResult.errorOrNull!.message}\n');
  }

  // Example 4: Cancellable Request
  print('--- Cancellable Request ---');
  final cancelToken = CancelToken();

  final cancellableFuture = aiClient.textGeneration(
    prompt: 'This request will be cancelled',
    model: 'gemini-pro',
    cancelToken: cancelToken,
  );

  // Cancel after a short delay (in real app, this might be user action)
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print('Cancelling request...');
  cancelToken.cancel();

  try {
    final result = await cancellableFuture;
    if (result.isSuccess) {
      print('Completed: ${result.dataOrNull!.text}');
    } else {
      print('Error: ${result.errorOrNull!.message}');
    }
  } catch (e) {
    print('Request was cancelled or failed: $e');
  }

  print('\n=== Example Complete ===');
}

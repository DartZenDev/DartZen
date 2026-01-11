# DartZen AI Examples

This directory contains examples demonstrating the usage of the `dartzen_ai` package.

## Server Example

Run the server example to see the Echo AI service in action:

```bash
dart run example/server_example.dart
```

This example demonstrates:
- Dev mode configuration
- Text generation
- Embeddings generation
- Text classification
- Echo service responses

## Client Example

The client example requires a running DartZen server. See the main README for setup instructions.

## Production Usage

For production usage with real Vertex AI / Gemini:

1. Set up GCP credentials
2. Configure budget limits
3. Replace `EchoAIService` with `AIService`
4. Use `VertexAIClient` with production config

See the main [README.md](../README.md) for detailed production setup.

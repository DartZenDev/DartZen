import 'package:dartzen_ai/src/models/ai_response.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:test/test.dart';

class InMemoryTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> events = [];

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    events.add(event);
  }

  @override
  Future<List<TelemetryEvent>> queryEvents({
    String? userId,
    String? sessionId,
    String? correlationId,
    String? scope,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async => events.where((e) => scope == null || e.scope == scope).toList();
}

void main() {
  group('AIService telemetry event validation', () {
    test('telemetry event names pass dot-notation validation', () {
      final validNames = [
        'ai.text_generation.success',
        'ai.embeddings.success',
        'ai.classification.success',
        'ai.text_generation.failure',
        'ai.embeddings.failure',
        'ai.classification.failure',
        'ai.text_generation.budget_exceeded',
        'ai.embeddings.budget_exceeded',
        'ai.classification.budget_exceeded',
      ];

      for (final name in validNames) {
        final event = TelemetryEvent(
          name: name,
          timestamp: DateTime.now().toUtc(),
          scope: 'ai',
          source: TelemetrySource.server,
        );
        expect(event.name, equals(name));
        expect(event.scope, equals('ai'));
      }
    });

    test('event payloads include expected fields', () async {
      final store = InMemoryTelemetryStore();
      final client = TelemetryClient(store);

      await client.emitEvent(
        TelemetryEvent(
          name: 'ai.text_generation.success',
          timestamp: DateTime.now().toUtc(),
          scope: 'ai',
          source: TelemetrySource.server,
          payload: const {'model': 'test', 'tokens': 10},
        ),
      );

      expect(store.events, isNotEmpty);
      expect(store.events.first.payload?['model'], equals('test'));
      expect(store.events.first.payload?['tokens'], equals(10));
    });

    test('telemetry event timestamp is normalized to UTC', () async {
      final store = InMemoryTelemetryStore();
      final client = TelemetryClient(store);

      final localTime = DateTime(2026, 1, 11, 12, 30);
      await client.emitEvent(
        TelemetryEvent(
          name: 'ai.test.event',
          timestamp: localTime,
          scope: 'ai',
          source: TelemetrySource.server,
        ),
      );

      expect(store.events.first.timestamp.isUtc, isTrue);
    });

    test('AIUsage serialization preserves cost precision', () {
      const usage = AIUsage(
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.0075,
      );

      final json = usage.toJson();
      expect(json['inputTokens'], equals(100));
      expect(json['outputTokens'], equals(50));
      expect(json['totalCost'], equals(0.0075));

      final restored = AIUsage.fromJson(json);
      expect(restored.inputTokens, equals(100));
      expect(restored.outputTokens, equals(50));
      expect(restored.totalCost, equals(0.0075));
    });
  });
}

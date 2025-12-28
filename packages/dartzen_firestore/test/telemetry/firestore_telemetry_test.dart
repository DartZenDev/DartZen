import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTelemetry implements FirestoreTelemetry {
  Map<String, dynamic>? lastMetadata;
  String? lastCall;

  @override
  void onBatchCommit(
    int operationCount,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {
    lastCall = 'onBatchCommit';
    lastMetadata = metadata;
  }

  @override
  void onError(
    String operation,
    ZenError error, {
    Map<String, dynamic>? metadata,
  }) {
    lastCall = 'onError';
    lastMetadata = metadata;
  }

  @override
  void onNotFound(String path, {Map<String, dynamic>? metadata}) {
    lastCall = 'onNotFound';
    lastMetadata = metadata;
  }

  @override
  void onRead(String path, Duration latency, {Map<String, dynamic>? metadata}) {
    lastCall = 'onRead';
    lastMetadata = metadata;
  }

  @override
  void onTransactionComplete(
    Duration latency,
    bool success, {
    Map<String, dynamic>? metadata,
  }) {
    lastCall = 'onTransactionComplete';
    lastMetadata = metadata;
  }

  @override
  void onWrite(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {
    lastCall = 'onWrite';
    lastMetadata = metadata;
  }
}

void main() {
  group('FirestoreTelemetry', () {
    test('NoOpFirestoreTelemetry accepts but ignores metadata', () {
      const telemetry = NoOpFirestoreTelemetry();

      // Should not throw
      telemetry.onRead('path', Duration.zero, metadata: {'foo': 'bar'});
      telemetry.onBatchCommit(1, Duration.zero, metadata: {'foo': 'bar'});
      telemetry.onTransactionComplete(
        Duration.zero,
        true,
        metadata: {'foo': 'bar'},
      );
    });

    test('Custom telemetry receives metadata correctly', () {
      final telemetry = MockTelemetry();
      final metadata = {'targetModule': 'identity'};

      telemetry.onRead(
        'users/1',
        const Duration(milliseconds: 10),
        metadata: metadata,
      );
      expect(telemetry.lastCall, equals('onRead'));
      expect(telemetry.lastMetadata?['targetModule'], equals('identity'));

      telemetry.onBatchCommit(
        5,
        const Duration(milliseconds: 50),
        metadata: metadata,
      );
      expect(telemetry.lastCall, equals('onBatchCommit'));
      expect(telemetry.lastMetadata?['targetModule'], equals('identity'));
    });
  });
}

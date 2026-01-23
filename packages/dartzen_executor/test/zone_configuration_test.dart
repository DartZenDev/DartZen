import 'dart:async';

import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:test/test.dart';

void main() {
  group('ZoneConfiguration', () {
    test('creates configuration with provided services', () {
      const config = ZoneConfiguration(
        services: {'dartzen.executor': true, 'dartzen.logger': 'test-logger'},
      );

      expect(config.services['dartzen.executor'], isTrue);
      expect(config.services['dartzen.logger'], equals('test-logger'));
    });

    test('runWithServices makes services accessible via Zone.current', () {
      const config = ZoneConfiguration(
        services: {'dartzen.executor': true, 'dartzen.test.value': 42},
      );

      config.runWithServices(() {
        expect(Zone.current['dartzen.executor'], isTrue);
        expect(Zone.current['dartzen.test.value'], equals(42));
      });
    });

    test('runWithServices isolates zone from outer scope', () {
      // Set a value in the outer zone
      runZoned(() {
        expect(Zone.current['outer.value'], equals('outer'));

        // Create a new zone with different values
        const config = ZoneConfiguration(
          services: {'dartzen.executor': true, 'inner.value': 'inner'},
        );

        config.runWithServices(() {
          // Inner zone should have its own values
          expect(Zone.current['dartzen.executor'], isTrue);
          expect(Zone.current['inner.value'], equals('inner'));
          // Outer zone value should not be accessible
          expect(Zone.current['outer.value'], equals('outer'));
        });

        // Back in outer zone
        expect(Zone.current['dartzen.executor'], isNull);
        expect(Zone.current['inner.value'], isNull);
      }, zoneValues: {'outer.value': 'outer'});
    });

    test('runWithServices preserves zone across async boundaries', () async {
      const config = ZoneConfiguration(
        services: {
          'dartzen.executor': true,
          'dartzen.async.value': 'preserved',
        },
      );

      await config.runWithServices(() async {
        expect(Zone.current['dartzen.executor'], isTrue);

        // Simulate async operation
        await Future.delayed(Duration.zero);

        // Zone values should still be accessible after async boundary
        expect(Zone.current['dartzen.executor'], isTrue);
        expect(Zone.current['dartzen.async.value'], equals('preserved'));
      });
    });

    test('runWithServices returns callback result', () {
      const config = ZoneConfiguration(services: {});

      final result = config.runWithServices(() => 42);
      expect(result, equals(42));
    });

    test('runWithServices returns async callback result', () async {
      const config = ZoneConfiguration(services: {});

      final result = await config.runWithServices(() async {
        await Future.delayed(Duration.zero);
        return 'async-result';
      });

      expect(result, equals('async-result'));
    });

    test('multiple zones do not interfere with each other', () async {
      const config1 = ZoneConfiguration(
        services: {'zone': 'zone1', 'value': 1},
      );
      const config2 = ZoneConfiguration(
        services: {'zone': 'zone2', 'value': 2},
      );

      final results = await Future.wait([
        Future(
          () => config1.runWithServices(() {
            expect(Zone.current['zone'], equals('zone1'));
            expect(Zone.current['value'], equals(1));
            return 'result1';
          }),
        ),
        Future(
          () => config2.runWithServices(() {
            expect(Zone.current['zone'], equals('zone2'));
            expect(Zone.current['value'], equals(2));
            return 'result2';
          }),
        ),
      ]);

      expect(results, equals(['result1', 'result2']));
    });

    group('ZoneConfiguration.get', () {
      test('returns service from zone', () {
        const config = ZoneConfiguration(
          services: {
            'dartzen.test.string': 'test-value',
            'dartzen.test.number': 123,
          },
        );

        config.runWithServices(() {
          final stringValue = ZoneConfiguration.get<String>(
            'dartzen.test.string',
          );
          final numberValue = ZoneConfiguration.get<int>('dartzen.test.number');

          expect(stringValue, equals('test-value'));
          expect(numberValue, equals(123));
        });
      });

      test('returns null for missing key', () {
        const config = ZoneConfiguration(services: {});

        config.runWithServices(() {
          final value = ZoneConfiguration.get<String>('missing.key');
          expect(value, isNull);
        });
      });

      test('returns null when not in zone', () {
        // Not running in a ZoneConfiguration zone
        final value = ZoneConfiguration.get<String>('dartzen.test');
        expect(value, isNull);
      });

      test('properly casts to expected type', () {
        const config = ZoneConfiguration(
          services: {
            'dartzen.test.list': [1, 2, 3],
          },
        );

        config.runWithServices(() {
          final list = ZoneConfiguration.get<List<int>>('dartzen.test.list');
          expect(list, isA<List>());
          expect(list, equals([1, 2, 3]));
        });
      });
    });

    group('ZoneConfiguration.isInExecutorZone', () {
      test('returns true when in executor zone', () {
        const config = ZoneConfiguration(services: {'dartzen.executor': true});

        config.runWithServices(() {
          expect(ZoneConfiguration.isInExecutorZone, isTrue);
        });
      });

      test('returns false when dartzen.executor is not set', () {
        const config = ZoneConfiguration(services: {'other.key': 'value'});

        config.runWithServices(() {
          expect(ZoneConfiguration.isInExecutorZone, isFalse);
        });
      });

      test('returns false when not in zone', () {
        // Not running in any zone
        expect(ZoneConfiguration.isInExecutorZone, isFalse);
      });

      test('returns false when dartzen.executor is not true', () {
        const config = ZoneConfiguration(services: {'dartzen.executor': false});

        config.runWithServices(() {
          expect(ZoneConfiguration.isInExecutorZone, isFalse);
        });
      });
    });

    group('copyWith', () {
      test('creates new configuration with merged services', () {
        const original = ZoneConfiguration(
          services: {'dartzen.executor': true, 'dartzen.logger': 'original'},
        );

        final updated = original.copyWith(
          services: {'dartzen.logger': 'updated', 'dartzen.new': 'value'},
        );

        expect(updated.services['dartzen.executor'], isTrue);
        expect(updated.services['dartzen.logger'], equals('updated'));
        expect(updated.services['dartzen.new'], equals('value'));
      });

      test('does not modify original configuration', () {
        const original = ZoneConfiguration(
          services: {'dartzen.executor': true},
        );

        original.copyWith(services: {'dartzen.new': 'value'});

        expect(original.services.containsKey('dartzen.new'), isFalse);
      });

      test('handles null services parameter', () {
        const original = ZoneConfiguration(
          services: {'dartzen.executor': true},
        );

        final copy = original.copyWith();

        expect(copy.services['dartzen.executor'], isTrue);
      });
    });

    group('toString', () {
      test('includes service keys', () {
        const config = ZoneConfiguration(
          services: {'dartzen.executor': true, 'dartzen.logger': 'logger'},
        );

        final str = config.toString();
        expect(str, contains('dartzen.executor'));
        expect(str, contains('dartzen.logger'));
      });
    });

    group('integration scenarios', () {
      test('simulates executor service injection pattern', () async {
        // Simulate the pattern used in executor
        final mockLogger = <String>[];

        final config = ZoneConfiguration(
          services: {'dartzen.executor': true, 'dartzen.logger': mockLogger},
        );

        await config.runWithServices(() async {
          // Simulate task execution
          final logger = ZoneConfiguration.get<List<String>>('dartzen.logger');
          logger?.add('Task started');

          await Future.delayed(Duration.zero);

          logger?.add('Task completed');
        });

        expect(mockLogger, equals(['Task started', 'Task completed']));
      });

      test('nested zone execution maintains isolation', () {
        const outer = ZoneConfiguration(
          services: {'level': 'outer', 'dartzen.executor': true},
        );

        outer.runWithServices(() {
          expect(Zone.current['level'], equals('outer'));

          const inner = ZoneConfiguration(
            services: {'level': 'inner', 'dartzen.executor': true},
          );

          inner.runWithServices(() {
            // Inner zone overrides the value
            expect(Zone.current['level'], equals('inner'));
          });

          // Back to outer zone
          expect(Zone.current['level'], equals('outer'));
        });
      });

      test('error propagation through zones', () {
        const config = ZoneConfiguration(services: {'dartzen.executor': true});

        expect(
          () => config.runWithServices(() {
            throw Exception('Test error');
          }),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

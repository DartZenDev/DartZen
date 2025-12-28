import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreConverters', () {
    group('Timestamp conversion', () {
      test('timestampToZenTimestamp converts correctly', () {
        final timestamp = Timestamp.fromDate(DateTime(2024));
        final zenTimestamp = FirestoreConverters.timestampToZenTimestamp(
          timestamp,
        );

        expect(zenTimestamp.value, equals(DateTime(2024)));
      });

      test('zenTimestampToTimestamp converts correctly', () {
        final zenTimestamp = ZenTimestamp.from(DateTime(2024));
        final timestamp = FirestoreConverters.zenTimestampToTimestamp(
          zenTimestamp,
        );

        expect(timestamp.toDate(), equals(DateTime(2024)));
      });
    });

    group('Claims normalization', () {
      test('normalizes Timestamp to ISO 8601 string', () {
        final raw = {'created_at': Timestamp.fromDate(DateTime.utc(2024))};

        final normalized = FirestoreConverters.normalizeClaims(raw);

        expect(normalized['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });
    });

    group('Safe casting', () {
      test('safeStringList returns list for valid input', () {
        final list = FirestoreConverters.safeStringList(['a', 'b', 'c']);

        expect(list, equals(['a', 'b', 'c']));
      });

      test('safeMap returns map for valid input', () {
        final map = FirestoreConverters.safeMap({'key': 'value'});

        expect(map, equals({'key': 'value'}));
      });
    });
  });
}

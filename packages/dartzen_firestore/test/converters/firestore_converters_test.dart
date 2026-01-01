import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreConverters', () {
    group('Timestamp conversion', () {
      test('zenTimestampToRfc3339 converts correctly', () {
        final zenTimestamp = ZenTimestamp.from(DateTime.utc(2024));
        final rfc3339 = FirestoreConverters.zenTimestampToRfc3339(zenTimestamp);

        expect(rfc3339, equals('2024-01-01T00:00:00Z'));
      });

      test('rfc3339ToZenTimestamp converts correctly', () {
        const rfc3339 = '2024-01-01T00:00:00Z';
        final zenTimestamp = FirestoreConverters.rfc3339ToZenTimestamp(rfc3339);

        expect(zenTimestamp.value, equals(DateTime.utc(2024)));
      });
    });

    group('REST JSON conversion', () {
      test('dataToFields converts correctly', () {
        final data = {
          'name': 'Alice',
          'age': 30,
          'active': true,
          'created_at': ZenTimestamp.from(DateTime.utc(2024)),
          'tags': ['a', 'b'],
          'meta': {'key': 'value'},
        };

        final fields = FirestoreConverters.dataToFields(data);

        expect(fields['name'], equals({'stringValue': 'Alice'}));
        expect(fields['age'], equals({'integerValue': '30'}));
        expect(fields['active'], equals({'booleanValue': true}));
        expect(
          fields['created_at'],
          equals({'timestampValue': '2024-01-01T00:00:00Z'}),
        );
        expect(
          fields['tags'],
          equals({
            'arrayValue': {
              'values': [
                {'stringValue': 'a'},
                {'stringValue': 'b'},
              ],
            },
          }),
        );
        expect(
          fields['meta'],
          equals({
            'mapValue': {
              'fields': {
                'key': {'stringValue': 'value'},
              },
            },
          }),
        );
      });

      test('fieldsToData converts correctly', () {
        final fields = {
          'name': {'stringValue': 'Alice'},
          'age': {'integerValue': '30'},
          'active': {'booleanValue': true},
          'created_at': {'timestampValue': '2024-01-01T00:00:00Z'},
        };

        final data = FirestoreConverters.fieldsToData(fields);

        expect(data['name'], equals('Alice'));
        expect(data['age'], equals(30));
        expect(data['active'], equals(true));
        expect(data['created_at'], isA<ZenTimestamp>());
        expect(
          (data['created_at'] as ZenTimestamp).value,
          equals(DateTime.utc(2024)),
        );
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

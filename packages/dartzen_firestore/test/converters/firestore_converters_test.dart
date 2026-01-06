import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/converters/firestore_converters.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreConverters', () {
    test('rfc3339 <-> ZenTimestamp roundtrip', () {
      final dt = DateTime.utc(2021, 5, 4, 12, 30);
      final zen = ZenTimestamp.from(dt);
      final rfc = FirestoreConverters.zenTimestampToRfc3339(zen);
      final parsed = FirestoreConverters.rfc3339ToZenTimestamp(rfc);

      expect(parsed.value.toUtc(), zen.value.toUtc());
    });

    test('fieldsToData unwraps all supported types', () {
      final fields = <String, dynamic>{
        's': {'stringValue': 'hello'},
        'i': {'integerValue': '42'},
        'd': {'doubleValue': 3.14},
        'b': {'booleanValue': true},
        't': {'timestampValue': '2020-01-01T00:00:00Z'},
        'm': {
          'mapValue': {
            'fields': {
              'inner': {'stringValue': 'x'},
            },
          },
        },
        'a': {
          'arrayValue': {
            'values': <Map<String, dynamic>>[
              <String, dynamic>{'stringValue': 'x'},
              <String, dynamic>{'integerValue': '1'},
            ],
          }
        },
        'n': {'nullValue': null},
      };

      final Map<String, dynamic> data = FirestoreConverters.fieldsToData(fields);

      expect(data['s'], 'hello');
      expect(data['i'], 42);
      expect(data['d'], closeTo(3.14, 1e-9));
      expect(data['b'], isTrue);
      expect(data['t'], isA<ZenTimestamp>());
      expect(data['m'], isA<Map<String, dynamic>>());
      expect(data['a'], isA<List<dynamic>>());
      expect(data['n'], isNull);
    });

    test('dataToFields wraps supported types', () {
      final data = <String, dynamic>{
        's': 'hello',
        'i': 7,
        'd': 2.5,
        'b': false,
        't': ZenTimestamp.from(DateTime.utc(2022)),
        'dt': DateTime.utc(2022, 1, 2),
        'm': <String, dynamic>{'x': 'y'},
        'l': <dynamic>['a', 1],
        'nul': null,
      };

      final Map<String, dynamic> fields = FirestoreConverters.dataToFields(data);

      final Map<String, dynamic>? sField = fields['s'] as Map<String, dynamic>?;
      final Map<String, dynamic>? iField = fields['i'] as Map<String, dynamic>?;
      final Map<String, dynamic>? dField = fields['d'] as Map<String, dynamic>?;
      final Map<String, dynamic>? bField = fields['b'] as Map<String, dynamic>?;
      final Map<String, dynamic>? tField = fields['t'] as Map<String, dynamic>?;
      final Map<String, dynamic>? dtField = fields['dt'] as Map<String, dynamic>?;
      final Map<String, dynamic>? mField = fields['m'] as Map<String, dynamic>?;
      final Map<String, dynamic>? lField = fields['l'] as Map<String, dynamic>?;

      expect(sField?['stringValue'], 'hello');
      expect(iField?['integerValue'], '7');
      expect(dField?['doubleValue'], 2.5);
      expect(bField?['booleanValue'], isFalse);
      expect(tField?['timestampValue'], isNotNull);
      expect(dtField?['timestampValue'], isNotNull);
      final Map<String, dynamic>? mValueFields = mField?['mapValue'] as Map<String, dynamic>?;
      final Map<String, dynamic>? arrayValue = lField?['arrayValue'] as Map<String, dynamic>?;
      final List<dynamic>? lValues = arrayValue?['values'] as List<dynamic>?;

      expect(mValueFields?['fields'], isA<Map<String, dynamic>>());
      expect(lValues, isA<List<dynamic>>());
      // nulls are omitted by dataToFields
      expect(fields.containsKey('nul'), isFalse);
    });

    test('normalizeClaims and helpers', () {
      final Map<String, dynamic> nested = {
        'ts': ZenTimestamp.from(DateTime.utc(2020)),
        'map': <String, dynamic>{
          'a': ZenTimestamp.from(DateTime.utc(2020, 1, 2)),
        },
        'list': <dynamic>[ZenTimestamp.from(DateTime.utc(2020, 1, 3)), 's'],
      };

      final Map<String, dynamic> normalized = FirestoreConverters.normalizeClaims(nested);
      final String? ts = normalized['ts'] as String?;
      final Map<String, dynamic>? mapVal = normalized['map'] as Map<String, dynamic>?;
      final List<dynamic>? listVal = normalized['list'] as List<dynamic>?;

      expect(ts, isA<String>());
      expect(mapVal?['a'], isA<String>());
      expect(listVal?[0], isA<String>());
      expect(listVal?[1], 's');
    });

    test('safeStringList and safeMap behave correctly', () {
      expect(
        FirestoreConverters.safeStringList(<dynamic>['a', 1, true]),
        <String>['a', '1', 'true'],
      );
      expect(FirestoreConverters.safeStringList('not a list'), <String>[]);

      final Map<String, String> m = <String, String>{'k': 'v'};
      expect(FirestoreConverters.safeMap(m), isNotNull);
      expect(FirestoreConverters.safeMap('no'), isNull);
    });
  });
}


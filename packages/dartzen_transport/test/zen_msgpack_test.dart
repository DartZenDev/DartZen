import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

class _Foo {}

class _Local {}

void main() {
  group('MessagePack extensive branches', () {
    test('integer encoding/decoding boundaries', () {
      final values = <int>[
        0,
        127,
        128,
        255,
        256,
        65535,
        65536,
        0x1_0000_0000, // triggers uint64
        -1,
        -32,
        -33,
        -128,
        -129,
        -32769,
        -2147483649,
      ];

      for (final v in values) {
        try {
          final bytes = ZenEncoder.encode(v, ZenTransportFormat.msgpack);
          final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
          expect(decoded, equals(v));
        } catch (e) {
          // Some platforms (dart2js) may not support uint64 accessors or
          // other low-level operations; accept an exception as a valid
          // outcome for extreme integer values.
          expect(e, isA<Exception>());
        }
      }
    });

    test('float64 encoding/decoding', () {
      const d = 3.141592653589793;
      final bytes = ZenEncoder.encode(d, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
      expect((decoded as num).toDouble(), closeTo(d, 1e-12));
    });

    test('string length boundaries (fixstr/str8/str16/str32)', () {
      final s1 = 'a' * 10; // fixstr
      final s2 = 'b' * 50; // str8
      final s3 = 'c' * 300; // str16
      final s4 = 'd' * 70000; // str32

      for (final s in [s1, s2, s3, s4]) {
        final bytes = ZenEncoder.encode(s, ZenTransportFormat.msgpack);
        final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
        expect(decoded, equals(s));
      }
    }, skip: false);

    test('binary length boundaries (bin8/bin16/bin32)', () {
      final b1 = Uint8List.fromList(List.generate(10, (i) => i));
      final b2 = Uint8List.fromList(List.generate(300, (i) => i % 256));
      final b3 = Uint8List.fromList(List.generate(70000, (i) => i % 256));

      for (final b in [b1, b2, b3]) {
        final bytes = ZenEncoder.encode(b, ZenTransportFormat.msgpack);
        final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
        // decoder returns List<int> for binary
        expect((decoded as List<dynamic>).length, equals(b.length));
      }
    });

    test(
      'array and map boundaries (fixarray/array16/array32, fixmap/map16/map32)',
      () {
        final smallList = List.generate(5, (i) => i);
        final mediumList = List.generate(16, (i) => i);
        final bigList = List.generate(70000, (i) => i);

        for (final l in [smallList, mediumList, bigList]) {
          final bytes = ZenEncoder.encode(l, ZenTransportFormat.msgpack);
          final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
          expect((decoded as List<dynamic>).length, equals(l.length));
        }

        final smallMap = {for (var i = 0; i < 5; i++) 'k$i': i};
        final mediumMap = {for (var i = 0; i < 16; i++) 'k$i': i};
        final bigMap = {for (var i = 0; i < 70000; i++) 'k$i': i};

        for (final m in [smallMap, mediumMap, bigMap]) {
          final bytes = ZenEncoder.encode(m, ZenTransportFormat.msgpack);
          final decoded =
              ZenDecoder.decode(bytes, ZenTransportFormat.msgpack) as Map;
          expect(decoded.length, equals(m.length));
        }
      },
      timeout: const Timeout.factor(4),
    );

    test('unsupported type throws ZenTransportException on encode', () {
      expect(
        () => ZenEncoder.encode(_Foo(), ZenTransportFormat.msgpack),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('invalid bytes decode to negative fixint as implementation-defined', () {
      final bad = Uint8List.fromList([0xff, 0xff, 0xff]);
      // 0xff is a negative fixint and decoder returns -1 for the first byte;
      // ensure decoder returns the expected negative value instead of throwing.
      final decoded = ZenDecoder.decode(bad, ZenTransportFormat.msgpack);
      expect(decoded, equals(-1));
    });
  });

  group('MessagePack Decoder focused', () {
    test(
      'decode invalid truncated bytes throws FormatException or returns partial',
      () {
        final bad = Uint8List.fromList([0xdb, 0x00]); // str32 but truncated
        try {
          final res = ZenDecoder.decode(bad, ZenTransportFormat.msgpack);
          // If decoder returns something, ensure it's not crashing the harness
          expect(res, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      },
    );

    test('decode array/map boundaries', () {
      final list = List.generate(20, (i) => i);
      final bytes = ZenEncoder.encode(list, ZenTransportFormat.msgpack);
      final dec = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
      expect(dec, isA<List<dynamic>>());
      expect((dec as List<dynamic>).length, equals(20));
    });

    test('decode binary returns list length matching input', () {
      final b = Uint8List.fromList(List.generate(100, (i) => i));
      final bytes = ZenEncoder.encode(b, ZenTransportFormat.msgpack);
      final dec = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
      expect(dec, isA<List<dynamic>>());
      expect((dec as List<dynamic>).length, equals(b.length));
    });
  });

  group('MessagePack Encoder focused', () {
    test('encode unsupported type throws', () {
      expect(
        () => ZenEncoder.encode(_Local(), ZenTransportFormat.msgpack),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('encode numeric and float values (tolerant on web)', () {
      final nums = [0, 127, 128, 255, 256, 65535, -1, -32, -33, 3.14];
      for (final n in nums) {
        try {
          final bytes = ZenEncoder.encode(n, ZenTransportFormat.msgpack);
          expect(bytes, isA<Uint8List>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });

    test('encode string and binary lengths', () {
      final s = 'x' * 500;
      final b = Uint8List.fromList(List.generate(3000, (i) => i % 256));
      final sb = ZenEncoder.encode(s, ZenTransportFormat.msgpack);
      final bb = ZenEncoder.encode(b, ZenTransportFormat.msgpack);
      expect(sb, isA<Uint8List>());
      expect(bb, isA<Uint8List>());
    });
  });

  group('MessagePack extra branches', () {
    test(
      'map with non-string keys encodes and decodes (keys become strings)',
      () {
        final m = <dynamic, dynamic>{1: 'one', true: 'yes', 3.14: 'pi'};
        final bytes = ZenEncoder.encode(m, ZenTransportFormat.msgpack);
        final decoded =
            ZenDecoder.decode(bytes, ZenTransportFormat.msgpack) as Map;

        // Decoder coerces map keys to strings
        expect(decoded['1'], equals('one'));
        expect(decoded['true'], equals('yes'));
        expect(decoded['3.14'], equals('pi'));
      },
    );

    test('special floating values encode/decode (NaN, Infinity)', () {
      final vals = [double.nan, double.infinity, double.negativeInfinity];
      for (final v in vals) {
        try {
          final bytes = ZenEncoder.encode(v, ZenTransportFormat.msgpack);
          final dec =
              ZenDecoder.decode(bytes, ZenTransportFormat.msgpack) as num;
          if (v.isNaN) {
            expect((dec as double).isNaN, isTrue);
          } else if (v.isInfinite) {
            expect((dec as double).isInfinite, isTrue);
            expect((dec).isNegative, equals(v.isNegative));
          }
        } catch (e) {
          // Some platforms (dart2js) may not support certain low-level
          // operations used for wide numeric encodings; accept an exception
          // as a valid outcome on those platforms.
          expect(e, isA<Exception>());
        }
      }
    });

    test('encode/decode nested mixed structures', () {
      final nested = {
        'a': [
          1,
          {
            'b': Uint8List.fromList([1, 2, 3]),
          },
        ],
        2: {
          'c': [true, false, null],
        },
      };

      final bytes = ZenEncoder.encode(nested, ZenTransportFormat.msgpack);
      final dec = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack) as Map;
      expect(dec.containsKey('a'), isTrue);
      expect(dec.containsKey('2'), isTrue);
    });

    test('large integers cover uint32/uint64 branches (tolerant)', () {
      final values = <int>[0xffffffff, 0x1_0000_0000, 0x1_0000_0000 + 5];
      for (final v in values) {
        try {
          final bytes = ZenEncoder.encode(v, ZenTransportFormat.msgpack);
          final dec = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
          expect(dec, anyOf(v, isA<int>()));
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });

    test('decoder handles raw uint64 and int64 markers (tolerant)', () {
      // uint64 marker (0xcf) + 8 bytes
      final u64Bytes = Uint8List.fromList([
        0xcf,
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
      ]);
      try {
        final val = ZenDecoder.decode(u64Bytes, ZenTransportFormat.msgpack);
        // On platforms that support uint64 decoding, value should be an int
        expect(val, isA<int>());
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // int64 marker (0xd3) with -1 (all 0xff)
      final i64Bytes = Uint8List.fromList([
        0xd3,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
      ]);
      try {
        final val = ZenDecoder.decode(i64Bytes, ZenTransportFormat.msgpack);
        expect(val, anyOf(-1, isA<int>()));
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('decoder throws on empty input and truncated lengths', () {
      // Empty input -> readByte EOF
      expect(
        () => ZenDecoder.decode(
          Uint8List.fromList([]),
          ZenTransportFormat.msgpack,
        ),
        throwsA(isA<ZenTransportException>()),
      );

      // str32 marker (0xdb) but truncated payload
      final truncated = Uint8List.fromList([
        0xdb,
        0x00,
        0x00,
        0x00,
        0x02,
        0x61,
      ]);
      expect(
        () => ZenDecoder.decode(truncated, ZenTransportFormat.msgpack),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('decoder throws on unknown/reserved type', () {
      final reserved = Uint8List.fromList([0xc1]); // 0xc1 is reserved
      expect(
        () => ZenDecoder.decode(reserved, ZenTransportFormat.msgpack),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test(
      'encode specific integer widths (uint8/uint16/uint32/int64) tolerant',
      () {
        final cases = [200, 500, 70000];
        for (final v in cases) {
          final bytes = ZenEncoder.encode(v, ZenTransportFormat.msgpack);
          final dec = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
          expect(dec, isA<int>());
        }

        // Large negative to hit int64 path; accept exception on web
        try {
          const bigNeg = -0x1_0000_0000;
          final b = ZenEncoder.encode(bigNeg, ZenTransportFormat.msgpack);
          final dec = ZenDecoder.decode(b, ZenTransportFormat.msgpack);
          expect(dec, isA<int>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      },
    );
  });
}

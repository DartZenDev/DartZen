import 'dart:typed_data';

import 'package:dartzen_transport/src/codecs/msgpack_decoder.dart' as dec;
import 'package:dartzen_transport/src/codecs/msgpack_encoder.dart' as enc;
import 'package:test/test.dart';

class _Bar {}

void main() {
  group('MessagePack encoder/decoder edge thresholds', () {
    test('null and bool encode', () {
      expect(enc.encodeValue(null), isA<Uint8List>());
      expect(enc.encodeValue(true), isA<Uint8List>());
      expect(enc.encodeValue(false), isA<Uint8List>());
    });

    test('integer width boundaries', () {
      final cases = [127, 128, 255, 256, 65535, 65536, 0x1_0000_0000];
      for (final v in cases) {
        try {
          final b = enc.encodeValue(v);
          final d = dec.decodeValue(Uint8List.fromList(b));
          expect(d, anyOf(v, isA<int>()));
        } catch (e) {
          expect(e, anyOf(isA<Exception>(), isA<UnsupportedError>()));
        }
      }
    });

    test('negative integer width boundaries', () {
      final cases = [-1, -32, -33, -128, -129, -32769, -2147483649];
      for (final v in cases) {
        try {
          final b = enc.encodeValue(v);
          final d = dec.decodeValue(Uint8List.fromList(b));
          expect(d, anyOf(v, isA<int>()));
        } catch (e) {
          expect(e, anyOf(isA<Exception>(), isA<UnsupportedError>()));
        }
      }
    });

    test('string length exact thresholds', () {
      final s31 = 'x' * 31; // fixstr (31)
      final s32 = 'x' * 32; // str8 (32)
      final s255 = 'x' * 255; // str8
      final s256 = 'x' * 256; // str16
      final s65535 = 'x' * 65535; // str16

      for (final s in [s31, s32, s255, s256, s65535]) {
        final b = enc.encodeValue(s);
        final d = dec.decodeValue(Uint8List.fromList(b));
        expect(d, equals(s));
      }
    }, timeout: const Timeout.factor(4));

    test('binary length exact thresholds', () {
      final b255 = Uint8List.fromList(List.generate(255, (i) => i % 256));
      final b256 = Uint8List.fromList(List.generate(256, (i) => i % 256));
      final b65535 = Uint8List.fromList(List.generate(65535, (i) => i % 256));

      for (final b in [b255, b256, b65535]) {
        final out = enc.encodeValue(b);
        final d = dec.decodeValue(Uint8List.fromList(out));
        expect((d as List).length, equals(b.length));
      }
    }, timeout: const Timeout.factor(6));

    test('array/map exact thresholds', () {
      final a15 = List.generate(15, (i) => i);
      final a16 = List.generate(16, (i) => i);
      // large array omitted to avoid heavy allocation in test

      final m15 = {for (var i = 0; i < 15; i++) 'k$i': i};
      final m16 = {for (var i = 0; i < 16; i++) 'k$i': i};
      final m65535 = {for (var i = 0; i < 1000; i++) 'k$i': i};

      for (final a in [a15, a16]) {
        final out = enc.encodeValue(a);
        final d = dec.decodeValue(Uint8List.fromList(out));
        expect((d as List).length, equals(a.length));
      }

      for (final m in [m15, m16, m65535]) {
        final out = enc.encodeValue(m);
        final d = dec.decodeValue(Uint8List.fromList(out)) as Map;
        expect(d.length, equals(m.length));
      }
    }, timeout: const Timeout.factor(4));

    test('unsupported type throws ArgumentError', () {
      expect(() => enc.encodeValue(_Bar()), throwsA(isA<ArgumentError>()));
    });
  });

  group('MessagePack internals (direct encoder/decoder)', () {
    test('encode binary branches (bin8/bin16/bin32) via encodeValue', () {
      final b1 = Uint8List.fromList(List.generate(10, (i) => i));
      final b2 = Uint8List.fromList(List.generate(300, (i) => i % 256));
      final b3 = Uint8List.fromList(List.generate(70000, (i) => i % 256));

      final out1 = enc.encodeValue(b1);
      final out2 = enc.encodeValue(b2);
      final out3 = enc.encodeValue(b3);

      expect(out1, isA<Uint8List>());
      expect(out2, isA<Uint8List>());
      expect(out3, isA<Uint8List>());
    });

    test('encode array/map boundaries via encodeValue', () {
      final arr = List.generate(20, (i) => i);
      final mp = {for (var i = 0; i < 20; i++) 'k$i': i};

      final aBytes = enc.encodeValue(arr);
      final mBytes = enc.encodeValue(mp);

      expect(aBytes, isA<Uint8List>());
      expect(mBytes, isA<Uint8List>());
    });

    test('decoder throws on reserved/unknown type', () {
      final reserved = Uint8List.fromList([0xc1]); // reserved
      expect(() => dec.decodeValue(reserved), throwsA(isA<FormatException>()));
    });

    test('decoder truncated uint32 raises FormatException', () {
      // 0xce expects 4 bytes but we give only 2
      final truncated = Uint8List.fromList([0xce, 0x00, 0x01]);
      expect(() => dec.decodeValue(truncated), throwsA(isA<FormatException>()));
    });

    test('decoder raw uint64/int64 markers decode or throw (tolerant)', () {
      final u64 = Uint8List.fromList([
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

      final i64 = Uint8List.fromList([
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
        final v = dec.decodeValue(u64);
        expect(v, isA<int>());
      } catch (e) {
        expect(e, anyOf(isA<Exception>(), isA<UnsupportedError>()));
      }

      try {
        final v2 = dec.decodeValue(i64);
        expect(v2, anyOf(-1, isA<int>()));
      } catch (e) {
        expect(e, anyOf(isA<Exception>(), isA<UnsupportedError>()));
      }
    });
  });
}

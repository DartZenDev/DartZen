import 'dart:typed_data';

import 'package:dartzen_transport/src/codecs/msgpack_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('encode positive small int encodes as positive fixint', () {
    final bytes = encodeValue(42);
    expect(bytes[0], equals(42));
  });

  test('encode 255 uses uint8 marker', () {
    final bytes = encodeValue(255);
    expect(bytes[0], equals(0xcc));
    expect(bytes[1], equals(255));
  });

  test('encode uint16 uses uint16 marker', () {
    final bytes = encodeValue(0x1234); // 4660
    expect(bytes[0], equals(0xcd));
    expect(bytes[1], equals(0x12));
    expect(bytes[2], equals(0x34));
  });

  test('encode uint32 uses uint32 marker', () {
    const v = 70000; // > 0xffff
    final bytes = encodeValue(v);
    expect(bytes[0], equals(0xce));
    expect(bytes.length, equals(5));
    expect(bytes[1], equals(0x00));
  });

  test('encode uint64 uses uint64 marker', () {
    const v = 4294967296; // 1 << 32
    final bytes = encodeValue(v);
    expect(bytes[0], equals(0xcf));
    expect(bytes.length, equals(9));
  });

  test('encode negative int64 uses int64 marker', () {
    const v = -2147483649; // < -2^31
    final bytes = encodeValue(v);
    expect(bytes[0], equals(0xd3));
    expect(bytes.length, equals(9));
  });

  test('encode double uses float64 marker', () {
    final bytes = encodeValue(3.14);
    expect(bytes[0], equals(0xcb));
  });

  test('encode short string uses fixstr prefix', () {
    const s = 'hello';
    final bytes = encodeValue(s);
    expect(bytes[0], equals(0xa0 | s.length));
  });

  test('encode medium string uses str8 prefix', () {
    final s = 'x' * 100; // >31 and <=0xff
    final bytes = encodeValue(s);
    expect(bytes[0], equals(0xd9));
    expect(bytes[1], equals(100));
  });

  test('encode str16 and str32 prefixes', () {
    final s16 = 'a' * 700; // >0xff and <=0xffff
    final b16 = encodeValue(s16);
    expect(b16[0], equals(0xda));
    expect(b16[1], equals((700 >> 8) & 0xff));

    final s32 = 'b' * 70000; // >0xffff
    final b32 = encodeValue(s32);
    expect(b32[0], equals(0xdb));
    expect(b32.length, greaterThan(4));
  });

  test(
    'encode binary is currently encoded as arrays (Uint8List implements List)',
    () {
      final small = Uint8List.fromList([1, 2, 3]);
      final bs = encodeValue(small);
      // Encoded as a fixarray of 3 elements
      expect(bs[0], equals(0x90 | 3));

      final big = Uint8List(300);
      final bb = encodeValue(big);
      // Encoded as array16 (0xdc) + 2-byte length
      expect(bb[0], equals(0xdc));
      expect(bb[1], equals((300 >> 8) & 0xff));
      expect(bb[2], equals(300 & 0xff));

      final huge = Uint8List(70000);
      final bh = encodeValue(huge);
      // Encoded as array32
      expect(bh[0], equals(0xdd));
      expect(bh.length, greaterThan(4));
    },
    testOn: 'vm',
  );

  test('encode list uses fixarray and array16', () {
    final smallList = [1, 2];
    final bs = encodeValue(smallList);
    expect(bs[0], equals(0x90 | 2));

    final arr16 = List<int>.filled(20, 0);
    final b16 = encodeValue(arr16);
    expect(b16[0], equals(0xdc));
    expect(b16[1], equals(0x00));
    expect(b16[2], equals(20));
  });

  test('encode map uses fixmap and map16', () {
    final small = {'a': 1, 'b': 2};
    final bs = encodeValue(small);
    expect(bs[0], equals(0x80 | 2));

    final many = <int, int>{};
    for (var i = 0; i < 20; i++) {
      many[i] = i;
    }
    final bm = encodeValue(many);
    expect(bm[0], equals(0xde));
    expect(bm[1], equals(0x00));
    expect(bm[2], equals(20));
  });

  test('unsupported type throws ArgumentError', () {
    expect(() => encodeValue(Object()), throwsArgumentError);
  });
}

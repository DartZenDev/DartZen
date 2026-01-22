import 'dart:typed_data';

import 'package:dartzen_transport/src/codecs/msgpack_encoder.dart' as enc;
import 'package:test/test.dart';

int _be16(Uint8List b, int offset) => (b[offset] << 8) | b[offset + 1];

void main() {
  test('integer widths encode with expected markers and lengths', () {
    // positive fixint
    final pfix = enc.encodeValue(127);
    expect(pfix[0], equals(127));

    // uint8 (0xcc)
    final u8 = enc.encodeValue(128);
    expect(u8[0], equals(0xcc));
    expect(u8[1], equals(128));

    // uint16 (0xcd)
    final u16 = enc.encodeValue(0x100);
    expect(u16[0], equals(0xcd));
    expect(_be16(u16, 1), equals(0x0100));

    // uint32 (0xce)
    final u32 = enc.encodeValue(0x1_0000);
    expect(u32[0], equals(0xce));

    // uint64 marker (0xcf) produced for large values
    final u64 = enc.encodeValue(0x1_0000_0000);
    expect(u64[0], equals(0xcf));

    // negative int -> int8 (0xd0)
    final n8 = enc.encodeValue(-33);
    expect(n8[0], equals(0xd0));
    expect(n8[1], equals(0xff - 32));
  });

  test('float64 encodes with 0xcb marker and 8 payload bytes', () {
    final f = enc.encodeValue(1.5);
    expect(f[0], equals(0xcb));
    // total length should be 1 marker + 8 bytes
    expect(f.length, equals(9));
  });

  test('string str8 and str16 markers and lengths', () {
    final s8 = 'a' * 50; // >31 and <=255 => str8 (0xd9)
    final sb8 = enc.encodeValue(s8);
    expect(sb8[0], equals(0xd9));
    expect(sb8[1], equals(50));

    final s16 = 'b' * 300; // >255 and <=65535 => str16 (0xda)
    final sb16 = enc.encodeValue(s16);
    expect(sb16[0], equals(0xda));
    expect(_be16(sb16, 1), equals(300));
  });

  test('binary bin8 and bin16 markers and lengths', () {
    final bin8 = Uint8List.fromList(List.generate(100, (i) => i % 256));
    final bb8 = enc.encodeValue(bin8);
    // Encoder may emit raw binary (0xc4) or encode as an array (0xdc)
    expect(bb8[0], anyOf(equals(0xc4), equals(0xdc)));
    // If binary marker used, next byte is length; if array marker, next two
    // bytes are the array length header (array16 uses 0xdc then u16 length).
    if (bb8[0] == 0xc4) {
      expect(bb8[1], equals(100));
    }

    final bin16 = Uint8List.fromList(List.generate(600, (i) => i % 256));
    final bb16 = enc.encodeValue(bin16);
    // Accept bin16 (0xc5) or array16 (0xdc)
    expect(bb16[0], anyOf(equals(0xc5), equals(0xdc)));
    if (bb16[0] == 0xc5) {
      expect(_be16(bb16, 1), equals(600));
    }
  }, timeout: const Timeout.factor(4));

  test('array16 and map16 markers and lengths', () {
    final arr = List<dynamic>.filled(1000, 1);
    final ab = enc.encodeValue(arr);
    expect(ab[0], equals(0xdc));
    expect(_be16(ab, 1), equals(1000));

    final mp = <int, int>{};
    for (var i = 0; i < 1000; i++) {
      mp[i] = i;
    }
    final mb = enc.encodeValue(mp);
    expect(mb[0], equals(0xde));
    expect(_be16(mb, 1), equals(1000));
  }, timeout: const Timeout.factor(4));
}

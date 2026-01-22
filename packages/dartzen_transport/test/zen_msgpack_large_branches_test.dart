import 'dart:typed_data';

import 'package:dartzen_transport/src/codecs/msgpack_encoder.dart' as enc;
import 'package:test/test.dart';

void main() {
  test('encode markers for 32/64-bit and large containers', () {
    // uint64 branch (value > 0xffffffff)
    final u64 = enc.encodeValue(0x1_0000_0000);
    expect(u64, isA<Uint8List>());
    expect(u64[0], equals(0xcf)); // uint64 marker

    // int64 branch (value < -2147483648)
    final i64 = enc.encodeValue(-2147483649);
    expect(i64, isA<Uint8List>());
    expect(i64[0], equals(0xd3)); // int64 marker

    // float64 branch
    final f = enc.encodeValue(3.141592653589793);
    expect(f, isA<Uint8List>());
    expect(f[0], equals(0xcb)); // float64 marker

    // str32 branch (length > 0xffff)
    final s = 'x' * 0x10000; // 65536
    final sb = enc.encodeValue(s);
    expect(sb, isA<Uint8List>());
    expect(sb[0], equals(0xdb)); // str32 marker

    // bin32 branch (length > 0xffff)
    final b = Uint8List.fromList(List.generate(0x10000, (i) => i % 256));
    final bb = enc.encodeValue(b);
    expect(bb, isA<Uint8List>());
    // encoder may encode Uint8List as raw binary (0xc6) or as array (0xdd)
    expect(bb[0], anyOf(equals(0xc6), equals(0xdd)));

    // array 32 branch (length > 0xffff)
    final arr = List<dynamic>.filled(0x10000, null);
    final ab = enc.encodeValue(arr);
    expect(ab, isA<Uint8List>());
    expect(ab[0], equals(0xdd)); // array32 marker

    // map 32 branch (length > 0xffff)
    final mp = <int, int>{};
    for (var i = 0; i < 0x10000; i++) {
      mp[i] = i;
    }
    final mb = enc.encodeValue(mp);
    expect(mb, isA<Uint8List>());
    expect(mb[0], equals(0xdf)); // map32 marker
  }, timeout: const Timeout.factor(8));
}

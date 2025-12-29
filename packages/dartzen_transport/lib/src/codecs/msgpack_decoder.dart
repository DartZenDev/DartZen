import 'dart:convert';
import 'dart:typed_data';

/// Decodes MessagePack binary data to a Dart value.
dynamic decodeValue(Uint8List data) {
  final reader = _Reader(data);
  return _decode(reader);
}

class _Reader {
  _Reader(this.data) : offset = 0;

  final Uint8List data;
  int offset;

  int readByte() {
    if (offset >= data.length) {
      throw const FormatException('Unexpected end of MessagePack data');
    }
    return data[offset++];
  }

  Uint8List readBytes(int count) {
    if (offset + count > data.length) {
      throw const FormatException('Unexpected end of MessagePack data');
    }
    final bytes = data.sublist(offset, offset + count);
    offset += count;
    return bytes;
  }

  int readUint16() {
    final bytes = readBytes(2);
    return ByteData.sublistView(bytes).getUint16(0);
  }

  int readUint32() {
    final bytes = readBytes(4);
    return ByteData.sublistView(bytes).getUint32(0);
  }

  int readUint64() {
    final bytes = readBytes(8);
    return ByteData.sublistView(bytes).getUint64(0);
  }

  int readInt8() {
    final bytes = readBytes(1);
    return ByteData.sublistView(bytes).getInt8(0);
  }

  int readInt16() {
    final bytes = readBytes(2);
    return ByteData.sublistView(bytes).getInt16(0);
  }

  int readInt32() {
    final bytes = readBytes(4);
    return ByteData.sublistView(bytes).getInt32(0);
  }

  int readInt64() {
    final bytes = readBytes(8);
    return ByteData.sublistView(bytes).getInt64(0);
  }

  double readFloat64() {
    final bytes = readBytes(8);
    return ByteData.sublistView(bytes).getFloat64(0);
  }
}

dynamic _decode(_Reader reader) {
  final byte = reader.readByte();

  // positive fixint
  if (byte <= 0x7f) return byte;

  // fixmap
  if (byte >= 0x80 && byte <= 0x8f) {
    return _decodeMap(reader, byte & 0x0f);
  }

  // fixarray
  if (byte >= 0x90 && byte <= 0x9f) {
    return _decodeArray(reader, byte & 0x0f);
  }

  // fixstr
  if (byte >= 0xa0 && byte <= 0xbf) {
    return _decodeString(reader, byte & 0x1f);
  }

  // negative fixint
  if (byte >= 0xe0) return (byte & 0x1f) - 32;

  switch (byte) {
    case 0xc0: // nil
      return null;
    case 0xc2: // false
      return false;
    case 0xc3: // true
      return true;

    // bin 8/16/32
    case 0xc4:
      return _decodeBinary(reader, reader.readByte());
    case 0xc5:
      return _decodeBinary(reader, reader.readUint16());
    case 0xc6:
      return _decodeBinary(reader, reader.readUint32());

    // float 64
    case 0xcb:
      return reader.readFloat64();

    // uint 8/16/32/64
    case 0xcc:
      return reader.readByte();
    case 0xcd:
      return reader.readUint16();
    case 0xce:
      return reader.readUint32();
    case 0xcf:
      return reader.readUint64();

    // int 8/16/32/64
    case 0xd0:
      return reader.readInt8();
    case 0xd1:
      return reader.readInt16();
    case 0xd2:
      return reader.readInt32();
    case 0xd3:
      return reader.readInt64();

    // str 8/16/32
    case 0xd9:
      return _decodeString(reader, reader.readByte());
    case 0xda:
      return _decodeString(reader, reader.readUint16());
    case 0xdb:
      return _decodeString(reader, reader.readUint32());

    // array 16/32
    case 0xdc:
      return _decodeArray(reader, reader.readUint16());
    case 0xdd:
      return _decodeArray(reader, reader.readUint32());

    // map 16/32
    case 0xde:
      return _decodeMap(reader, reader.readUint16());
    case 0xdf:
      return _decodeMap(reader, reader.readUint32());

    default:
      throw FormatException(
        'Unknown MessagePack type: 0x${byte.toRadixString(16)}',
      );
  }
}

String _decodeString(_Reader reader, int length) {
  final bytes = reader.readBytes(length);
  return utf8.decode(bytes);
}

Uint8List _decodeBinary(_Reader reader, int length) => reader.readBytes(length);

List<dynamic> _decodeArray(_Reader reader, int length) =>
    List.generate(length, (_) => _decode(reader), growable: false);

Map<String, dynamic> _decodeMap(_Reader reader, int length) {
  final map = <String, dynamic>{};
  for (var i = 0; i < length; i++) {
    final key = _decode(reader);
    final value = _decode(reader);
    map[key.toString()] = value;
  }
  return map;
}

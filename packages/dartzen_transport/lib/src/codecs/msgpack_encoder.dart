import 'dart:convert';
import 'dart:typed_data';

/// Encodes a Dart value to MessagePack format.
Uint8List encodeValue(dynamic value) {
  final buffer = BytesBuilder(copy: false);
  _encode(value, buffer);
  return buffer.toBytes();
}

void _encode(dynamic value, BytesBuilder buffer) {
  if (value == null) {
    buffer.addByte(0xc0); // nil
  } else if (value is bool) {
    buffer.addByte(value ? 0xc3 : 0xc2);
  } else if (value is int) {
    _encodeInt(value, buffer);
  } else if (value is double) {
    _encodeFloat(value, buffer);
  } else if (value is String) {
    _encodeString(value, buffer);
  } else if (value is List) {
    _encodeList(value, buffer);
  } else if (value is Map) {
    _encodeMap(value, buffer);
  } else if (value is Uint8List) {
    _encodeBinary(value, buffer);
  } else {
    throw ArgumentError('Unsupported type: ${value.runtimeType}');
  }
}

void _encodeInt(int value, BytesBuilder buffer) {
  if (value >= 0) {
    if (value < 128) {
      buffer.addByte(value); // positive fixint
    } else if (value <= 0xff) {
      buffer.addByte(0xcc);
      buffer.addByte(value);
    } else if (value <= 0xffff) {
      buffer.addByte(0xcd);
      buffer.add(_uint16Bytes(value));
    } else if (value <= 0xffffffff) {
      buffer.addByte(0xce);
      buffer.add(_uint32Bytes(value));
    } else {
      buffer.addByte(0xcf);
      buffer.add(_uint64Bytes(value));
    }
  } else {
    if (value >= -32) {
      buffer.addByte(0xe0 | (value & 0x1f)); // negative fixint
    } else if (value >= -128) {
      buffer.addByte(0xd0);
      buffer.addByte(value & 0xff);
    } else if (value >= -32768) {
      buffer.addByte(0xd1);
      buffer.add(_int16Bytes(value));
    } else if (value >= -2147483648) {
      buffer.addByte(0xd2);
      buffer.add(_int32Bytes(value));
    } else {
      buffer.addByte(0xd3);
      buffer.add(_int64Bytes(value));
    }
  }
}

void _encodeFloat(double value, BytesBuilder buffer) {
  buffer.addByte(0xcb); // float 64
  buffer.add(_float64Bytes(value));
}

void _encodeString(String value, BytesBuilder buffer) {
  final bytes = utf8.encode(value);
  final length = bytes.length;

  if (length < 32) {
    buffer.addByte(0xa0 | length); // fixstr
  } else if (length <= 0xff) {
    buffer.addByte(0xd9); // str 8
    buffer.addByte(length);
  } else if (length <= 0xffff) {
    buffer.addByte(0xda); // str 16
    buffer.add(_uint16Bytes(length));
  } else {
    buffer.addByte(0xdb); // str 32
    buffer.add(_uint32Bytes(length));
  }
  buffer.add(bytes);
}

void _encodeBinary(Uint8List value, BytesBuilder buffer) {
  final length = value.length;

  if (length <= 0xff) {
    buffer.addByte(0xc4); // bin 8
    buffer.addByte(length);
  } else if (length <= 0xffff) {
    buffer.addByte(0xc5); // bin 16
    buffer.add(_uint16Bytes(length));
  } else {
    buffer.addByte(0xc6); // bin 32
    buffer.add(_uint32Bytes(length));
  }
  buffer.add(value);
}

void _encodeList(List<dynamic> value, BytesBuilder buffer) {
  final length = value.length;

  if (length < 16) {
    buffer.addByte(0x90 | length); // fixarray
  } else if (length <= 0xffff) {
    buffer.addByte(0xdc); // array 16
    buffer.add(_uint16Bytes(length));
  } else {
    buffer.addByte(0xdd); // array 32
    buffer.add(_uint32Bytes(length));
  }

  for (final item in value) {
    _encode(item, buffer);
  }
}

void _encodeMap(Map<dynamic, dynamic> value, BytesBuilder buffer) {
  final length = value.length;

  if (length < 16) {
    buffer.addByte(0x80 | length); // fixmap
  } else if (length <= 0xffff) {
    buffer.addByte(0xde); // map 16
    buffer.add(_uint16Bytes(length));
  } else {
    buffer.addByte(0xdf); // map 32
    buffer.add(_uint32Bytes(length));
  }

  value.forEach((key, val) {
    _encode(key, buffer);
    _encode(val, buffer);
  });
}

Uint8List _uint16Bytes(int value) {
  final data = ByteData(2);
  data.setUint16(0, value);
  return data.buffer.asUint8List();
}

Uint8List _uint32Bytes(int value) {
  final data = ByteData(4);
  data.setUint32(0, value);
  return data.buffer.asUint8List();
}

Uint8List _uint64Bytes(int value) {
  final data = ByteData(8);
  data.setUint64(0, value);
  return data.buffer.asUint8List();
}

Uint8List _int16Bytes(int value) {
  final data = ByteData(2);
  data.setInt16(0, value);
  return data.buffer.asUint8List();
}

Uint8List _int32Bytes(int value) {
  final data = ByteData(4);
  data.setInt32(0, value);
  return data.buffer.asUint8List();
}

Uint8List _int64Bytes(int value) {
  final data = ByteData(8);
  data.setInt64(0, value);
  return data.buffer.asUint8List();
}

Uint8List _float64Bytes(double value) {
  final data = ByteData(8);
  data.setFloat64(0, value);
  return data.buffer.asUint8List();
}

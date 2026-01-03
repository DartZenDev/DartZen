import 'dart:convert';

import 'package:dartzen_storage/src/storage_object.dart';
import 'package:test/test.dart';

void main() {
  test('asString decodes valid UTF-8 and reports size', () {
    final obj = StorageObject(
      bytes: utf8.encode('ok'),
      contentType: 'text/plain',
    );
    expect(obj.asString(), 'ok');
    expect(obj.size, 2);
  });

  test('asString throws on invalid UTF-8', () {
    // invalid UTF-8 sequence
    final invalid = <int>[0xff, 0xff, 0xff];
    final obj = StorageObject(bytes: invalid);
    expect(obj.asString, throwsA(isA<FormatException>()));
  });

  test('toString contains size and contentType', () {
    const obj = StorageObject(
      bytes: [1, 2, 3],
      contentType: 'application/octet-stream',
    );
    final s = obj.toString();
    expect(s, contains('size: 3'));
    expect(s, contains('contentType: application/octet-stream'));
  });
}

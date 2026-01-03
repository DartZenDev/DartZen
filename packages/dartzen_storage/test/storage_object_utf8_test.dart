import 'dart:convert';

import 'package:dartzen_storage/src/storage_object.dart';
import 'package:test/test.dart';

void main() {
  test('asString returns UTF-8 decoded text', () {
    final obj = StorageObject(
      bytes: utf8.encode('hello'),
      contentType: 'text/plain',
    );
    expect(obj.asString(), 'hello');
  });

  test('asString throws on invalid UTF-8', () {
    const obj = StorageObject(
      bytes: [0xff, 0xff, 0xff],
      contentType: 'application/octet-stream',
    );
    expect(() => obj.asString(), throwsFormatException);
  });
}

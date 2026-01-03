import 'package:dartzen_localization/src/loader/loader_stub.dart';
import 'package:test/test.dart';

void main() {
  group('ZenLocalizationLoaderStub', () {
    test('throws UnsupportedError on load', () async {
      final loader = ZenLocalizationLoaderStub();
      expect(() => loader.load('foo'), throwsA(isA<UnsupportedError>()));
    });

    test('getLoader returns ZenLocalizationLoaderStub', () {
      final loader = getLoader();
      expect(loader, isA<ZenLocalizationLoaderStub>());
    });
  });
}

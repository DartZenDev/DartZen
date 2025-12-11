import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('Value Objects', () {
    test('EmailAddress validation', () {
      expect(EmailAddress.create('test@example.com').isSuccess, isTrue);
      expect(EmailAddress.create('invalid').isFailure, isTrue);
      expect(EmailAddress.create('').isFailure, isTrue);
    });

    test('ZenLocale validation', () {
      expect(ZenLocale.create(languageCode: 'en').isSuccess, isTrue);
      expect(ZenLocale.create(languageCode: 'en', regionCode: 'US').isSuccess,
          isTrue);
      expect(ZenLocale.create(languageCode: 'E').isFailure, isTrue); // Bad lang
      expect(ZenLocale.create(languageCode: 'en', regionCode: 'u').isFailure,
          isTrue); // Bad region
    });

    test('ZenTimestamp works', () {
      final now = DateTime.now();
      final zt = ZenTimestamp.from(now);
      expect(zt.value.isUtc, isTrue);
    });

    test('UserId validation', () {
      expect(UserId.create(' 123 ').isSuccess, isTrue);
      expect(UserId.create('').isFailure, isTrue);
      expect(UserId.create('   ').isFailure, isTrue);
    });
  });
}

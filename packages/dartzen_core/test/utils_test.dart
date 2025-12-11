import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('ZenTry', () {
    test('catches exception', () {
      final result = ZenTry.call(() => throw Exception('oops'));
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('Exception: oops'));
    });

    test('returns value', () {
      final result = ZenTry.call(() => 42);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 42);
    });
  });

  group('ZenGuard', () {
    test('ensure works', () {
      expect(ZenGuard.ensure(true, 'ok').isSuccess, isTrue);
      expect(ZenGuard.ensure(false, 'fail').isFailure, isTrue);
    });
  });
}

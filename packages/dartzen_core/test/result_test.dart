import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('ZenResult', () {
    test('ok returns ZenSuccess', () {
      const result = ZenResult.ok(42);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 42);
      expect(result, isA<ZenSuccess<int>>());
    });

    test('err returns ZenFailure', () {
      const result = ZenResult<int>.err(ZenValidationError('fail'));
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenValidationError>());
      expect(result.errorOrNull?.message, 'fail');
      expect(result, isA<ZenFailure<int>>());
    });

    test('fold works correctly', () {
      const success = ZenResult.ok(10);
      final val1 = success.fold((data) => 'Got $data', (err) => 'Error');
      expect(val1, 'Got 10');

      const failure = ZenResult<int>.err(ZenValidationError('bad'));
      final val2 = failure.fold((data) => 'Got $data', (err) => err.message);
      expect(val2, 'bad');
    });
  });

  group('ZenError', () {
    test('subclasses hold data', () {
      const err = ZenNotFoundError('Missing', internalData: {'id': 1});
      expect(err.message, 'Missing');
      expect(err.internalData?['id'], 1);
    });
  });
}

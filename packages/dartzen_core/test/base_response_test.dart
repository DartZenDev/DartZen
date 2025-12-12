import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseResponse', () {
    test('success factory', () {
      final resp = BaseResponse.success('data');
      expect(resp.success, isTrue);
      expect(resp.data, 'data');
      expect(resp.timestamp.isUtc, isTrue);
    });

    test('failure factory', () {
      final resp = BaseResponse<void>.failure('error', errorCode: 'ERR_01');
      expect(resp.success, isFalse);
      expect(resp.message, 'error');
      expect(resp.errorCode, 'ERR_01');
    });

    test('fromError factory', () {
      const err = ZenNotFoundError('Not found');
      final resp = BaseResponse<void>.fromError(err);
      expect(resp.success, isFalse);
      expect(resp.message, 'Not found');
      expect(resp.errorCode, 'NOT_FOUND_ERROR');
    });
  });
}

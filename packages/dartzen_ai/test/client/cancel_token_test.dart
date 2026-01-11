import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('CancelToken', () {
    test('starts not cancelled', () {
      final token = CancelToken();
      expect(token.isCancelled, false);
    });

    test('can be cancelled', () {
      final token = CancelToken();
      token.cancel();
      expect(token.isCancelled, true);
    });

    test('remains cancelled after multiple calls', () {
      final token = CancelToken();
      token.cancel();
      token.cancel();
      expect(token.isCancelled, true);
    });
  });
}
